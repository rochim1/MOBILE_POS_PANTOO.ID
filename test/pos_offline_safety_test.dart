import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_pos_pantoo/core/network/pos_operator_identity.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_offline_pin_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_offline_stock.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';

PosProduct product(
  String id, {
  double stock = 20,
  bool tracksStock = true,
  List<Map<String, dynamic>> components = const [],
}) => PosProduct(
  id: id,
  code: id,
  name: id,
  category: '',
  price: 1000,
  stock: stock,
  tracksStock: tracksStock,
  packageComponents: components,
  unitConversions: const [
    {'unit': 'box', 'factor': 12},
  ],
);
Map<String, dynamic> item(String id, double qty, [String unit = 'unit']) => {
  'inventaris_id': id,
  'qty': qty,
  'unit': unit,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('profile with stock tracking disabled does not decrement stock', () {
    expect(
      offlineStockConsumption(
        {'a': product('a', stock: 0)},
        [item('a', 2)],
        trackStock: false,
      ),
      isEmpty,
    );
  });
  test(
    'offline operator marker retains identity but is not a server token',
    () {
      expect(operatorIdFromToken('offline_operator:cashier-a'), 'cashier-a');
      expect(operatorTokenIsCurrent('offline_operator:cashier-a'), isFalse);
      expect(operatorIdFromToken('invalid'), '');
    },
  );
  test('expired operator JWT requires verification again', () {
    final now = DateTime.utc(2026, 9, 24);
    String token(int seconds) =>
        'header.${base64Url.encode(utf8.encode(jsonEncode({'type': 'pos_operator', 'user_id': 'a', 'exp': now.millisecondsSinceEpoch ~/ 1000 + seconds})))}.signature';
    expect(operatorTokenIsCurrent(token(-1), now: now), isFalse);
    expect(operatorTokenIsCurrent(token(300), now: now), isTrue);
  });
  test('sync cannot replace an offline cashier with a different cashier', () {
    String token(String id) =>
        'header.${base64Url.encode(utf8.encode(jsonEncode({'type': 'pos_operator', 'user_id': id, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})))}.signature';
    final sameCashier = token('a');
    expect(
      operatorTokenForSync('offline_operator:a', sameCashier),
      sameCashier,
    );
    expect(operatorTokenForSync('offline_operator:a', token('b')), isNull);
    expect(operatorTokenForSync('offline_operator:a', ''), isNull);
  });
  test('offline stock uses base units and sums shared ingredients', () {
    final catalog = {
      'a': product('a', stock: 50),
      'b': product(
        'b',
        components: [
          {'inventaris_id': 'a', 'qty_base': 2},
        ],
      ),
    };
    expect(
      offlineStockConsumption(catalog, [item('a', 1, 'box'), item('b', 3)]),
      {'a': 18.0},
    );
  });
  test('nested bundle with BOM consumes leaves, not parent stock', () {
    final catalog = {
      'a': product('a'),
      'b': product(
        'b',
        components: [
          {'inventaris_id': 'a', 'qty_base': 2},
        ],
      ),
      'c': product(
        'c',
        components: [
          {'inventaris_id': 'b', 'qty_base': 3},
        ],
      ),
    };
    expect(offlineStockConsumption(catalog, [item('c', 2)]), {'a': 12.0});
  });
  test(
    'missing ingredients, cycles, unknown units and insufficient stock stop safely',
    () {
      expect(
        () => offlineStockConsumption(
          {
            'b': product(
              'b',
              components: [
                {'inventaris_id': 'x', 'qty_base': 1},
              ],
            ),
          },
          [item('b', 1)],
        ),
        throwsStateError,
      );
      expect(
        () => offlineStockConsumption(
          {
            'b': product(
              'b',
              components: [
                {'inventaris_id': 'b', 'qty_base': 1},
              ],
            ),
          },
          [item('b', 1)],
        ),
        throwsStateError,
      );
      expect(
        () => offlineStockConsumption(
          {'a': product('a')},
          [item('a', 1, 'missing')],
        ),
        throwsStateError,
      );
      expect(
        () => offlineStockConsumption(
          {'a': product('a', stock: 1)},
          [item('a', 2)],
        ),
        throwsStateError,
      );
    },
  );
  test('non-stock service does not decrement stock', () {
    expect(
      offlineStockConsumption(
        {'s': product('s', stock: 0, tracksStock: false)},
        [item('s', 2)],
      ),
      isEmpty,
    );
  });
  group('offline PIN cache', () {
    late DateTime now;
    late PosOfflinePinStore store;
    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      now = DateTime.utc(2026, 9, 24);
      store = PosOfflinePinStore(scope: 'tenant', clock: () => now);
      await store.cacheVerifiedPin(
        userId: 'a',
        pin: '123456',
        response: {'name': 'A'},
      );
    });
    test('expires after seven days and rejects clock rollback', () async {
      expect((await store.verify('a', '123456'))?['success'], isTrue);
      now = now.add(const Duration(days: 8));
      expect(await store.verify('a', '123456'), isNull);
      expect(await store.employees(), isEmpty);
      now = DateTime.utc(2026, 9, 23);
      expect(await store.verify('a', '123456'), isNull);
    });
    test(
      'removed PIN and removed operator invalidate cached credential',
      () async {
        await store.cacheEmployees([
          {'_id': 'a', 'has_pin': false},
        ]);
        expect(await store.verify('a', '123456'), isNull);
        await store.cacheVerifiedPin(userId: 'a', pin: '123456', response: {});
        await store.cacheEmployees([], completeRoster: true);
        expect(await store.verify('a', '123456'), isNull);
      },
    );
    test('partial search results do not revoke unrelated operators', () async {
      await store.cacheEmployees([]);
      expect((await store.verify('a', '123456'))?['success'], isTrue);
    });
    test(
      'five wrong attempts lock even a correct PIN for fifteen minutes',
      () async {
        for (var i = 0; i < 5; i++) {
          await store.verify('a', '000000');
        }
        expect((await store.verify('a', '123456'))?['success'], isFalse);
        now = now.add(const Duration(minutes: 16));
        expect((await store.verify('a', '123456'))?['success'], isTrue);
      },
    );
  });
}
