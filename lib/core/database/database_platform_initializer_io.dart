import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializePlatformDatabase() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

bool get supportsOfflineDatabase => true;
