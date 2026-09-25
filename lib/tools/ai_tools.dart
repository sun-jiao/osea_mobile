import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:image/image.dart' as img;

import '../entities/detection_result.dart';

class AiTools {
  static OrtSession? _classifyModel;
  static OrtSession? _detectModel;
  static Future<void>? _initialization;
  static Future<void> _pending = Future.value();
  static bool _closing = false;

  static Future<void> initFuture() {
    if (_closing) return Future.error(StateError('Models are closing'));
    return _initialization ??= _initialize().catchError((Object error) {
      _detectModel?.release();
      _classifyModel?.release();
      _detectModel = null;
      _classifyModel = null;
      _initialization = null;
      throw error;
    });
  }

  static Future<void> _initialize() async {
    _detectModel = await _loadModel('assets/models/ssd_mobilenet.onnx');
    _classifyModel = await _loadModel('assets/models/bird_model.onnx');
  }

  static Future<OrtSession> _loadModel(String path) async {
    final asset = await rootBundle.load(path);
    final bytes = asset.buffer.asUint8List(
      asset.offsetInBytes,
      asset.lengthInBytes,
    );
    return Isolate.run(() {
      final options = OrtSessionOptions();
      try {
        return OrtSession.fromBuffer(bytes, options);
      } finally {
        options.release();
      }
    });
  }

  static Future<T> _enqueue<T>(Future<T> Function() action) {
    if (_closing) return Future.error(StateError('Models are closing'));
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  static Future<void> dispose() async {
    _closing = true;
    await _pending;
    try {
      await _initialization;
    } catch (_) {}
    _detectModel?.release();
    _classifyModel?.release();
    _detectModel = null;
    _classifyModel = null;
    _initialization = null;
  }

  static Future<List<DetectionResult>> birdDetect(Uint8List file) =>
      _enqueue(() async {
        await initFuture();

        late final Uint8List input;
        late final List<int> shape;

        (input, shape) = await Isolate.run<(Uint8List, List<int>)>(() async {
          img.Image image =
              (img.decodeImage(file) ??
              (throw const FormatException('Unsupported image')));
          final input = image.getBytes(order: img.ChannelOrder.rgb);
          final shape = [1, image.height, image.width, 3];
          return (input, shape);
        });

        final inputOrt = OrtValueTensor.createTensorWithDataList(input, shape);

        final inputs = {_detectModel!.inputNames[0]: inputOrt};
        final runOptions = OrtRunOptions();
        List<OrtValue?>? outputs;
        try {
          outputs = await _detectModel!.runAsync(runOptions, inputs);
          final boxes = (outputs![0]!.value as List<List<List<double>>>)[0];
          final classes = (outputs[1]!.value as List<List<double>>)[0];
          final scores = (outputs[2]!.value as List<List<double>>)[0];
          final count = (outputs[3]!.value as List)[0] as double;
          return List.generate(
            count.toInt(),
            (i) => DetectionResult(boxes[i], classes[i].toInt(), scores[i]),
          );
        } finally {
          for (final output in outputs ?? <OrtValue?>[]) {
            output?.release();
          }
          inputOrt.release();
          runOptions.release();
        }
      });

  static Future<List<double>> birdID(Uint8List image0) => _enqueue(() async {
    await initFuture();

    late final Float32List inputTensor;
    late final List<int> shape;

    (inputTensor, shape) = await Isolate.run<(Float32List, List<int>)>(
      () async {
        img.Image image =
            (img.decodeImage(image0) ??
            (throw const FormatException('Unsupported image')));
        image = img.copyResize(image, width: 224, height: 224);

        final rgbaTensor = await _imageToFloatTensor(image);
        final inputTensor = Float32List.fromList(rgbaTensor);
        final shape = [1, 3, 224, 224];
        return (inputTensor, shape);
      },
    );

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      inputTensor,
      shape,
    );

    final inputs = {_classifyModel!.inputNames[0]: inputOrt};
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;
    try {
      outputs = await _classifyModel!.runAsync(runOptions, inputs);
      final result = (outputs![0]!.value as List);
      return List<double>.from(result[0] as List);
    } finally {
      for (final output in outputs ?? <OrtValue?>[]) {
        output?.release();
      }
      inputOrt.release();
      runOptions.release();
    }
  });

  // normalize image
  static Future<List<double>> _imageToFloatTensor(
    img.Image image, {
    List<double> mean = const [0.485, 0.456, 0.406],
    List<double> std = const [0.229, 0.224, 0.225],
  }) async {
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
