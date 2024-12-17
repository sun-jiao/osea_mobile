/*
* This file includes code from the documents of crop_your_image,
* Copyright (c) 2021 Tsuyoshi Chujo. Licensed under the Apache License v 2.0.
* */

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

class CropPage extends StatefulWidget {
  const CropPage({super.key, required this.imageData});
  final Uint8List imageData;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final _controller = CropController();
  late final Uint8List _imageData;

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
              onPressed: () {
                _controller.crop();
              },
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
          interactive: true,
          onCropped: (result) {
            switch (result) {
              case CropSuccess(:final croppedImage):
                Navigator.pop(context, croppedImage);
              case CropFailure():
                return;
            }
          },
      ),
    );
  }
}
