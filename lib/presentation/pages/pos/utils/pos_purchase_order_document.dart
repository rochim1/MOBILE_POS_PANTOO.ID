import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PosPurchaseOrderDocument {
  const PosPurchaseOrderDocument._();

  static bool isApproved(Map<String, dynamic> purchase) => const {
    'approved',
    'partially_received',
    'completed',
  }.contains(purchase['status']?.toString());

  static Future<Uint8List> build({
    required Map<String, dynamic> purchase,
    required Map<String, String> company,
  }) async {
    final document = pw.Document();
    final official = isApproved(purchase);
    final rows = (purchase['items'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final buyerName = _firstFilled([
      company['nama_resmi'],
      company['nama_instansi'],
    ], 'Pembeli');
    final buyerAddress = [
      company['alamat'],
      company['kabupaten'],
      company['provinsi'],
    ].where((part) => part?.trim().isNotEmpty == true).join(', ');
    final subtotal = _amount(purchase['total_amount']);
    final discount = purchase['diskon_type'] == 'persen'
        ? subtotal * _amount(purchase['diskon_persen']) / 100
        : _amount(purchase['diskon_fixed']);
    final extraCosts = (purchase['biaya_tambahan'] as List? ?? const [])
        .whereType<Map>()
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (!official)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                color: PdfColors.orange100,
                child: pw.Text(
                  'DRAFT - BELUM DISETUJUI - BUKAN PESANAN RESMI',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.deepOrange,
                  ),
                ),
              ),
            pw.SizedBox(height: 12),
            pw.Text(
              'PURCHASE ORDER',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal800,
              ),
            ),
            pw.Divider(color: PdfColors.teal800),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (_) => [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _block('Dari', [
                  buyerName,
                  if (buyerAddress.isNotEmpty) buyerAddress,
                  if ((company['telpon_number'] ?? '').isNotEmpty)
                    company['telpon_number']!,
                  if ((company['email'] ?? '').isNotEmpty) company['email']!,
                ]),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _block('Kepada', [
                  _string(purchase['supplier_name']),
                  if (_string(purchase['alamat_pengiriman']).isNotEmpty)
                    'Alamat kirim: ${_string(purchase['alamat_pengiriman'])}',
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 20,
            runSpacing: 5,
            children: [
              _field('Nomor PO', _string(purchase['no_po'])),
              _field('Tanggal PO', _date(purchase['tanggal_po'])),
              _field('Pengiriman', _date(purchase['tanggal_pengiriman'])),
              _field('Jatuh tempo', _date(purchase['due_date'])),
              _field('Status', _string(purchase['status']).toUpperCase()),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const [
              'No.',
              'Kode / Barang',
              'Jumlah',
              'Satuan',
              'Harga',
              'Subtotal',
            ],
            data: [
              for (var index = 0; index < rows.length; index++)
                [
                  '${index + 1}',
                  [
                    _string(rows[index]['kode_inventaris']),
                    _string(rows[index]['nama_inventaris']),
                  ].where((value) => value.isNotEmpty).join('\n'),
                  _quantity(rows[index]['qty_ordered']),
                  _string(rows[index]['unit']),
                  _money(rows[index]['harga_beli']),
                  _money(rows[index]['subtotal']),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FixedColumnWidth(43),
              3: const pw.FixedColumnWidth(48),
              4: const pw.FixedColumnWidth(72),
              5: const pw.FixedColumnWidth(75),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalLine('Subtotal', subtotal),
                  if (discount > 0) _totalLine('Diskon', -discount),
                  if (_amount(purchase['ppn_amount']) > 0)
                    _totalLine('PPN', _amount(purchase['ppn_amount'])),
                  for (final cost in extraCosts)
                    _totalLine(
                      _firstFilled([
                        cost['deskripsi']?.toString(),
                        cost['jenis_biaya']?.toString(),
                      ], 'Biaya tambahan'),
                      _amount(cost['nominal']),
                    ),
                  if (extraCosts.isEmpty &&
                      _amount(purchase['biaya_pengiriman']) > 0)
                    _totalLine(
                      'Ongkos kirim',
                      _amount(purchase['biaya_pengiriman']),
                    ),
                  pw.Divider(),
                  _totalLine(
                    'Grand total',
                    _amount(purchase['grand_total']),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          if (_string(purchase['syarat_pembayaran']).isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _block('Syarat pembayaran', [
              _string(purchase['syarat_pembayaran']),
            ]),
          ],
          if (_string(purchase['catatan']).isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _block('Catatan', [_string(purchase['catatan'])]),
          ],
        ],
      ),
    );
    return document.save();
  }

  static pw.Widget _block(String label, List<String> lines) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfColors.grey700,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
      pw.SizedBox(height: 4),
      for (final line in lines)
        pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
    ],
  );

  static pw.Widget _field(String label, String value) => pw.SizedBox(
    width: 150,
    child: pw.Text(
      '$label: ${value.isEmpty ? '-' : value}',
      style: const pw.TextStyle(fontSize: 9),
    ),
  );

  static pw.Widget _totalLine(
    String label,
    double amount, {
    bool bold = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Text(
          _money(amount),
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    ),
  );

  static String _string(Object? value) => value?.toString().trim() ?? '';
  static double _amount(Object? value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  static String _firstFilled(Iterable<String?> values, String fallback) =>
      values
          .map((value) => value?.trim() ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => fallback);
  static String _quantity(Object? value) =>
      NumberFormat.decimalPattern('id_ID').format(_amount(value));
  static String _money(Object? value) =>
      'Rp ${NumberFormat.decimalPattern('id_ID').format(_amount(value))}';
  static String _date(Object? value) {
    final raw = _string(value);
    if (raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? raw : DateFormat('dd/MM/yyyy').format(parsed);
  }
}
