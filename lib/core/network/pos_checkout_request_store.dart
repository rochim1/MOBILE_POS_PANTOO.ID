import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Recovery fence for one checkout, not an offline authorization grant.
/// Credentials are deliberately excluded; replay uses the current operator.
class PosCheckoutRequestStore {
  PosCheckoutRequestStore(this.preferences, this.scope);
  final SharedPreferences preferences;
  final String scope;
  String get key => 'pos_checkout_pending_v1:$scope';

  Map<String, dynamic>? load() {
    final raw = preferences.getString(key);
    if (raw == null) return null;
    try {
      final value = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final input = value['input'] as Map;
      final receipt = value['receipt'] as Map;
      if (input['client_transaction_id'] is! String ||
          !RegExp(
            r'^[\w-]{16,100}$',
          ).hasMatch(input['client_transaction_id'] as String) ||
          input['toko_id'] is! String ||
          (input['toko_id'] as String).isEmpty ||
          input['items'] is! List ||
          (input['items'] as List).isEmpty ||
          input['metode_pembayaran'] is! String ||
          receipt['receipt_items'] is! List ||
          (receipt['receipt_items'] as List).isEmpty ||
          ![
            'subtotal',
            'manual_discount',
            'tax',
            'total',
            'cash_received',
          ].every((key) {
            final amount = receipt[key];
            return amount is num && amount.isFinite && amount >= 0;
          })) {
        throw const FormatException();
      }
      return value;
    } catch (_) {
      throw StateError(
        'Bukti pembayaran lokal tidak terbaca. Jangan bayar ulang; minta pemeriksaan administrator.',
      );
    }
  }

  static Map<String, dynamic> safeInput(Map<String, dynamic> input) =>
      {...input}
        ..remove('operator_session_token')
        ..remove('expired_sale_authorizer_pin');

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final key in keys) key: _canonical(value[key])};
    }
    if (value is List) return value.map(_canonical).toList();
    return value;
  }

  static String _agreement(
    Map<String, dynamic> input,
    Map<String, dynamic> receipt,
  ) {
    final comparable = safeInput(input)
      ..remove('client_transaction_id')
      ..remove('tanggal');
    return jsonEncode(_canonical({'input': comparable, 'receipt': receipt}));
  }

  Future<Map<String, dynamic>> begin(
    Map<String, dynamic> input,
    Map<String, dynamic> receipt,
  ) async {
    final prior = load();
    if (prior != null) {
      if (_agreement(
            Map<String, dynamic>.from(prior['input'] as Map),
            Map<String, dynamic>.from(prior['receipt'] as Map),
          ) !=
          _agreement(input, receipt)) {
        throw StateError(
          'Pembayaran sebelumnya belum terkonfirmasi. Pulihkan pembayaran tersebut sebelum mengubah keranjang atau membuat pembayaran baru.',
        );
      }
      return prior;
    }
    final value = {
      'input': {
        ...safeInput(input),
        'client_transaction_id': const Uuid().v4(),
      },
      'receipt': receipt,
    };
    if (!await preferences.setString(key, jsonEncode(value))) {
      throw StateError(
        'Bukti pembayaran gagal disimpan. Pembayaran belum dikirim; periksa penyimpanan perangkat.',
      );
    }
    final saved = load();
    if ((saved?['input'] as Map?)?['client_transaction_id'] !=
        (value['input'] as Map)['client_transaction_id']) {
      throw StateError(
        'Bukti pembayaran gagal diverifikasi. Pembayaran belum dikirim.',
      );
    }
    return saved!;
  }

  Future<void> acknowledge(String id) async {
    if ((load()?['input'] as Map?)?['client_transaction_id'] == id &&
        !await preferences.remove(key)) {
      throw StateError(
        'Pembayaran sudah diterima tetapi bukti lokal belum diperbarui. Pulihkan pembayaran; jangan bayar ulang.',
      );
    }
  }
}
