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

class _Runtime implements PosRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'inventory_profile': 'simple',
    'permissions': {'manage_settings': true},
    'configuration_health': {'valid': true, 'issues': <String>[]},
  };
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Settings implements PosSettingsRepository {
  _Settings({this.catalog});
  final PosRemoteProfileCatalog? catalog;
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async =>
      catalog ?? PosRemoteProfileCatalog.bundled();
  Map<String, dynamic>? saved;
  @override
  Future<Either<Failure, PosSettings>> getSettings() async => const Right(
    PosSettings(
      businessProfile: 'jasa',
      enabledFeatures: {'use_service_order': true, 'track_stock': true},
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
    for (var i = 0; i < 3; i++) {
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
    'salon mengambil data server, menampilkan fitur lengkap dan menyimpan kontrak bersama',
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
      final staff = find.widgetWithText(SwitchListTile, 'Teknisi / staf');
      expect(tester.widget<SwitchListTile>(staff).value, isTrue);
      expect(
        find.widgetWithText(SwitchListTile, 'Kitchen flow'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(SwitchListTile, 'Data kendaraan'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        '5.5',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
      expect(repository.saved?['business_profile'], 'salon');
      expect(
        repository.saved?['enabled_features'],
        posProfileFeatures('salon'),
      );
      expect(repository.saved?['pajak_persen'], 5.5);
      expect(repository.saved?['auto_print_receipt'], isTrue);
      expect(repository.saved?['onboarding_completed'], isTrue);
      expect(find.text('Contoh respons gagal menyimpan'), findsOneWidget);
    },
  );
}
