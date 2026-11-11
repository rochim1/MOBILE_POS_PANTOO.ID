import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/models/pos_receipt_template.dart';

class PosReceiptDocumentData {
  final String invoice;
  final String dateLabel;
  final String cashierName;
  final String storeName;
  final String shiftReference;
  final String transactionReference;
  final String customerName;
  final String paymentMethod;
  final String salesChannel;
  final String customerSegment;
  final String orderType;
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
    this.shiftReference = '',
    this.transactionReference = '',
    this.customerName = '',
    required this.paymentMethod,
    this.salesChannel = '',
    this.customerSegment = '',
    this.orderType = '',
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
  static final Map<String, Future<pw.MemoryImage?>> _logoCache = {};

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
    final pageFormat = pageFormatFor(template, data.items.length);
    final fontSize = (template.fontSize ?? 12).clamp(8, 18).toDouble();
    final headerTitle = _resolve(
      template.headerTitle,
      company,
      cashierName: data.cashierName,
    );
    final headerLines =
        [template.headerSubtitle, template.headerLine3, template.headerLine4]
            .map(
              (line) => _resolve(line, company, cashierName: data.cashierName),
            )
            .where((line) => line.isNotEmpty);
    final footerLines =
        [template.footerLine1, template.footerLine2, template.footerLine3]
            .map(
              (line) => _resolve(line, company, cashierName: data.cashierName),
            )
            .where((line) => line.isNotEmpty);
    final logo = await _loadLogo(template, company);

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (_) => pw.DefaultTextStyle(
          style: pw.TextStyle(fontSize: fontSize),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logo != null) ...[
                pw.Center(
                  child: pw.Image(
                    logo,
                    width: 34 * PdfPageFormat.mm,
                    height: 16 * PdfPageFormat.mm,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 3),
              ],
              if (headerTitle.isNotEmpty)
                pw.Text(
                  headerTitle,
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
              if (template.showInvoice != false) pw.Text(posCurrentLocale().posded34ba7cec1((data.invoice).toString())),
              if (template.showTanggal != false && data.dateLabel.isNotEmpty)
                pw.Text(posCurrentLocale().pos54ec6781af4f((data.dateLabel).toString())),
              if (template.showKasir != false && data.cashierName.isNotEmpty)
                pw.Text(posCurrentLocale().pos354df62f6aa3((data.cashierName).toString())),
              if (template.showToko != false && data.storeName.isNotEmpty)
                pw.Text(posCurrentLocale().pos25b5fa1d18b0((data.storeName).toString())),
              if (data.shiftReference.isNotEmpty)
                pw.Text(posCurrentLocale().pos98c99bd51ac2((data.shiftReference).toString())),
              if (data.transactionReference.isNotEmpty)
                pw.Text(posCurrentLocale().pos96b044b6e7c2((data.transactionReference).toString())),
              if (template.showPelanggan != false &&
                  data.customerName.isNotEmpty)
                pw.Text(posCurrentLocale().pose8576d8afa6c((data.customerName).toString())),
              if (template.showChannel == true && data.salesChannel.isNotEmpty)
                pw.Text(posCurrentLocale().pos49724ddf398a((data.salesChannel).toString())),
              if (template.showSegment == true &&
                  data.customerSegment.isNotEmpty)
                pw.Text(posCurrentLocale().posf35e7016437f((data.customerSegment).toString())),
              if (template.showOrderType != false && data.orderType.isNotEmpty)
                pw.Text(posCurrentLocale().pos351aef710752((_orderTypeLabel(data.orderType)).toString())),
              pw.Text(posCurrentLocale().posc5a29ff60a03((data.paymentMethod.toUpperCase()).toString())),
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
                pw.Text(posCurrentLocale().posb0bf84cc5839((data.note).toString())),
              ],
              pw.SizedBox(height: 8),
              ...footerLines.map(
                (line) => pw.Text(line, textAlign: pw.TextAlign.center),
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
          pw.Text((label).trCurrent(), style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  /// Text equivalent of [build] for ESC/POS Bluetooth printers. It follows
  /// the exact same template switches, ordering, placeholder resolution and
  /// footer rules as the PDF renderer, while avoiding PDF/raster conversion.
  static String buildThermalText({
    required PosReceiptDocumentData data,
    required PosReceiptTemplate template,
    required Map<String, String> company,
  }) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final lines = <String>[];
    void add(String value) {
      if (value.trim().isNotEmpty) lines.add(value.trim());
    }

    final title = _resolve(
      template.headerTitle,
      company,
      cashierName: data.cashierName,
    );
    add(title);
    for (final value in [
      template.headerSubtitle,
      template.headerLine3,
      template.headerLine4,
    ]) {
      add(_resolve(value, company, cashierName: data.cashierName));
    }
    lines.add('------------------------------');
    if (template.showInvoice != false) add(posCurrentLocale().posded34ba7cec1((data.invoice).toString()));
    if (template.showTanggal != false && data.dateLabel.isNotEmpty) {
      add(posCurrentLocale().pos54ec6781af4f((data.dateLabel).toString()));
    }
    if (template.showKasir != false && data.cashierName.isNotEmpty) {
      add(posCurrentLocale().pos354df62f6aa3((data.cashierName).toString()));
    }
    if (template.showToko != false && data.storeName.isNotEmpty) {
      add(posCurrentLocale().pos25b5fa1d18b0((data.storeName).toString()));
    }
    if (data.shiftReference.isNotEmpty) {
      add(posCurrentLocale().pos98c99bd51ac2((data.shiftReference).toString()));
    }
    if (data.transactionReference.isNotEmpty) {
      add(posCurrentLocale().pos96b044b6e7c2((data.transactionReference).toString()));
    }
    if (template.showPelanggan != false && data.customerName.isNotEmpty) {
      add(posCurrentLocale().pose8576d8afa6c((data.customerName).toString()));
    }
    if (template.showChannel == true && data.salesChannel.isNotEmpty) {
      add(posCurrentLocale().pos49724ddf398a((data.salesChannel).toString()));
    }
    if (template.showSegment == true && data.customerSegment.isNotEmpty) {
      add(posCurrentLocale().posf35e7016437f((data.customerSegment).toString()));
    }
    if (template.showOrderType != false && data.orderType.isNotEmpty) {
      add(posCurrentLocale().pos351aef710752((_orderTypeLabel(data.orderType)).toString()));
    }
    add(posCurrentLocale().posc5a29ff60a03((data.paymentMethod.toUpperCase()).toString()));
    lines.add('------------------------------');
    for (final item in data.items) {
      final name =
          item['nama_inventaris']?.toString() ??
          item['name']?.toString() ??
          item['nama']?.toString() ??
          '-';
      final qty = item['qty']?.toString() ?? '0';
      final price = _number(
        item['harga_jual'] ?? item['harga_satuan'] ?? item['unit_price'],
      );
      final lineSubtotal = _number(item['subtotal']);
      add(name);
      add(
        '$qty x ${currency.format(price)}    ${currency.format(lineSubtotal)}',
      );
    }
    lines.add('------------------------------');
    add(posCurrentLocale().poseb08b632f2d5((currency.format(data.subtotal)).toString()));
    if (data.discount > 0) add(posCurrentLocale().posd20c0326fffe((currency.format(data.discount)).toString()));
    if (template.showPromo != false && data.promoDiscount > 0) {
      add(posCurrentLocale().pos5f0e590eb67a((currency.format(data.promoDiscount)).toString()));
    }
    if (template.showPromo == true && data.promoCode.isNotEmpty) {
      add(posCurrentLocale().pos5d8a179eb068((data.promoCode).toString()));
    }
    if (data.tax > 0) add(posCurrentLocale().pos62e104d5b8c0((currency.format(data.tax)).toString()));
    add(posCurrentLocale().posf584192c76e1((currency.format(data.total)).toString()));
    if (data.cashReceived > 0) {
      add(posCurrentLocale().pos6cbe2ba54793((currency.format(data.cashReceived)).toString()));
    }
    if (data.change > 0) add(posCurrentLocale().pos9346d428aef7((currency.format(data.change)).toString()));
    if (data.note.trim().isNotEmpty) add(posCurrentLocale().posb0bf84cc5839((data.note).toString()));
    // Internal marker consumed by the ESC/POS writer; it is never sent to
    // the printer and keeps the footer centered like the visual template.
    lines.add('[[PANTOO_CENTER_FOOTER]]');
    for (final footer in [
      template.footerLine1,
      template.footerLine2,
      template.footerLine3,
    ]) {
      add(_resolve(footer, company, cashierName: data.cashierName));
    }
    return lines.join('\n');
  }

  static PdfPageFormat pageFormatFor(
    PosReceiptTemplate template,
    int itemCount,
  ) {
    final paperWidth = template.paperWidth == 80 ? 80.0 : 58.0;
    // Thermal rolls are continuous. Keep enough room for unusually large carts
    // so a valid sale does not fail merely because it contains many lines.
    final estimatedHeight = (150.0 + (itemCount * 15)).clamp(165.0, 4500.0);
    return PdfPageFormat(
      paperWidth * PdfPageFormat.mm,
      estimatedHeight * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );
  }

  static double _number(dynamic value) =>
      double.tryParse(value?.toString() ?? '0') ?? 0;

  static String _resolve(
    String? raw,
    Map<String, String> company, {
    String cashierName = '',
  }) {
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
      'nama_kasir': cashierName,
      'kasir': cashierName,
      'cashier_name': cashierName,
    };
    replacements.forEach((key, replacement) {
      value = value.replaceAll('{{$key}}', replacement);
    });
    return value.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '').trim();
  }

