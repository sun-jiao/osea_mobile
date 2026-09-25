import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:osea/pages/manually_crop_page.dart';

void main() {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 20, height: 20)),
  );
  Future<Crop> openCrop(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<Uint8List>(
                    builder: (_) => CropPage(imageData: bytes),
                  ),
                ),
                child: const Text('Open crop'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open crop'));
    await tester.pumpAndSettle();
    return tester.widget<Crop>(find.byType(Crop));
  }

  testWidgets('late crop completion cannot pop the previous route', (
    tester,
  ) async {
    final crop = await openCrop(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    crop.onCropped(CropSuccess(bytes));
    crop.onStatusChanged?.call(CropStatus.ready);
    await tester.pumpAndSettle();
    expect(find.text('Open crop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate completion only closes the crop route once', (
    tester,
  ) async {
    final crop = await openCrop(tester);
    crop.onCropped(CropSuccess(bytes));
    crop.onCropped(CropSuccess(bytes));
    await tester.pumpAndSettle();
    expect(find.text('Open crop'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('crop failure stays on the page with a retryable action', (
    tester,
  ) async {
    final crop = await openCrop(tester);
    crop.onStatusChanged?.call(CropStatus.cropping);
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.check))
          .onPressed,
      isNull,
    );
    crop.onCropped(CropFailure(StateError('crop failed'), StackTrace.current));
    await tester.pumpAndSettle();
    expect(find.byType(CropPage), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.check))
          .onPressed,
      isNotNull,
    );
  });
}
