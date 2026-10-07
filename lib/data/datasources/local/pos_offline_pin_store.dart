import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted, device-local cache for operators that have already verified a
/// POS PIN online.  The PIN itself is never persisted; only a salted digest is
/// kept so the lock screen can still be used when the API is unreachable.
class PosOfflinePinStore {
  PosOfflinePinStore({required String scope, DateTime Function()? clock})
    : _scope = scope,
      _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  static const credentialLifetime = Duration(days: 7);

  bool _isFresh(Map record) {
    final verified = DateTime.tryParse(
      record['last_verified_at']?.toString() ?? '',
    );
    final age = verified == null ? null : _clock().toUtc().difference(verified);
    return age != null && !age.isNegative && age <= credentialLifetime;
  }

  Future<void> invalidate(String userId) async {
    final values = await _read();
    values.remove(userId);
    await _write(values);
  }

  static const _storageKeyPrefix = 'pos_offline_pin_credentials_v1_';
  static const _maxAttempts = 5;
  static const _lockoutMinutes = 15;
  final String _scope;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String get _key => '$_storageKeyPrefix${_safeScope(_scope)}';

  static String _safeScope(String value) =>
      value.trim().isEmpty ? 'default' : base64Url.encode(utf8.encode(value));

  Future<Map<String, dynamic>> _read() async {
    try {
      final raw = await _storage.read(key: _key);
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is! Map) return <String, dynamic>{};
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Future<void> _write(Map<String, dynamic> values) async {
    await _storage.write(key: _key, value: jsonEncode(values));
  }

  Future<void> cacheEmployees(
    Iterable<Map<String, dynamic>> employees, {
    bool completeRoster = false,
  }) async {
    final values = await _read();
    if (completeRoster) {
      final ids = employees
          .map((row) => (row['_id'] ?? row['id']).toString())
          .toSet();
      values.removeWhere((id, _) => !ids.contains(id));
    }
    for (final row in employees) {
      final id = row['_id']?.toString() ?? row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (row['has_pin'] == false) {
        values.remove(id);
        continue;
      }
      final previous = Map<String, dynamic>.from(
        values[id] as Map? ?? const {},
      );
      values[id] = <String, dynamic>{
        ...previous,
        'user_id': id,
        'name': row['name']?.toString() ?? previous['name'] ?? '',
        'username': row['username']?.toString() ?? previous['username'] ?? '',
        'photo_url':
            row['photo_url']?.toString() ?? previous['photo_url'] ?? '',
        'has_pin': row['has_pin'] == true || previous['pin_hash'] != null,
        'locked_until': row['locked_until'] ?? previous['locked_until'],
      };
    }
    try {
      await _write(values);
    } catch (_) {
      // Secure storage can be unavailable on some desktop/web targets. The
      // online authentication result must still be allowed to succeed.
    }
  }

  Future<void> cacheVerifiedPin({
    required String userId,
    required String pin,
    required Map<String, dynamic> response,
  }) async {
    final values = await _read();
    final previous = Map<String, dynamic>.from(
      values[userId] as Map? ?? const {},
    );
    final salt = _randomSalt();
    values[userId] = <String, dynamic>{
      ...previous,
      'user_id': userId,
      'name': response['name']?.toString() ?? previous['name'] ?? '',
      'username':
          response['username']?.toString() ?? previous['username'] ?? '',
      'photo_url':
          response['photo_url']?.toString() ?? previous['photo_url'] ?? '',
      'has_pin': true,
      'salt': salt,
      'pin_hash': _hash(salt, pin),
      'failed_attempts': 0,
      'locked_until': null,
      'last_verified_at': _clock().toUtc().toIso8601String(),
    };
    try {
      await _write(values);
    } catch (_) {
      // See cacheEmployees: local caching is best-effort.
    }
  }

  Future<List<Map<String, dynamic>>> employees({String search = ''}) async {
    final needle = search.trim().toLowerCase();
    final values = await _read();
    return values.values
        .whereType<Map>()
        .where(_isFresh)
        .map((value) {
          final row = Map<String, dynamic>.from(value);
          return <String, dynamic>{
            '_id': row['user_id']?.toString() ?? '',
            'name': row['name']?.toString() ?? '',
            'username': row['username']?.toString() ?? '',
            'photo_url': row['photo_url']?.toString() ?? '',
            'has_pin': row['pin_hash']?.toString().isNotEmpty == true,
            'failed_attempts': row['failed_attempts'] ?? 0,
            'locked_until': row['locked_until'],
            'offline_cached': true,
          };
        })
        .where((row) {
          if (row['has_pin'] != true) {
            return false;
          }
          if (needle.isEmpty) {
            return true;
          }
          return '${row['name']} ${row['username']}'.toLowerCase().contains(
            needle,
          );
        })
        .toList();
  }

  Future<Map<String, dynamic>?> verify(String userId, String pin) async {
    final values = await _read();
    final raw = values[userId];
    if (raw is! Map ||
        !_isFresh(raw) ||
        raw['pin_hash']?.toString().isEmpty != false) {
      return null;
    }
    final record = Map<String, dynamic>.from(raw);
    final now = _clock().toUtc();
    final lockedUntil = DateTime.tryParse(
      record['locked_until']?.toString() ?? '',
    );
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return {
        'success': false,
        'message':
            'PIN terkunci sementara. Coba lagi setelah ${lockedUntil.toLocal()}.',
        'locked_until': lockedUntil.toIso8601String(),
      };
    }
    if (lockedUntil != null) {
      record['locked_until'] = null;
      record['failed_attempts'] = 0;
    }
    final valid =
        record['pin_hash'] == _hash(record['salt']?.toString() ?? '', pin);
    if (!valid) {
      final attempts = (record['failed_attempts'] as num? ?? 0).toInt() + 1;
      record['failed_attempts'] = attempts;
      DateTime? newLock;
      if (attempts >= _maxAttempts) {
        newLock = now.add(const Duration(minutes: _lockoutMinutes));
        record['locked_until'] = newLock.toIso8601String();
        record['failed_attempts'] = 0;
      }
      values[userId] = record;
      try {
        await _write(values);
      } catch (_) {
        // Keep the current attempt result even if local storage is full.
      }
      return {
        'success': false,
        'message': newLock == null
            ? 'PIN salah'
            : 'Terlalu banyak percobaan. PIN dikunci 15 menit.',
        'locked_until': newLock?.toIso8601String(),
      };
    }
    record['failed_attempts'] = 0;
    record['locked_until'] = null;
    values[userId] = record;
    try {
      await _write(values);
    } catch (_) {
      return {
        'success': false,
        'message':
            'Penyimpanan PIN tidak tersedia. Verifikasi online diperlukan.',
      };
    }
    return {
      'success': true,
      'user_id': userId,
      'name': record['name'],
      'username': record['username'],
      'operator_token': 'offline_operator:$userId',
    };
  }

  String _randomSalt() => base64Url.encode(
    List<int>.generate(24, (_) => Random.secure().nextInt(256)),
  );

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();
}
