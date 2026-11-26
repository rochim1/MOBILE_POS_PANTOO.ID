import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// One unresolved intent per document (or new-transfer form) and identity.
/// Never expires on age/navigation. It is evidence, not an offline permission.
class PosTransferIntentStore {
  PosTransferIntentStore(this.preferences, this.scope);
  final SharedPreferences preferences;
  final String scope;
  String key(String? id) =>
      'pos_transfer_pending_v1:${jsonEncode([scope, id])}';

  Map<String, dynamic>? load(String? id) {
    final raw = preferences.getString(key(id));
    if (raw == null) return null;
    try {
      final row = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (row['root'] is! String ||
          row['document'] is! String ||
          row['variables'] is! Map ||
          row['document_id'] != id ||
          row['request_id'] is! String ||
          (row['request_id'] as String).isEmpty) {
        throw const FormatException();
      }
      return row;
    } catch (_) {
      throw StateError(
        'Bukti transfer tidak terbaca. Jangan ulangi transfer baru; hubungi pengelola.',
      );
    }
  }

  static String signature(String root, Map variables) {
    dynamic canonical(dynamic value) {
      if (value is Map) {
        final keys =
            value.keys
                .map((k) => '$k')
                .where(
                  (k) => ![
                    'request_id',
                    'operator_session_token',
                    'authorizer_pin',
                  ].contains(k),
                )
                .toList()
              ..sort();
        return {for (final k in keys) k: canonical(value[k])};
      }
      if (value is List) return value.map(canonical).toList();
      return value;
    }

    return jsonEncode([root, canonical(variables)]);
  }

  Future<Map<String, dynamic>> prepare(
    String document,
    Map<String, dynamic> variables,
    String root,
  ) async {
    if (scope.isEmpty) {
      throw StateError('Sesi belum siap. Masuk kembali.');
    }
    final id = variables['id']?.toString();
    final prior = load(id);
    if (prior != null) {
      if (signature(root, variables) !=
          signature(prior['root'] as String, prior['variables'] as Map)) {
        throw StateError(
          'Selesaikan pemeriksaan transfer sebelumnya sebelum mengubah atau mengirim data baru.',
        );
      }
      return prior;
    }
    // Only transfer payloads are stored. Authentication stays in the current link.
    final clean =
        Map<String, dynamic>.from(jsonDecode(jsonEncode(variables)) as Map)
          ..remove('operator_session_token')
          ..remove('authorizer_pin');
    final input = clean['input'];
    if (input is Map) {
      input.remove('operator_session_token');
      input.remove('authorizer_pin');
    }
    final supplied = root == 'ReportInventoryTransferDiscrepancy'
        ? (clean['input'] as Map)['request_id']
        : clean['request_id'];
    final requestId = supplied is String && supplied.isNotEmpty
        ? supplied
        : 'mobile-transfer-${const Uuid().v4()}';
    if (root == 'ReportInventoryTransferDiscrepancy') {
      (clean['input'] as Map)['request_id'] = requestId;
    } else if (root != 'DecideInventoryTransferDiscrepancy' &&
        root != 'UpdateInventoryTransfer') {
      clean['request_id'] = requestId;
    }
    final row = {
      'root': root,
      'document': document,
      'variables': clean,
      'document_id': id,
      'request_id': requestId,
      'saved_at': DateTime.now().toUtc().toIso8601String(),
    };
    final encoded = jsonEncode(row);
    if (!await preferences.setString(key(id), encoded) ||
        preferences.getString(key(id)) != encoded) {
      throw StateError(
        'Bukti transfer gagal disimpan. Permintaan belum dikirim.',
      );
    }
    return row;
  }

  Future<void> acknowledge(String? id, String requestId) async {
    if (load(id)?['request_id'] != requestId) {
      throw StateError('Identitas bukti transfer berubah. Muat ulang.');
    }
    if (!await preferences.remove(key(id)) ||
        preferences.containsKey(key(id))) {
      throw StateError(
        'Transfer sudah diproses tetapi bukti lokal belum diperbarui. Periksa transfer yang sama.',
      );
    }
  }
}
