import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Online intent recovery, not an offline return/refund queue. One unresolved
/// draft per endpoint/tenant/terminal/PIN operator prevents silent replacement.
class PosReturnDraftRequestStore {
  PosReturnDraftRequestStore(this.preferences, this.scope);
  final SharedPreferences preferences;
  final String scope;
  String get _key => 'pos_return_draft_pending_v1:$scope';

  Map<String, dynamic>? load() {
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final value = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final requestId = value['client_request_id'];
      if (requestId is! String ||
          !RegExp(r'^[\w-]{16,150}$').hasMatch(requestId) ||
          value['sumber'] != 'pos' ||
          value['sumber_id'] is! String ||
          (value['sumber_id'] as String).isEmpty ||
          value['items'] is! List ||
          (value['items'] as List).isEmpty) {
        throw const FormatException();
      }
      return value;
    } catch (_) {
      throw StateError(
        'Bukti draft retur lokal tidak terbaca. Jangan buat pengganti; minta pemeriksaan administrator.',
      );
    }
  }

  Future<Map<String, dynamic>> begin(Map<String, dynamic>? input) async {
    final prior = load();
    if (prior != null) return prior;
    if (input == null) {
      throw StateError('Tidak ada draft retur untuk dipulihkan.');
    }
    final value = {...input, 'client_request_id': const Uuid().v4()};
    if (!await preferences.setString(_key, jsonEncode(value))) {
      throw StateError(
        'Bukti draft tidak dapat disimpan. Retur belum dikirim.',
      );
    }
    final persisted = load();
    if (persisted?['client_request_id'] != value['client_request_id']) {
      throw StateError('Bukti draft gagal disimpan. Retur belum dikirim.');
    }
    return persisted!;
  }

  Future<void> acknowledge(String requestId) async {
    if (load()?['client_request_id'] == requestId &&
        !await preferences.remove(_key)) {
      throw StateError(
        'Retur diterima tetapi bukti lokal belum diperbarui. Pulihkan sebelum membuat retur lain.',
      );
    }
  }
}
