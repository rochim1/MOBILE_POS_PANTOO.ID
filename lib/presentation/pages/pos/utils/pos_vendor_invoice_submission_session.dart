import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Per-page retry state. No financial transaction or offline auto-posting.
class PosVendorInvoiceSubmissionSession {
  PosVendorInvoiceSubmissionSession(this.purchaseId);

  final String purchaseId;
  final Map<String, String> _requestIds = {};
  final Map<String, String> _uploadedUrls = {};
  int _sequence = 0;

  String? uploadedUrl(String fileHash) => _uploadedUrls[fileHash];
  void rememberUpload(String fileHash, String url) {
    if (url.isNotEmpty) _uploadedUrls[fileHash] = url;
  }

  String requestId({
    required String fileHash,
    required String invoiceNumber,
    required String invoiceDate,
    required String note,
  }) {
    final fingerprint = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'purchase_id': purchaseId,
              'evidence_hash': fileHash,
              'supplier_invoice_number': invoiceNumber.trim().toUpperCase(),
              'invoice_date': invoiceDate.trim(),
              'note': note.trim(),
            }),
          ),
        )
        .toString();
    return _requestIds.putIfAbsent(
      fingerprint,
      () =>
          'invoice-submission-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}-$purchaseId',
    );
  }

  static bool validInvoiceDate(String value) {
    if (value.isEmpty) return true;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final date = DateTime.tryParse(value);
    return date != null &&
        date.year == int.parse(value.substring(0, 4)) &&
        date.month == int.parse(value.substring(5, 7)) &&
        date.day == int.parse(value.substring(8, 10));
  }
}
