import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../entities/predict_result.dart';
import '../pages/manually_crop_page.dart';
import 'detection_result.dart';

// convert predict result to probabilities
// take the Python code in Chinese Wikipedia as a reference:
// https://zh.wikipedia.org/wiki/Softmax%E5%87%BD%E6%95%B0
List<double> softmax(List<double> nums) {
  Iterable<double> exps = nums.map((e) => math.exp(e));

  double sumExp = exps.reduce((a, b) => a + b);
  Iterable<double> probabilities = exps.map((exp) => exp / sumExp);

  return probabilities.toList();
}

List<PredictResult> getTop(List<double> probs, {
  int amount = 3,
  bool hideLowProb = true,
  double lowestValue = 0.01
}) {
  List<MapEntry<int, double>> sortedList = List.from(probs.asMap().entries)
    ..sort((a, b) => b.value.compareTo(a.value));
  List<MapEntry<int, double>> filteredList =
      sortedList.where((e) => !hideLowProb || e.value > lowestValue).toList();

  return filteredList
      .take(amount)
      .map((e) => PredictResult(e.key, e.value))
      .toList();
}

Future<Uint8List?> autoCrop(Uint8List imageData, DetectionBox box) async {
  final decoded = img.decodeImage(imageData);

  if (decoded == null) {
    return null;
  }

  final int imageWidth = decoded.width;
  final int imageHeight = decoded.height;

  final int left = (imageWidth * box.left).floor();
  final int width = (imageWidth * box.width).floor();
  final int top = (imageHeight * box.top).floor();
  final int height = (imageHeight * box.height).floor();

  final cropped =
      img.copyCrop(decoded, x: left, y: top, width: width, height: height);

  return Uint8List.fromList(img.encodePng(cropped));
}

Future<Uint8List?> manuallyCrop(BuildContext context, Uint8List file) async {
  final crop = await Navigator.push(context,
      MaterialPageRoute(builder: (context) => CropPage(imageData: file)));

  if (crop is Uint8List) {
    return crop;
  } else {
    return null;
  }
}
