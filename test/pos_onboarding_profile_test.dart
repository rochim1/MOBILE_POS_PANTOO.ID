import 'dart:convert';
import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';

class _Runtime extends Fake implements PosRepository {
  _Runtime({
    this.inventory = 'simple',
    this.issues = const [],
    this.canManage = true,
  });
  final String inventory;
  final List<String> issues;
  final bool canManage;
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'inventory_profile': inventory,
    'inventory_policy': {'use_display_stock': true},
    'permissions': {'manage_settings': canManage},
    'configuration_health': {'valid': issues.isEmpty, 'issues': issues},
  };
}

class _Settings extends Fake implements PosSettingsRepository {
  _Settings({this.catalog, this.initial});
  final PosRemoteProfileCatalog? catalog;
  final PosSettings? initial;
  int saves = 0;
  bool succeed = false, failLoad = false;
  Completer<Either<Failure, PosSettings>>? pending;
  Map<String, dynamic>? saved;
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async =>
      catalog ?? PosRemoteProfileCatalog.bundled();
  @override
  Future<Either<Failure, PosSettings>> getSettings() async => failLoad
      ? const Left(NetworkFailure('Koneksi terputus'))
      : Right(
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
    saves++;
    saved = input;
    if (pending != null) return pending!.future;
    if (succeed) return Right(PosSettings.fromJson(input));
    return const Left(ServerFailure('Gagal menyimpan, silakan coba lagi'));
  }
}

