import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../entities/predict_result.dart';
import '../pages/manually_crop_page.dart';
import '../entities/detection_result.dart';

// convert predict result to probabilities
// take the Python code in Chinese Wikipedia as a reference:
// https://zh.wikipedia.org/wiki/Softmax%E5%87%BD%E6%95%B0
List<PredictResult> softmax(List<MapEntry<int, double>> nums) {
  if (nums.isEmpty) return [];
  final maximum = nums.map((e) => e.value).reduce(math.max);
  Iterable<double> exps = nums.map((e) => math.exp(e.value - maximum));

  double sumExp = exps.reduce((a, b) => a + b);
  List<double> probabilities = exps.map((exp) => exp / sumExp).toList();

  return List.generate(
    nums.length,
    (i) => PredictResult(nums[i].key, probabilities[i]),
  );
}

List<PredictResult> getTop(
  List<PredictResult> probs, {
  int amount = 3,
  bool hideLowProb = true,
  double lowestValue = 0.01,
}) {
  probs.sort((a, b) => b.prob.compareTo(a.prob));

  return probs
      .where((e) => !hideLowProb || e.prob > lowestValue)
      .take(amount)
      .toList();
}

Future<Uint8List?> autoCrop(Uint8List imageData, DetectionBox box) async =>
    Isolate.run<Uint8List?>(() => _autoCrop(imageData, box));

Future<Uint8List?> _autoCrop(Uint8List imageData, DetectionBox box) async {
  if (!box.isValid) return null;
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(imageData);
  } catch (_) {
    return null;
  }

  if (decoded == null || !box.isValid) {
    return null;
  }

  final int imageWidth = decoded.width;
  final int imageHeight = decoded.height;

  final left = (imageWidth * box.left).floor().clamp(0, imageWidth - 1);
  final top = (imageHeight * box.top).floor().clamp(0, imageHeight - 1);
  final right = (imageWidth * box.right).ceil().clamp(left + 1, imageWidth);
  final bottom = (imageHeight * box.bottom).ceil().clamp(top + 1, imageHeight);
  final width = right - left;
  final height = bottom - top;

  final cropped = img.copyCrop(
    decoded,
    x: left,
    y: top,
    width: width,
    height: height,
  );

  return Uint8List.fromList(img.encodePng(cropped));
}

Future<Uint8List?> manuallyCrop(BuildContext context, Uint8List file) async {
  final crop = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CropPage(imageData: file)),
  );

  if (crop is Uint8List) {
    return crop;
  } else {
    return null;
  }
}
