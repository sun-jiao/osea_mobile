import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:osea/entities/detection_result.dart';
import 'package:osea/tools/tools.dart';

void main() {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 10, height: 20)),
  );
  test('crop clamps a partly out-of-frame detection', () async {
    final result = await autoCrop(bytes, DetectionBox(-0.2, -0.1, 1.2, 1.1));
    final image = img.decodePng(result!)!;
    expect((image.width, image.height), (10, 20));
  });
  test('invalid, reversed and outside boxes are rejected', () async {
    for (final box in [
      DetectionBox(0, 0, double.nan, 1),
      DetectionBox(0.5, 0.5, 0.2, 0.2),
      DetectionBox(2, 2, 3, 3),
      DetectionBox(0, 0, 0, 1),
    ]) {
      expect(await autoCrop(bytes, box), isNull);
    }
    expect(await autoCrop(Uint8List(0), DetectionBox(0, 0, 1, 1)), isNull);
  });
  test('subpixel crops still produce a nonempty image', () async {
    final result = await autoCrop(bytes, DetectionBox(0.999, 0.999, 1, 1));
    final image = img.decodePng(result!)!;
    expect((image.width, image.height), (1, 1));
  });
  test('softmax handles large logits and empty input', () {
    expect(softmax([]), isEmpty);
    final results = softmax([const MapEntry(7, 1000), const MapEntry(9, 1001)]);
    expect(
      results.map((e) => e.prob).reduce((a, b) => a + b),
      closeTo(1, 1e-10),
    );
    expect(getTop(results).first.cls, 9);
  });
}
