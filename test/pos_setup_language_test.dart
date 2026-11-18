import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/language_picker.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';

class _Auth extends Fake implements AuthRepository {
  final pending = Completer<Either<Failure, String>>();
  int creates = 0;
  @override
  Future<Either<Failure, String>> createWorkspace({
    required String businessName,
    required String phone,
    String businessProfile = 'retail',
  }) {
    creates++;
    return pending.future;
  }
}

class _Settings extends Fake implements PosSettingsRepository {
  final pending = Completer<Either<Failure, PosSettings>>();
  @override
  Future<Either<Failure, PosSettings>> getSettings() => pending.future;
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async =>
      PosRemoteProfileCatalog.bundled();
}

class _Runtime extends Fake implements PosRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'permissions': {'manage_settings': true},
  };
}

Future<void> _open(
  WidgetTester tester,
  Widget page, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    ValueListenableBuilder<Locale?>(
      valueListenable: AppLanguageController.instance,
      builder: (_, locale, child) => MaterialApp(
        locale: locale,
        localeResolutionCallback: (device, _) =>
            AppLanguageController.resolve(device),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: child,
      ),
      child: page,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _chooseLanguage(WidgetTester tester, String label) async {
  await tester.tap(find.byType(LanguagePicker));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void _visiblePicker(WidgetTester tester) {
  expect(find.byType(LanguagePicker), findsOneWidget);
  expect(find.byType(LanguagePicker).hitTestable(), findsOneWidget);
  final rect = tester.getRect(find.byType(LanguagePicker));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.bottom, lessThanOrEqualTo(80));
  expect(rect.height, greaterThanOrEqualTo(48));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'token': 'unchanged-session',
      'shift_id': 'unchanged-shift',
      'instansi_id': 'tenant',
      'user_id': 'user',
    });
    final prefs = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(prefs);
    await AppLanguageController.instance.select('id');
  });
  tearDown(() async {
    await sl.reset();
  });
  for (final config in [
    (const Size(320, 568), 1.5),
    (const Size(390, 844), 1.0),
    (const Size(844, 390), 1.3),
  ]) {
    testWidgets(
      'setup language remains pinned after scrolling and keyboard at ${config.$1}, scale ${config.$2}',
      (tester) async {
        await _open(
          tester,
          const BusinessSetupPage(),
          size: config.$1,
          scale: config.$2,
        );
        _visiblePicker(tester);
        final before = tester.getTopLeft(find.byType(LanguagePicker));
        await tester.ensureVisible(find.text('Buat Profil & Lanjutkan'));
        await tester.pump();
        _visiblePicker(tester);
        expect(tester.getTopLeft(find.byType(LanguagePicker)), before);
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        await tester.pump();
        _visiblePicker(tester);
        expect(tester.getTopLeft(find.byType(LanguagePicker)), before);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'language changes immediately without losing business fields, selected profile, login or shift',
    (tester) async {
      await _open(tester, const BusinessSetupPage());
      await tester.enterText(find.byType(TextFormField).at(0), 'Usaha QA');
      await tester.enterText(find.byType(TextFormField).at(1), '081234567890');
      final selector = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(selector);
      await tester.tap(selector);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jasa').last);
      await tester.pumpAndSettle();
      await _chooseLanguage(tester, 'English');
      expect(find.text('Create Profile & Continue'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(0))
            .controller!
            .text,
        'Usaha QA',
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        '081234567890',
      );
      expect(tester.state<FormFieldState<String>>(selector).value, 'jasa');
      final prefs = sl<SharedPreferences>();
      expect(prefs.getString(AppLanguageController.preferenceKey), 'en');
      expect(prefs.getString('token'), 'unchanged-session');
      expect(prefs.getString('shift_id'), 'unchanged-shift');
      await _chooseLanguage(tester, 'Bahasa Indonesia');
      expect(find.text('Buat Profil & Lanjutkan'), findsOneWidget);
      _visiblePicker(tester);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'language remains usable during business submission and after failure',
    (tester) async {
      final auth = _Auth();
      sl.registerSingleton<AuthRepository>(auth);
      await _open(tester, const BusinessSetupPage());
      await tester.enterText(find.byType(TextFormField).at(0), 'Usaha QA');
      await tester.enterText(find.byType(TextFormField).at(1), '081234567890');
      await tester.ensureVisible(find.text('Buat Profil & Lanjutkan'));
      await tester.tap(find.text('Buat Profil & Lanjutkan'));
      await tester.pump();
      expect(auth.creates, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      _visiblePicker(tester);
      await _chooseLanguage(tester, 'English');
      expect(AppLanguageController.instance.value, const Locale('en'));
      auth.pending.complete(const Left(NetworkFailure('Connection failed')));
      await tester.pumpAndSettle();
      _visiblePicker(tester);
      expect(find.text('Create Profile & Continue'), findsOneWidget);
      expect(auth.creates, 1);
      expect(tester.takeException(), isNull);
    },
  );
  for (final gate in [true, false]) {
    testWidgets(
      'language stays visible on ${gate ? 'setup gate' : 'profile configuration'} loading and retry error',
      (tester) async {
        final settings = _Settings();
        sl.registerSingleton<PosSettingsRepository>(settings);
        sl.registerSingleton<PosRepository>(_Runtime());
        await _open(
          tester,
          gate ? const PosOnboardingGate() : const PosOnboardingPage(),
        );
        _visiblePicker(tester);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await _chooseLanguage(tester, 'English');
        settings.pending.complete(
          const Left(NetworkFailure('Connection failed')),
        );
        await tester.pumpAndSettle();
        _visiblePicker(tester);
        expect(find.text('Connection failed'), findsOneWidget);
        await _chooseLanguage(tester, 'Bahasa Indonesia');
        _visiblePicker(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 26));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
