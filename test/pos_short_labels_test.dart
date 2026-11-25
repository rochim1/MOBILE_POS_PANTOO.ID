import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_success_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_order_age.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_thermal_document.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_payment_connection_badge.dart';

Widget localized(Widget child, {String code = 'en'}) => MaterialApp(
  locale: Locale(code),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
    await AppLanguageController.instance.select('en');
  });
  tearDown(() async {
    await AppLanguageController.instance.select('id');
  });

  test(
    'thermal purchasing labels translate while custom text stays intact',
    () {
      final text = PosPurchaseThermalDocument.paymentProof(
        payable: {
          'no_po': 'PO-1',
          'supplier_name': 'Detail',
          'outstanding_amount': 5000,
        },
        payment: {
          'status': 'active',
          'amount': 10000,
          'payment_date': '2026-11-10',
          'payment_method': 'cash',
          'reference_number': 'REF-1',
          'notes': 'Catatan asli',
        },
        company: {},
        charactersPerLine: 32,
      );
      expect(text, startsWith('BUYER\n'));
      expect(text, contains('PAID'));
      expect(text, isNot(contains('DIBAYAR')));
      expect(text, isNot(contains('BUKTI PENCATATAN')));
      expect(text, contains('Detail'));
      expect(text, contains('Reference: REF-1'));
      expect(text, contains('Notes: Catatan asli'));
      expect(text, contains('Rp 10.000'));
      final po = PosPurchaseThermalDocument.purchaseOrder(
        purchase: {
          'no_po': 'PO-1',
          'supplier_name': 'Detail',
          'alamat_pengiriman': 'Jalan Ringkasan',
          'biaya_tambahan': [
            {'deskripsi': 'Alasan', 'nominal': 2000},
          ],
          'total_amount': 10000,
          'grand_total': 12000,
        },
        company: {'nama_instansi': 'Dibuat'},
        charactersPerLine: 32,
      );
      expect(po, startsWith('Dibuat\n'));
      expect(po, contains('Address: Jalan Ringkasan'));
      expect(po, contains('Alasan'));
    },
  );

  testWidgets('stock in and out keep their stock meaning and API codes', (
    tester,
  ) async {
    const codes = ['masuk', 'keluar', 'penyesuaian', 'retur'];
    for (final code in ['en', 'id']) {
      await tester.pumpWidget(
        localized(
          Builder(
            builder: (context) => Column(
              children: [
                for (final value in codes)
                  Text(posStockMovementLabel(value, context)),
              ],
            ),
          ),
          code: code,
        ),
      );
      await tester.pumpAndSettle();
      for (final text
          in code == 'en'
              ? ['Stock In', 'Stock Out', 'Adjustment', 'Returns']
              : ['Masuk', 'Keluar', 'Koreksi', 'Retur']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Sign Out'), findsNothing);
    }
    expect(codes, ['masuk', 'keluar', 'penyesuaian', 'retur']);
  });

  testWidgets('composed age tooltip translates its phase without changing it', (
    tester,
  ) async {
    const age = PosOrderAge('Menunggu dapur', 5, PosOrderAgeTone.normal);
    await tester.pumpWidget(
      localized(Builder(builder: (context) => Text(age.labelFor(context)))),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Awaiting kitchen'), findsOneWidget);
    expect(find.textContaining('Menunggu dapur'), findsNothing);
    expect(age.phase, 'Menunggu dapur');
  });

  testWidgets('payment badge translates checking and connected states', (
    tester,
  ) async {
    final reading = Completer<List<ConnectivityResult>>();
    await tester.pumpWidget(
      localized(
        PosPaymentConnectionBadge(
          changes: const Stream<List<ConnectivityResult>>.empty(),
          readConnectivity: () => reading.future,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget);
    expect(find.byTooltip('Device connection status unknown.'), findsOneWidget);
    reading.complete([ConnectivityResult.wifi]);
    await tester.pumpAndSettle();
    expect(find.text('Connected'), findsOneWidget);
  });

  testWidgets('shared receipt text is English and preserves names and amounts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Uri? destination;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'launch') {
        destination = Uri.parse((call.arguments as Map)['url'] as String);
      }
      return true; // Simulates the destination; never opens or sends externally.
    });
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    addTearDown(() async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      await sl.reset();
    });
    const transaction = PosTransactionResult(
      id: 'sale-1',
      invoice: 'POS-001',
      subtotal: 10000,
      discount: 0,
      promoDiscount: 0,
      tax: 0,
      total: 10000,
      cashReceived: 15000,
      change: 5000,
      paymentMethod: 'cash',
      cashierName: 'Simpan',
      customerName: 'Bayar',
      customerPhone: '08123456789',
      transactionReference: 'REF-001',
      note: 'Catatan asli',
      items: [
        {'name': 'Detail', 'qty': 1, 'subtotal': 10000},
      ],
    );
    await tester.pumpWidget(
      localized(const PosSuccessPage(transaction: transaction)),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Share Receipt'));
    await tester.tap(find.text('Share Receipt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp as text'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    final text = destination!.queryParameters['text']!;
    expect(text, contains('Receipt POS-001'));
    expect(text, contains('Cashier: Simpan'));
    expect(text, contains('Customer: Bayar'));
    expect(text, isNot(contains('Reference: REF-001')));
    expect(text, contains('Detail x1'));
    expect(text, contains('Rp10.000'));
    expect(text, contains('Notes: Catatan asli'));
    expect(text, endsWith('Thank you.'));
    expect(tester.takeException(), isNull);
  });
}
