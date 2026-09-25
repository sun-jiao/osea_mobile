import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:osea/entities/localization_mixin.dart';
import 'package:osea/pages/map_page.dart';
import 'package:osea/tools/shared_pref_tool.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryTiles extends TileProvider {
  final bytes = Uint8List.fromList(
    img.encodePng(img.Image(width: 1, height: 1)),
  );
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(bytes);
}

class MapLocation extends GeolocatorPlatform {
  late final permission = Completer<LocationPermission>();
  late final fix = Completer<Position>();
  var subscriptions = 0;
  var fixRequests = 0;
  var cancellations = 0;
  late final positions = StreamController<Position>.broadcast(
    onCancel: () => cancellations++,
  );
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() => permission.future;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    subscriptions++;
    return positions.stream;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    fixRequests++;
    return fix.future;
  }
}

void main() {
  late GeolocatorPlatform original;
  late MapLocation location;
  setUp(() {
    original = GeolocatorPlatform.instance;
    location = MapLocation();
    GeolocatorPlatform.instance = location;
    SharedPreferences.setMockInitialValues({});
    SharedPrefTool.prefs = null;
    SharedPrefTool.locationFilter = AppLocale.locationFilterOff;
    SharedPrefTool.locationFilterLat = 12;
    SharedPrefTool.locationFilterLng = 34;
  });
  tearDown(() async {
    GeolocatorPlatform.instance = original;
    await location.positions.close();
  });
  Future<void> openMap(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MapPage(
          tileLayer: TileLayer(
            tileProvider: MemoryTiles(),
            urlTemplate: 'memory://{z}/{x}/{y}',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String value) async {
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is RadioListTile<String> && widget.value == value,
      ),
    );
    await tester.pumpAndSettle();
  }

  final variant = TargetPlatformVariant.only(TargetPlatform.iOS);

  testWidgets(
    'switching mode during permission check prevents a late subscription',
    (tester) async {
      await openMap(tester);
      await select(tester, AppLocale.locationFilterAuto);
      await select(tester, AppLocale.locationFilterOff);
      location.permission.complete(LocationPermission.whileInUse);
      await tester.pumpAndSettle();
      expect(location.subscriptions, 0);
    },
    variant: variant,
  );

  testWidgets(
    'disposal while checking permission prevents a late subscription',
    (tester) async {
      await openMap(tester);
      await select(tester, AppLocale.locationFilterAuto);
      await tester.pumpWidget(const SizedBox());
      location.permission.complete(LocationPermission.whileInUse);
      await tester.pumpAndSettle();
      expect(location.subscriptions, 0);
      expect(tester.takeException(), isNull);
    },
    variant: variant,
  );

  testWidgets('switching off cancels the existing location subscription', (
    tester,
  ) async {
    location.permission.complete(LocationPermission.whileInUse);
    await openMap(tester);
    await select(tester, AppLocale.locationFilterAuto);
    expect(location.subscriptions, 1);
    await select(tester, AppLocale.locationFilterOff);
    expect(location.cancellations, 1);
  }, variant: variant);

  testWidgets(
    'pending one-shot location cannot overwrite a new fixed selection',
    (tester) async {
      location.permission.complete(LocationPermission.whileInUse);
      await openMap(tester);
      await tester.tap(find.byIcon(Icons.my_location_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.my_location_outlined));
      await tester.pumpAndSettle();
      expect(location.fixRequests, 1);
      await select(tester, AppLocale.locationFilterFix);
      location.fix.complete(
        Position(
          latitude: 55,
          longitude: 66,
          timestamp: DateTime.now(),
          accuracy: 1,
          altitude: 0,
          altitudeAccuracy: 1,
          heading: 0,
          headingAccuracy: 1,
          speed: 0,
          speedAccuracy: 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.byKey(const Key('location_text'))).data,
        contains('12.0'),
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('location_text'))).data,
        isNot(contains('55.0')),
      );
    },
    variant: variant,
  );
}
