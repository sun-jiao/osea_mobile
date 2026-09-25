import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../entities/detection_result.dart';
import '../entities/localization_mixin.dart';
import '../entities/predict_result.dart';
import '../tools/ai_tools.dart';
import '../tools/distribution_tool.dart';
import '../tools/shared_pref_tool.dart';
import '../tools/location_tool.dart';
import '../tools/tools.dart' as tools;
import '../pages/settings_page.dart';
import '../widgets/blured_image.dart';
import '../widgets/predict_tile.dart';
import 'camera_awesome_page.dart';
import 'map_page.dart';

final ImagePicker picker = ImagePicker();

class PredictScreen extends StatefulWidget {
  const PredictScreen({
    super.key,
    this.detect = AiTools.birdDetect,
    this.identify = AiTools.birdID,
    this.pickImage,
    this.autoCrop = tools.autoCrop,
  });

  final Future<List<DetectionResult>> Function(Uint8List) detect;
  final Future<List<double>> Function(Uint8List) identify;
  final Future<XFile?> Function(ImageSource)? pickImage;
  final Future<Uint8List?> Function(Uint8List, DetectionBox) autoCrop;

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  static const int _birdIndex = 16;
  static const double _minimumDetectionScore = 0.5;

  List<PredictResult> _topResults = [];
  List<DetectionResult> _detectionResults = [];
  int _objIndex = 0;
  List<double> _predictions = [];
  bool isOutOfRange = false;

  // the complete image file
  Uint8List _file = Uint8List(0);

  // part of the complete image, used for identification,
  // cropped by user or automatically cropped based on yolo detection
  Uint8List _image = Uint8List(0);

