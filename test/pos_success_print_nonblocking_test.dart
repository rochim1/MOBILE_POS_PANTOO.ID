import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_success_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
