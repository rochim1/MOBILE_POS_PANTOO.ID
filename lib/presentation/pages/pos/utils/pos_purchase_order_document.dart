import 'dart:typed_data';

import 'package:intl/date_symbol_data_local.dart';
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
    Uint8List? logoBytes,
  }) async {
    await initializeDateFormatting('id_ID');
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
    final buyerContact = [
      company['telpon_number'],
      company['email'],
      company['website'],
    ].where((part) => part?.trim().isNotEmpty == true).join(' | ');
    final creator = purchase['created_by'];
    final creatorName = creator is Map
        ? _firstFilled([
            creator['name']?.toString(),
            creator['username']?.toString(),
          ], '-')
        : '-';
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
            pw.SizedBox(height: 10),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoBytes != null && logoBytes.isNotEmpty) ...[
                  pw.Image(pw.MemoryImage(logoBytes), width: 52, height: 52),
                  pw.SizedBox(width: 12),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        buyerName,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (buyerAddress.isNotEmpty)
                        pw.Text(
                          buyerAddress,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (buyerContact.isNotEmpty)
                        pw.Text(
                          buyerContact,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.grey400),
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
                child: _block('Purchase Order', [
                  'Dokumen pesanan pembelian inventory',
                  'No PO: ${_string(purchase['no_po'])}',
                  'Tanggal PO: ${_date(purchase['tanggal_po'])}',
                ]),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _block('Supplier / Pengiriman', [
                  _string(purchase['supplier_name']),
                  if (_string(purchase['alamat_pengiriman']).isNotEmpty)
                    _string(purchase['alamat_pengiriman']),
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 12,
            runSpacing: 5,
            children: [
              _field('Pengiriman', _date(purchase['tanggal_pengiriman'])),
              _field('Jatuh tempo', _date(purchase['due_date'])),
              _field('Status', _string(purchase['status']).toUpperCase()),
              _field('Dibuat oleh', creatorName),
              _field(
                'Diperbarui',
                _dateTime(purchase['updatedAt'] ?? purchase['createdAt']),
              ),
            ],
          ),
          if (_string(purchase['catatan']).isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _block('Catatan PO', [_string(purchase['catatan'])]),
          ],
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const [
              'No.',
              'Kode',
              'Item',
              'Qty',
              'Harga',
              'Subtotal',
              'Keterangan',
            ],
            data: [
              for (var index = 0; index < rows.length; index++)
                [
                  '${index + 1}',
                  _string(rows[index]['kode_inventaris']),
                  _string(rows[index]['nama_inventaris']),
                  '${_quantity(rows[index]['qty_ordered'])} ${_string(rows[index]['unit'])}',
                  _money(rows[index]['harga_beli']),
                  _money(rows[index]['subtotal']),
                  _string(rows[index]['catatan_item']),
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
              1: const pw.FixedColumnWidth(68),
              2: const pw.FlexColumnWidth(2.5),
              3: const pw.FixedColumnWidth(55),
              4: const pw.FixedColumnWidth(70),
              5: const pw.FixedColumnWidth(73),
              6: const pw.FlexColumnWidth(2),
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
          if ((purchase['jadwal_termin'] as List? ?? const []).isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _block('Jadwal Termin Pembayaran', const []),
            pw.TableHelper.fromTextArray(
              headers: const ['Termin', 'Jatuh tempo', 'Jumlah', 'Status'],
              data: [
                for (final raw
                    in (purchase['jadwal_termin'] as List).whereType<Map>())
                  [
                    _string(raw['no_termin']),
                    _date(raw['due_date']),
                    _money(raw['amount']),
                    _string(raw['status']),
                  ],
              ],
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Text(
            'Dokumen ini dicetak dari sistem pada ${_dateTime(DateTime.now())}.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
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
    return parsed == null
        ? raw
        : DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
  }

  static String _dateTime(Object? value) {
    final raw = _string(value);
    final parsed = DateTime.tryParse(raw);
    return parsed == null
        ? (raw.isEmpty ? '-' : raw)
        : DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(parsed.toLocal());
  }
}
