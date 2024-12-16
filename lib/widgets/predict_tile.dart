import 'package:flutter/material.dart';

import '../entities/predict_result.dart';

class ResultTile extends StatelessWidget {
  const ResultTile({super.key, required this.result});
  final PredictResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.star_border_rounded,
      ),
      title: Text(
        result.label,
        style: const TextStyle(fontSize: 18),
      ),
      trailing: Text('${(result.prob * 100).toStringAsFixed(2)}%'),
    );
  }
}
