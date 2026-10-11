import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PosStockBarcodeDocument {
  const PosStockBarcodeDocument._();

  static bool supportsCode(String code) =>
      code.trim().isNotEmpty && RegExp(r'^[\x20-\x7E]+$').hasMatch(code.trim());

  static Future<Uint8List> build({
    required String name,
    required String code,
    required int quantity,
    String size = 'medium',
    String companyName = '',
    Uint8List? logoBytes,
  }) async {
    final value = code.trim();
    if (!supportsCode(value) || quantity < 1 || quantity > 50) {
      throw ArgumentError('Kode dan jumlah label (1–50) wajib valid.');
    }
    final columns = switch (size) {
      'small' => 3,
      'large' => 1,
      _ => 2,
    };
    final height = switch (size) {
      'small' => 70.0,
      'large' => 140.0,
      _ => 95.0,
    };
    final rows = switch (size) {
      'small' => 10,
      'large' => 5,
      _ => 7,
    };
    const page = PdfPageFormat.a4;
    const margin = 22.0;
    const gap = 7.0;
    final width = (page.width - margin * 2 - gap * (columns - 1)) / columns;
    final perPage = columns * rows;
    final pdf = pw.Document(title: 'Label Barcode $name');
    for (var first = 0; first < quantity; first += perPage) {
      final count = quantity - first < perPage ? quantity - first : perPage;
      pdf.addPage(
        pw.Page(
          pageFormat: page,
          margin: const pw.EdgeInsets.all(margin),
          build: (_) => pw.Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var index = 0; index < count; index++)
                pw.Container(
                  width: width,
                  height: height,
                  padding: const pw.EdgeInsets.all(7),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (companyName.trim().isNotEmpty ||
                          logoBytes != null) ...[
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            if (logoBytes != null && logoBytes.isNotEmpty) ...[
                              pw.Image(
                                pw.MemoryImage(logoBytes),
                                width: 12,
                                height: 12,
                              ),
                              pw.SizedBox(width: 3),
                            ],
                            if (companyName.trim().isNotEmpty)
                              pw.SizedBox(
                                width: width - 42,
                                child: pw.Text(
                                  companyName.trim(),
                                  maxLines: 1,
                                  style: pw.TextStyle(
                                    fontSize: size == 'small' ? 6 : 7,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                      ],
                      pw.Text(
                        name,
                        maxLines: 1,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: size == 'small' ? 7 : 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.code128(),
                        data: value,
                        width: width - 22,
                        height: size == 'small' ? 27 : 42,
                        drawText: false,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(value, style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }

  /// One narrow page for a small batch of Bluetooth thermal labels. Callers
  /// split larger quantities into batches so rasterizing never creates an
  /// excessively tall image or silently drops pages.
  static Future<Uint8List> buildThermal({
    required String name,
    required String code,
    required int quantity,
    required int paperWidthMm,
    String companyName = '',
    Uint8List? logoBytes,
  }) async {
    if (!supportsCode(code) || quantity < 1 || quantity > 8) {
      throw ArgumentError('Jumlah label thermal harus 1–8.');
    }
    final width = (paperWidthMm == 80 ? 80 : 58) * PdfPageFormat.mm;
    final labelHeight = 36 * PdfPageFormat.mm;
    final pdf = pw.Document(title: 'Label Barcode $name');
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, labelHeight * quantity),
        margin: const pw.EdgeInsets.all(6),
        build: (_) => pw.Column(
          children: [
            for (var index = 0; index < quantity; index++)
              pw.Container(
                height: labelHeight - 12,
                width: double.infinity,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey400),
                  ),
                ),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (companyName.trim().isNotEmpty || logoBytes != null)
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          if (logoBytes != null && logoBytes.isNotEmpty) ...[
                            pw.Image(
                              pw.MemoryImage(logoBytes),
                              width: 12,
                              height: 12,
                            ),
                            pw.SizedBox(width: 3),
                          ],
                          pw.Text(
                            companyName.trim(),
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    pw.Text(
                      name,
                      maxLines: 1,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.code128(),
                      data: code.trim(),
                      width: width - 25,
                      height: 35,
                      drawText: false,
                    ),
                    pw.Text(
                      code.trim(),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
