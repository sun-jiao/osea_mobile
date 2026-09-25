/*
* This file includes code from the documents of crop_your_image,
* Copyright (c) 2021 Tsuyoshi Chujo. Licensed under the Apache License v 2.0.
* */

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../entities/localization_mixin.dart';

class CropPage extends StatefulWidget {
  const CropPage({super.key, required this.imageData});
  final Uint8List imageData;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final _controller = CropController();
  late final Uint8List _imageData;
  CropStatus _status = CropStatus.loading;
  bool _completed = false;

  @override
  void initState() {
    _imageData = widget.imageData;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _status == CropStatus.ready && !_completed
                ? () {
                    setState(() => _status = CropStatus.cropping);
                    _controller.crop();
                  }
                : null,
            icon: Icon(Icons.check),
          ),
        ],
      ),
      body: Crop(
        image: _imageData,
        controller: _controller,
        initialRectBuilder: InitialRectBuilder.withSizeAndRatio(
          size: 0.8,
          aspectRatio: 1.3,
        ),
        interactive: _status != CropStatus.cropping,
        onStatusChanged: (status) {
          if (!mounted || _completed || status == _status) return;
          setState(() => _status = status);
        },
        onCropped: (result) {
          if (!mounted ||
              _completed ||
              ModalRoute.of(context)?.isCurrent != true) {
            return;
          }
          switch (result) {
            case CropSuccess(:final croppedImage):
              _completed = true;
              Navigator.pop(context, croppedImage);
            case CropFailure():
              setState(() => _status = CropStatus.ready);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocale.cropFailed.getString(context)),
                ),
              );
          }
        },
      ),
    );
  }
}
