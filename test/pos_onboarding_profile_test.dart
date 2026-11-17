import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

class _Runtime implements PosRepository {
  _Runtime({this.inventoryProfile = 'simple', this.policy = const {}});
  final String inventoryProfile;
  final Map<String, bool> policy;
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'inventory_profile': inventoryProfile,
    'inventory_policy': policy,
    'permissions': {'manage_settings': true},
    'configuration_health': {'valid': true, 'issues': <String>[]},
  };
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements PosSettingsRepository {
  _Settings({this.catalog, this.initial});
  final PosRemoteProfileCatalog? catalog;
  final PosSettings? initial;
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async =>
      catalog ?? PosRemoteProfileCatalog.bundled();
  Map<String, dynamic>? saved;
  @override
  Future<Either<Failure, PosSettings>> getSettings() async => Right(
    initial ??
        const PosSettings(
          businessProfile: 'jasa',
          enabledFeatures: {
            'use_service_order': true,
            'track_stock': true,
            '__typename': false,
          },
          pajakPersen: 5.5,
          autoPrintReceipt: true,
          defaultChannelPenjualan: 'retail',
          defaultPriceLevel: 'retail',
          defaultTipePesanan: 'take_away',
        ),
  );
  @override
  Future<Either<Failure, PosSettings>> updateSettings(
    Map<String, dynamic> input,
  ) async {
    saved = input;
    // Keep this test on the wizard and exercise its server-error feedback too.
    return const Left(ServerFailure('Contoh respons gagal menyimpan'));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(() async => sl.reset());
  testWidgets(
    'transaction defaults keep dropdown titles and tax label visible',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<PosRepository>(_Runtime());
      sl.registerSingleton<PosSettingsRepository>(_Settings());
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light(), home: const PosOnboardingPage()),
      );
      await tester.pumpAndSettle();
      for (var step = 0; step < 1; step++) {
        await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
        await tester.pumpAndSettle();
      }
      for (final title in [
        'Channel penjualan',
        'Tipe pemenuhan',
        'Level harga',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      final tax = find.byWidgetPredicate(
        (w) =>
            w is InputDecorator &&
            w.decoration.labelText == 'Pajak transaksi (%)',
      );
      expect(
        tester.widget<InputDecorator>(tax).decoration.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
      await tester.enterText(find.byType(TextFormField), '7.5');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(
        tester.widget<InputDecorator>(tax).decoration.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('GraphQL metadata is never copied into POS feature input', () {
    final settings = PosSettings.fromJson({
      'enabled_features': {
        '__typename': 'POSFeatureFlags',
        'track_stock': true,
        'use_tables': false,
        'unexpected_future_flag': true,
      },
    });
    expect(settings.enabledFeatures, {
      'track_stock': true,
      'use_tables': false,
    });
  });
  testWidgets('backend-only profile appears without bundled catalog update', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<PosRepository>(_Runtime());
    final payload = PosRemoteProfileCatalog.bundled().toJson();
    final profiles = payload['profiles'] as List;
    profiles.add({
      ...Map<String, dynamic>.from(
        profiles.firstWhere((p) => p['value'] == 'salon'),
      ),
      'value': 'studio_baru',
      'label': 'Studio Baru Backend',
      'default_order_type': 'reservation',
    });
    final repository = _Settings(
      catalog: PosRemoteProfileCatalog.fromJson(payload),
    );
    sl.registerSingleton<PosSettingsRepository>(repository);
    await tester.pumpWidget(const MaterialApp(home: PosOnboardingPage()));
    await tester.pumpAndSettle();
    expect(posProfileIds.contains('studio_baru'), isFalse);
    final choice = find.widgetWithText(ChoiceChip, 'Studio Baru Backend');
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();
    expect(repository.saved?['business_profile'], 'studio_baru');
    expect(repository.saved?['default_tipe_pesanan'], 'reservation');
    expect(repository.saved?['enabled_features']['use_appointments'], isTrue);
  });
  testWidgets(
    'salon skips operational needs and saves profile presets with server defaults',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'pos_runtime_config': jsonEncode({
          'business_profile': 'retail',
          'tax_percent': 99,
        }),
      });
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<PosRepository>(_Runtime());
      final repository = _Settings();
      sl.registerSingleton<PosSettingsRepository>(repository);
      await tester.pumpWidget(const MaterialApp(home: PosOnboardingPage()));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Jasa'))
            .selected,
        isTrue,
      );
      await tester.ensureVisible(
        find.widgetWithText(ChoiceChip, 'Salon / Barbershop'),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Salon / Barbershop'));
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Kebutuhan operasional'), findsNothing);
      expect(
        find.widgetWithText(SwitchListTile, 'Teknisi / staf'),
        findsNothing,
      );
      expect(find.text('Langkah 2 dari 3 · Default Transaksi'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '5.5',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      expect(
        find.text('Langkah 3 dari 3 · Validasi Inventory'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(repository.saved?['business_profile'], 'salon');
      expect(
        repository.saved?['enabled_features'],
        posProfileFeatures('salon'),
      );
      expect(
        (repository.saved?['enabled_features'] as Map).containsKey(
          '__typename',
        ),
        isFalse,
      );
      expect(repository.saved?['pajak_persen'], 5.5);
      expect(repository.saved?['auto_print_receipt'], isTrue);
      expect(repository.saved?['onboarding_completed'], isTrue);
      expect(find.text('Contoh respons gagal menyimpan'), findsOneWidget);
    },
  );

  for (final profile in posProfileIds) {
    testWidgets('$profile uses three steps and preserves safe features', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<PosRepository>(_Runtime());
      final repository = _Settings();
      sl.registerSingleton<PosSettingsRepository>(repository);
      await tester.pumpWidget(const MaterialApp(home: PosOnboardingPage()));
      await tester.pumpAndSettle();
      expect(find.text('Langkah 1 dari 3 · Profil Usaha'), findsOneWidget);
      final choice = find.widgetWithText(
        ChoiceChip,
        profile == 'custom' ? 'Kustom' : posProfileLabels[profile]!,
      );
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Langkah 2 dari 3 · Default Transaksi'), findsOneWidget);
      expect(find.text('Kebutuhan operasional'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(repository.saved?['business_profile'], profile);
      expect(
        repository.saved?['enabled_features'],
        posProfileFeatures(
          profile,
          current: {
            ...posProfileFeatures('jasa'),
            'use_service_order': true,
            'track_stock': true,
          },
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'English setup translates the three-step flow and deferred settings guidance',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<PosRepository>(_Runtime());
      sl.registerSingleton<PosSettingsRepository>(_Settings());
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PosOnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 3 · Business Profile'), findsOneWidget);
      expect(
        find.text(
          'Operational features follow your business profile. Customize them later in POS Settings → Transactions & Sales.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2 of 3 · Transaction Defaults'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 3 · Inventory Validation'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final inventory in ['simple', 'centralized', 'advanced', 'custom']) {
    testWidgets(
      'hidden tracking stays valid for $inventory inventory without changing profile',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        sl.registerSingleton<SharedPreferences>(
          await SharedPreferences.getInstance(),
        );
        sl.registerSingleton<PosRepository>(
          _Runtime(
            inventoryProfile: inventory,
            policy: const {'use_display_stock': true},
          ),
        );
        final repository = _Settings(
          initial: const PosSettings(
            businessProfile: 'custom',
            enabledFeatures: {'track_stock': false, 'use_order_queue': true},
          ),
        );
        sl.registerSingleton<PosSettingsRepository>(repository);
        await tester.pumpWidget(const MaterialApp(home: PosOnboardingPage()));
        await tester.pumpAndSettle();
        for (var i = 0; i < 2; i++) {
          await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
        await tester.pumpAndSettle();
        expect(
          repository.saved?['enabled_features']['track_stock'],
          inventory != 'simple',
        );
        expect(
          repository.saved?['enabled_features']['use_order_queue'],
          isTrue,
        );
        expect(repository.saved?['business_profile'], 'custom');
        expect(tester.takeException(), isNull);
      },
    );
  }
}
