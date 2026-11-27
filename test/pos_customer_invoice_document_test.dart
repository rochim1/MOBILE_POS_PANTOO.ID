import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_customer_invoice_document.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final company = {
    'nama_instansi': 'Pantoo Store',
    'nama_resmi': 'PT Pantoo Jaya',
    'alamat': 'Jl. Merdeka 10',
    'telpon_number': '081234567890',
    'email': 'toko@example.test',
    'NPWP': '01.234.567.8-901.000',
  };
  Map<String, dynamic> invoice({
    String status = 'partial',
    int itemCount = 1,
  }) => {
    'invoice_number': 'INV-QA-001',
    'customer_name': 'Budi Santoso',
    'customer_address': 'Jl. Melati 2',
    'invoice_date': '2026-11-27',
    'due_date': '2026-12-04',
    'status': status,
    'currency': 'IDR',
    'net_amount': 100000 * itemCount,
    'tax_amount': 11000 * itemCount,
    'total_amount': 111000 * itemCount,
    'paid_amount': 30000,
    'credited_amount': 10000,
    'outstanding_amount': 111000 * itemCount - 40000,
    'source_context': {
      'store_name': 'Toko Bandung',
      'receipt_number': 'POS-001',
      'shift_id': 'secret-shift',
    },
    'notes': 'Hubungi kasir untuk konfirmasi pembayaran.',
    'lines': List.generate(
      itemCount,
      (index) => {
        'description': 'Layanan transport ${index + 1}',
        'quantity': 1,
        'unit_price': 100000,
        'discount': 0,
        'line_net': 100000,
        'revenue_account_code': 'secret-coa',
      },
    ),
  };
  test('order model preserves invoice settlement and edited service price', () {
    final order = PosOrder.fromJson({
      '_id': 'sale',
      'invoice': 'POS-1',
      'sales_invoice_id': 'ar-1',
      'due_date': '2026-12-04',
      'status_pembayaran': 'partial',
      'paid_amount': 30000,
      'credited_amount': 10000,
      'outstanding_amount': 71000,
      'toko_nama': 'Bandung',
      'total': 111000,
      'items': [
        {
          'nama_inventaris': 'Transport',
          'qty': 1,
          'harga_jual': 14500,
          'subtotal': 14500,
        },
      ],
    });
    expect(order.salesInvoiceId, 'ar-1');
    expect(order.dueDate, '2026-12-04');
    final mapped = PosCustomerInvoiceDocument.fromOrder(order);
    expect(mapped['outstanding_amount'], 71000);
    expect(mapped['paid_amount'], 30000);
    expect((mapped['lines'] as List).single['unit_price'], 14500);
  });
  test(
    'legacy unconfirmed payment does not invent settled or outstanding amount',
    () {
      final order = PosOrder.fromJson({
        'invoice': 'OLD',
        'metode_pembayaran': 'tempo',
        'status_pembayaran': 'partial',
        'total': 50000,
      });
      final data = PosCustomerInvoiceDocument.fromOrder(order);
      expect(data['outstanding_amount'], isNull);
      expect(data['paid_amount'], isNull);
      final paid = PosOrder.fromJson({
        'invoice': 'PAID',
        'total': 50000,
        'status_pembayaran': 'lunas',
      });
      expect(
        PosCustomerInvoiceDocument.fromOrder(paid)['outstanding_amount'],
        0,
      );
    },
  );
  test('unpaid order remains distinct from Finance receivable', () {
    final order = PosOrder.fromPendingOrderJson({
      'order_no': 'ORDER-1',
      'grand_total': 25000,
      'toko': {'nama_toko': 'Toko A'},
    });
    final data = PosCustomerInvoiceDocument.fromOrder(order);
    expect(data['pending_order'], isTrue);
    expect(data['outstanding_amount'], 25000);
    expect(order.storeName, 'Toko A');
  });
  test(
    'requires company identity instead of emitting anonymous formal invoice',
    () async {
      await expectLater(
        PosCustomerInvoiceDocument.build(invoice: invoice(), company: {}),
        throwsStateError,
      );
    },
  );
  for (final language in ['id', 'en']) {
    test(
      'A4 invoice builds with partial payment, logo and multipage items $language',
      () async {
        for (final count in [1, 70]) {
          final bytes = await PosCustomerInvoiceDocument.build(
            invoice: invoice(itemCount: count),
            company: company,
            language: language,
            logoBytes: File('assets/images/brand_logo.png').readAsBytesSync(),
          );
          expect(String.fromCharCodes(bytes.take(4)), '%PDF');
          expect(bytes.length, greaterThan(1000));
          if (const bool.fromEnvironment('WRITE_INVOICE_SAMPLES')) {
            final dir = Directory('output/customer-invoice-20261127')
              ..createSync(recursive: true);
            File(
              '${dir.path}/mobile-invoice-$language-$count.pdf',
            ).writeAsBytesSync(bytes);
          }
        }
      },
    );
  }
  test(
    'draft cancelled and paid invoices render without routing to thermal',
    () async {
      for (final status in ['draft', 'cancelled', 'paid']) {
        final data = invoice(status: status);
        if (status == 'paid') {
          data['paid_amount'] = 111000;
          data['credited_amount'] = 0;
          data['outstanding_amount'] = 0;
        }
        final bytes = await PosCustomerInvoiceDocument.build(
          invoice: data,
          company: company,
        );
        expect(bytes, isNotEmpty);
      }
      final source = File(
        'lib/presentation/pages/pos/pos_order_page.dart',
      ).readAsStringSync();
      expect(source, contains('PosInvoiceSource.load'));
      expect(source, contains('Printing.sharePdf'));
      expect(source, contains('printDocumentPdf('));
    },
  );
}
