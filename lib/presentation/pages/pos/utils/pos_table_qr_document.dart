import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pos_table_qr_print_settings.dart';

class PosTableQrEntry {
  const PosTableQrEntry({
    required this.storeName,
    required this.tableName,
    required this.url,
    this.capacity = 0,
    this.area = '',
    this.floor = '',
  });

  final String storeName;
  final String tableName;
  final Uri url;
  final int capacity;
  final String area;
  final String floor;

  String get location =>
      [floor, area].where((value) => value.trim().isNotEmpty).join(' · ');
}

class PosTableQrDocument {
  const PosTableQrDocument._();

  static Future<Uint8List> build(
    List<PosTableQrEntry> entries, {
    PosTableQrPrintSettings settings = const PosTableQrPrintSettings(),
    Uint8List? logoBytes,
  }) async {
    if (entries.isEmpty) {
      throw ArgumentError.value(entries, 'entries', 'Daftar meja kosong');
    }
    final landscape = settings.orientation == 'landscape';
    final document = pw.Document(title: 'QR Meja Pantoo POS');
    final logo = settings.useLogo && logoBytes != null
        ? pw.MemoryImage(logoBytes)
        : null;
    document.addPage(
      pw.MultiPage(
        pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        maxPages: entries.length + 1,
        margin: const pw.EdgeInsets.all(28),
        build: (_) => [
          for (var index = 0; index < entries.length; index += 2) ...[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: _card(entries[index], settings, logo)),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: index + 1 < entries.length
                      ? _card(entries[index + 1], settings, logo)
                      : pw.SizedBox(),
                ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _card(
    PosTableQrEntry entry,
    PosTableQrPrintSettings settings,
    pw.MemoryImage? logo,
  ) {
    final landscape = settings.orientation == 'landscape';
    final dark = settings.theme == 'dark';
    final primary = settings.theme == 'primary';
    final background = dark
        ? PdfColor.fromHex('#2D2D2D')
        : primary
        ? PdfColor.fromHex('#E6F4F2')
        : PdfColors.white;
    final foreground = dark ? PdfColors.white : PdfColor.fromHex('#172033');
    final secondary = dark
        ? PdfColor.fromHex('#D7DCE3')
        : PdfColor.fromHex('#667085');
    final accent = dark
        ? PdfColor.fromHex('#6EE7D6')
        : PdfColor.fromHex('#087F75');
    final details = pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          pw.Image(logo, height: 42, fit: pw.BoxFit.contain),
          pw.SizedBox(height: 7),
        ],
        pw.Text(
          entry.storeName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 11,
            color: foreground,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          settings.title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 15,
            color: foreground,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (settings.subtitle.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            settings.subtitle,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, color: secondary),
          ),
        ],
        pw.SizedBox(height: 9),
        pw.Text(
          entry.tableName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 20,
            color: accent,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (entry.capacity > 0)
          pw.Text(
            'Kapasitas: ${entry.capacity} Orang',
            style: pw.TextStyle(fontSize: 9, color: secondary),
          ),
        if (entry.location.isNotEmpty)
          pw.Text(
            entry.location.replaceAll(' · ', ' / '),
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 8, color: secondary),
          ),
      ],
    );
    final qr = pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: entry.url.toString(),
        width: landscape ? 140 : 155,
        height: landscape ? 140 : 155,
        drawText: false,
      ),
    );
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: background,
        border: pw.Border.all(
          color: dark ? PdfColors.grey700 : PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: landscape
          ? pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(child: details),
                pw.SizedBox(width: 10),
                qr,
              ],
            )
          : pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                details,
                pw.SizedBox(height: 11),
                qr,
                pw.SizedBox(height: 5),
                pw.Text(
                  entry.url.host,
                  style: pw.TextStyle(fontSize: 8, color: secondary),
                ),
              ],
            ),
    );
  }
}
