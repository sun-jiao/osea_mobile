
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:geolocator/geolocator.dart';

import '../entities/localization_mixin.dart';
import 'device_tool.dart';

// Merge service unavailability to LocationPermission.unableToDetermine
Future<LocationPermission> locationAvailabilityChecker(BuildContext context) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.locationDisabled.getString(context)),
      ),
    );
    return LocationPermission.unableToDetermine;
  }

  if (!serviceEnabled) {
    return LocationPermission.unableToDetermine;
  }

  LocationPermission locationPermission = await Geolocator.checkPermission();
  if (locationPermission == LocationPermission.denied) {
    locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocale.locationPermissionDenied.getString(context)),
          ),
        );
      }
      return locationPermission;
    }
  }

  if (locationPermission == LocationPermission.deniedForever && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocale.locationPermissionDenied.getString(context)),
      ),
    );
    return locationPermission;
  }

  return locationPermission;
}

Future<LocationSettings> getLocationSettings() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSettings(
      forceLocationManager: await DeviceTool().isGoogleAval,
    );
  } else {
    return const LocationSettings();
  }
}

Future<Position?> getCurrentLocation(BuildContext context) async {
  final locationAvailable = await locationAvailabilityChecker(context);
  if (locationAvailable.isFalse()) {
    return null;
  }

  return await Geolocator.getCurrentPosition(
    locationSettings: await getLocationSettings(),
  );
}

extension ToBool on LocationPermission {
  isTrue() {
    return [
      LocationPermission.whileInUse,
      LocationPermission.always,
    ].contains(this);
  }

  isFalse() {
    return [
      LocationPermission.denied,
      LocationPermission.deniedForever,
      LocationPermission.unableToDetermine,
    ].contains(this);
  }
}
