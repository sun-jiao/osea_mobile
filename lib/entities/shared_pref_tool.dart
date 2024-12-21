import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'localization_mixin.dart';

class SharedPrefTool {
  static SharedPreferences? prefs;
  static String uiLanguage = '';
  static String cnLanguage = '';
  static String selectedSpeciesDisplay = AppLocale.commonName;

  // load preferences from SharedPreferences
  static Future<void> loadSettings() async {
    while (prefs == null) {
      prefs = await SharedPreferences.getInstance();
    }
    
    selectedSpeciesDisplay = prefs!.getString(AppLocale.nameDisplay) ?? AppLocale.nameBoth;
    uiLanguage = prefs!.getString(AppLocale.uiLanguage) ?? Platform.localeName.split(RegExp('[_-]')).first;
    cnLanguage = prefs!.getString(AppLocale.cnLanguage) ?? uiLanguage;
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
    ]);
  }
}