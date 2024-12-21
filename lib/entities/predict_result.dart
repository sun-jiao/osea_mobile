import 'dart:convert';

import 'package:flutter/services.dart';

import '../entities/shared_pref_tool.dart';

class PredictResult {
  final int cls;
  final double prob;

  static List<dynamic> speciesInfo = [];

  PredictResult(this.cls, this.prob);

  String get label {
    try {
      // default English common name
      return speciesInfo[cls][SharedPrefTool.cnLanguage == 'zh' ? 0 : 1];
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

  static Future<void> loadSpeciesInfo() async {
    if (speciesInfo.isNotEmpty) {
      return;
    }

    final String birdInfoJson =
        await rootBundle.loadString('assets/labels/bird_info.json');
    speciesInfo = json.decode(birdInfoJson);
  }
}
