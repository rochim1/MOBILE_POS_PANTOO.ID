import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/receipt/pos_receipt_print_service.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_customer_invoice_document.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_invoice_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final company = {
    'nama_instansi': 'QA Invoice Audit',
    'alamat': 'Jl. Pengujian 1',
  };
  Map<String, dynamic> invoice({
    int paid = 30000,
    int credit = 20000,
    int due = 50000,
    String status = 'partial',
  }) => {
    '_id': 'ar-1',
    'invoice_number': 'INV-AUDIT',
    'invoice_date': '2026-11-27',
    'due_date': '2026-12-04',
    'customer_name': 'Pelanggan QA',
    'status': status,
    'total_amount': 100000,
    'net_amount': 100000,
    'tax_amount': 0,
    'paid_amount': paid,
    'credited_amount': credit,
    'outstanding_amount': due,
    'lines': [
      {
        'description': 'Layanan harga fleksibel',
        'quantity': 1,
        'unit_price': 100000,
        'line_net': 100000,
      },
    ],
  };
  PosOrder sale({String? finance}) => PosOrder.fromJson({
    '_id': 'sale-1',
    'invoice': 'POS-OLD',
    'total': 999,
    'sales_invoice_id': finance,
  });
  test(
    'legacy source reloaded by ID and newly linked Finance is authoritative',
    () async {
      final calls = <String>[];
      final result = await PosInvoiceSource.load(sale(), (
        query,
        variables,
      ) async {
        if (query.contains('GetPOSPenjualan')) {
          calls.add('sale');
          return {
            'GetPOSPenjualan': {
              'items': [
                {'_id': 'other', 'total': 1},
                {'_id': 'sale-1', 'sales_invoice_id': 'ar-1'},
              ],
            },
          };
        }
        calls.add(variables['_id']);
        return {'GetPOSReceivable': invoice()};
      });
      expect(calls, ['sale', 'ar-1']);
      expect(result['outstanding_amount'], 50000);
    },
  );
  test('canonical error and wrong ID never use cached amounts', () async {
    await expectLater(
      PosInvoiceSource.load(
        sale(finance: 'ar-1'),
        (q, v) async => {
          'GetPOSReceivable': {...invoice(), '_id': 'other'},
        },
      ),
      throwsStateError,
    );
    await expectLater(
      PosInvoiceSource.load(
        sale(finance: 'ar-1'),
        (q, v) async => throw StateError('offline'),
      ),
      throwsStateError,
    );
    await expectLater(
      PosInvoiceSource.load(
        sale(),
        (q, v) async => {
          'GetPOSPenjualan': {
            'items': [
              {'_id': 'other'},
            ],
          },
        },
      ),
      throwsStateError,
    );
  });
  test(
    'pending order refreshes current price and refuses converted or cancelled order',
    () async {
      final pending = PosOrder.fromPendingOrderJson({
        '_id': 'order-1',
        'order_no': 'ORDER-1',
        'grand_total': 999,
      });
      final raw = {
        '_id': 'order-1',
        'order_no': 'ORDER-1',
        'grand_total': 50000,
        'status_pembayaran': 'belum_bayar',
        'status': 'Baru',
      };
      final loaded = await PosInvoiceSource.load(
        pending,
        (q, v) async => {'GetOnePOSOrder': raw},
      );
      expect(loaded['total_amount'], 50000);
      expect(loaded['pending_order'], true);
      for (final extra in [
        {'status_pembayaran': 'lunas'},
        {'pos_transaction_id': 'sale-1'},
        {'status': 'Batal'},
      ]) {
        await expectLater(
          PosInvoiceSource.load(
            pending,
            (q, v) async => {
              'GetOnePOSOrder': {...raw, ...extra},
            },
          ),
          throwsStateError,
        );
      }
    },
  );
  for (final values in [
    [0, 0, 100000, 'issued'],
    [30000, 0, 70000, 'partial'],
    [30000, 20000, 50000, 'partial'],
    [30000, 70000, 0, 'paid'],
    [100000, 0, 0, 'paid'],
    [0, 100000, 0, 'credited'],
  ]) {
    test(
      'confirmed settlement renders after installment/return $values',
      () async {
        final data = invoice(
          paid: values[0] as int,
          credit: values[1] as int,
          due: values[2] as int,
          status: values[3] as String,
        );
        PosCustomerInvoiceDocument.validateBalance(data);
        final bytes = await PosCustomerInvoiceDocument.build(
          invoice: data,
          company: company,
        );
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
        if (const bool.fromEnvironment('WRITE_INVOICE_SAMPLES')) {
          final dir = Directory('output/customer-invoice-audit-20261127')
            ..createSync(recursive: true);
          File(
            '${dir.path}/invoice-${values[0]}-${values[1]}-${values[2]}.pdf',
          ).writeAsBytesSync(bytes);
        }
      },
    );
  }
  for (final invalid in [
    {'outstanding_amount': 50001},
    {'outstanding_amount': -1},
    {'paid_amount': 'abc'},
    {'paid_amount': double.nan},
    {'paid_amount': double.infinity},
    {'status': 'paid'},
  ]) {
    test('invalid invoice cannot be printed or shared: $invalid', () async {
      await expectLater(
        PosCustomerInvoiceDocument.build(
          invoice: {...invoice(), ...invalid},
          company: company,
        ),
        throwsStateError,
      );
    });
  }
  for (final cancelled in [false, true]) {
    testWidgets(
      'A4 print and share deliver identical invoice PDF; cancelled=$cancelled',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        SharedPreferences.setMockInitialValues({
          'pos.receipt_bluetooth_address': 'thermal-must-not-be-used',
        });
        final prefs = await SharedPreferences.getInstance();
        final bytes = await PosCustomerInvoiceDocument.build(
          invoice: invoice(),
          company: company,
        );
        const channel = MethodChannel('net.nfet.printing');
        const codec = StandardMethodCodec();
        final received = <String, Uint8List>{};
        Future<dynamic> nativeCall(
          String method,
          Map<String, dynamic> args,
        ) async {
          final done = Completer<ByteData?>();
          ServicesBinding.instance.channelBuffers.push(
            'net.nfet.printing',
            codec.encodeMethodCall(MethodCall(method, args)),
            done.complete,
          );
          return codec.decodeEnvelope((await done.future)!);
        }

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            final args = Map<String, dynamic>.from(call.arguments);
            if (call.method == 'sharePdf') {
              received['share'] = args['doc'];
              expect(args['name'], 'Invoice-AUDIT.pdf');
              return cancelled ? 0 : 1;
            }
            if (call.method == 'printPdf') {
              expect(args['printer'], isNull);
              expect(args['width'], closeTo(PdfPageFormat.a4.width, .01));
              received['print'] = await nativeCall('onLayout', {
                'job': args['job'],
                'width': args['width'],
                'height': args['height'],
                'marginLeft': 0.0,
                'marginRight': 0.0,
                'marginTop': 0.0,
                'marginBottom': 0.0,
              });
              await nativeCall('onCompleted', {
                'job': args['job'],
                'completed': !cancelled,
              });
              return 1;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await tester.runAsync(() async {
          expect(
            await PosReceiptPrintService(
              prefs,
            ).printDocumentPdf(bytes: bytes, name: 'Invoice-AUDIT.pdf'),
            !cancelled,
          );
          expect(
            await Printing.sharePdf(
              bytes: bytes,
              filename: 'Invoice-AUDIT.pdf',
            ),
            !cancelled,
          );
        });
        expect(received['share'], orderedEquals(bytes));
        expect(received['print'], orderedEquals(bytes));
        expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
