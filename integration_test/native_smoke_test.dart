import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:osea/pages/predict_page.dart';
import 'package:osea/pages/manually_crop_page.dart';
import 'package:osea/pages/map_page.dart';
import 'package:osea/widgets/blured_image.dart';
import 'package:osea/entities/localization_mixin.dart';
import 'package:osea/tools/shared_pref_tool.dart';
import 'package:osea/main.dart' as app;
import 'package:osea/entities/predict_result.dart';
import 'package:osea/tools/ai_tools.dart';
import 'package:osea/tools/distribution_tool.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'native inference, cropping and repeated map navigation work on device',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image_rounded), findsOneWidget);

      // A synthetic image tests the entire native inference path, not accuracy.
      final image = img.Image(width: 224, height: 224);
      img.fill(image, color: img.ColorRgb8(120, 160, 200));
      final bytes = Uint8List.fromList(img.encodePng(image));
      await tester.runAsync(() async {
        await AiTools.initFuture();
        final detections = await AiTools.birdDetect(bytes);
        expect(detections.every((result) => result.score.isFinite), isTrue);
        final predictions = await AiTools.birdID(bytes);
        expect(
          predictions.length,
          greaterThanOrEqualTo(PredictResult.speciesInfo.length),
        );
        final labeled = PredictResult.labeledScores(predictions);
        expect(labeled.length, PredictResult.speciesInfo.length);
        expect(predictions.every((value) => value.isFinite), isTrue);
        // This region includes a species lacking a model class in the bundled DB.
        final classes = await Distribution.query(12.5, -86.5);
        expect(classes, isNotEmpty);
        expect(
          classes.every((value) => value >= 0 && value < labeled.length),
          isTrue,
        );
        // Repeated inference exercises session reuse and the async worker queue.
        final repeated = await AiTools.birdID(bytes);
        expect(repeated, orderedEquals(predictions));
      });

      SharedPrefTool.locationFilter = AppLocale.locationFilterOff;
      final navigator = Navigator.of(
        tester.element(find.byType(PredictScreen)),
      );
      unawaited(
        navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => PredictScreen(
              // Supply synthetic bytes rather than reading the user's photo library.
              pickImage: (_) async => XFile.fromData(bytes),
              // Force the manual crop branch; the real detector was tested above.
              detect: (_) async => [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.image_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CropPage), findsOneWidget);
      final confirm = find.widgetWithIcon(IconButton, Icons.check);
      for (
        var i = 0;
        i < 50 && tester.widget<IconButton>(confirm).onPressed == null;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.widget<IconButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(minutes: 1),
      );
      expect(find.byType(CropPage), findsNothing);
      expect(find.byType(BlurredImageWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SnackBar), findsNothing);

      // Real map provider/cache lifecycle; tile connectivity is not asserted.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byIcon(Icons.location_on_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(MapPage), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Icons.crop_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CropPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(BlurredImageWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      navigator.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
