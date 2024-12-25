import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:onnxruntime/onnxruntime.dart';

import 'entities/localization_mixin.dart';
import 'entities/predict_result.dart';
import '../entities/app_dir.dart';
import '../tools/distribution_tool.dart';
import 'tools/shared_pref_tool.dart';
import 'pages/predict_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OrtEnv.instance.init();
  await Future.wait([
    FlutterLocalization.instance.ensureInitialized(),
    PredictResult.loadSpeciesInfo(),
    SharedPrefTool.loadSettings(),
    Distribution.initDB(),
    AppDir.setDir(),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  void initState() {
    _localization.init(
      mapLocales: [
        const MapLocale(
          'en',
          AppLocale.EN,
        ),
        const MapLocale(
          'zh',
          AppLocale.ZH,
        ),
      ],
      initLanguageCode: 'en',
    );
    _localization.onTranslatedLanguage = _onTranslatedLanguage;
    _localization.translate(SharedPrefTool.uiLanguage);
    super.initState();
  }

  @override
  void dispose() {
    OrtEnv.instance.release();
    Distribution.closeDB();
    super.dispose();
  }

  void _onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocale.title.getString(context),
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: PredictScreen(),
    );
  }
}
