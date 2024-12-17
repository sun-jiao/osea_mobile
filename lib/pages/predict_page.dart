import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

import '../entities/predict_result.dart';
import '../entities/tools.dart' as tools;
import '../widgets/blured_image.dart';
import '../widgets/predict_tile.dart';
import 'camera_awesome_page.dart';

final ImagePicker picker = ImagePicker();
const _bird = 14;

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  static ClassificationModel? classificationModel;
  static ModelObjectDetection? objectModel;

  List<PredictResult> topResults = [];
  String imagePath = '';
  Uint8List image = Uint8List(0);

  bool isPredicting = false;

  startNewPredict(XFile result) async {
    String path = result.path;
    setState(() {
      // 清空上次的识别结果
      topResults.clear();
      imagePath = path;
    });

    var file = await File(imagePath).readAsBytes();

    setState(() {
      image = file;
    });

    while (objectModel == null) {
      objectModel = await PytorchLite.loadObjectDetectionModel(
          "assets/models/yolo11n.pt", 80, 640, 640,
          objectDetectionModelType: ObjectDetectionModelType.yolov8);
    }

    List<ResultObjectDetection> objDetect = await objectModel!.getImagePrediction(file);

    final birds = objDetect.where((e) => e.classIndex == _bird).toList();

    if (birds.isNotEmpty) {
      file = await tools.cropImage(file, birds.first.rect) ?? file;

      setState(() {
        image = file;
      });
    }

    while (classificationModel == null) {
      classificationModel = await PytorchLite.loadClassificationModel(
          "assets/models/bird_model.pt", 224, 224, 11000);
    }

    List<double> prediction = await classificationModel!.getImagePredictionList(file);

    setState(() {
      topResults = tools.getTop(tools.softmax(prediction));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bird ID'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: IconButton(
          icon: const Icon(Icons.image),
          onPressed: () async {
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);

            if (image != null) {
              startNewPredict(image);
            }
          },
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        label: IconButton(
          icon: const Icon(Icons.camera),
          onPressed: () async {
            XFile? photo;
            try {
              photo = await picker.pickImage(source: ImageSource.camera);
            } catch (e) {
              if (context.mounted) {
                photo = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraPage()),
                );
              }
            }

            if (photo != null) {
              startNewPredict(photo);
            }
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          imagePath.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: BlurredImageWidget(
                        imageProvider: MemoryImage(image),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shadowColor: Colors.transparent,
                      child: Column(
                        children: topResults.map((e) => ResultTile(result: e)).toList(),
                      ),
                    )
                  ],
                )
              : const Center(
            child: Text(
              '请上传图片以供识别',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (isPredicting)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
