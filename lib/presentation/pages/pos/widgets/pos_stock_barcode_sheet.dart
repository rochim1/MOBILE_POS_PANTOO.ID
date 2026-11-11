import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/receipt/pos_receipt_print_service.dart';
import '../../../../domain/models/pos_stock.dart';
import '../../../../domain/repositories/pos_receipt_repository.dart';
import '../../../../injections.dart';
import '../utils/pos_business_print_branding.dart';
import '../utils/pos_pdf_preview_bytes.dart';
import '../utils/pos_stock_barcode_document.dart';

class PosStockBarcodeSheet extends StatefulWidget {
  const PosStockBarcodeSheet({super.key, required this.stock});

  final PosStock stock;

  @override
  State<PosStockBarcodeSheet> createState() => _PosStockBarcodeSheetState();
}

class _PosStockBarcodeSheetState extends State<PosStockBarcodeSheet> {
  final _quantity = TextEditingController(text: '1');
  late String _codeSource;
  String _size = 'medium';
  String? _error;
  bool _printing = false;
  int _printedLabels = 0;
  int _targetLabels = 0;

  @override
  void initState() {
    super.initState();
    _codeSource = widget.stock.barcode.isNotEmpty
        ? 'barcode'
        : widget.stock.sku.isNotEmpty
        ? 'sku'
        : 'code';
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  String get _code => switch (_codeSource) {
    'barcode' => widget.stock.barcode,
    'sku' => widget.stock.sku,
    _ => widget.stock.kodeInventaris,
  };

  Future<void> _print({bool preview = false}) async {
    if (_printing) return;
    final count = int.tryParse(_quantity.text.trim());
    final code = _code.trim();
    if (count == null || count < 1 || count > 50) {
      setState(() => _error = 'Jumlah label harus 1–50.');
      return;
    }
    if (!PosStockBarcodeDocument.supportsCode(code)) {
      setState(() => _error = 'Kode kosong atau tidak didukung Code 128.');
      return;
    }
    setState(() {
      _error = null;
      _printing = true;
      _printedLabels = 0;
      _targetLabels = count;
    });
    try {
      Map<String, String> company = const {};
      var paperWidthMm = 58;
      try {
        final brand = await sl<PosReceiptRepository>()
            .getReceiptPrintData(forceRefresh: true)
            .timeout(const Duration(seconds: 5));
        company = brand.fold<Map<String, String>>(
          (_) => const {},
          (data) => data.company,
        );
        paperWidthMm = brand.fold<int>(
          (_) => 58,
          (data) => data.template.paperWidth == 80 ? 80 : 58,
        );
      } catch (_) {
        // Offline labels still print using their product data.
      }
      final logo = await PosBusinessPrintBranding.loadCompanyLogo(
        company['logo'] ?? '',
      );
      final companyName = [company['nama_resmi'], company['nama_instansi']]
          .whereType<String>()
          .map((name) => name.trim())
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');
      final printer = PosReceiptPrintService(sl());
      if (!preview && !printer.hasConfiguredPrinter) {
        throw StateError('Pilih printer di Pengaturan Printer Terminal.');
      }
      if (!preview && printer.selectedBluetoothAddress.isNotEmpty) {
        for (var remaining = count; remaining > 0; remaining -= 8) {
          final batch = remaining > 8 ? 8 : remaining;
          final thermalBytes = await PosStockBarcodeDocument.buildThermal(
            name: widget.stock.namaInventaris,
            code: code,
            quantity: batch,
            paperWidthMm: paperWidthMm,
            companyName: companyName,
            logoBytes: logo,
          );
          final printed = await printer.printPdf(
            bytes: thermalBytes,
            name: 'Label-${widget.stock.kodeInventaris}',
            format: PdfPageFormat(
              paperWidthMm * PdfPageFormat.mm,
              batch * 36 * PdfPageFormat.mm,
            ),
          );
          if (!printed) throw StateError('Printer menolak sebagian label.');
          if (mounted) setState(() => _printedLabels += batch);
        }
        return;
      }
      final bytes = await PosStockBarcodeDocument.build(
        name: widget.stock.namaInventaris,
        code: code,
        quantity: count,
        size: _size,
        companyName: companyName,
        logoBytes: logo,
      );
      if (!mounted) return;
      final fileName = 'Label-${widget.stock.kodeInventaris}.pdf';
      if (preview) {
        final previewBytes = PosPdfPreviewBytes(bytes);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: Text(posLocale(context).posd56f5ea7493b((widget.stock.namaInventaris).toString())),
              ),
              body: PdfPreview(
                build: (_) async => previewBytes.freshBytes(),
                pdfFileName: fileName,
                canChangePageFormat: false,
                canChangeOrientation: false,
                allowPrinting: false,
              ),
            ),
          ),
        );
      } else {
        final printed = await printer.printPdf(
          bytes: bytes,
          name: fileName,
          format: PdfPageFormat.a4,
        );
        if (!printed) throw StateError('Pencetakan label dibatalkan.');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          final reason = error is StateError
              ? error.message
              : 'Gagal menyiapkan label.';
          _error = _printedLabels > 0
              ? '$reason $_printedLabels dari $_targetLabels label telah dikirim. '
                    'Periksa hasil fisik sebelum mengulang; batch terakhir mungkin sudah tercetak.'
              : '$reason Periksa hasil fisik sebelum mencoba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosText(
            'Cetak label barcode',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(widget.stock.namaInventaris),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _codeSource,
            decoration:  InputDecoration(
              labelText: ('Kode pada label').tr(context),
              border: OutlineInputBorder(),
            ),
            items: [
              if (widget.stock.barcode.isNotEmpty)
                DropdownMenuItem(
                  value: 'barcode',
                  child: Text(posLocale(context).pos49b67ac0c655((widget.stock.barcode).toString())),
                ),
              if (widget.stock.sku.isNotEmpty)
                DropdownMenuItem(
                  value: 'sku',
                  child: Text(posLocale(context).pos19aa65c6a13e((widget.stock.sku).toString())),
                ),
              DropdownMenuItem(
                value: 'code',
                child: Text(posLocale(context).pos844214a54fe7((widget.stock.kodeInventaris).toString())),
              ),
            ],
            onChanged: (value) => setState(() => _codeSource = value ?? 'code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration:  InputDecoration(
              labelText: ('Jumlah label (1–50)').tr(context),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _size,
            decoration:  InputDecoration(
              labelText: ('Ukuran label').tr(context),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'small', child: PosText('Kecil')),
              DropdownMenuItem(value: 'medium', child: PosText('Sedang')),
              DropdownMenuItem(value: 'large', child: PosText('Besar')),
            ],
            onChanged: (value) => setState(() => _size = value ?? 'medium'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            PosText(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_printing && _targetLabels > 0) ...[
            const SizedBox(height: 8),
            Text(posLocale(context).pos58df45e9d2a1((_printedLabels).toString(), (_targetLabels).toString())),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _printing ? null : () => _print(),
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print_outlined),
            label: const PosText('Cetak label'),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _printing ? null : () => _print(preview: true),
            icon: const Icon(Icons.preview_outlined),
            label: const PosText('Pratinjau label'),
          ),
          const SizedBox(height: 6),
          const PosText(
            'Cetak memakai printer terminal yang dipilih di Pengaturan Printer. Bluetooth thermal memakai kertas 58/80 mm; pratinjau PDF dapat dibagikan untuk cetak label A4.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
