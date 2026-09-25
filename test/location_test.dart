import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:osea/tools/location_tool.dart';

class FakeLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  bool enabled = true;
  int requests = 0;
  int fixes = 0;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    fixes++;
    settings = locationSettings;
    throw TimeoutException('No GPS fix');
  }
}

void main() {
  late GeolocatorPlatform original;
  late FakeLocation fake;
  setUp(() {
    original = GeolocatorPlatform.instance;
    fake = FakeLocation();
    GeolocatorPlatform.instance = fake;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  Future<BuildContext> contextFor(WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    return context;
  }

  testWidgets(
    'denied permission returns no location and does not request a fix',
    (tester) async {
      final context = await contextFor(tester);
      expect(await getCurrentLocation(context), isNull);
      expect(fake.requests, 1);
      expect(fake.fixes, 0);
      await tester.pumpAndSettle();
    },
  );
  testWidgets('permanent denial does not prompt again', (tester) async {
    fake.permission = LocationPermission.deniedForever;
    final context = await contextFor(tester);
    expect(await getCurrentLocation(context), isNull);
    expect(fake.requests, 0);
    expect(fake.fixes, 0);
    await tester.pumpAndSettle();
  });
  testWidgets('disabled service does not request permission or a fix', (
    tester,
  ) async {
    fake.enabled = false;
    final context = await contextFor(tester);
    expect(await getCurrentLocation(context), isNull);
    expect(fake.requests, 0);
    expect(fake.fixes, 0);
    await tester.pumpAndSettle();
  });
  testWidgets('GPS failure falls back and single fixes have a time limit', (
    tester,
  ) async {
    // Use the generic settings path; no Android device/GMS method channels.
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      fake.permission = LocationPermission.whileInUse;
      final context = await contextFor(tester);
      expect(await getCurrentLocation(context), isNull);
      expect(fake.settings?.timeLimit, const Duration(seconds: 15));
      expect((await getLocationSettings()).timeLimit, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
