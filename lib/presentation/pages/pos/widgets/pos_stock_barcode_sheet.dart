import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../domain/models/pos_stock.dart';
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

  void _preview() {
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
    setState(() => _error = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Label ${widget.stock.namaInventaris}')),
          body: PdfPreview(
            build: (_) => PosStockBarcodeDocument.build(
              name: widget.stock.namaInventaris,
              code: code,
              quantity: count,
              size: _size,
            ),
            pdfFileName: 'Label-${widget.stock.kodeInventaris}.pdf',
            canChangePageFormat: false,
            canChangeOrientation: false,
          ),
        ),
      ),
    );
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
          Text(
            'Cetak label barcode',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(widget.stock.namaInventaris),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _codeSource,
            decoration: const InputDecoration(
              labelText: 'Kode pada label',
              border: OutlineInputBorder(),
            ),
            items: [
              if (widget.stock.barcode.isNotEmpty)
                DropdownMenuItem(
                  value: 'barcode',
                  child: Text('Barcode · ${widget.stock.barcode}'),
                ),
              if (widget.stock.sku.isNotEmpty)
                DropdownMenuItem(
                  value: 'sku',
                  child: Text('SKU · ${widget.stock.sku}'),
                ),
              DropdownMenuItem(
                value: 'code',
                child: Text('Kode inventaris · ${widget.stock.kodeInventaris}'),
              ),
            ],
            onChanged: (value) => setState(() => _codeSource = value ?? 'code'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Jumlah label (1–50)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _size,
            decoration: const InputDecoration(
              labelText: 'Ukuran label',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'small', child: Text('Kecil')),
              DropdownMenuItem(value: 'medium', child: Text('Sedang')),
              DropdownMenuItem(value: 'large', child: Text('Besar')),
            ],
            onChanged: (value) => setState(() => _size = value ?? 'medium'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _preview,
            icon: const Icon(Icons.print_outlined),
            label: const Text('Pratinjau & Cetak'),
          ),
          const SizedBox(height: 6),
          const Text(
            'Label memakai kode produk yang sama dengan web. Pilih printer label pada layar cetak; jangan gunakan printer struk jika ukuran kertas tidak cocok.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
