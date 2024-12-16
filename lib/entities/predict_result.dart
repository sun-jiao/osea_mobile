class PredictResult {
  final int cls;
  final double prob;

  PredictResult(this.cls, this.prob);

  String get label {
    return cls.toString();
  }
}