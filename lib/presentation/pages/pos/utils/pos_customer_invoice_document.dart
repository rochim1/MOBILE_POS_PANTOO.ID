import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../domain/models/pos_order.dart';

/// Customer-facing A4 invoice, deliberately independent of thermal settings.
class PosCustomerInvoiceDocument {
  const PosCustomerInvoiceDocument._();

  static Map<String, dynamic> fromOrder(PosOrder order) => {
    'invoice_number': order.invoice,
    'invoice_date': order.date,
    'due_date': order.dueDate,
    'customer_name': order.customer,
    'customer_phone': order.customerPhone,
    'source_context': {'store_name': order.storeName},
    'status': order.paymentStatus == 'lunas' ? 'paid' : order.paymentStatus,
    'subtotal': order.subtotal,
    'discount_amount': order.discountAmount,
    'tax_amount': order.taxAmount,
    'total_amount': order.total,
    'paid_amount':
        order.paidAmount ??
        (order.paymentStatus == 'lunas'
            ? order.total
            : order.isInvoice
            ? 0
            : null),
    'outstanding_amount':
        order.outstandingAmount ??
        (order.paymentStatus == 'lunas'
            ? 0
            : order.isInvoice
            ? order.total
            : null),
    'credited_amount': order.creditedAmount,
    'notes': order.note,
    'lines': order.items
        .map(
          (item) => {
            'description': item['nama_inventaris'] ?? item['nama'],
            'quantity': item['qty'],
            'unit': item['unit'],
            'unit_price': item['harga_jual'] ?? item['harga_satuan'],
            'line_net': item['subtotal'],
          },
        )
        .toList(),
    'pending_order': order.isInvoice,
  };

  static double _number(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    return number.isFinite ? number : 0;
  }

  static String _text(dynamic value) => value?.toString().trim() ?? '';
  static String _date(dynamic value) {
    final raw = _text(value);
    if (raw.isEmpty ||
        (!RegExp(r'^\d+$').hasMatch(raw) && DateTime.tryParse(raw) == null)) {
      return '-';
    }
    return DateFormat('dd/MM/yyyy').format(PosOrder.parseDateValue(value));
  }

  static void validateBalance(Map<String, dynamic> invoice) {
    const keys = [
      'total_amount',
      'paid_amount',
      'credited_amount',
      'outstanding_amount',
    ];
    bool present(dynamic value) => value != null && _text(value).isNotEmpty;
    for (final key in keys) {
      if (!present(invoice[key])) continue;
      final value = double.tryParse(invoice[key].toString());
      if (value == null || !value.isFinite || value < 0) {
        throw StateError(
          'Saldo invoice tidak valid. Muat ulang sebelum mencetak atau membagikan.',
        );
      }
    }
    if (['draft', 'cancelled'].contains(invoice['status'])) return;
    if (keys.every((key) => present(invoice[key])) &&
        (_number(invoice['total_amount']) -
                    _number(invoice['paid_amount']) -
                    _number(invoice['credited_amount']) -
                    _number(invoice['outstanding_amount']))
                .abs() >
            .01) {
      throw StateError(
        'Saldo invoice tidak konsisten. Muat ulang sebelum mencetak atau membagikan.',
      );
    }
    if (['paid', 'credited'].contains(invoice['status']) &&
        present(invoice['outstanding_amount']) &&
        _number(invoice['outstanding_amount']) != 0) {
      throw StateError(
        'Status dan saldo invoice tidak sesuai. Muat ulang transaksi.',
      );
    }
  }

