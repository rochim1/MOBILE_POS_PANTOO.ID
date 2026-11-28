// Isolated native QA entry point. Production/development app entry points do not
// import this file. It uses production Travel widgets and the real HTTP client.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_travel_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_travel_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_visibility.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_system_safe_area.dart';

class _QaCompactScaler extends TextScaler {
  const _QaCompactScaler(this.base);
  final TextScaler base;
  @override
  double scale(double fontSize) => base.scale(fontSize) * .84;
  @override
  double get textScaleFactor => scale(14) / 14;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const endpoint = String.fromEnvironment('POS_QA_ENDPOINT');
  if (!kDebugMode ||
      !const bool.fromEnvironment('POS_TRAVEL_GUI_QA') ||
      endpoint != 'http://127.0.0.1:18129/graphql') {
    throw StateError('Native Travel QA requires the isolated debug endpoint.');
  }
  dotenv.loadFromString(envString: 'API_URL=$endpoint\n');
  final preferences = await SharedPreferences.getInstance();
  // No preference clear: pending request evidence must survive process restart.
  await preferences.setString(
    'instansi_id',
    const String.fromEnvironment('TRAVEL_QA_TENANT'),
  );
  await preferences.setString(
    'user_id',
    const String.fromEnvironment('TRAVEL_QA_TERMINAL'),
  );
  final provider = GraphQLClientProvider(
    preferences,
    const FlutterSecureStorage(),
    environment: FlavorEnvironment.development,
  );
  provider.setAccessToken(const String.fromEnvironment('TRAVEL_QA_ACCESS'));
  provider.setPOSOperatorToken(
    const String.fromEnvironment('TRAVEL_QA_OPERATOR'),
  );
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      scrollBehavior: const PosKeyboardScrollBehavior(),
      theme: AppTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.size.width < 600
                ? _QaCompactScaler(media.textScaler)
                : media.textScaler,
          ),
          child: PosKeyboardVisibility(child: PosSystemSafeArea(child: child!)),
        );
      },
      home: Scaffold(
        appBar: AppBar(title: const Text('Travel Android QA · Lokal')),
        body: SafeArea(
          child: PosTravelPage(
            repository: PosTravelRepository(provider),
            initialStoreId: const String.fromEnvironment('TRAVEL_QA_STORE'),
          ),
        ),
      ),
    ),
  );
}
