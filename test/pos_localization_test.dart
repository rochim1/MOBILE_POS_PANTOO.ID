import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/l10n/pos_translation_lookup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('language persists without changing session or shift', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'session',
      'shift_id': 'shift',
    });
    final controller = AppLanguageController();
    await controller.load();
    await controller.select('en');
    final restored = AppLanguageController();
    await restored.load();
    expect(restored.value, const Locale('en'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), 'session');
    expect(prefs.getString('shift_id'), 'shift');
    await restored.select('system');
    expect(restored.value, isNull);
    expect(prefs.containsKey(AppLanguageController.preferenceKey), isFalse);
    expect(
      AppLanguageController.resolve(const Locale('ja')),
      const Locale('id'),
    );
    await expectLater(restored.select('fr'), throwsArgumentError);
    controller.dispose();
    restored.dispose();
  });

  test('dynamic messages preserve parameters', () {
    final entries =
        jsonDecode(
              File(
                'test/fixtures/pos_translation_patterns.json',
              ).readAsStringSync(),
            )
            as List;
    final en = lookupAppLocalizations(const Locale('en'));
    for (final entry in entries) {
      String render(String source) => source.replaceAllMapped(
        RegExp(r'\{arg(\d+)\}'),
        (m) => 'USER_${m[1]}',
      );
      expect(
        translatePosText(render(entry['source'] as String), en),
        render(entry['en'] as String),
        reason: entry['key'] as String,
      );
    }
  });

  testWidgets('language changes live while user content stays intact', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('id'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (_, value, child) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Column(children: [PosText('Simpan'), Text('Bayar')]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Simpan'), findsOneWidget);
    locale.value = const Locale('en');
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Bayar'), findsOneWidget);
    locale.value = const Locale('id');
    await tester.pumpAndSettle();
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('cached validator changes language without clearing input', (
    tester,
  ) async {
    final locale = ValueNotifier(const Locale('en'));
    final form = GlobalKey<FormState>();
    final input = TextEditingController(text: 'Bayar');
    addTearDown(locale.dispose);
    addTearDown(input.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (_, value, child) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => Form(
                key: form,
                child: TextFormField(
                  controller: input,
                  validator: (_) => 'Username wajib diisi'.tr(context),
                  errorBuilder: posValidationError,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    form.currentState!.validate();
    await tester.pumpAndSettle();
    expect(find.text('Username wajib diisi'), findsNothing);
    locale.value = const Locale('id');
    await tester.pumpAndSettle();
    expect(find.text('Username wajib diisi'), findsOneWidget);
    expect(input.text, 'Bayar');
  });
}
