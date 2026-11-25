import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

/// Google proves identity; Pantoo's Login mutation still authorizes the session.
class GoogleIdentityService {
  static Future<void>? _initialization;
  static String? _clientId;
  static bool _initialized = false;

  static Future<void> initialize(AuthRepository api) async {
    final clientId = await api.googleClientId().timeout(
      const Duration(seconds: 15),
    );
    if (_clientId != null && _clientId != clientId) {
      throw StateError(
        'Server Google berubah. Tutup dan buka kembali aplikasi.',
      );
    }
    // The native SDK must be initialized once, not awaited again whenever a
    // login/register widget is recreated after an account-picker round trip.
    if (_initialized) return;
    _clientId = clientId;
    final initialization = _initialization ??= GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? clientId : null,
      serverClientId: kIsWeb ? null : clientId,
    );
    try {
      await initialization;
      _initialized = true;
    } catch (_) {
      _initialized = false;
      _initialization = null;
      _clientId = null;
      rethrow;
    }
  }
}