  static Future<pw.MemoryImage?> _loadLogo(
    PosReceiptTemplate template,
    Map<String, String> company,
  ) async {
    if (template.showLogo == false) return null;
    final url = company['logo']?.trim() ?? '';
    if (url.isEmpty) return null;
    final cached = _logoCache[url];
    if (cached != null) return cached;

    final request = _downloadLogo(url);
    _logoCache[url] = request;
    final logo = await request;
    if (logo == null) _logoCache.remove(url);
    return logo;
  }

  static Future<pw.MemoryImage?> _downloadLogo(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          response.bodyBytes.isEmpty ||
          response.bodyBytes.length > 5 * 1024 * 1024 ||
          (contentType.isNotEmpty && !contentType.startsWith('image/'))) {
        return null;
      }
      return pw.MemoryImage(response.bodyBytes);
    } catch (_) {
      // Kegagalan logo tidak boleh menggagalkan pencetakan transaksi.
      return null;
    }
  }

  static String _orderTypeLabel(String value) {
    return switch (value.trim().toLowerCase()) {
      'dine_in' => 'Makan di Tempat'.trCurrent(),
      'free_table' => 'Makan di Tempat (Tanpa Meja)'.trCurrent(),
      'take_away' => 'Bawa Pulang'.trCurrent(),
      'delivery' || 'online_delivery' => 'Pesan Antar'.trCurrent(),
      'quick_service' => 'Layanan Cepat'.trCurrent(),
      'reservation' => 'Reservasi'.trCurrent(),
      _ => value,
    };
  }
}
