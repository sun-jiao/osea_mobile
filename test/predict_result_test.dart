import 'package:flutter_test/flutter_test.dart';
import 'package:osea/entities/predict_result.dart';
import 'package:osea/tools/tools.dart';

void main() {
  setUp(
    () => PredictResult.speciesInfo = [
      ['甲', 'Bird A', 'Species A'],
      ['乙', 'Bird B', 'Species B'],
    ],
  );
  test(
    'unlabeled output channels cannot win ranking or affect normalization',
    () {
      final labeled = PredictResult.labeledScores([1, 2, 1000]);
      final ranked = getTop(softmax(labeled.asMap().entries.toList()));
      expect(ranked.map((e) => e.cls), [1, 0]);
      expect(ranked.first.label, 'Bird B');
      expect(ranked.first.prob, closeTo(0.73105858, 1e-7));
    },
  );
  test('too few channels and nonfinite labeled scores fail explicitly', () {
    expect(() => PredictResult.labeledScores([1]), throwsStateError);
    expect(
      () => PredictResult.labeledScores([1, double.nan]),
      throwsFormatException,
    );
    PredictResult.speciesInfo = [];
    expect(() => PredictResult.labeledScores([1]), throwsStateError);
  });
}
