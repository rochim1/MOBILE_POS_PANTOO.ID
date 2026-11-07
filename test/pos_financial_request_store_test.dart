import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'invalid persisted receipts fail closed without replacing the original proof',
    () async {
      for (final raw in [
        '{"request_id":"","amount":4000}',
        '{"request_id":"qa","amount":-1}',
        '{"request_id":"qa","amount":0.5}',
        '{"request_id":"qa","amount":0}',
        '{"request_id":"qa","amount":4000,"invoice_id":"other"}',
      ]) {
        SharedPreferences.setMockInitialValues({
          'pos_financial_pending_v1:qa:invoice': raw,
        });
        final prefs = await SharedPreferences.getInstance();
        final store = PosFinancialRequestStore(prefs, 'qa');
        await expectLater(
          store.begin('invoice', {'amount': 4000}),
          throwsStateError,
        );
        expect(prefs.getString('pos_financial_pending_v1:qa:invoice'), raw);
      }
    },
  );
  test(
    'unacknowledged receipt survives recreation, freezes payload and isolates cashier/tenant',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PosFinancialRequestStore(prefs, 'tenant:cashier');
      final first = await store.begin('invoice', {
        'amount': 4000,
        'reference': 'QA',
      });
      final recovered = PosFinancialRequestStore(prefs, 'tenant:cashier');
      expect(recovered.load('invoice'), first);
      expect(recovered.pendingInvoiceIds, ['invoice']);
      expect(
        (await recovered.begin('invoice', {'amount': 6000}))['amount'],
        4000,
      );
      expect(
        PosFinancialRequestStore(prefs, 'other:cashier').load('invoice'),
        isNull,
      );
      expect(
        PosFinancialRequestStore(prefs, 'tenant:other').load('invoice'),
        isNull,
      );
      await recovered.acknowledge('invoice');
      expect(recovered.load('invoice'), isNull);
      expect(recovered.pendingInvoiceIds, isEmpty);
      expect(
        (await recovered.begin('invoice', {'amount': 6000}))['request_id'],
        isNot(first['request_id']),
      );
    },
  );
  test(
    'corrupt pending financial data blocks a new payment, never silently replaces it',
    () async {
      SharedPreferences.setMockInitialValues({
        'pos_financial_pending_v1:tenant:cashier:invoice': 'invalid',
      });
      final store = PosFinancialRequestStore(
        await SharedPreferences.getInstance(),
        'tenant:cashier',
      );
      expect(() => store.load('invoice'), throwsStateError);
      await expectLater(
        store.begin('invoice', {'amount': 4000}),
        throwsStateError,
      );
    },
  );
}
