import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_startup_loading.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_trusted_clock.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_link.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_subscription_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_subscription_boundary.dart';

final now = DateTime.utc(2026, 11, 15, 8);
Map<String, dynamic> status({
  String level = 'full',
  bool owner = true,
  String state = 'active',
  DateTime? operational,
  DateTime? readOnly,
}) => {
  'access_level': level,
  'is_owner': owner,
  'effective_state': state,
  'server_now': now.toIso8601String(),
  'offline_valid_until': now.add(const Duration(hours: 24)).toIso8601String(),
  'expires_at': now.add(const Duration(days: 30)).toIso8601String(),
  'operational_until': (operational ?? now.add(const Duration(days: 33)))
      .toIso8601String(),
  'read_only_until': (readOnly ?? now.add(const Duration(days: 37)))
      .toIso8601String(),
  'package_name': 'Pantoo POS',
  'days_remaining': 30,
};
PosSubscriptionService service(
  Future<Map<String, dynamic>> Function() fetch, {
  String Function()? scope,
  DateTime Function()? clock,
  Future<PosTrustedClockStamp?> Function()? trustedClock,
}) => PosSubscriptionService(
  fetch: fetch,
  readScope: scope ?? () => 'endpoint|tenant|owner|cashier',
  storage: const FlutterSecureStorage(),
  clock: clock ?? () => now,
  trustedClock:
      trustedClock ??
      () async => PosTrustedClockStamp(
        'test-boot',
        100000 + (clock?.call() ?? now).difference(now).inMilliseconds,
      ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));
  setUpAll(() async {
    await initializeDateFormatting('id');
  });

  test(
    'login preparation distinguishes known restriction from unverified access',
    () async {
      for (final level in ['full', 'read_only', 'billing_only', 'blocked']) {
        final s = service(() async => status(level: level));
        expect(await s.prepareLogin(), true, reason: level);
        s.dispose();
      }
      final unknown = service(() async => throw StateError('offline'));
      expect(await unknown.prepareLogin(), false);
      expect(unknown.canSell, false);
      unknown.dispose();
      final noScope = service(
        () async => throw StateError('not called'),
        scope: () => '',
      );
      expect(await noScope.prepareLogin(), true);
      noScope.dispose();
    },
  );

  test(
    'offline login preparation keeps a valid trusted cached grant',
    () async {
      var online = true;
      Future<Map<String, dynamic>> fetch() async {
        if (!online) throw StateError('offline');
        return status();
      }

      final first = service(fetch);
      expect(await first.prepareLogin(), true);
      first.dispose();
      online = false;
      final restored = service(fetch);
      expect(await restored.prepareLogin(), true);
      expect(restored.offline, true);
      expect(restored.canSell, true);
      restored.dispose();
    },
  );

  testWidgets('pending verification is not a subscription billing page', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    final s = service(() => pending.future);
    final nav = GlobalKey<NavigatorState>();
    final receipt = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        builder: (_, child) => PosSubscriptionBoundary(
          service: s,
          authenticated: true,
          navigatorKey: nav,
          receiptVisible: receipt,
          onLogout: () {},
          child: child!,
        ),
        home: const Scaffold(body: Text('private cashier')),
      ),
    );
    await tester.pump();
    expect(
      find.byType(PosSubscriptionPage),
      findsNothing,
      reason: 'An unfinished check is not evidence of an expired subscription',
    );
    expect(s.canSell, isFalse);
    pending.complete(status());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    receipt.dispose();
    s.dispose();
  });

  testWidgets(
    'unverified access retries in neutral overlay and only then shows billing',
    (tester) async {
      var online = false;
      var privateTaps = 0;
      final response = Completer<Map<String, dynamic>>();
      final s = service(() {
        if (!online) throw StateError('offline');
        return response.future;
      });
      await s.activate();
      final nav = GlobalKey<NavigatorState>();
      final receipt = ValueNotifier(false);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          builder: (_, child) => PosSubscriptionBoundary(
            service: s,
            authenticated: true,
            navigatorKey: nav,
            receiptVisible: receipt,
            onLogout: () {},
            child: child!,
          ),
          home: Scaffold(
            body: TextButton(
              onPressed: () => privateTaps++,
              child: const Text('private'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PosSubscriptionPage), findsNothing);
      await tester.tap(find.text('private'), warnIfMissed: false);
      final retry = find.byType(FilledButton);
      expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
      online = true;
      await tester.tap(retry);
      await tester.pump();
      expect(retry, findsNothing);
      expect(find.byType(PosStartupLoading), findsOneWidget);
      expect(find.textContaining('Access has not been confirmed'), findsNothing);
      expect(s.canSell, false);
      expect(privateTaps, 0);
      response.complete(status(level: 'billing_only', state: 'recovery'));
      await tester.pumpAndSettle();
      expect(find.byType(PosSubscriptionPage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
      receipt.dispose();
    },
  );

  test('model switches access at exact server deadlines', () {
    final value = PosSubscription.fromJson(
      status(operational: now, readOnly: now.add(const Duration(days: 4))),
    );
    expect(
      value.levelAt(now.subtract(const Duration(microseconds: 1))),
      'full',
    );
    expect(value.levelAt(now), 'read_only');
    expect(value.levelAt(now.add(const Duration(days: 4))), 'billing_only');
    final staff = PosSubscription.fromJson(
      status(owner: false, operational: now, readOnly: now),
    );
    expect(staff.levelAt(now), 'blocked');
  });

  test(
    'failed initial verification blocks sales without claiming subscription expired',
    () async {
      final s = service(() async => throw Exception('offline'));
      addTearDown(s.dispose);
      await s.activate();
      expect(s.accessLevel, 'unknown');
      expect(s.canSell, false);
      expect(await s.guardOfflineWrite(), posSubscriptionUnverifiedMessage);
      expect(
        (await s.guardMutation({'ProcessPOSPenjualan'}))?.extensions?['code'],
        'SUBSCRIPTION_REQUIRED',
      );
      expect(await s.guardMutation({'VerifyPOSUserPin'}), isNull);
      expect(await s.guardMutation({'ClosePOSKasirShift'}), isNull);
    },
  );

  test(
    'bounded secure cache works offline and expires across restart; tenant and operator isolated',
    () async {
      var time = now;
      var identity = 'server|tenant-a|owner|cashier-a';
      final a = service(
        () async => status(),
        scope: () => identity,
        clock: () => time,
      );
      await a.activate();
      expect(a.canSell, true);
      a.dispose();
      time = now.add(const Duration(hours: 2));
      final b = service(
        () async => throw Exception('offline'),
        scope: () => identity,
        clock: () => time,
      );
      await b.activate();
      expect(b.offline, true);
      expect(b.canSell, true);
      b.dispose();
      time = now.add(const Duration(hours: 25));
      final c = service(
        () async => throw Exception('offline'),
        scope: () => identity,
        clock: () => time,
      );
      await c.activate();
      expect(c.canSell, false);
      c.dispose();
      time = now;
      identity = 'server|tenant-b|owner|cashier-a';
      final d = service(
        () async => throw Exception('offline'),
        scope: () => identity,
      );
      await d.activate();
      expect(d.canSell, false);
      d.dispose();
      identity = 'server|tenant-a|owner|cashier-b';
      final e = service(
        () async => throw Exception('offline'),
        scope: () => identity,
      );
      await e.activate();
      expect(e.canSell, false);
      e.dispose();
    },
  );

  test(
    'device clock rollback cannot extend a persisted offline grant',
    () async {
      final a = service(() async => status());
      await a.activate();
      a.dispose();
      final b = service(
        () async => throw Exception('offline'),
        clock: () => now.subtract(const Duration(hours: 1)),
      );
      await b.activate();
      expect(b.canSell, false);
      b.dispose();
    },
  );

  test(
    'device date changes cannot restore an expired monotonic offline grant',
    () async {
      var deviceTime = now;
      var uptime = 100000;
      var boot = 'one';
      Future<PosTrustedClockStamp?> readClock() async =>
          PosTrustedClockStamp(boot, uptime);
      PosSubscriptionService offline() => service(
        () async => throw Exception('offline'),
        clock: () => deviceTime,
        trustedClock: readClock,
      );
      final online = service(
        () async => status(),
        clock: () => deviceTime,
        trustedClock: readClock,
      );
      await online.activate();
      online.dispose();
      uptime += const Duration(days: 3).inMilliseconds;
      deviceTime = now.add(const Duration(minutes: 1));
      final expired = offline();
      await expired.activate();
      expect(expired.canSell, false);
      expired.dispose();
      uptime = 100001; // Previously rejected cache has been erased.
      final replay = offline();
      await replay.activate();
      expect(replay.canSell, false);
      replay.dispose();
    },
  );

  test(
    'same-boot restart works offline but reboot and legacy cache require verification',
    () async {
      var uptime = 100000;
      var boot = 'first';
      Future<PosTrustedClockStamp?> readClock() async =>
          PosTrustedClockStamp(boot, uptime);
      final online = service(() async => status(), trustedClock: readClock);
      await online.activate();
      online.dispose();
      uptime += 60000;
      final offline = service(
        () async => throw Exception('offline'),
        trustedClock: readClock,
      );
      await offline.activate();
      expect(offline.canSell, true);
      offline.dispose();
      boot = 'second';
      final reboot = service(
        () async => throw Exception('offline'),
        trustedClock: readClock,
      );
      await reboot.activate();
      expect(reboot.canSell, false);
      reboot.dispose();
      boot = 'first';
      final oldBoot = service(
        () async => throw Exception('offline'),
        trustedClock: readClock,
      );
      await oldBoot.activate();
      expect(oldBoot.canSell, false);
      oldBoot.dispose();
    },
  );

  test(
    'deep sleep elapsed time and unavailable trusted time deny offline writes',
    () async {
      var uptime = 100000;
      var available = true;
      final s = service(
        () async => status(),
        trustedClock: () async =>
            available ? PosTrustedClockStamp('boot', uptime) : null,
      );
      await s.activate();
      uptime += const Duration(hours: 25).inMilliseconds;
      expect(await s.guardOfflineWrite(), isNotNull);
      await s.refresh();
      available = false;
      expect(await s.guardOfflineWrite(), isNotNull);
      s.dispose();
    },
  );

  test('legacy date-only cache cannot authorize offline startup', () async {
    final a = service(() async => status());
    await a.activate();
    a.dispose();
    const storage = FlutterSecureStorage();
    final values = await storage.readAll();
    for (final entry in values.entries) {
      if (!entry.key.startsWith('pos_subscription:')) continue;
      final json = Map<String, dynamic>.from(jsonDecode(entry.value) as Map);
      json.remove('boot');
      json.remove('elapsed_ms');
      await storage.write(key: entry.key, value: jsonEncode(json));
    }
    final b = service(() async => throw Exception('offline'));
    await b.activate();
    expect(b.canSell, false);
    b.dispose();
  });

  test(
    'concurrent refresh is coalesced and an old identity response cannot restore access',
    () async {
      var scope = 'a';
      var calls = 0;
      final response = Completer<Map<String, dynamic>>();
      final s = service(() {
        calls++;
        return response.future;
      }, scope: () => scope);
      addTearDown(s.dispose);
      final activate = s.activate();
      await Future<void>.delayed(Duration.zero);
      final refresh = s.refresh();
      expect(calls, 1);
      scope = 'b';
      response.complete(status());
      await activate;
      await refresh;
      expect(s.snapshot, isNull);
      expect(s.canSell, false);
    },
  );

  test(
    'renewal is server-confirmed, recovery fires once and errors do not sign out',
    () async {
      var data = status(level: 'billing_only', state: 'recovery');
      final s = service(() async => data);
      addTearDown(s.dispose);
      await s.activate();
      expect(s.canSell, false);
      data = status();
      await s.refresh();
      expect(s.canSell, true);
      expect(s.recovered.value, 1);
      await s.refresh();
      expect(s.recovered.value, 1);
      s.handleRequired({
        'access_level': 'blocked',
      }, requestScope: 'other-tenant');
      expect(s.canSell, true);
    },
  );

  test(
    'read-only guard rejects mixed safe/write mutation and permits reconciliation only',
    () async {
      final s = service(
        () async => status(level: 'read_only', state: 'read_only'),
      );
      addTearDown(s.dispose);
      await s.activate();
      expect(await s.guardMutation({'ClosePOSKasirShift'}), isNull);
      expect(
        await s.guardMutation({'ClosePOSKasirShift', 'OpenPOSKasirShift'}),
        isNotNull,
      );
      expect(await s.guardMutation({'CreatePOSManualTrade'}), isNotNull);
      expect(await s.guardOfflineWrite(), isNotNull);
    },
  );

  test(
    'link finds aliases/fragments and never forwards a denied mutation',
    () async {
      final request = Request(
        operation: Operation(
          document: gql(r'''
      mutation FakeReadName { alias: ProcessPOSPenjualan(input: {}) ...Shared }
      fragment Shared on Mutation { ClosePOSKasirShift(input: {}) }
    '''),
        ),
      );
      expect(mutationRootFields(request), {
        'ProcessPOSPenjualan',
        'ClosePOSKasirShift',
      });
      var forwarded = false;
      final link = posSubscriptionLink(
        () =>
            (_) async => const GraphQLError(
              message: 'renew',
              extensions: {'code': 'SUBSCRIPTION_REQUIRED'},
            ),
        () => 'scope',
      );
      final replies = await link.request(request, (_) {
        forwarded = true;
        return const Stream.empty();
      }).toList();
      expect(forwarded, false);
      expect(
        replies.single.errors!.single.extensions?['code'],
        'SUBSCRIPTION_REQUIRED',
      );
    },
  );

  testWidgets(
    'owner opens only the existing web billing URL and pending return alone does not activate',
    (tester) async {
      final s = service(() async => status(level: 'billing_only'));
      await s.activate();
      Uri? opened;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PosSubscriptionPage(
            service: s,
            openWeb: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('subscription_open_web')),
      );
      await tester.tap(find.byKey(const Key('subscription_open_web')));
      await tester.pumpAndSettle();
      expect(opened, pantooBillingWebUri);
      expect(opened!.query, isEmpty);
      expect(s.canSell, false);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );

  testWidgets(
    'staff sees owner instructions and cannot open billing controls',
    (tester) async {
      final s = service(() async => status(level: 'blocked', owner: false));
      await s.activate();
      await tester.pumpWidget(
        MaterialApp(home: PosSubscriptionPage(service: s)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('subscription_open_web')), findsNothing);
      expect(find.textContaining('Contact the owner'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
    },
  );

  testWidgets(
    'resume rechecks server and restores the mounted checkout draft without login',
    (tester) async {
      var data = status();
      var calls = 0;
      final s = service(() async {
        calls++;
        return data;
      });
      await s.activate();
      final nav = GlobalKey<NavigatorState>();
      final receipt = ValueNotifier(false);
      final controller = TextEditingController(text: 'draft tetap ada');
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          builder: (context, child) => PosSubscriptionBoundary(
            service: s,
            authenticated: true,
            navigatorKey: nav,
            receiptVisible: receipt,
            onLogout: () {},
            child: child!,
          ),
          home: Scaffold(body: TextField(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      data = status(level: 'billing_only', state: 'recovery');
      await s.refresh();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('subscription_open_web')), findsOneWidget);
      final before = calls;
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      data = status();
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(calls, greaterThan(before));
      expect(s.canSell, true);
      expect(controller.text, 'draft tetap ada');
      expect(find.byKey(const Key('subscription_open_web')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
      receipt.dispose();
      controller.dispose();
    },
  );
  testWidgets(
    'accepted receipt stays visible after expiry and recovery appears after Done',
    (tester) async {
      var data = status();
      final s = service(() async => data);
      await s.activate();
      final nav = GlobalKey<NavigatorState>();
      final observer = PosSubscriptionRouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: nav,
          navigatorObservers: [observer],
          builder: (context, child) => PosSubscriptionBoundary(
            service: s,
            authenticated: true,
            navigatorKey: nav,
            receiptVisible: observer.receiptVisible,
            onLogout: () {},
            child: child!,
          ),
          home: const Scaffold(body: Text('cashier draft')),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'pos_payment_success'),
            builder: (_) => const Scaffold(body: Text('accepted receipt')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      data = status(level: 'billing_only', state: 'recovery');
      await s.refresh();
      await tester.pumpAndSettle();
      expect(find.text('accepted receipt'), findsOneWidget);
      expect(find.byKey(const Key('subscription_open_web')), findsNothing);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('subscription_open_web')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      s.dispose();
      observer.receiptVisible.dispose();
    },
  );
}
