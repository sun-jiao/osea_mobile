import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class BlurredImageWidget extends StatelessWidget {
  final ImageProvider imageProvider;
  final ImageProvider backProvider;
  final double margin;

  const BlurredImageWidget({
    super.key,
    required this.imageProvider,
    required this.backProvider,
    this.margin = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRect(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: backProvider,
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            margin: EdgeInsets.all(margin),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12))),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              child: Image(
                image: imageProvider,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
