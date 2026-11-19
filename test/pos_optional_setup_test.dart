import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_suggestion.dart';

class _Settings extends Fake implements PosSettingsRepository {
  bool offline = false, recoveryFails = false, complete = false;
  int recoveries = 0, writes = 0;
  @override
  Future<Either<Failure, Map<String, dynamic>>> ensureInitialSetup() async {
    recoveries++;
    return recoveryFails ? const Left(NetworkFailure('offline')) : const Right({'status': 'ready'});
  }
  @override
  Future<Either<Failure, PosSettings>> getSettings() async => offline
      ? const Left(NetworkFailure('offline'))
      : Right(PosSettings(onboardingCompleted: complete));
  @override
  Future<Either<Failure, PosSettings>> updateSettings(Map<String, dynamic> input) async {
    writes++;
    return Right(PosSettings.fromJson(input));
  }
}

void main() {
  tearDown(() async => sl.reset());
  for (final mode in ['new', 'legacy', 'offline', 'pending-offline', 'pending-owner', 'pending-staff']) {
    testWidgets('$mode reaches home without forcing setup or changing configuration', (tester) async {
      SharedPreferences.setMockInitialValues({
        'instansi_id': 'tenant', 'user_id': 'user',
        'pos_runtime_config': jsonEncode({
          'initial_setup': {
            'automatic': mode.startsWith('pending'), 'status': 'pending',
            'can_manage': mode != 'pending-staff',
          },
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      sl.registerSingleton<SharedPreferences>(prefs);
      final settings = _Settings()
        ..offline = mode.contains('offline')
        ..recoveryFails = mode.contains('offline')
        ..complete = mode == 'legacy';
      sl.registerSingleton<PosSettingsRepository>(settings);
      await tester.pumpWidget(MaterialApp(home: PosOnboardingGate(
        shellBuilder: (_) => const Scaffold(body: Text('POS home')),
      )));
      await tester.pumpAndSettle();
      expect(find.text('POS home'), findsOneWidget);
      expect(settings.writes, 0);
      expect(settings.recoveries, mode.startsWith('pending') && mode != 'pending-staff' ? 1 : 0);
      expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), false);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('suggestion can dismiss persistently without completing setup and is tenant scoped', (tester) async {
    SharedPreferences.setMockInitialValues({'instansi_id': 'a', 'user_id': 'u'});
    final prefs = await SharedPreferences.getInstance();
    var opened = 0;
    Future<void> show(String tenant) async {
      await prefs.setString('instansi_id', tenant);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: PosSetupSuggestion(
        preferences: prefs, onOpenGuide: () => opened++,
      ))));
      await tester.pumpAndSettle();
    }
    await show('a');
    await tester.tap(find.text('Lihat panduan')); expect(opened, 1);
    await tester.tap(find.byTooltip('Sembunyikan panduan')); await tester.pumpAndSettle();
    expect(find.text('Lihat panduan'), findsNothing);
    expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), false);
    await show('a'); expect(find.text('Lihat panduan'), findsNothing);
    await show('b'); expect(find.text('Lihat panduan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 900.0]) {
    testWidgets('optional suggestion fits width $width with large text', (tester) async {
      SharedPreferences.setMockInitialValues({'instansi_id': 'a', 'user_id': 'u'});
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(home: MediaQuery(
        data: MediaQueryData(size: Size(width, 700), textScaler: const TextScaler.linear(1.5)),
        child: Scaffold(body: PosSetupSuggestion(preferences: prefs, onOpenGuide: () {})),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Lihat panduan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
