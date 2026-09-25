import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:osea/entities/detection_result.dart';
import 'package:osea/entities/localization_mixin.dart';
import 'package:osea/entities/predict_result.dart';
import 'package:osea/pages/predict_page.dart';
import 'package:osea/tools/shared_pref_tool.dart';

void main() {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 2, height: 2)),
  );
  setUp(() {
    SharedPrefTool.locationFilter = AppLocale.locationFilterOff;
    SharedPrefTool.cnLanguage = 'en';
    PredictResult.speciesInfo = [
      ['鸟', 'Test bird', 'Test species'],
    ];
  });

  // XFile bytes avoid disk I/O, just as the platform picker abstraction does.
  PredictScreen screen({
    required Future<List<double>> Function(Uint8List) identify,
    Future<XFile?> Function(ImageSource)? pick,
  }) => PredictScreen(
    pickImage: pick ?? (_) async => XFile.fromData(bytes),
    detect: (_) async => [
      DetectionResult([0, 0, 1, 1], 16, 0.9),
    ],
    autoCrop: (data, _) async => data,
    identify: identify,
  );

  testWidgets('a second pick is blocked while identification is running', (
    tester,
  ) async {
    final pending = Completer<List<double>>();
    var picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: screen(
          identify: (_) => pending.future,
          pick: (_) async {
            picks++;
            return XFile.fromData(bytes);
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.image_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.image_rounded));
    await tester.pump();
    expect(picks, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete([1]);
    await tester.pumpAndSettle();
    expect(find.text('Test bird'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('inference failure stops the spinner and allows retry', (
    tester,
  ) async {
    var attempts = 0;
    var picks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: screen(
          pick: (_) async {
            picks++;
            return XFile.fromData(bytes);
          },
          identify: (_) async {
            if (++attempts == 1) throw StateError('inference failed');
            return [1];
          },
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.image_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    await tester.tap(find.byType(SnackBarAction));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(picks, 1);
    expect(find.text('Test bird'), findsOneWidget);
  });

  testWidgets('a result arriving after disposal does not update the page', (
    tester,
  ) async {
    final pending = Completer<List<double>>();
    await tester.pumpWidget(
      MaterialApp(home: screen(identify: (_) => pending.future)),
    );
    await tester.tap(find.byIcon(Icons.image_rounded));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    pending.complete([1]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
