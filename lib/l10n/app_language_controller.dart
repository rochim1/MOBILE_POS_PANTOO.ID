import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// null means follow the device; unsupported device languages fall back to id.
class AppLanguageController extends ValueNotifier<Locale?> {
  AppLanguageController() : super(null);
  static final instance = AppLanguageController();
  static const preferenceKey = 'pos_app_locale';
  bool _loaded = false;
  static Locale resolve(Locale? locale) =>
      locale?.languageCode == 'en' ? const Locale('en') : const Locale('id');
  Locale get effectiveLocale => resolve(
    value ??
        (_loaded ? WidgetsBinding.instance.platformDispatcher.locale : null),
  );
  Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(
      preferenceKey,
    );
    _loaded = true;
    value = ['id', 'en'].contains(saved) ? Locale(saved!) : null;
    Intl.defaultLocale = effectiveLocale.languageCode;
  }

  Future<void> select(String code) async {
    if (!const ['id', 'en', 'system'].contains(code)) {
      throw ArgumentError.value(code, 'code', 'Unsupported language');
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = code == 'system'
        ? await prefs.remove(preferenceKey)
        : await prefs.setString(preferenceKey, code);
    if (!saved) throw StateError('Locale preference was not saved');
    value = code == 'system' ? null : resolve(Locale(code));
    Intl.defaultLocale = effectiveLocale.languageCode;
  }
}
