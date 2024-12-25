import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:geolocator/geolocator.dart';

import '../entities/localization_mixin.dart';

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

Future<Position?> getCurrentLocation(BuildContext context) async {
  final locationAvailable = await locationAvailabilityChecker(context);
  if (locationAvailable.isFalse()) {
    return null;
  }

  if (Platform.isAndroid) {
    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        forceLocationManager: true,
      ),
    );
  } else if (Platform.isIOS) {
    return await Geolocator.getCurrentPosition(
      locationSettings: AppleSettings(),
    );
  } else {
    throw UnimplementedError();
  }
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
