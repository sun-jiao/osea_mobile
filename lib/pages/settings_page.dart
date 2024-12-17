import 'package:birdid/pages/settings_child_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/localization_mixin.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSpeciesDisplay = AppLocale.commonName;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 从 SharedPreferences 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedSpeciesDisplay =
          prefs.getString(AppLocale.nameDisplay) ?? AppLocale.commonName;
    });
  }

  // 保存设置到 SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppLocale.nameDisplay, _selectedSpeciesDisplay);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.settings.getString(context)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // UI language
            ListTile(
              title: Text(AppLocale.uiLanguage.getString(context),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Chinese'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsChildPage(
                      title: AppLocale.uiLanguage.getString(context),
                      map: {
                        'en': 'English',
                        'zh': '中文',
                      },
                      selected: 'zh',
                      callback: (value) {
                        FlutterLocalization.instance.translate(value);
                      },
                    ),
                  ),
                );
              },
            ),
            Divider(),

            // Common name language
            ListTile(
              title: Text(AppLocale.cnLanguage.getString(context),
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Chinese'),
            ),
            Divider(),

            // Species Name Display
            ListTile(
              title: Text(AppLocale.nameDisplay.getString(context),
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            RadioListTile<String>(
              title: Text(AppLocale.commonName.getString(context)),
              value: AppLocale.commonName,
              groupValue: _selectedSpeciesDisplay,
              onChanged: (value) {
                setState(() {
                  _selectedSpeciesDisplay = value!;
                  _saveSettings();
                });
              },
            ),
            RadioListTile<String>(
              title: Text(AppLocale.scientificName.getString(context)),
              value: AppLocale.scientificName,
              groupValue: _selectedSpeciesDisplay,
              onChanged: (value) {
                setState(() {
                  _selectedSpeciesDisplay = value!;
                  _saveSettings();
                });
              },
            ),
            RadioListTile<String>(
              title: Text(AppLocale.nameBoth.getString(context)),
              value: AppLocale.nameBoth,
              groupValue: _selectedSpeciesDisplay,
              onChanged: (value) {
                setState(() {
                  _selectedSpeciesDisplay = value!;
                  _saveSettings();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
