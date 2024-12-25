import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import 'settings_child_page.dart';
import '../entities/localization_mixin.dart';
import '../tools/shared_pref_tool.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        SharedPrefTool.saveSettings();
      },
      child: Scaffold(
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
                subtitle: Text(languageMap[SharedPrefTool.uiLanguage]!),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsChildPage(
                        title: AppLocale.uiLanguage.getString(context),
                        map: languageMap,
                        selected: SharedPrefTool.uiLanguage,
                        callback: (value) {
                          FlutterLocalization.instance.translate(value);
                          SharedPrefTool.uiLanguage = value;
                        },
                      ),
                    ),
                  ).then((value) {
                    setState(() {});
                  });
                },
              ),
              Divider(),

              // Common name language
              ListTile(
                title: Text(AppLocale.cnLanguage.getString(context),
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(languageMap[SharedPrefTool.cnLanguage]!),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsChildPage(
                        title: AppLocale.cnLanguage.getString(context),
                        map: languageMap,
                        selected: SharedPrefTool.cnLanguage,
                        callback: (value) {
                          SharedPrefTool.cnLanguage = value;
                        },
                      ),
                    ),
                  ).then((value) {
                    setState(() {});
                  });
                },
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
                groupValue: SharedPrefTool.selectedSpeciesDisplay,
                onChanged: (value) {
                  setState(() {
                    SharedPrefTool.selectedSpeciesDisplay = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocale.scientificName.getString(context)),
                value: AppLocale.scientificName,
                groupValue: SharedPrefTool.selectedSpeciesDisplay,
                onChanged: (value) {
                  setState(() {
                    SharedPrefTool.selectedSpeciesDisplay = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text(AppLocale.nameBoth.getString(context)),
                value: AppLocale.nameBoth,
                groupValue: SharedPrefTool.selectedSpeciesDisplay,
                onChanged: (value) {
                  setState(() {
                    SharedPrefTool.selectedSpeciesDisplay = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
