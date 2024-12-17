import 'dart:convert';

import 'package:flutter/services.dart';

class PredictResult {
  final int cls;
  final double prob;

  static List<dynamic> speciesInfo = [];

  PredictResult(this.cls, this.prob);

  String get label {
    try {
      return speciesInfo[cls][0];
    } catch (e) {
      return cls.toString();
    }
  }

  String get scientificName {
    try {
      return speciesInfo[cls][2];
    } catch (e) {
      return cls.toString();
    }
  }

  static loadSpeciesInfo() async {
    if (speciesInfo.isNotEmpty) {
      return;
    }

    final String birdInfoJson =
        await rootBundle.loadString('assets/labels/bird_info.json');
    speciesInfo = json.decode(birdInfoJson);
  }
}
