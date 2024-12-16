import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../entities/predict_result.dart';
import '../widgets/blured_image.dart';
import '../widgets/predict_tile.dart';
import 'camera_awesome_page.dart';

final ImagePicker picker = ImagePicker();

class PredictScreen extends StatefulWidget {
  const PredictScreen({super.key});

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  List<PredictResult> topResults = [];
  String imagePath = '';

  bool isPredicting = false;

  startNewPredict(XFile result) async {
    String? path = result.path;
    setState(() {
      // 清空上次的识别结果
      topResults.clear();
      imagePath = path;
    });
    // _uploadAndRecognizeImage(path);
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
                        imageProvider: FileImage(File(imagePath)),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shadowColor: Colors.transparent,
                      child: Column(
                        children: [
                          if (topResults.isNotEmpty)
                            ResultTile(result: topResults.first),
                          if (topResults.length > 1)
                            ResultTile(result: topResults[1]),
                          if (topResults.length > 2)
                            ResultTile(result: topResults[2]),
                        ],
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
