import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppDir {
  static Directory data = Directory('');
  static Directory cache = Directory('');

  static Future<void> setDir() async {
    data = await getApplicationDocumentsDirectory();
    cache = await getTemporaryDirectory();
  }
}
