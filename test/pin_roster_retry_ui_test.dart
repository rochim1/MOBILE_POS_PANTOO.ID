import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';
import 'pin_lock_responsive_test.dart' show TestLockCubit, TestPosRepository;

const message = 'Daftar kasir belum dapat dimuat. Periksa koneksi lalu coba lagi.';
class RetryLock extends TestLockCubit {
  int loads = 0;
  Completer<bool> response = Completer<bool>();
  void fail() => emit(const AppLockState(status: AppLockStatus.locked, errorMessage: message));
  @override
  Future<void> loadEmployees({String search = ''}) async {
    loads++;
    emit(state.copyWith(loadingEmployees: true, errorMessage: ''));
    final ready = await response.future;
    response = Completer<bool>();
    if (ready) { seedLocked(); } else { fail(); }
  }
}
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_id': 'u1', 'instansi_id': 'tenant'});
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    sl.registerSingleton<PosRepository>(TestPosRepository());
  });
  tearDown(() => sl.reset());
  Future<void> mount(WidgetTester tester, RetryLock lock, {Locale locale = const Locale('id')}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(lock.close);
    await tester.pumpWidget(BlocProvider<AppLockCubit>.value(value: lock, child: MaterialApp(
      locale: locale, localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), home: const Scaffold(body: PinLockScreen()),
    )));
    await tester.pump(const Duration(milliseconds: 400));
  }
  for (final locale in [const Locale('id'), const Locale('en')]) {
    testWidgets('failed roster offers a working explicit retry without logout (${locale.languageCode})', (tester) async {
      final lock = RetryLock()..fail();
      await mount(tester, lock, locale: locale);
      final retry = find.byKey(const Key('pin-roster-retry'));
      expect(retry, findsOneWidget);
      expect(find.text(locale.languageCode == 'id' ? 'Coba lagi' : 'Try again'), findsOneWidget);
      await tester.ensureVisible(retry); await tester.pump();
      await tester.tap(retry); await tester.pump();
      expect(lock.loads, 1);
      expect(lock.state.loadingEmployees, true);
      expect(lock.state.status, AppLockStatus.locked);
      lock.response.complete(true); await tester.pump();
      expect(lock.state.selectedEmployeeId, 'u1');
      expect(lock.state.status, AppLockStatus.locked);
      expect(lock.enteredPins, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('picker opens during retry, distinguishes load failure from empty search, and retries in place', (tester) async {
    final lock = RetryLock()..fail();
    await mount(tester, lock);
    await tester.tap(find.byKey(posPinOperatorTourTarget));
    await tester.pump(const Duration(milliseconds: 400));
    final openedWhileLoading = find.text('Pilih Kasir').evaluate().isNotEmpty;
    lock.response.complete(false); await tester.pump(const Duration(milliseconds: 400));
    expect(openedWhileLoading, true);
    expect(find.byKey(const Key('pin-picker-roster-retry')), findsOneWidget);
    expect(find.text('Karyawan tidak ditemukan'), findsNothing);
    await tester.tap(find.byKey(const Key('pin-picker-roster-retry'))); await tester.pump();
    expect(lock.loads, 2);
    lock.response.complete(true); await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Kasir Dua'), findsOneWidget);
    expect(lock.state.status, AppLockStatus.locked);
    expect(lock.enteredPins, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
