import 'dart:async';
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

class _Settings extends Fake implements PosSettingsRepository {
  int recoveries = 0, reads = 0;
  bool fail = true;
  @override
  Future<Either<Failure, Map<String, dynamic>>> ensureInitialSetup() async {
    recoveries++;
    return fail ? const Left(NetworkFailure('Koneksi terputus')) : const Right({'status': 'ready'});
  }
  @override
  Future<Either<Failure, PosSettings>> getSettings() {
    reads++;
    return Completer<Either<Failure, PosSettings>>().future;
  }
}
void main() {
  tearDown(() async => sl.reset());
  Future<_Settings> open(WidgetTester tester, Map<String,dynamic>? initial) async {
    SharedPreferences.setMockInitialValues({'instansi_id':'tenant','user_id':'owner','pos_runtime_config':jsonEncode({'initial_setup':initial})});
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    final settings = _Settings();sl.registerSingleton<PosSettingsRepository>(settings);
    await tester.pumpWidget(const MaterialApp(home:PosOnboardingGate()));
    await tester.pump();await tester.pump();return settings;
  }
  testWidgets('pending owner context recovers before loading settings and a failed request can retry', (tester) async {
    final settings = await open(tester, {'automatic':true,'status':'pending','can_manage':true});
    expect(settings.recoveries,1);expect(settings.reads,0);
    expect(find.textContaining('Koneksi terputus'),findsOneWidget);
    settings.fail=false;await tester.tap(find.text('Coba lagi'));await tester.pump();await tester.pump();
    expect(settings.recoveries,2);expect(settings.reads,1);
    expect(find.text('Coba lagi'),findsNothing);
  });
  testWidgets('legacy and non-owner do not attempt automatic provisioning', (tester) async {
    final settings = await open(tester, null);expect(settings.recoveries,0);expect(settings.reads,1);
    await tester.pumpWidget(const SizedBox());await sl.reset();
    final staff = await open(tester, {'automatic':true,'status':'pending','can_manage':false});
    expect(staff.recoveries,0);expect(staff.reads,1);
  });
}