  static Future<Uint8List> build({
    required Map<String, dynamic> invoice,
    required Map<String, String> company,
    Uint8List? logoBytes,
    String language = 'id',
  }) async {
    validateBalance(invoice);
    final en = language.startsWith('en');
    String t(String id, String english) => en ? english : id;
    final name = _text(company['nama_resmi']).isNotEmpty
        ? _text(company['nama_resmi'])
        : _text(company['nama_instansi']);
    if (name.isEmpty) {
      throw StateError(
        t(
          'Identitas usaha belum tersedia. Muat ulang lalu coba lagi.',
          'Business identity is unavailable. Reload and try again.',
        ),
      );
    }
    final moneyFormat = NumberFormat.currency(
      locale: en ? 'en_GB' : 'id_ID',
      symbol: invoice['currency'] == null || invoice['currency'] == 'IDR'
          ? 'Rp '
          : '${invoice['currency']} ',
      decimalDigits: 0,
    );
    String money(dynamic value) => moneyFormat.format(_number(value));
    final labels = {
      'draft': t('DRAFT - BELUM DITERBITKAN', 'DRAFT - NOT ISSUED'),
      'cancelled': t('DIBATALKAN - BUKAN TAGIHAN', 'CANCELLED - NOT PAYABLE'),
      'paid': t('Lunas', 'Paid'),
      'partial': t('Dibayar sebagian', 'Partially paid'),
      'issued': t('Belum dibayar', 'Unpaid'),
      'belum_bayar': t('Belum dibayar', 'Unpaid'),
      'credited': t('Dikreditkan', 'Credited'),
    };
    final blocked = ['draft', 'cancelled'].contains(invoice['status']);
    final address =
        [
              'alamat',
              'kelurahan',
              'kecamatan',
              'kabupaten',
              'provinsi',
              'pos_code',
            ]
            .map((key) => _text(company[key]))
            .where((value) => value.isNotEmpty)
            .join(', ');
    final contact = ['telpon_number', 'email', 'website']
        .map((key) => _text(company[key]))
        .where((value) => value.isNotEmpty)
        .join(' | ');
    final lines = (invoice['lines'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final source = invoice['source_context'] is Map
        ? invoice['source_context'] as Map
        : const {};
    pw.Widget field(String label, dynamic value) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(_text(value).isEmpty ? '-' : _text(value)),
        ],
      ),
    );
    pw.Widget total(
      String label,
      dynamic value, {
      bool bold = false,
    }) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Text(
            value == null ? t('Belum tersedia', 'Unavailable') : money(value),
            style: pw.TextStyle(
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
    final document = pw.Document(
      title: 'Invoice ${_text(invoice['invoice_number'])}',
      author: name,
    );
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-regular.ttf'),
    );
    final boldFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto-bold.ttf'),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(42),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: boldFont,
        ).copyWith(defaultTextStyle: const pw.TextStyle(fontSize: 10)),
        header: (_) => pw.Column(
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoBytes != null && logoBytes.isNotEmpty) ...[
                  pw.Image(
                    pw.MemoryImage(logoBytes),
                    width: 52,
                    height: 52,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.SizedBox(width: 12),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (address.isNotEmpty)
                        pw.Text(
                          address,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (contact.isNotEmpty)
                        pw.Text(
                          contact,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      if (_text(company['NPWP']).isNotEmpty)
                        pw.Text(
                          'NPWP: ${company['NPWP']}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.teal700, thickness: 1.5),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              t(
                'Dokumen ini bukan faktur pajak.',
                'This document is not a tax invoice.',
              ),
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (_) => [
          if (blocked)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(9),
              color: PdfColors.orange100,
              child: pw.Text(
                labels[invoice['status']]!,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 23,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(_text(invoice['invoice_number'])),
                ],
              ),
              pw.Text(
                labels[invoice['status']] ??
                    t('Status belum tersedia', 'Status unavailable'),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    field(
                      t('Ditagihkan kepada', 'Bill to'),
                      invoice['customer_name'],
                    ),
                    if (_text(invoice['customer_address']).isNotEmpty)
                      field(
                        t('Alamat', 'Address'),
                        invoice['customer_address'],
                      ),
                    if (_text(invoice['customer_phone']).isNotEmpty)
                      field(t('Telepon', 'Phone'), invoice['customer_phone']),
                    if (_text(invoice['customer_tax_number']).isNotEmpty)
                      field('NPWP', invoice['customer_tax_number']),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    field(
                      t('Tanggal invoice', 'Invoice date'),
                      _date(invoice['invoice_date']),
                    ),
                    field(
                      t('Jatuh tempo', 'Due date'),
                      _date(invoice['due_date']),
                    ),
                    field(
                      t('Toko / Cabang', 'Store / Branch'),
                      source['store_name'] ?? invoice['branch_name'],
                    ),
                    if (_text(source['receipt_number']).isNotEmpty)
                      field(
                        t('Referensi transaksi', 'Receipt reference'),
                        source['receipt_number'],
                      ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              '#',
              t('Barang / Layanan', 'Item / Service'),
              'Qty',
              t('Harga', 'Price'),
              t('Diskon', 'Discount'),
              t('Jumlah', 'Amount'),
            ],
            data: [
              for (var index = 0; index < lines.length; index++)
                [
                  '${index + 1}',
                  _text(lines[index]['description']),
                  '${NumberFormat('0.###').format(_number(lines[index]['quantity']))} ${_text(lines[index]['unit'])}',
                  money(lines[index]['unit_price']),
                  money(lines[index]['discount']),
                  money(lines[index]['line_net']),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellPadding: const pw.EdgeInsets.all(6),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
            columnWidths: {
              0: const pw.FixedColumnWidth(23),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1.6),
              4: const pw.FlexColumnWidth(1.4),
              5: const pw.FlexColumnWidth(1.7),
            },
            cellAlignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Inseparable(
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 270,
                child: pw.Column(
                  children: [
                    total(
                      invoice['subtotal'] == null
                          ? t('Neto', 'Net amount')
                          : 'Subtotal',
                      invoice['subtotal'] ?? invoice['net_amount'],
                    ),
                    if (_number(invoice['discount_amount']) > 0)
                      total(
                        t('Diskon', 'Discount'),
                        -_number(invoice['discount_amount']),
                      ),
                    total(t('Pajak', 'Tax'), invoice['tax_amount']),
                    total('Total', invoice['total_amount'], bold: true),
                    total(
                      t('Sudah dibayar', 'Paid amount'),
                      invoice['paid_amount'],
                    ),
                    if (_number(invoice['credited_amount']) > 0)
                      total(
                        t('Kredit / Retur', 'Credit / Return'),
                        invoice['credited_amount'],
                      ),
                    pw.Divider(),
                    total(
                      t('Sisa tagihan', 'Amount due'),
                      blocked ? null : invoice['outstanding_amount'],
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_number(invoice['credited_amount']) > 0)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Text(
                t(
                  'Kredit yang ditampilkan mengurangi piutang. Refund atau saldo kredit pelanggan dicatat terpisah.',
                  'The credit shown reduces this receivable. Refunds or customer credit balances are recorded separately.',
                ),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          if (_text(invoice['notes']).isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              t('Catatan', 'Notes'),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(_text(invoice['notes'])),
          ],
          pw.SizedBox(height: 20),
          if (invoice['pending_order'] == true)
            pw.Text(
              t(
                'Pesanan belum dibayar; belum merupakan piutang Finance.',
                'Unpaid order; not yet a Finance receivable.',
              ),
              style: const pw.TextStyle(fontSize: 9),
            ),
          pw.Text(
            t(
              'Invoice ini bukan bukti pembayaran. Pembayaran dan saldo mengikuti pencatatan yang telah dikonfirmasi.',
              'This invoice is not proof of payment. Payments and balances reflect confirmed records.',
            ),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return document.save();
  }
}
