import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosReceiptPrintService {
  static const _printerUrlKey = 'pos.receipt_printer_url';
  static const _printerNameKey = 'pos.receipt_printer_name';

  final SharedPreferences preferences;

  const PosReceiptPrintService(this.preferences);

  String get selectedPrinterUrl =>
      preferences.getString(_printerUrlKey)?.trim() ?? '';

  String get selectedPrinterName =>
      preferences.getString(_printerNameKey)?.trim() ?? '';

  Future<void> selectPrinter(Printer? printer) async {
    if (printer == null) {
      await preferences.remove(_printerUrlKey);
      await preferences.remove(_printerNameKey);
      return;
    }
    await preferences.setString(_printerUrlKey, printer.url);
    await preferences.setString(_printerNameKey, printer.name);
  }

  Future<List<Printer>> availablePrinters() async {
    if (kIsWeb) return const [];
    final info = await Printing.info();
    if (!info.canListPrinters) return const [];
    final printers = await Printing.listPrinters();
    printers.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return printers.where((printer) => printer.isAvailable).toList();
  }

  Future<bool> printPdf({
    required Uint8List bytes,
    required String name,
    required PdfPageFormat format,
    bool useConfiguredPrinter = true,
  }) async {
    if (!kIsWeb && useConfiguredPrinter && selectedPrinterUrl.isNotEmpty) {
      try {
        final printer = (await availablePrinters()).cast<Printer?>().firstWhere(
          (candidate) => candidate?.url == selectedPrinterUrl,
          orElse: () => null,
        );
        if (printer != null) {
          return await Printing.directPrintPdf(
            printer: printer,
            name: name,
            format: format,
            onLayout: (_) async => bytes,
          );
        }
      } catch (_) {
        // Driver/printer yang tersimpan dapat hilang. Dialog sistem adalah
        // fallback aman agar kasir tetap bisa menyelesaikan pencetakan.
      }
    }

    return Printing.layoutPdf(
      name: name,
      format: format,
      onLayout: (_) async => bytes,
    );
  }
}
