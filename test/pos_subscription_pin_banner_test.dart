import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_trusted_clock.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_subscription_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/inactivity_wrapper.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_subscription_boundary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repository extends Fake implements PosRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'pos_lock_enabled': true,
    'pos_lock_on_background': false,
    'pos_auto_lock_minutes': 5,
  };
}

class _Lock extends AppLockCubit {
  void setLocked(bool locked) => emit(
    AppLockState(
      status: locked ? AppLockStatus.locked : AppLockStatus.unlocked,
      hasPinConfigured: true,
      selectedEmployeeId: 'cashier',
      employees: const [
        {'_id': 'cashier', 'name': 'Kasir QA', 'has_pin': true},
      ],
    ),
  );
  @override
  Future<void> loadEmployees({String search = ''}) async {}
}

class _Access {
  static final start = DateTime.utc(2026, 11, 22, 8);
  DateTime now = start;
  bool online = true;
  String level = 'full';
  int calls = 0;
  bool disposed = false;
  String scope = 'qa|tenant|user|cashier';
  Completer<Map<String, dynamic>>? pending;
  late final service = PosSubscriptionService(
    fetch: () async {
      calls++;
      if (pending != null) return pending!.future;
      if (!online) throw StateError('Offline QA');
      return {
        'access_level': level,
        'effective_state': level == 'full' ? 'active' : 'recovery',
        'server_now': now.toIso8601String(),
        'offline_valid_until': now
            .add(const Duration(hours: 24))
            .toIso8601String(),
        'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
        'operational_until': now
            .add(const Duration(days: 33))
            .toIso8601String(),
        'read_only_until': now.add(const Duration(days: 37)).toIso8601String(),
        'is_owner': true,
      };
    },
    readScope: () => scope,
    storage: const FlutterSecureStorage(),
    clock: () => now,
    trustedClock: () async => PosTrustedClockStamp(
      'qa-boot',
      1000 + now.difference(start).inMilliseconds,
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id');
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'instansi_id': 'tenant'});
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<PosRepository>(_Repository());
  });
  tearDown(() => sl.reset());

  Future<void> cleanup(WidgetTester tester, _Access access, _Lock lock) async {
    if (access.disposed) return;
    await tester.pumpWidget(const SizedBox());
    await lock.close();
    access.service.dispose();
    access.disposed = true;
    if (access.pending?.isCompleted == false) {
      access.pending!.completeError(StateError('Test ended'));
      await tester.pump();
    }
  }

  Future<void> mount(
    WidgetTester tester,
    _Access access,
    _Lock lock, {
    VoidCallback? onPrivateTap,
    bool settle = true,
  }) async {
    final nav = GlobalKey<NavigatorState>();
    final receipt = ValueNotifier(false);
    addTearDown(() async {
      await cleanup(tester, access, lock);
      receipt.dispose();
    });
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: lock,
        child: MaterialApp(
          navigatorKey: nav,
          builder: (_, child) => PosSubscriptionBoundary(
            service: access.service,
            authenticated: true,
            onLogout: () {},
            navigatorKey: nav,
            receiptVisible: receipt,
            child: InactivityWrapper(authenticated: true, child: child!),
          ),
          home: Scaffold(
            body: TextButton(
              onPressed: onPrivateTap ?? () {},
              child: const Text('Private workspace'),
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets(
    'pending access after PIN shows progress without premature recovery actions',
    (tester) async {
      final access = _Access()..pending = Completer<Map<String, dynamic>>();
      final lock = _Lock()..setLocked(false);
      var privateTaps = 0;
      await mount(
        tester,
        access,
        lock,
        settle: false,
        onPrivateTap: () => privateTaps++,
      );
      expect(access.service.checking, true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.textContaining('Access has not been confirmed'),
        findsNothing,
      );
      expect(find.text('Close shift'), findsNothing);
      expect(find.text('View offline queue'), findsNothing);
      expect(find.text('Sign out'), findsNothing);
      await tester.tap(find.text('Private workspace'), warnIfMissed: false);
      expect(privateTaps, 0);
      final pending = access.pending!;
      access.pending = null;
      pending.complete(await access.service.fetch());
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Private workspace'));
      expect(privateTaps, 1);
      expect(access.service.canSell, true);
      await cleanup(tester, access, lock);
    },
  );

  testWidgets(
    'locking cashier with an unverified new scope keeps PIN usable and writes denied',
    (tester) async {
      final access = _Access();
      final lock = _Lock()..setLocked(false);
      await mount(tester, access, lock);
      access.scope = 'qa|tenant|user|';
      access.online = false;
      lock.setLocked(true);
      await access.service.activate();
      await tester.pumpAndSettle();
      expect(find.byType(PinLockScreen), findsOneWidget);
      expect(
        find.textContaining('Access has not been confirmed'),
        findsNothing,
      );
      expect(find.text('Close shift'), findsNothing);
      expect(access.service.canSell, false);
      expect(
        await access.service.guardMutation({'ProcessPOSPenjualan'}),
        isNotNull,
      );
      expect(await access.service.guardOfflineWrite(), isNotNull);
      expect(await access.service.guardMutation({'VerifyPOSUserPin'}), isNull);
      await cleanup(tester, access, lock);
    },
  );

  testWidgets(
    'verification timeout offers recovery and retry returns to progress until a real decision',
    (tester) async {
      final access = _Access()..pending = Completer<Map<String, dynamic>>();
      final lock = _Lock()..setLocked(false);
      var privateTaps = 0;
      await mount(
        tester,
        access,
        lock,
        settle: false,
        onPrivateTap: () => privateTaps++,
      );
      await tester.pump(const Duration(seconds: 13));
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Close shift'), findsOneWidget);
      expect(find.text('View offline queue'), findsOneWidget);
      expect(access.service.canSell, false);
      access.pending!.completeError(StateError('Late failed response'));
      access.pending = Completer<Map<String, dynamic>>();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(
        find.textContaining('Access has not been confirmed'),
        findsNothing,
      );
      expect(find.text('Close shift'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      access.level = 'billing_only';
      final pending = access.pending!;
      access.pending = null;
      pending.complete(await access.service.fetch());
      await tester.pumpAndSettle();
      expect(find.byType(PosSubscriptionPage), findsOneWidget);
      await tester.tap(find.text('Private workspace'), warnIfMissed: false);
      expect(privateTaps, 0);
      expect(await access.service.guardOfflineWrite(), isNotNull);
      await cleanup(tester, access, lock);
    },
  );

  testWidgets(
    'PIN hides offline banner while polling and trusted offline access continue',
    (tester) async {
      final access = _Access();
      final lock = _Lock()..setLocked(true);
      await access.service.activate();
      access.online = false;
      await access.service.refresh();
      await mount(tester, access, lock);
      expect(find.byType(PinLockScreen), findsOneWidget);
      expect(access.service.showWarning, true);
      expect(find.textContaining('Last known subscription'), findsNothing);
      expect(find.text('Details'), findsNothing);
      expect(
        tester.getSize(find.byType(PinLockScreen)).height,
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      );
      expect(await access.service.guardOfflineWrite(), isNull);
      final beforePoll = access.calls;
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(access.calls, greaterThan(beforePoll));
      expect(find.textContaining('Last known subscription'), findsNothing);
      final beforeResume = access.calls;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(access.calls, greaterThan(beforeResume));
      expect(find.textContaining('Last known subscription'), findsNothing);
      lock.setLocked(false);
      await tester.pumpAndSettle();
      expect(find.textContaining('Last known subscription'), findsOneWidget);
      lock.setLocked(true);
      await tester.pumpAndSettle();
      expect(find.textContaining('Last known subscription'), findsNothing);
      expect(tester.takeException(), isNull);
      await cleanup(tester, access, lock);
    },
  );

  testWidgets(
    'server restriction still blocks sales when PIN hides the banner',
    (tester) async {
      final access = _Access();
      final lock = _Lock()..setLocked(true);
      var privateTaps = 0;
      await mount(tester, access, lock, onPrivateTap: () => privateTaps++);
      access.level = 'billing_only';
      await access.service.refresh();
      await tester.pumpAndSettle();
      expect(access.service.canSell, false);
      expect(find.byType(PosSubscriptionPage), findsOneWidget);
      expect(
        await access.service.guardMutation({'ProcessPOSPenjualan'}),
        isNotNull,
      );
      expect(await access.service.guardOfflineWrite(), isNotNull);
      expect(await access.service.guardMutation({'VerifyPOSUserPin'}), isNull);
      expect(
        await access.service.guardMutation({'ClosePOSKasirShift'}),
        isNull,
      );
      lock.setLocked(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private workspace'), warnIfMissed: false);
      expect(privateTaps, 0);
      expect(find.byType(PosSubscriptionPage), findsOneWidget);
      await cleanup(tester, access, lock);
    },
  );

  testWidgets('read-only remains enforced and banner returns only after PIN', (
    tester,
  ) async {
    final access = _Access()..level = 'read_only';
    final lock = _Lock()..setLocked(true);
    await mount(tester, access, lock);
    expect(find.textContaining('Read-only mode'), findsNothing);
    expect(
      await access.service.guardMutation({'ProcessPOSPenjualan'}),
      isNotNull,
    );
    expect(await access.service.guardOfflineWrite(), isNotNull);
    lock.setLocked(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('Read-only mode'), findsOneWidget);
    expect(access.service.canSell, false);
    await cleanup(tester, access, lock);
  });

  testWidgets('hidden banner cannot extend the trusted offline deadline', (
    tester,
  ) async {
    final access = _Access();
    final lock = _Lock()..setLocked(true);
    var privateTaps = 0;
    await mount(tester, access, lock, onPrivateTap: () => privateTaps++);
    access.online = false;
    await access.service.refresh();
    await tester.pumpAndSettle();
    expect(find.textContaining('Last known subscription'), findsNothing);
    access.now = access.now.add(const Duration(hours: 25));
    expect(await access.service.guardOfflineWrite(), isNotNull);
    expect(
      await access.service.guardMutation({'ProcessPOSPenjualan'}),
      isNotNull,
    );
    await tester.pumpAndSettle();
    lock.setLocked(false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Private workspace'), warnIfMissed: false);
    expect(privateTaps, 0);
    expect(access.service.canSell, false);
    await cleanup(tester, access, lock);
  });
}
