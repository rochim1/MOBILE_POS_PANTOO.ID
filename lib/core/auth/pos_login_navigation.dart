import 'dart:async';
import 'package:flutter/foundation.dart';

/// A slow lock roster must not strand an authenticated user on Login.
/// [lock] must engage the local lock before awaiting its roster request.
Future<void> finishPosLoginNavigation({
  required bool needsWorkspace,
  required Future<bool> Function() readLockEnabled,
  required Future<void> Function() lock,
  required VoidCallback resetLock,
  required bool Function() isCurrent,
  required VoidCallback navigate,
  Duration timeout = const Duration(seconds: 8),
}) async {
  var enabled = true;
  if (!needsWorkspace) {
    try {
      enabled = await readLockEnabled().timeout(timeout);
    } catch (_) {
      // Fail closed: connection failure must never bypass the cashier PIN.
      enabled = true;
    }
  }
  if (!isCurrent()) return;
  if (!needsWorkspace && enabled) {
    unawaited(
      lock().catchError((Object error) {
        debugPrint('POS lock roster unavailable; lock remains active.');
      }),
    );
  } else {
    resetLock();
  }
  navigate();
}
