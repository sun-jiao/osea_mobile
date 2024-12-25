import 'package:flutter/material.dart';

import '../entities/localization_mixin.dart';
import '../entities/predict_result.dart';
import '../tools/shared_pref_tool.dart';

class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.result});
  final PredictResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        getIcon(result.prob),
      ),
      title: Text(
        SharedPrefTool.selectedSpeciesDisplay != AppLocale.scientificName ? result.label : result.scientificName,
        style: TextStyle(fontSize: 18, fontStyle: SharedPrefTool.selectedSpeciesDisplay == AppLocale.scientificName ? FontStyle.italic : null),
      ),
      subtitle: SharedPrefTool.selectedSpeciesDisplay == AppLocale.nameBoth ? Text(
        result.scientificName,
        style: const TextStyle(fontStyle: FontStyle.italic),
      ) : null,
      trailing: Text('${(result.prob * 100).toStringAsFixed(2)}%'),
    );
  }

  static IconData getIcon(double prob) {
    if (prob > 0.75) {
      return Icons.star_rounded;
    } else if (prob > 0.4) {
      return Icons.star_half_rounded;
    } else {
      return Icons.star_border_rounded;
    }
  }
}
