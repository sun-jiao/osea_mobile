class DetectionBox {
  DetectionBox(this.top, this.left, this.bottom, this.right);
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;
}

class DetectionResult {
  DetectionResult(
    List<double> box,
    this.cls,
    this.score,
  ) {
    this.box = DetectionBox(box[0], box[1], box[2], box[3]);
  }

  late final DetectionBox box;
  final int cls;
  final double score;
}
