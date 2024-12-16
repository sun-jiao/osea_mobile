import 'dart:math' as math;

import 'package:birdid/entities/predict_result.dart';

// convert predict result to probabilities
// take the Python code in Chinese Wikipedia as a reference:
// https://zh.wikipedia.org/wiki/Softmax%E5%87%BD%E6%95%B0
List<double> softmax(List<double> nums) {
  Iterable<double> exps = nums.map((e) => math.exp(e));

  double sumExp = exps.reduce((a, b) => a + b);
  Iterable<double> probabilities = exps.map((exp) => exp / sumExp);

  return probabilities.toList();
}

List<PredictResult> getTop(List<double> probs, {int amount = 3, bool hideLowProb = true, double lowestValue = 0.01}) {
  List<MapEntry<int, double>> sortedList = List.from(probs.asMap().entries)..sort((a, b) => b.value.compareTo(a.value));
  List<MapEntry<int, double>> filteredList = sortedList.where((e) => !hideLowProb || e.value > lowestValue).toList();

  return filteredList.take(amount).map((e) => PredictResult(e.key, e.value)).toList();
}
