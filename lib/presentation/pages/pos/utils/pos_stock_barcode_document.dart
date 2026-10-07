import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PosStockBarcodeDocument {
  const PosStockBarcodeDocument._();

  static bool supportsCode(String code) =>
      code.trim().isNotEmpty &&
      RegExp(r'^[\x20-\x7E]+$').hasMatch(code.trim());

  static Future<Uint8List> build({
    required String name,
    required String code,
    required int quantity,
    String size = 'medium',
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
}
