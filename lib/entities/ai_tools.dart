import 'dart:typed_data';

import 'package:pytorch_lite/pytorch_lite.dart';

class AiTools {
  static ClassificationModel? _classifyModel;
  static ModelObjectDetection? _detectModel;

  static Future<List<ResultObjectDetection>> birdDetect(Uint8List file) async {
    while (_detectModel == null) {
      _detectModel = await PytorchLite.loadObjectDetectionModel(
          "assets/models/yolo11n.pt", 80, 640, 640,
          labelPath: "assets/labels/yolo_labels.txt",
          objectDetectionModelType: ObjectDetectionModelType.yolov8);
    }

    List<ResultObjectDetection> objDetect = await _detectModel!.getImagePrediction(file);

    return objDetect.where((e) => e.className == "bird").toList();
  }

  static Future<List<double>> birdID(Uint8List image) async {
    while (_classifyModel == null) {
      _classifyModel = await PytorchLite.loadClassificationModel(
          "assets/models/bird_model.pt", 224, 224, 11000);
    }

    return await _classifyModel!.getImagePredictionList(image);
  }
}