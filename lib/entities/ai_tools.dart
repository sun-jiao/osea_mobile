import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:image/image.dart' as img;

import 'detection_result.dart';

class AiTools {
  static ClassificationModel? _classifyModel;
  static OrtSession? _classifyModelOnnx;
  static OrtSession? _detectModel;

  static Future<void> _initDetectModel() async {
    final sessionOptions = OrtSessionOptions();
    final rawAssetFile = await rootBundle.load("assets/models/ssd_mobilenet.onnx");
    final bytes = rawAssetFile.buffer.asUint8List();
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

    return List.generate(count.toInt(), (i) => DetectionResult(boxes[i], classes[i].toInt(), scores[i]));
  }

  static Future<List<double>> birdID(Uint8List image) async {
    while (_classifyModel == null) {
      _classifyModel = await PytorchLite.loadClassificationModel(
          "assets/models/bird_model.pt", 224, 224, 11000);
    }

    return await _classifyModel!.getImagePredictionList(image);
  }

  static Future<void> _initClassifyModel() async {
    final sessionOptions = OrtSessionOptions();
    final rawAssetFile = await rootBundle.load("assets/models/bird_model.onnx");
    final bytes = rawAssetFile.buffer.asUint8List();
    _classifyModelOnnx = OrtSession.fromBuffer(bytes, sessionOptions);
  }

  static Future<List<double>> birdIDOnnx(Uint8List image0) async {
    while (_classifyModelOnnx == null) {
      await _initClassifyModel();
    }

    img.Image image = img.decodeImage(image0)!;
    image = img.copyResize(image, width: 224, height: 224);

    final rgbaTensor = await _imageToFloatTensor(image);
    final inputTensor = Float32List.fromList(rgbaTensor);
    final shape = [1, 3, 224, 224];

    final inputOrt = OrtValueTensor.createTensorWithDataList(inputTensor, shape);

    final sessionOptions = OrtSessionOptions();
    final rawAssetFile = await rootBundle.load("assets/models/bird_model.onnx");
    final bytes = rawAssetFile.buffer.asUint8List();
    final session = OrtSession.fromBuffer(bytes, sessionOptions);

    final inputs = {session.inputNames[0]: inputOrt};
    final runOptions = OrtRunOptions();
    final outputs = await session.runAsync(runOptions, inputs);
    inputOrt.release();
    runOptions.release();
    final result = (outputs![0]!.value as List);
    for (var element in outputs) {
      element?.release();
    }
    return result[0] as List<double>;
  }

  static Future<List<double>> _imageToFloatTensor(img.Image image) async {
    final imageAsFloatBytes = image.getBytes(order: img.ChannelOrder.rgba);
    final rgbaUints = Uint8List.view(imageAsFloatBytes.buffer);

    final indexed = rgbaUints.indexed;
    return [
      ...indexed.where((e) => e.$1 % 4 == 0).map((e) => e.$2.toDouble()),
      ...indexed.where((e) => e.$1 % 4 == 1).map((e) => e.$2.toDouble()),
      ...indexed.where((e) => e.$1 % 4 == 2).map((e) => e.$2.toDouble()),
    ];
  }
}
