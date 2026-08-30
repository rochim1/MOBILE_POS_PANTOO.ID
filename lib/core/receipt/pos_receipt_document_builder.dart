import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/pos_receipt_template.dart';

class PosReceiptDocumentData {
  final String invoice;
  final String dateLabel;
  final String cashierName;
  final String storeName;
  final String customerName;
  final String paymentMethod;
  final String salesChannel;
  final String customerSegment;
  final String promoCode;
  final double subtotal;
  final double discount;
  final double promoDiscount;
  final double tax;
  final double total;
  final double cashReceived;
  final double change;
  final String note;
  final List<Map<String, dynamic>> items;

  const PosReceiptDocumentData({
    required this.invoice,
    required this.dateLabel,
    this.cashierName = '',
    this.storeName = '',
    this.customerName = '',
    required this.paymentMethod,
    this.salesChannel = '',
    this.customerSegment = '',
    this.promoCode = '',
    required this.subtotal,
    this.discount = 0,
    this.promoDiscount = 0,
    this.tax = 0,
    required this.total,
    this.cashReceived = 0,
    this.change = 0,
    this.note = '',
    this.items = const [],
  });
}

class PosReceiptDocumentBuilder {
  static Future<Uint8List> build({
    required PosReceiptDocumentData data,
    required PosReceiptTemplate template,
    required Map<String, String> company,
  }) async {
    final document = pw.Document(
      title: 'Struk ${data.invoice}',
      author: 'Pantoo POS',
    );
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final paperWidth = template.paperWidth == 80 ? 80.0 : 58.0;
    final estimatedHeight = (150.0 + (data.items.length * 15)).clamp(
      165.0,
      1000.0,
    );
    final pageFormat = PdfPageFormat(
      paperWidth * PdfPageFormat.mm,
      estimatedHeight * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );
    final fontSize = (template.fontSize ?? 10).clamp(8, 13).toDouble();
    final headerTitle = _resolve(template.headerTitle, company);
    final headerLines = [
      template.headerSubtitle,
      template.headerLine3,
      template.headerLine4,
    ].map((line) => _resolve(line, company)).where((line) => line.isNotEmpty);
    final footerLines = [
      template.footerLine1,
      template.footerLine2,
      template.footerLine3,
    ].map((line) => _resolve(line, company)).where((line) => line.isNotEmpty);

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.DefaultTextStyle(
          style: pw.TextStyle(fontSize: fontSize),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                headerTitle.isNotEmpty ? headerTitle : 'PANTOO POS',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: fontSize + 3,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              ...headerLines.map(
                (line) => pw.Text(line, textAlign: pw.TextAlign.center),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              if (template.showInvoice != false) pw.Text('No: ${data.invoice}'),
              if (template.showTanggal != false && data.dateLabel.isNotEmpty)
                pw.Text('Tanggal: ${data.dateLabel}'),
              if (template.showKasir != false && data.cashierName.isNotEmpty)
                pw.Text('Kasir: ${data.cashierName}'),
              if (template.showToko == true && data.storeName.isNotEmpty)
                pw.Text('Toko: ${data.storeName}'),
              if (template.showPelanggan != false &&
                  data.customerName.isNotEmpty)
                pw.Text('Pelanggan: ${data.customerName}'),
              if (template.showChannel == true && data.salesChannel.isNotEmpty)
                pw.Text('Channel: ${data.salesChannel}'),
              if (template.showSegment == true &&
                  data.customerSegment.isNotEmpty)
                pw.Text('Segmen: ${data.customerSegment}'),
              pw.Text('Bayar: ${data.paymentMethod.toUpperCase()}'),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              ...data.items.expand((item) {
                final name =
                    item['nama_inventaris']?.toString() ??
                    item['name']?.toString() ??
                    item['nama']?.toString() ??
                    '-';
                final qty = item['qty']?.toString() ?? '0';
                final price = _number(
                  item['harga_jual'] ??
                      item['harga_satuan'] ??
                      item['unit_price'],
                );
                final lineSubtotal = _number(item['subtotal']);
                return [
                  pw.Text(
                    name,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('$qty x ${currency.format(price)}'),
                      pw.Text(currency.format(lineSubtotal)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                ];
              }),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _totalRow('Subtotal', currency.format(data.subtotal)),
              if (data.discount > 0)
                _totalRow('Diskon', '-${currency.format(data.discount)}'),
              if (template.showPromo != false && data.promoDiscount > 0)
                _totalRow('Promo', '-${currency.format(data.promoDiscount)}'),
              if (template.showPromo == true && data.promoCode.isNotEmpty)
                _totalRow('Kode promo', data.promoCode),
              if (data.tax > 0) _totalRow('Pajak', currency.format(data.tax)),
              _totalRow('TOTAL', currency.format(data.total), bold: true),
              if (data.cashReceived > 0)
                _totalRow('Diterima', currency.format(data.cashReceived)),
              if (data.change > 0)
                _totalRow('Kembalian', currency.format(data.change)),
              if (data.note.trim().isNotEmpty) ...[
                pw.SizedBox(height: 5),
                pw.Text('Catatan: ${data.note}'),
              ],
              pw.SizedBox(height: 8),
              ...footerLines.map(
                (line) => pw.Text(line, textAlign: pw.TextAlign.center),
              ),
              if (footerLines.isEmpty)
                pw.Text(
                  'Terima kasih atas kunjungan Anda',
                  textAlign: pw.TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0;

  static String _resolve(String? raw, Map<String, String> company) {
    var value = raw?.trim() ?? '';
    final replacements = <String, String>{
      'nama_instansi': company['nama_instansi'] ?? '',
      'nama_resmi': company['nama_resmi'] ?? '',
      'alamat': company['alamat'] ?? '',
      'telpon_nomor': company['telpon_number'] ?? '',
      'telpon_number': company['telpon_number'] ?? '',
      'email': company['email'] ?? '',
      'website': company['website'] ?? '',
      'provinsi': company['provinsi'] ?? '',
      'kabupaten': company['kabupaten'] ?? '',
      'npwp': company['NPWP'] ?? '',
    };
    replacements.forEach((key, replacement) {
      value = value.replaceAll('{{$key}}', replacement);
    });
    return value.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '').trim();
  }
}
