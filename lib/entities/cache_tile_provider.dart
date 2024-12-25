// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
// ignore: implementation_imports
import 'package:flutter_map/src/layer/tile_layer/tile_provider/network_image_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart';
import 'package:http/retry.dart';

import 'app_dir.dart';

class CacheTileProvider extends NetworkTileProvider {
  String tileName;

  final BaseClient _httpClient;

  CacheTileProvider(
      this.tileName, {
        super.headers,
        super.httpClient,
      }) : _httpClient = httpClient ?? RetryClient(Client());

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    File file = File(path.join(AppDir.cache.path, 'flutter_map_tiles', tileName, coordinates.z.round().toString(), coordinates.x.round().toString(),
        '${coordinates.y.round().toString()}.png'));

    if (file.existsSync()) {
      return FileImage(file);
    } else {
      return NetworkImageSaverProvider(
        file,
        url: getTileUrl(coordinates, options),
        headers: headers,
        httpClient: _httpClient,
        fallbackUrl: null,
        silenceExceptions: true,
        startedLoading: () {  },
        finishedLoadingBytes: () {  },
      );
    }
  }
}

class NetworkImageSaverProvider extends MapNetworkImageProvider {
  final File file;

  const NetworkImageSaverProvider(
      this.file, {
        required super.url,
        super.fallbackUrl,
        required super.httpClient,
        super.headers = const {},
        required super.silenceExceptions,
        required super.startedLoading,
        required super.finishedLoadingBytes,
      });

  @override
  ImageStream createStream(ImageConfiguration configuration) {
    ImageStream stream = ImageStream();
    ImageStreamListener listener = ImageStreamListener(imageListener);
    stream.addListener(listener);
    return stream;
  }

  void imageListener(ImageInfo imageInfo, bool synchronousCall) {
    ui.Image uiImage = imageInfo.image;
    _saveImage(uiImage);
  }

  Future<void> _saveImage(ui.Image uiImage) async {
    try {
      Directory parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      ByteData? bytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (bytes != null) {
        final buffer = bytes.buffer;
        file.writeAsBytes(buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      }
    } catch (e) {
      dev.log(e.toString());
    }
  }
}
