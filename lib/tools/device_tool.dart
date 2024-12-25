import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:google_api_availability/google_api_availability.dart';

class DeviceTool {
  bool? _isHuawei;

  Future<bool> get isHuawei async {
    if (_isHuawei == null) {
      if (Platform.isAndroid) {
        final brand = (await DeviceInfoPlugin().androidInfo).brand.toLowerCase();
        _isHuawei = brand == "huawei" || brand == "honor";
      } else {
        _isHuawei = false;
      }
    }

    return _isHuawei!;
  }

  bool? _isGoogleAval;

  Future<bool> get isGoogleAval async {
    // Some Huawei devices will return success for unknown reasons, even though they do not have GMS.
    _isGoogleAval ??= await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability() ==
        GooglePlayServicesAvailability.success;

    return (await isHuawei) || !_isGoogleAval!;
  }
}
