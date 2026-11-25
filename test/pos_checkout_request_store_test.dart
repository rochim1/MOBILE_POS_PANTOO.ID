import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/pos_checkout_request_store.dart';

class FlakyPreferences extends Fake implements SharedPreferences {
  final values = <String, String>{};
  bool rejectWrite = false;
  bool rejectRemove = false;
  bool loseWrite = false;
  @override
  String? getString(String key) => values[key];
  @override
  Future<bool> setString(String key, String value) async {
    if (rejectWrite) return false;
    if (!loseWrite) values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (rejectRemove) return false;
    values.remove(key);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late PosCheckoutRequestStore store;
  final input = <String, dynamic>{
    'toko_id': 'store',
    'tanggal': 'old',
    'metode_pembayaran': 'transfer',
    'operator_session_token': 'secret-token',
    'expired_sale_authorizer_pin': '123456',
    'items': [
      {'inventaris_id': 'p', 'qty': 1, 'unit': 'unit'},
    ],
  };
  final receipt = <String, dynamic>{
    'total': 100,
    'subtotal': 100,
    'manual_discount': 0,
    'tax': 0,
    'cash_received': 0,
    'receipt_items': [
      {'inventaris_id': 'p', 'qty': 1},
    ],
  };
  test('failed durable write never authorizes transmission', () async {
    final prefs = FlakyPreferences()..rejectWrite = true;
    await expectLater(
      PosCheckoutRequestStore(prefs, 's').begin(input, receipt),
      throwsStateError,
    );
  });
  for (final invalid in [
    'empty-items',
    'missing-store',
    'negative-total',
    'missing-subtotal',
  ]) {
    test(
      'invalid fresh $invalid cannot leave an unreadable payment fence',
      () async {
        final badInput = {...input};
        final badReceipt = {...receipt};
        if (invalid == 'empty-items') badInput['items'] = [];
        if (invalid == 'missing-store') badInput.remove('toko_id');
        if (invalid == 'negative-total') badReceipt['total'] = -1;
        if (invalid == 'missing-subtotal') badReceipt.remove('subtotal');
        await expectLater(store.begin(badInput, badReceipt), throwsStateError);
        expect(
          prefs.getString(store.key),
          isNull,
          reason:
              'Nothing was transmitted; invalid new data must not poison recovery',
        );
        final next = await store.begin(input, receipt);
        expect(store.load(), next);
      },
    );
  }
  test('write success without readable original ID is rejected', () async {
    final prefs = FlakyPreferences()..loseWrite = true;
    await expectLater(
      PosCheckoutRequestStore(prefs, 's').begin(input, receipt),
      throwsStateError,
    );
  });
  test(
    'failed acknowledgement preserves the original recovery record',
    () async {
      final prefs = FlakyPreferences();
      final store = PosCheckoutRequestStore(prefs, 's');
      final record = await store.begin(input, receipt);
      prefs.rejectRemove = true;
      await expectLater(
        store.acknowledge(
          (record['input'] as Map)['client_transaction_id'] as String,
        ),
        throwsStateError,
      );
      expect(store.load(), record);
    },
  );
  test(
    'partial receipt data fails closed before recovery UI or request',
    () async {
      await prefs.setString(
        store.key,
        jsonEncode({
          'input': {...input, 'client_transaction_id': 'valid-original-id-123'},
          'receipt': {},
        }),
      );
      expect(store.load, throwsStateError);
    },
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = PosCheckoutRequestStore(prefs, 'tenant:terminal:operator');
  });
  test(
    'write-ahead fence persists an ID, but never operator token or supervisor PIN',
    () async {
      final record = await store.begin(input, receipt);
      final raw = prefs.getString(store.key)!;
      expect(raw, isNot(contains('secret-token')));
      expect(raw, isNot(contains('123456')));
      expect((record['input'] as Map)['client_transaction_id'], isNotEmpty);
      expect(jsonDecode(raw), record);
    },
  );
  test('new process and map ordering retain original ID and date', () async {
    final first = await store.begin(input, receipt);
    final next = PosCheckoutRequestStore(prefs, store.scope);
    final recovered = await next.begin({
      ...input,
      'tanggal': 'new',
      'operator_session_token': 'new-token',
    }, Map.fromEntries(receipt.entries.toList().reversed));
    expect(recovered, first);
    expect((recovered['input'] as Map)['tanggal'], 'old');
  });
  test('different agreement cannot replace pending payment', () async {
    final before = await store.begin(input, receipt);
    await expectLater(
      store.begin({...input, 'toko_id': 'other'}, receipt),
      throwsStateError,
    );
    expect(store.load(), before);
  });
  test('only matching acknowledgement releases the fence', () async {
    final record = await store.begin(input, receipt);
    await store.acknowledge('foreign');
    expect(store.load(), isNotNull);
    await store.acknowledge(
      (record['input'] as Map)['client_transaction_id'] as String,
    );
    expect(store.load(), isNull);
    final next = await store.begin(input, receipt);
    expect(
      (next['input'] as Map)['client_transaction_id'],
      isNot((record['input'] as Map)['client_transaction_id']),
    );
  });
  test('tenant terminal operator and endpoint scopes are isolated', () async {
    await store.begin(input, receipt);
    expect(
      PosCheckoutRequestStore(prefs, 'other-tenant:terminal:operator').load(),
      isNull,
    );
    expect(
      PosCheckoutRequestStore(prefs, 'tenant:terminal:other').load(),
      isNull,
    );
    expect(
      PosCheckoutRequestStore(
        prefs,
        'other-endpoint:tenant:terminal:operator',
      ).load(),
      isNull,
    );
  });
  for (final raw in ['bad-json', '{}', '{"input":null,"receipt":{}}']) {
    test('corrupt local fence is never silently replaced: $raw', () async {
      await prefs.setString(store.key, raw);
      expect(store.load, throwsStateError);
      await expectLater(store.begin(input, receipt), throwsStateError);
      expect(prefs.getString(store.key), raw);
    });
  }
}
