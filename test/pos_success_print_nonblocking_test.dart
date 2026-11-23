import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_success_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final method in [
    'qris',
    'transfer',
    'debit',
    'e_wallet',
    'kartu_kredit',
    'credit_card',
    'split',
    'tunai',
    'cash',
    'tempo',
  ]) {
    testWidgets('success shows the correct received amount for $method', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      addTearDown(() async {
        await sl.reset();
      });
      final cash = method == 'cash' || method == 'tunai';
      final credit = method == 'tempo';
      final transaction = PosTransactionResult(
        id: 'payment-$method',
        invoice: 'QA-001',
        subtotal: 1000,
        discount: 0,
        promoDiscount: 0,
        tax: 0,
        total: 1000,
        cashReceived: cash
            ? 2000
            : method == 'split'
            ? 400
            : 0,
        change: cash ? 1000 : 0,
        paymentMethod: method,
      );
      await tester.pumpWidget(
        MaterialApp(locale: const Locale('en'), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: PosSuccessPage(transaction: transaction)),
      );
      await tester.pumpAndSettle();
      final label = find.text(switch (method) {
        'cash' || 'tunai' => 'Cash',
        'qris' => 'QRIS',
        'transfer' => 'Transfer',
        'debit' => 'Debit Card',
        'e_wallet' => 'E-Wallet',
        'kartu_kredit' || 'credit_card' => 'Credit Card',
        'split' => 'Split Payment',
        'tempo' => 'Credit / Receivables',
        _ => throw StateError('missing test label'),
      });
      final row = find.ancestor(of: label, matching: find.byType(Row)).first;
      expect(
        find.descendant(
          of: row,
          matching: find.text(
            cash
                ? 'Rp2.000'
                : credit
                ? 'Rp0'
                : 'Rp1.000',
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('auto print tanpa printer tidak menahan halaman sukses', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() async {
      await sl.reset();
    });
    SharedPreferences.setMockInitialValues({});
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    const transaction = PosTransactionResult(
      id: 'sale-1',
      invoice: 'POS-001',
      subtotal: 10000,
      discount: 0,
      promoDiscount: 0,
      tax: 0,
      total: 10000,
      cashReceived: 10000,
      change: 0,
      paymentMethod: 'cash',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const PosSuccessPage(
                    transaction: transaction,
                    autoPrint: true,
                  ),
                ),
              ),
              child: const Text('Buka hasil'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka hasil'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Struk belum dicetak'), findsOneWidget);
    expect(find.text('Mencetak struk…'), findsNothing);
    await tester.ensureVisible(find.text('Selesai'));
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Buka hasil'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
}
