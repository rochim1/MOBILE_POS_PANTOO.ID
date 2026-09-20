import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/flavor/flavor_config.dart';
import 'core/database/database_platform_initializer.dart';
import 'injections.dart';

import 'core/utils/logger.dart';

Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required FlavorConfig flavor,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  initializePlatformDatabase();

  FlutterError.onError = (details) {
    // `exceptionAsString()` hanya berisi ringkasan (mis. RenderFlex overflow)
    // dan membuang diagnostics yang menunjukkan creator/widget penyebabnya.
    // Simpan representasi lengkap agar overflow responsif bisa dilacak sampai
    // ke halaman dan RenderObject yang tepat dari log pengguna.
    appLogger.e(
      details.toString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await dotenv.load(fileName: ".env");

  await initLocator(flavor);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(await builder());
}
