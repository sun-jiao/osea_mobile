import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../entities/ai_tools.dart';
import '../entities/detection_result.dart';
import '../entities/localization_mixin.dart';
import '../entities/predict_result.dart';
import '../entities/tools.dart' as tools;
import '../pages/settings_page.dart';
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
  static const int _birdIndex = 16;

  List<PredictResult> _topResults = [];
  List<DetectionResult> _detectionResults = [];
  int _objIndex = 0;

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
        title: Text(AppLocale.title.getString(context)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
            },
            icon: Icon(Icons.more_vert_rounded),
          ),
        ],
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
                        if (_objIndex > 0)
                          Positioned(
                            left: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton.filled(
                                onPressed: () {
                                  _objIndex--;
                                  _switchCrop();
                                },
                                icon: Icon(Icons.arrow_left_rounded),
                              ),
                            ),
                          ),
                        if (_objIndex < _detectionResults.length - 1)
                          Positioned(
                            right: 4,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: IconButton.filled(
                                onPressed: () {
                                  _objIndex++;
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
              : Center(
                  child: Text(
                    AppLocale.imgNeeded.getString(context),
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
    _detectionResults = (await AiTools.birdDetect(_file)).where((e) => e.cls == _birdIndex).toList();
    _objIndex = 0;
    final Uint8List crop;

    if (_detectionResults.isNotEmpty) {
      crop = await tools.autoCrop(_file, _detectionResults[_objIndex].box) ?? _file;
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

    _objIndex = -1;
  }

  Future<void> _switchCrop() async {
    if (_detectionResults.isEmpty) {
      return;
    }

    _startProcess();

    final crop = await tools.autoCrop(_file, _detectionResults[_objIndex].box) ?? _file;

    setState(() {
      _image = crop;
    });

    List<double> prediction = await AiTools.birdID(_image);
    _endProcess(tools.getTop(tools.softmax(prediction)));
  }
}
