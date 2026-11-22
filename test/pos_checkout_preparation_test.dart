import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_trusted_clock.dart';

void main() {
  test(
    'checkout preparation moves stale verification ahead of the payment guard',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      var now = DateTime.utc(2026, 11, 22, 8);
      final start = now;
      var calls = 0;
      var level = 'full';
      var online = true;
      var scope = 'tenant-a|operator-a';
      final service = PosSubscriptionService(
        fetch: () async {
          calls++;
          if (!online) throw StateError('offline');
          return {
            'access_level': level,
            'effective_state': 'active',
            'is_owner': true,
            'server_now': now.toIso8601String(),
            'offline_valid_until': now
                .add(const Duration(hours: 24))
                .toIso8601String(),
          };
        },
        readScope: () => scope,
        clock: () => now,
        trustedClock: () async => PosTrustedClockStamp(
          'boot',
          1000 + now.difference(start).inMilliseconds,
        ),
        storage: const FlutterSecureStorage(),
      );
      addTearDown(service.dispose);
      await service.activate();
      await service.prepareCheckout();
      expect(calls, 1, reason: 'fresh status needs no extra request');
      now = now.add(const Duration(seconds: 90));
      await Future.wait([service.prepareCheckout(), service.prepareCheckout()]);
      expect(calls, 2, reason: 'overlapping preparation coalesces');
      expect(await service.guardMutation({'ProcessPOSPenjualan'}), isNull);
      expect(
        calls,
        2,
        reason: 'payment does not repeat the prepared verification',
      );
      now = now.add(const Duration(seconds: 90));
      level = 'read_only';
      await service.prepareCheckout();
      expect(await service.guardMutation({'ProcessPOSPenjualan'}), isNotNull);
      expect(await service.guardOfflineWrite(), isNotNull);
      scope = 'tenant-b|operator-b';
      online = false;
      await service.prepareCheckout();
      expect(
        service.canSell,
        false,
        reason: 'old identity cannot authorize new checkout',
      );
    },
  );
}
