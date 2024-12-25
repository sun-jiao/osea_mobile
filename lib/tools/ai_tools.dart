import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

import '../entities/detection_result.dart';

class AiTools {
  static OrtSession? _classifyModel;
  static OrtSession? _detectModel;

  static Future<void> _initDetectModel() async {
    final rawAssetFile = await rootBundle.load("assets/models/ssd_mobilenet.onnx");
    final bytes = rawAssetFile.buffer.asUint8List();
    final sessionOptions = OrtSessionOptions();
    _detectModel = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  static Future<List<DetectionResult>> birdDetect(Uint8List file) async {
    while (_detectModel == null) {
      await _initDetectModel();
    }

    img.Image image = img.decodeImage(file)!;
    final input = image.getBytes(order: img.ChannelOrder.rgb);
    final shape = [1, image.height, image.width, 3];
    final inputOrt = OrtValueTensor.createTensorWithDataList(input, shape);

    final inputs = {_detectModel!.inputNames[0]: inputOrt};
    final runOptions = OrtRunOptions();
    final outputs = await _detectModel!.runAsync(runOptions, inputs);
    inputOrt.release();
    runOptions.release();
    final boxes = (outputs![0]!.value as List<List<List<double>>>)[0];
    final classes = (outputs[1]!.value as List<List<double>>)[0];
    final scores = (outputs[2]!.value as List<List<double>>)[0];
    final count = (outputs[3]!.value as List)[0] as double;
    for (var element in outputs) {
      element?.release();
    }

    return List.generate(count.toInt(),
        (i) => DetectionResult(boxes[i], classes[i].toInt(), scores[i]));
  }
  
  static Future<void> _initClassifyModel() async {
    final rawAssetFile = await rootBundle.load("assets/models/bird_model.onnx");
    final bytes = rawAssetFile.buffer.asUint8List();
    final sessionOptions = OrtSessionOptions();
    _classifyModel = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  static Future<List<double>> birdID(Uint8List image0) async {
    while (_classifyModel == null) {
      await _initClassifyModel();
    }

    img.Image image = img.decodeImage(image0)!;
    image = img.copyResize(image, width: 224, height: 224);

    final rgbaTensor = await _imageToFloatTensor(image);
    final inputTensor = Float32List.fromList(rgbaTensor);
    final shape = [1, 3, 224, 224];

    final inputOrt = OrtValueTensor.createTensorWithDataList(inputTensor, shape);

    final inputs = {_classifyModel!.inputNames[0]: inputOrt};
    final runOptions = OrtRunOptions();
    final outputs = await _classifyModel!.runAsync(runOptions, inputs);
    inputOrt.release();
    runOptions.release();
    final result = (outputs![0]!.value as List);
    for (var element in outputs) {
      element?.release();
    }
    return result[0] as List<double>;
  }

  // normalize image
  static Future<List<double>> _imageToFloatTensor(img.Image image,
      {List<double> mean = const [0.485, 0.456, 0.406],
      List<double> std = const [0.229, 0.224, 0.225]}) async {
    final imageAsFloatBytes = image.getBytes(order: img.ChannelOrder.rgba);
    final rgbaUints = Uint8List.view(imageAsFloatBytes.buffer);

    final indexed = rgbaUints.indexed;
    return [
      ...indexed
          .where((e) => e.$1 % 4 == 0)
          .map((e) => (e.$2.toDouble() / 255 - mean[0]) / std[0]),
      ...indexed
          .where((e) => e.$1 % 4 == 1)
          .map((e) => (e.$2.toDouble() / 255 - mean[1]) / std[1]),
      ...indexed
          .where((e) => e.$1 % 4 == 2)
          .map((e) => (e.$2.toDouble() / 255 - mean[2]) / std[2]),
    ];
  }
}
