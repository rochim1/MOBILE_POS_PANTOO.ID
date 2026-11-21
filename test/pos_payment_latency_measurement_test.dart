import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_trusted_clock.dart';

void main() {
  test('measure checkout subscription wait with controlled response latency', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final samples = <double>[];
    var calls = 0;
    for (var i = 0; i < 12; i++) {
      var now = DateTime.utc(2026, 11, 22, 8);
      final start = now;
      final service = PosSubscriptionService(
        fetch: () async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 120));
          return {
            'access_level': 'full', 'is_owner': true, 'effective_state': 'active',
            'server_now': now.toIso8601String(),
            'offline_valid_until': now.add(const Duration(hours: 24)).toIso8601String(),
          };
        },
        readScope: () => 'local-benchmark-$i',
        storage: const FlutterSecureStorage(), clock: () => now,
        trustedClock: () async => PosTrustedClockStamp('boot', 1000 + now.difference(start).inMilliseconds),
      );
      await service.activate();
      now = now.add(const Duration(seconds: 90));
      final phase = Platform.environment['POS_PAYMENT_MEASURE_PHASE'] ?? 'before';
      if (phase == 'after') await service.prepareCheckout();
      final timer = Stopwatch()..start();
      expect(await service.guardMutation({'ProcessPOSPenjualan'}), isNull);
      samples.add(timer.elapsedMicroseconds / 1000);
      service.dispose();
    }
    samples.sort();
    final phase = Platform.environment['POS_PAYMENT_MEASURE_PHASE'] ?? 'before';
    print('PAYMENT_MOBILE_MEASUREMENT ${jsonEncode({
      'phase': phase, 'samples': samples.length, 'controlledFetchDelayMs': 120,
      'p50Ms': samples[5], 'p95Ms': samples[11], 'p99Ms': samples[11],
      'subscriptionFetches': calls,
      'scope': 'button-time subscription guard only, not server payment or GUI',
    })}');
  });
}
