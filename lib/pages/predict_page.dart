import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/lib.dart';

import '../entities/ai_tools.dart';
import '../entities/predict_result.dart';
import '../entities/tools.dart' as tools;
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
  List<PredictResult> _topResults = [];
  List<ResultObjectDetection> _yoloResults = [];
  int _yoloIndex = 0;
  
  // the complete image file
  Uint8List _file = Uint8List(0);
  
  // part of the complete image, used for identification,
  // cropped by user or automatically cropped based on yolo detection
  Uint8List _image = Uint8List(0);

  bool _isProcessing = false;

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
          onPressed: _pickPhoto,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        label: IconButton(
          icon: const Icon(Icons.camera),
          onPressed: _takePhoto,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          _image.isNotEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1,
                          child: BlurredImageWidget(
                            imageProvider: MemoryImage(_image),
                            backProvider: MemoryImage(_file),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: IconButton.filled(
                            onPressed: _reCropImage,
                            icon: Icon(Icons.crop_rounded),
                          ),
                        ),
                        if (_yoloIndex > 0)
                          Positioned(
                            left: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton.filled(
                                onPressed: () {
                                  _yoloIndex--;
                                  _switchCrop();
                                },
                                icon: Icon(Icons.arrow_left_rounded),
                              ),
                            ),
                          ),
                        if (_yoloIndex < _yoloResults.length - 1)
                          Positioned(
                            right: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton.filled(
                                onPressed: () {
                                  _yoloIndex++;
                                  _switchCrop();
                                },
                                icon: Icon(Icons.arrow_right_rounded),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      shadowColor: Colors.transparent,
                      child: Column(
                        children: _topResults
                            .map((e) => ResultTile(result: e))
                            .toList(),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    '请上传图片以供识别',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    XFile? photo;
    try {
      // call device stock camera
      photo = await picker.pickImage(source: ImageSource.camera);
    } catch (e) {
      // if stock camera is unavailable, use built-in camera
      if (mounted) {
        photo = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraPage()),
        );
      }
    }

    if (photo != null) {
      _startNewPredict(photo);
    }
  }

  Future<void> _pickPhoto() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _startNewPredict(image);
    }
  }
  
  void _startProcess() {
    setState(() {
      // clear previous id result
      _topResults.clear();
      _isProcessing = true;
    });
  }

  void _endProcess(List<PredictResult> results) {
    setState(() {
      _topResults = results;
      _isProcessing = false;
    });
  }

  void _startNewPredict(XFile xFile) async {
    _startProcess();
    _file = await File(xFile.path).readAsBytes();
    _yoloResults = await AiTools.birdDetect(_file);
    _yoloIndex = 0;
    final Uint8List crop;

    if (_yoloResults.isNotEmpty) {
      crop = await tools.autoCrop(_file, _yoloResults[_yoloIndex].rect) ?? _file;
    } else if (mounted) {
      crop = (await tools.manuallyCrop(context, _file)) ?? _file;
    } else {
      return;
    }

    setState(() {
      _image = crop;
    });

    List<double> prediction = await AiTools.birdID(_image);
    _endProcess(tools.getTop(tools.softmax(prediction)));
  }
  
  Future<void> _reCropImage() async {
    _startProcess();

    final Uint8List? crop = await tools.manuallyCrop(context, _file);

    if (crop is Uint8List) {
      setState(() {
        _image = crop;
      });
    }

    List<double> prediction = await AiTools.birdID(_image);

    _endProcess(tools.getTop(tools.softmax(prediction)));

    _yoloIndex = -1;
  }

  Future<void> _switchCrop() async {
    if (_yoloResults.isEmpty) {
      return;
    }

    _startProcess();

    final crop = await tools.autoCrop(_file, _yoloResults[_yoloIndex].rect) ?? _file;

    setState(() {
      _image = crop;
    });

    List<double> prediction = await AiTools.birdID(_image);
    _endProcess(tools.getTop(tools.softmax(prediction)));
  }
}
