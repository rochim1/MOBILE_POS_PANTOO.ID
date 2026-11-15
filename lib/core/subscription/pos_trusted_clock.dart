import 'package:flutter/services.dart';

/// Android elapsed realtime includes deep sleep and cannot be set in Date/Time.
/// A different boot invalidates a persisted offline grant.
class PosTrustedClockStamp {
  const PosTrustedClockStamp(this.boot, this.elapsedMs);
  final String boot;
  final int elapsedMs;
  static const _channel = MethodChannel('pantoo.pos/subscription_clock');

  static Future<PosTrustedClockStamp?> read() async {
    try {
      final value = await _channel.invokeMapMethod<String, dynamic>('read');
      final boot = value?['boot']?.toString();
      final elapsed = value?['elapsed_ms'];
      if (boot == null || elapsed is! int || elapsed < 0) return null;
      return PosTrustedClockStamp(boot, elapsed);
    } catch (_) {
      return null; // Unsupported platform: require online after process restart.
    }
  }
}
