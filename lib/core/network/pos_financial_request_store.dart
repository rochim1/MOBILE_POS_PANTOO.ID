import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Not an offline payment queue. A submitted online request is frozen until
/// the server acknowledges it, including after a crash or lost response.
class PosFinancialRequestStore {
  PosFinancialRequestStore(this.preferences, this.scope);
  final SharedPreferences preferences;
  final String scope;
  String _key(String invoice) => 'pos_financial_pending_v1:$scope:$invoice';
  List<String> get pendingInvoiceIds {
    final prefix = 'pos_financial_pending_v1:$scope:';
    return preferences
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .toList()
      ..sort();
  }

  Map<String, dynamic>? load(String invoice) {
    final raw = preferences.getString(_key(invoice));
    if (raw == null) return null;
    try {
      final value = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _validate(invoice, value);
      return value;
    } catch (_) {
      throw StateError(
        'Bukti penerimaan lokal tidak terbaca. Jangan membuat pembayaran baru; minta pemeriksaan administrator.',
      );
    }
  }

  static void _validate(String invoice, Map<String, dynamic> value) {
    final amount = value['amount'];
    if (invoice.trim().isEmpty ||
        value['request_id'] is! String ||
        (value['request_id'] as String).trim().isEmpty ||
        amount is! num ||
        !amount.isFinite ||
        amount <= 0 ||
        amount > 9007199254740991 ||
        amount != amount.round() ||
        (value['invoice_id'] != null && value['invoice_id'] != invoice)) {
      throw const FormatException();
    }
  }

  Future<Map<String, dynamic>> begin(
    String invoice,
    Map<String, dynamic> input,
  ) async {
    final existing = load(invoice);
    if (existing != null) return existing;
    final value = {...input, 'request_id': const Uuid().v4()};
    try {
      _validate(invoice, value);
    } catch (_) {
      throw StateError(
        'Data penerimaan belum valid. Periksa isian; pembayaran belum dikirim.',
      );
    }
    if (!await preferences.setString(_key(invoice), jsonEncode(value))) {
      throw StateError(
        'Bukti penerimaan tidak dapat disimpan. Pembayaran belum dikirim.',
      );
    }
    final persisted = load(invoice);
    if (persisted?['request_id'] != value['request_id']) {
      throw StateError(
        'Bukti penerimaan gagal diverifikasi. Pembayaran belum dikirim.',
      );
    }
    return persisted!;
  }

  Future<void> acknowledge(String invoice) async {
    if (!await preferences.remove(_key(invoice))) {
      throw StateError(
        'Pembayaran diterima server, tetapi bukti lokal belum dapat diperbarui. Muat ulang sebelum melanjutkan.',
      );
    }
  }
}
