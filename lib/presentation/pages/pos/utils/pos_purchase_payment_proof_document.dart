import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PosPurchasePaymentProofDocument {
  const PosPurchasePaymentProofDocument._();

  static bool canDistribute(Map<String, dynamic> payment) =>
      (payment['status']?.toString() ?? 'active') == 'active';

  static Future<Uint8List> build({
    required Map<String, dynamic> payable,
    required Map<String, dynamic> payment,
    required Map<String, String> company,
  }) async {
    final document = pw.Document();
    final status = payment['status']?.toString() ?? 'active';
    final buyer = _firstFilled([
      company['nama_resmi'],
      company['nama_instansi'],
    ], 'Pembeli');
    final recorder = payment['recorded_by'];
    final recorderName = recorder is Map
        ? _firstFilled([
            recorder['name']?.toString(),
            recorder['username']?.toString(),
          ], '-')
        : '-';

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (status != 'active')
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.red100,
                child: pw.Text(
                  status == 'cancelled'
                      ? 'DIBATALKAN - BUKAN BUKTI PEMBAYARAN AKTIF'
                      : 'PEMBATALAN DIPROSES - BUKAN BUKTI PEMBAYARAN AKTIF',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.red800,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            pw.SizedBox(height: 12),
            pw.Text(
              'BUKTI PENCATATAN PEMBAYARAN',
              style: pw.TextStyle(
                fontSize: 17,
                color: PdfColors.teal800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Divider(color: PdfColors.teal800),
          ],
        ),
        build: (_) => [
          pw.Text(
            'Dokumen ini dibuat oleh pihak pembeli dan bukan tanda terima yang diterbitkan supplier.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 22),
          _line('Pembeli', buyer),
          _line('Supplier', _text(payable['supplier_name'])),
          _line('Nomor PO', _text(payable['no_po'])),
          _line('ID pembayaran', _text(payment['_id'])),
          _line('Tanggal pembayaran', _date(payment['payment_date'])),
          _line('Dicatat pada', _dateTime(payment['recorded_at'])),
          _line('Dicatat oleh', recorderName),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          _line('Metode', _paymentMethod(payment['payment_method'])),
          if (_text(payment['bank_account_name']).isNotEmpty)
            _line(
              'Rekening',
              maskBankAccount(_text(payment['bank_account_name'])),
            ),
          if (_text(payment['reference_number']).isNotEmpty)
            _line('Referensi transfer', _text(payment['reference_number'])),
          if (payment['no_termin'] != null)
            _line('Termin', _text(payment['no_termin'])),
          pw.SizedBox(height: 10),
          _line('Pembayaran ini', _money(payment['amount']), bold: true),
          pw.SizedBox(height: 16),
          pw.Divider(color: PdfColors.grey300),
          _line('Total tagihan PO', _money(payable['total_amount'])),
          _line(
            'Total pembayaran aktif saat dokumen dibuat',
            _money(payable['paid_amount']),
          ),
          _line(
            'Sisa tagihan saat dokumen dibuat',
            _money(payable['outstanding_amount']),
          ),
          if (_text(payment['notes']).isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _line('Catatan', _text(payment['notes'])),
          ],
          if (status != 'active') ...[
            pw.SizedBox(height: 16),
            _line(
              'Status',
              status == 'cancelled' ? 'DIBATALKAN' : 'PEMBATALAN DIPROSES',
              bold: true,
            ),
            if (_text(payment['cancellation_reason']).isNotEmpty)
              _line('Alasan', _text(payment['cancellation_reason'])),
            if (payment['cancelled_at'] != null)
              _line('Dibatalkan pada', _dateTime(payment['cancelled_at'])),
          ],
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ),
    );
    return document.save();
  }

  static pw.Widget _line(String label, String value, {bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 190,
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? '-' : value,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static String _firstFilled(Iterable<String?> values, String fallback) =>
      values
          .map((value) => value?.trim() ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => fallback);
  static double _amount(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  static String _money(Object? value) =>
      'Rp ${NumberFormat.decimalPattern('id_ID').format(_amount(value))}';
  static String _date(Object? value) {
    final raw = _text(value);
    final parsed = DateTime.tryParse(raw);
    return parsed == null
        ? (raw.isEmpty ? '-' : raw)
        : DateFormat('dd/MM/yyyy').format(parsed);
  }

  static String _dateTime(Object? value) {
    final raw = _text(value);
    final parsed = DateTime.tryParse(raw);
    return parsed == null
        ? (raw.isEmpty ? '-' : raw)
        : DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  static String _paymentMethod(Object? value) => switch (_text(value)) {
    'cash' => 'Tunai',
    'transfer' => 'Transfer',
    'giro' => 'Giro',
    final other => other,
  };
  static String maskBankAccount(String value) {
    final digitCount = RegExp(r'\d').allMatches(value).length;
    if (digitCount < 5) return value;
    var seen = 0;
    final masked = StringBuffer();
    for (final character in value.split('')) {
      if (RegExp(r'\d').hasMatch(character)) {
        seen++;
        masked.write(seen <= digitCount - 4 ? '*' : character);
      } else {
        masked.write(character);
      }
    }
    return masked.toString();
  }
}
