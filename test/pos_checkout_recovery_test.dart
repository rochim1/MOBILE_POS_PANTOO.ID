import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_local_database.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';

class Provider extends Fake implements GraphQLClientProvider {
  Provider(this.client);
  @override
  final GraphQLClient client;
  @override
  String get endpointUrl => 'https://qa.invalid/graphql';
  @override
  Future<String?> checkOfflineSubscription() async => null;
}
const product = PosProduct(id: 'p', code: 'P', name: 'Product', price: 100, stock: 10, category: 'QA');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late Database db;
  var network = 'wifi';
  setUpAll(() async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('pantoo-checkout-recovery-');
    await databaseFactoryFfi.setDatabasesPath(dir.path);
    db = await PosLocalDatabase.instance.database;
  });
  tearDownAll(() => PosLocalDatabase.instance.close());
  setUp(() async {
    SharedPreferences.setMockInitialValues({'instansi_id': 'tenant', 'user_id': 'terminal'});
    prefs = await SharedPreferences.getInstance();
    network = 'wifi';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => [network]);
    await db.delete('offline_transactions');
    await db.delete('products');
    await db.delete('stores');
    await db.delete('read_snapshots');
  });
  Future<dynamic> pay(PosRepository repo, {double cash = 100, String method = 'transfer'}) =>
    repo.submitTransaction(cart: {product: 1}, total: 100, paymentMethod: method,
      tokoId: 's', shiftId: 'shift', cashReceived: cash);

  test('lost ACK survives repository restart and retries the original transaction ID', () async {
    final ids = <String>[];
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
      final input = request.variables['input'] as Map;
      ids.add(input['client_transaction_id'] as String);
      if (ids.length == 1) throw ServerException(originalException: Exception('lost ACK after commit'));
      yield Response(data: {'ProcessPOSPenjualan': {'_id': 'tx', 'invoice': 'INV',
        'client_transaction_id': ids.first, 'total': 100, 'subtotal': 100}}, response: {});
    }));
    expect((await pay(PosRepository(Provider(client), prefs))).isLeft(), true);
    expect((await pay(PosRepository(Provider(client), prefs))).isRight(), true);
    expect(ids, hasLength(2));
    expect(ids[1], ids[0], reason: 'Retry must not create a second financial intent');
  });

  test('changed cash cannot silently replace an unresolved transaction', () async {
    var writes = 0;
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
      writes++;
      throw ServerException(originalException: Exception('lost ACK'));
    }));
    final repo = PosRepository(Provider(client), prefs);
    await pay(repo);
    await pay(repo, cash: 200);
    expect(writes, 1, reason: 'Resolve the original intent before changing payment details');
  });

  test('offline receipt preserves pre-discount subtotal and queues only once', () async {
    network = 'none';
    await db.insert('stores', {'id': 's', 'name': 'Store', 'branchId': 'b', 'status': 'active',
      'address': '', 'phone': '', 'branchName': 'Branch'});
    await db.insert('products', {'id': 'p', 'code': 'P', 'name': 'Product', 'price': 100, 'stock': 10,
      'category': 'QA', 'product_json': jsonEncode(product.toJson())});
    await db.insert('read_snapshots', {'scope_key': 'pos_active_product_catalog_v1',
      'payload': jsonEncode({'catalog_key': 'pos_product_catalog_v1:tenant:terminal:b'}),
      'cached_at': DateTime.now().toUtc().toIso8601String()});
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
      throw StateError('No network call while offline');
    }));
    final result = await PosRepository(Provider(client), prefs).submitTransaction(cart: {product: 1},
      receiptUnitPrices: {'p': 100}, total: 95, paymentMethod: 'tunai',
      tokoId: 's', shiftId: 'shift', cashReceived: 100, diskon: 10, pajak: 5);
    expect(result.isRight(), true, reason: result.toString());
    result.fold((_) {}, (tx) {
      expect(tx.subtotal, 100);
      expect(tx.subtotal - tx.discount + tx.tax, tx.total);
      expect(tx.total, 95);
      expect(tx.change, 5);
    });
    expect(await db.query('offline_transactions'), hasLength(1));
  });
}
