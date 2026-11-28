import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/graphql/pos_travel_queries.dart';

/// Evidence survives navigation/restarts. It never grants offline payment access.
class PosTravelIntentStore {
  PosTravelIntentStore(this.preferences, this.scope);
  final SharedPreferences preferences;
  final String scope;
  String get key => 'pos_travel_pending_v1:${jsonEncode(scope)}';

  Map<String, dynamic>? load() {
    final raw = preferences.getString(key);
    if (raw == null) return null;
    try {
      final row = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final input = row['input'];
      if (row['scope'] != scope ||
          !PosTravelQueries.writes.containsKey(row['operation']) ||
          input is! Map ||
          !RegExp(r'^[a-fA-F0-9]{24}$').hasMatch('${input['toko_id']}') ||
          input['request_id'] is! String ||
          (input['request_id'] as String).trim().isEmpty ||
          (input['request_id'] as String).length > 100 ||
          row['attempts'] is! int ||
          (row['attempts'] as int) < 0) {
        throw const FormatException();
      }
      return row;
    } on FormatException {
      throw StateError(
        'Bukti Travel tidak terbaca. Jangan membuat pembayaran pengganti; hubungi pengelola.',
      );
    } on TypeError {
      throw StateError(
        'Bukti Travel tidak terbaca. Jangan membuat pembayaran pengganti; hubungi pengelola.',
      );
    }
  }

  Future<void> save(Map<String, dynamic> row) async {
    final value = jsonEncode(row);
    if (!await preferences.setString(key, value) ||
        preferences.getString(key) != value) {
      throw StateError(
        'Bukti Travel gagal disimpan; permintaan belum dikirim.',
      );
    }
  }

  Future<Map<String, dynamic>> prepare(
    String operation,
    Map<String, dynamic> input,
  ) async {
    if (scope.isEmpty || !PosTravelQueries.writes.containsKey(operation)) {
      throw StateError('Sesi Travel belum siap.');
    }
    if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch('${input['toko_id']}')) {
      throw StateError('Pilih toko Travel yang valid sebelum melanjutkan.');
    }
    if (load() != null) {
      throw StateError(
        'Pulihkan permintaan Travel sebelumnya sebelum mengirim yang baru.',
      );
    }
    final clean =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(input)) as Map)
          ..remove('operator_session_token')
          ..remove('authorizer_pin');
    final row = {
      'scope': scope,
      'operation': operation,
      'input': {...clean, 'request_id': 'travel-${const Uuid().v4()}'},
      'attempts': 0,
    };
    await save(row);
    // Validate before any network side effect.
    return load()!;
  }

  Future<void> acknowledge(String requestId) async {
    if (load()?['input']['request_id'] != requestId) {
      throw StateError('Identitas permintaan Travel berubah.');
    }
    if (!await preferences.remove(key) || preferences.containsKey(key)) {
      throw StateError(
        'Hasil Travel sudah tercatat tetapi bukti lokal belum diperbarui. Pulihkan permintaan yang sama.',
      );
    }
  }
}