Future<void> _open(
  WidgetTester tester,
  _Settings settings, {
  _Runtime? runtime,
  String? pending,
  bool english = false,
  VoidCallback? onCompleted,
}) async {
  SharedPreferences.setMockInitialValues({
    'instansi_id': 'tenant',
    'user_id': 'user',
    if (pending != null) 'pos_initial_business_profile_v1:tenant:user': pending,
    'pos_runtime_config': jsonEncode({
      'permissions': {'manage_settings': true},
    }),
  });
  sl.registerSingleton<SharedPreferences>(
    await SharedPreferences.getInstance(),
  );
  sl.registerSingleton<PosRepository>(runtime ?? _Runtime());
  sl.registerSingleton<PosSettingsRepository>(settings);
  await tester.binding.setSurfaceSize(const Size(390, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: english ? const Locale('en') : null,
      localizationsDelegates: english
          ? AppLocalizations.localizationsDelegates
          : null,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PosOnboardingPage(onCompleted: onCompleted),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() async => sl.reset());

  testWidgets(
    'incomplete existing workspace only asks business profile, no transaction wizard',
    (tester) async {
      await _open(tester, _Settings());
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Profil usaha'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Default transaksi'), findsNothing);
      expect(find.text('Kebutuhan operasional'), findsNothing);
      expect(find.text('Channel penjualan'), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('GraphQL metadata is not a supported POS feature', () {
    expect(
      PosSettings.fromJson({
        'enabled_features': {
          'track_stock': true,
          '__typename': 'flags',
          'future': true,
        },
      }).enabledFeatures,
      {'track_stock': true},
    );
  });

  for (final profile in posProfileIds) {
    testWidgets(
      '$profile saves presets and preserves transaction defaults in one action',
      (tester) async {
        final settings = _Settings();
        await _open(tester, settings);
        await _choose(
          tester,
          profile == 'custom' ? 'Kustom' : posProfileLabels[profile]!,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
        await tester.pumpAndSettle();
        expect(settings.saves, 1);
        expect(settings.saved?['business_profile'], profile);
        expect(
          settings.saved?['enabled_features'],
          posProfileFeatures(profile, current: posProfileFeatures('jasa')),
        );
        expect(settings.saved?['pajak_persen'], 5.5);
        expect(settings.saved?['auto_print_receipt'], isTrue);
        expect(settings.saved?['default_channel_penjualan'], 'retail');
        expect(settings.saved?['default_price_level'], 'retail');
        expect(settings.saved?['onboarding_completed'], isTrue);
        expect(find.text('Gagal menyimpan, silakan coba lagi'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'backend-only profile still appears and saves reservation default',
    (tester) async {
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
      final settings = _Settings(
        catalog: PosRemoteProfileCatalog.fromJson(payload),
      );
      await _open(tester, settings);
      await _choose(tester, 'Studio Baru Backend');
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(settings.saved?['business_profile'], 'studio_baru');
      expect(settings.saved?['default_tipe_pesanan'], 'reservation');
      expect(settings.saved?['enabled_features']['use_appointments'], isTrue);
    },
  );

  for (final inventory in ['simple', 'centralized', 'advanced', 'custom']) {
    testWidgets(
      '$inventory keeps hidden tracking safe without resetting custom flags',
      (tester) async {
        final settings = _Settings(
          initial: const PosSettings(
            businessProfile: 'custom',
            enabledFeatures: {'track_stock': false, 'use_order_queue': true},
          ),
        );
        await _open(tester, settings, runtime: _Runtime(inventory: inventory));
        await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
        await tester.pumpAndSettle();
        expect(
          settings.saved?['enabled_features']['track_stock'],
          inventory != 'simple',
        );
        expect(settings.saved?['enabled_features']['use_order_queue'], isTrue);
      },
    );
  }

  testWidgets(
    'pending business creation auto-applies selection and retries without asking profile again',
    (tester) async {
      final settings = _Settings();
      await _open(tester, settings, pending: 'restoran');
      expect(settings.saves, 1);
      expect(settings.saved?['business_profile'], 'restoran');
      expect(settings.saved?['default_tipe_pesanan'], 'dine_in');
      expect(
        sl<SharedPreferences>().getString(
          'pos_initial_business_profile_v1:tenant:user',
        ),
        'restoran',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(settings.saves, 2);
      expect(settings.saved?['business_profile'], 'restoran');
    },
  );

  testWidgets(
    'inventory issues still block automatic completion with a visible explanation',
    (tester) async {
      final settings = _Settings();
      await _open(
        tester,
        settings,
        pending: 'restoran',
        runtime: _Runtime(issues: ['Lokasi stok belum valid']),
      );
      expect(settings.saves, 0);
      expect(find.textContaining('Lokasi stok belum valid'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan'))
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'English recovery screen uses the same compact labeled selector',
    (tester) async {
      await _open(tester, _Settings(), english: true);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
      expect(find.text('Default transaksi'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'new business automatically finishes with selected profile and no extra prompt',
    (tester) async {
      final settings = _Settings()..succeed = true;
      var completed = 0;
      await _open(
        tester,
        settings,
        pending: 'restoran',
        onCompleted: () => completed++,
      );
      expect(completed, 1);
      expect(settings.saves, 1);
      final prefs = sl<SharedPreferences>();
      expect(
        prefs.containsKey(PosOnboardingPage.pendingProfileKey(prefs)),
        isFalse,
      );
      expect(PosOnboardingPage.isCompleted(prefs), isTrue);
      final runtime = jsonDecode(prefs.getString('pos_runtime_config')!) as Map;
      expect(runtime['business_profile'], 'restoran');
      expect(runtime['default_order_type'], 'dine_in');
      expect(runtime['features']['use_kitchen_flow'], isTrue);
      expect(runtime['tax_percent'], 5.5);
    },
  );

  testWidgets(
    'lost save response reopens committed setup without overwriting it',
    (tester) async {
      final settings = _Settings(
        initial: const PosSettings(
          onboardingCompleted: true,
          businessProfile: 'laundry',
        ),
      );
      var completed = 0;
      await _open(
        tester,
        settings,
        pending: 'restoran',
        onCompleted: () => completed++,
      );
      expect(completed, 1);
      expect(settings.saves, 0);
      final prefs = sl<SharedPreferences>();
      expect(
        prefs.containsKey(PosOnboardingPage.pendingProfileKey(prefs)),
        isFalse,
      );
      expect(PosOnboardingPage.isCompleted(prefs), isTrue);
    },
  );

  testWidgets(
    'loading failure is recoverable without a new business creation',
    (tester) async {
      final settings = _Settings()..failLoad = true;
      await _open(tester, settings);
      expect(find.text('Koneksi terputus'), findsOneWidget);
      settings.failLoad = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(settings.saves, 0);
    },
  );

  testWidgets(
    'cashier without manage permission cannot apply a pending profile',
    (tester) async {
      final settings = _Settings();
      await _open(
        tester,
        settings,
        pending: 'restoran',
        runtime: _Runtime(canManage: false),
      );
      expect(settings.saves, 0);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .onChanged,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan'))
            .onPressed,
        isNull,
      );
    },
  );

  for (final tax in [-1.0, 101.0, double.nan]) {
    testWidgets('invalid stored tax $tax cannot silently finish setup', (
      tester,
    ) async {
      final settings = _Settings(initial: PosSettings(pajakPersen: tax));
      await _open(tester, settings, pending: 'retail');
      expect(settings.saves, 0);
      expect(find.text('Pajak harus antara 0 dan 100 persen'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Simpan'))
            .onPressed,
        isNull,
      );
    });
  }

  testWidgets(
    'pending profile is validated against the catalog before auto-save',
    (tester) async {
      final settings = _Settings();
      await _open(tester, settings, pending: 'untrusted_profile');
      expect(settings.saves, 0);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    },
  );

  testWidgets('pending save shows progress and cannot submit twice', (
    tester,
  ) async {
    final settings = _Settings()
      ..pending = Completer<Either<Failure, PosSettings>>();
    await _open(tester, settings);
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pump();
    expect(settings.saves, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Simpan'), findsNothing);
    settings.pending!.complete(const Left(NetworkFailure('Koneksi terputus')));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi terputus'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Simpan'), findsOneWidget);
  });
}
