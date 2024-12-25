import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../entities/localization_mixin.dart';

class SharedPrefTool {
  static SharedPreferences? prefs;
  static String uiLanguage = '';
  static String cnLanguage = '';
  static String selectedSpeciesDisplay = AppLocale.commonName;
  static String locationFilter = '';
  static double locationFilterLat = 0.0;
  static double locationFilterLng = 0.0;

  // load preferences from SharedPreferences
  static Future<void> loadSettings() async {
    while (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
    
    selectedSpeciesDisplay = prefs!.getString(AppLocale.nameDisplay) ?? AppLocale.nameBoth;
    uiLanguage = prefs!.getString(AppLocale.uiLanguage) ?? Platform.localeName.split(RegExp('[_-]')).first;
    cnLanguage = prefs!.getString(AppLocale.cnLanguage) ?? uiLanguage;
    locationFilter = prefs!.getString(AppLocale.locationFilter) ?? AppLocale.locationFilterOff;
    locationFilterLat = prefs!.getDouble('lat') ?? 0.0;
    locationFilterLng = prefs!.getDouble('lng') ?? 0.0;
  }

  // save preferences to SharedPreferences
  static Future<void> saveSettings() async {
    while (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
    
    await Future.wait([
      prefs!.setString(AppLocale.nameDisplay, selectedSpeciesDisplay),
      prefs!.setString(AppLocale.uiLanguage, uiLanguage),
      prefs!.setString(AppLocale.cnLanguage, cnLanguage),
      prefs!.setString(AppLocale.locationFilter, locationFilter),
      prefs!.setDouble('lat', locationFilterLat),
      prefs!.setDouble('lng', locationFilterLng),
    ]);
  }
}