  bool _isProcessing = false;
  Future<void> Function()? _retryAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocale.title.getString(context)),
        actions: [
          IconButton(
            onPressed: _isProcessing
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    ).then((e) {
                      if (mounted) setState(() {});
                    });
                  },
            icon: Icon(Icons.settings_rounded),
          ),
        ],
        leading: IconButton(
          onPressed: _isProcessing
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapPage()),
                  ).then((e) {
                    if (mounted && _predictions.isNotEmpty) {
                      _runProcess(_endProcess);
                    }
                  });
                },
          icon: Icon(Icons.location_on_rounded),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: IconButton(
          icon: const Icon(Icons.image_rounded),
          onPressed: _isProcessing ? null : _pickPhoto,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(100)),
        ),
        label: IconButton(
          icon: const Icon(Icons.camera_alt_rounded),
          onPressed: _isProcessing ? null : _takePhoto,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Stack(
        children: [
          _image.isNotEmpty
              ? OrientationBuilder(
                  builder: (context, orientation) {
                    final imageWidget = Expanded(
                      child: Stack(
                        children: [
                          BlurredImageWidget(
                            imageProvider: MemoryImage(_image),
                            backProvider: MemoryImage(_file),
                          ),
                          Positioned(
                            left: 4,
                            bottom: 4,
                            child: IconButton.filled(
                              onPressed: _isProcessing ? null : _reCropImage,
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
                                    if (_isProcessing) return;
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
                                    if (_isProcessing) return;
                                    _objIndex++;
                                    _switchCrop();
                                  },
                                  icon: Icon(Icons.arrow_right_rounded),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                    if (orientation == Orientation.portrait) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          imageWidget,
                          if (isOutOfRange)
                            Center(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: Text(
                                  AppLocale.outOfRange.getString(context),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              child: ListView(
                                children: _topResults
                                    .map((e) => ResultTile(result: e))
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          imageWidget,
                          Expanded(
                            child: Column(
                              children: [
                                if (isOutOfRange)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        0,
                                      ),
                                      child: Text(
                                        AppLocale.outOfRange.getString(context),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.all(16),
                                    child: ListView(
                                      children: _topResults
                                          .map((e) => ResultTile(result: e))
                                          .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                )
              : Center(
                  child: Text(
                    AppLocale.imgNeeded.getString(context),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
          if (_isProcessing) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Future<void> _runProcess(Future<void> Function() action) async {
    if (_isProcessing || !mounted) return;
    _retryAction = null;
    setState(() => _isProcessing = true);
    try {
      await action();
      _retryAction = null;
    } catch (error, stack) {
      debugPrint('Identification failed: $error\n$stack');
      if (mounted) {
        _retryAction ??= action;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocale.processingFailed.getString(context)),
            action: SnackBarAction(
              label: AppLocale.retry.getString(context),
              onPressed: () {
                final retry = _retryAction;
                if (retry != null) _runProcess(retry);
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<XFile?> _pickImage(ImageSource source) =>
      widget.pickImage?.call(source) ?? picker.pickImage(source: source);

  Future<void> _takePhoto() => _runProcess(() async {
    XFile? photo;
    try {
      photo = await _pickImage(ImageSource.camera);
    } catch (_) {
      if (mounted) {
        photo = await Navigator.push<XFile>(
          context,
          MaterialPageRoute(builder: (_) => const CameraPage()),
        );
      }
    }
    if (photo != null && mounted) await _startNewPredict(photo);
  });

  Future<void> _pickPhoto() => _runProcess(() async {
    final image = await _pickImage(ImageSource.gallery);
    if (image != null && mounted) await _startNewPredict(image);
  });

  Future<void> _endProcess() async {
    final List<MapEntry<int, double>> filtered;

    switch (SharedPrefTool.locationFilter) {
      case AppLocale.locationFilterOff:
        filtered = _predictions.asMap().entries.toList();
        break;
      case AppLocale.locationFilterFix:
        filtered = await Distribution.getFilteredPredictions(
          _predictions,
          SharedPrefTool.locationFilterLat,
          SharedPrefTool.locationFilterLng,
        );
        break;
      case AppLocale.locationFilterAuto:
        final Position? position = await getCurrentLocation(context);

        if (position == null) {
          if (!mounted) {
            return;
          }

          Fluttertoast.showToast(
            msg: AppLocale.locationRetrieveFailed.getString(context),
          );
          filtered = _predictions.asMap().entries.toList();
        } else {
          filtered = await Distribution.getFilteredPredictions(
            _predictions,
            position.latitude,
            position.longitude,
          );
        }
        break;
      default:
        Fluttertoast.showToast(
          msg: AppLocale.locationFilterError.getString(context),
        );
        filtered = _predictions.asMap().entries.toList();
        break;
    }

    List<PredictResult> results;

    if (filtered.isEmpty) {
      results = [];
    } else {
      results = tools.getTop(tools.softmax(filtered));
    }

    if (results.isEmpty) {
      isOutOfRange = true;
      results = tools.getTop(
        tools.softmax(_predictions.asMap().entries.toList()),
      );
    } else {
      isOutOfRange = false;
    }

    if (!mounted) return;
    setState(() {
      _topResults = results;
    });
  }

  Future<void> _startNewPredict(XFile xFile) async {
    _retryAction = () => _startNewPredict(xFile);
    setState(() {
      _topResults = [];
      _image = Uint8List(0);
      _predictions = [];
    });
    isOutOfRange = false;
    _file = await xFile.readAsBytes();
    _detectionResults = (await widget.detect(_file))
        .where(
          (e) =>
              e.cls == _birdIndex &&
              e.score.isFinite &&
              e.score >= _minimumDetectionScore &&
              e.box.isValid,
        )
        .toList();
    _objIndex = 0;
    final Uint8List crop;

    if (_detectionResults.isNotEmpty) {
      crop =
          await widget.autoCrop(_file, _detectionResults[_objIndex].box) ??
          _file;
    } else if (mounted) {
      crop = (await tools.manuallyCrop(context, _file)) ?? _file;
    } else {
      return;
    }

    if (!mounted) return;
    setState(() {
      _image = crop;
      _topResults = [];
      _predictions = [];
    });

    _predictions = PredictResult.labeledScores(await widget.identify(_image));
    if (mounted) await _endProcess();
  }

  Future<void> _reCropImage() => _runProcess(() async {
    final Uint8List? crop = await tools.manuallyCrop(context, _file);

    if (!mounted || crop == null) return;
    setState(() {
      _image = crop;
      _topResults = [];
      _predictions = [];
      _objIndex = -1;
    });

    _predictions = PredictResult.labeledScores(await widget.identify(_image));

    if (mounted) await _endProcess();
  });

  Future<void> _switchCrop() => _runProcess(() async {
    if (_detectionResults.isEmpty) {
      return;
    }

    final crop =
        await widget.autoCrop(_file, _detectionResults[_objIndex].box) ?? _file;

    if (!mounted) return;
    setState(() {
      _image = crop;
      _topResults = [];
      _predictions = [];
    });

    _predictions = PredictResult.labeledScores(await widget.identify(_image));
    if (mounted) await _endProcess();
  });
}
