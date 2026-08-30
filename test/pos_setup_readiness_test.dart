import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_setup_guide_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const complete = PosSetupReadiness(
    hasStore: true,
    hasStockLocation: true,
    hasProducts: true,
    hasInitialStock: true,
    hasPin: true,
    hasShift: true,
    configurationHealthy: true,
  );

  test('POS siap hanya ketika seluruh prasyarat operasional selesai', () {
    expect(complete.ready, isTrue);
  });

  test('shift tidak dapat menutupi setup lokasi, produk, dan PIN', () {
    const incomplete = PosSetupReadiness(
      hasStore: true,
      hasStockLocation: false,
      hasProducts: false,
      hasInitialStock: false,
      hasPin: false,
      hasShift: true,
      configurationHealthy: true,
    );

    expect(incomplete.ready, isFalse);
  });

  test('konfigurasi inventory tidak valid memblokir mulai berjualan', () {
    const unhealthy = PosSetupReadiness(
      hasStore: true,
      hasStockLocation: true,
      hasProducts: true,
      hasInitialStock: true,
      hasPin: true,
      hasShift: true,
      configurationHealthy: false,
    );

    expect(unhealthy.ready, isFalse);
  });

  test('status setup operasional terpisah per instansi dan user', () async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-a',
      'user_id': 'cashier-a',
    });
    final prefs = await SharedPreferences.getInstance();
    final key = PosOnboardingPage.setupPreferenceKey(prefs);

    expect(key, contains('tenant-a:cashier-a'));
    expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), isFalse);
    await prefs.setBool(key, true);
    expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), isTrue);
  });

  test('flag tour lama dipulihkan sebagai setup operasional selesai', () async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-legacy',
      'user_id': 'cashier-legacy',
      'pos_cashier_tour_v1:tenant-legacy:cashier-legacy': true,
    });
    final prefs = await SharedPreferences.getInstance();

    expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), isTrue);
    await PosOnboardingPage.markOperationalSetupCompleted(prefs);
    expect(prefs.getBool(PosOnboardingPage.setupPreferenceKey(prefs)), isTrue);
  });

  test('reset onboarding membersihkan flag setup dan tour', () async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-reset',
      'user_id': 'cashier-reset',
    });
    final prefs = await SharedPreferences.getInstance();
    await PosOnboardingPage.markOperationalSetupCompleted(prefs);
    await PosOnboardingPage.clearOperationalSetupCompleted(prefs);

    expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), isFalse);
  });

  test('routing awal selalu melewati gate database onboarding', () async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-gate',
      'user_id': 'cashier-gate',
      'pos_onboarding_completed_v2:tenant-gate:cashier-gate': true,
    });
    final prefs = await SharedPreferences.getInstance();

    expect(
      PosOnboardingPage.initialDestination(prefs),
      isA<PosOnboardingGate>(),
    );
  });
}
