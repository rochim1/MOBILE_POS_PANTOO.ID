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

const product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'Product',
  price: 100,
  stock: 10,
  category: 'QA',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late Database db;
  var network = 'wifi';
  setUpAll(() async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp(
      'pantoo-checkout-recovery-',
    );
    await databaseFactoryFfi.setDatabasesPath(dir.path);
    db = await PosLocalDatabase.instance.database;
  });
  tearDownAll(() => PosLocalDatabase.instance.close());
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'terminal',
    });
    prefs = await SharedPreferences.getInstance();
    network = 'wifi';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => [network],
        );
    await db.delete('offline_transactions');
    await db.delete('products');
    await db.delete('stores');
    await db.delete('read_snapshots');
  });
  Future<dynamic> pay(
    PosRepository repo, {
    double cash = 100,
    String method = 'transfer',
  }) => repo.submitTransaction(
    cart: {product: 1},
    total: 100,
    paymentMethod: method,
    tokoId: 's',
    shiftId: 'shift',
    cashReceived: cash,
  );

  test(
    'lost ACK survives repository restart and retries the original transaction ID',
    () async {
      final ids = <String>[];
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          final input = request.variables['input'] as Map;
          ids.add(input['client_transaction_id'] as String);
          if (ids.length == 1) {
            throw ServerException(
              originalException: Exception('lost ACK after commit'),
            );
          }
          yield Response(
            data: {
              'ProcessPOSPenjualan': {
                '_id': 'tx',
                'invoice': 'INV',
                'client_transaction_id': ids.first,
                'total': 100,
                'subtotal': 100,
              },
            },
            response: {},
          );
        }),
      );
      expect(
        (await pay(PosRepository(Provider(client), prefs))).isLeft(),
        true,
      );
      expect(
        (await pay(PosRepository(Provider(client), prefs))).isRight(),
        true,
      );
      expect(ids, hasLength(2));
      expect(
        ids[1],
        ids[0],
        reason: 'Retry must not create a second financial intent',
      );
    },
  );

  test(
    'changed cash cannot silently replace an unresolved transaction',
    () async {
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          throw ServerException(originalException: Exception('lost ACK'));
        }),
      );
      final repo = PosRepository(Provider(client), prefs);
      await pay(repo);
      await pay(repo, cash: 200);
      expect(
        writes,
        1,
        reason: 'Resolve the original intent before changing payment details',
      );
    },
  );

  test(
    'explicit recovery works without cart and releases the fence only on matching ACK',
    () async {
      var writes = 0;
      String? original;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          final input = request.variables['input'] as Map;
          original ??= input['client_transaction_id'] as String;
          expect(input['client_transaction_id'], original);
          if (writes == 1) {
            throw ServerException(originalException: Exception('lost ACK'));
          }
          yield Response(
            data: {
              'ProcessPOSPenjualan': {
                '_id': 'tx',
                'invoice': 'INV',
                'client_transaction_id': original,
                'total': 100,
                'subtotal': 100,
              },
            },
            response: {},
          );
        }),
      );
      await pay(PosRepository(Provider(client), prefs));
      final restarted = PosRepository(Provider(client), prefs);
      expect(restarted.pendingCheckout, isNotNull);
      final result = await restarted.recoverPendingCheckout();
      expect(result.isRight(), true);
      expect(restarted.pendingCheckout, isNull);
      expect((await restarted.recoverPendingCheckout()).isLeft(), true);
      expect(writes, 2);
    },
  );

  for (final code in ['BAD_REQUEST', 'FORBIDDEN', 'SUBSCRIPTION_REQUIRED']) {
    test(
      'first definite rejection $code releases its fence for correction',
      () async {
        final ids = <String>[];
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            ids.add(
              (request.variables['input'] as Map)['client_transaction_id']
                  as String,
            );
            yield Response(
              data: const {'__typename': 'Mutation'},
              errors: [
                GraphQLError(message: 'QA denied', extensions: {'code': code}),
              ],
              response: {},
            );
          }),
        );
        final repo = PosRepository(Provider(client), prefs);
        await pay(repo);
        expect(repo.pendingCheckout, isNull);
        await pay(repo, cash: 200);
        expect(ids, hasLength(2));
        expect(ids.first, isNot(ids.last));
      },
    );
  }
  for (final scenario in [
    'wrong-ack',
    'invalid-response',
    'replay-forbidden',
    'internal-error',
  ]) {
    test('ambiguous $scenario never releases the pending fence', () async {
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          if (writes == 1) {
            throw ServerException(originalException: Exception('lost ACK'));
          }
          if (scenario == 'wrong-ack') {
            yield Response(
              data: {
                'ProcessPOSPenjualan': {
                  '_id': 'tx',
                  'invoice': 'INV',
                  'client_transaction_id': 'foreign',
                },
              },
              response: {},
            );
          } else if (scenario == 'invalid-response') {
            yield Response(
              data: const {'ProcessPOSPenjualan': null},
              response: {},
            );
          } else {
            yield Response(
              data: const {'__typename': 'Mutation'},
              errors: [
                GraphQLError(
                  message: 'QA denied',
                  extensions: {
                    'code': scenario == 'replay-forbidden'
                        ? 'FORBIDDEN'
                        : 'INTERNAL_SERVER_ERROR',
                  },
                ),
              ],
              response: {},
            );
          }
        }),
      );
      final repo = PosRepository(Provider(client), prefs);
      await pay(repo);
      final original = repo.pendingCheckout;
      expect((await repo.recoverPendingCheckout()).isLeft(), true);
      expect(repo.pendingCheckout, original);
    });
  }
  test(
    'a response from previous tenant cannot acknowledge or reveal its payment to new tenant',
    () async {
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          final id =
              (request.variables['input'] as Map)['client_transaction_id'];
          await prefs.setString('instansi_id', 'other');
          yield Response(
            data: {
              'ProcessPOSPenjualan': {
                '_id': 'tx',
                'invoice': 'INV',
                'client_transaction_id': id,
              },
            },
            response: {},
          );
        }),
      );
      final repo = PosRepository(Provider(client), prefs);
      expect((await pay(repo)).isLeft(), true);
      expect(repo.pendingCheckout, isNull);
      await prefs.setString('instansi_id', 'tenant');
      expect(repo.pendingCheckout, isNotNull);
    },
  );

  test(
    'offline recovery explains the connection problem and keeps the same proof',
    () async {
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          throw ServerException(originalException: Exception('lost ACK'));
        }),
      );
      final repo = PosRepository(Provider(client), prefs);
      await pay(repo);
      final original = repo.pendingCheckout!;
      network = 'none';
      final result = await repo.recoverPendingCheckout();
      expect(
        result.fold((failure) => failure.message, (_) => ''),
        contains('koneksi internet'),
      );
      expect(repo.pendingCheckout, original);
      expect(writes, 1);
    },
  );

  test(
    'recovery shows server denial without discarding uncertain original payment',
    () async {
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          if (++writes == 1)
            throw ServerException(originalException: Exception('lost ACK'));
          yield Response(
            data: const {'__typename': 'Mutation'},
            errors: [
              GraphQLError(
                message: 'QA operator permission revoked',
                extensions: const {'code': 'FORBIDDEN'},
              ),
            ],
            response: {},
          );
        }),
      );
      final repo = PosRepository(Provider(client), prefs);
      await pay(repo);
      final original = repo.pendingCheckout!;
      final result = await repo.recoverPendingCheckout();
      expect(
        result.fold((failure) => failure.message, (_) => ''),
        'QA operator permission revoked',
      );
      expect(repo.pendingCheckout, original);
      expect(writes, 2);
    },
  );

  for (final startsOffline in [true, false]) {
    test(
      'offline receipt preserves subtotal (startsOffline=$startsOffline)',
      () async {
        network = startsOffline ? 'none' : 'wifi';
        await db.insert('stores', {
          'id': 's',
          'name': 'Store',
          'branchId': 'b',
          'status': 'active',
          'address': '',
          'phone': '',
          'branchName': 'Branch',
        });
        await db.insert('products', {
          'id': 'p',
          'code': 'P',
          'name': 'Product',
          'price': 100,
          'stock': 10,
          'category': 'QA',
          'product_json': jsonEncode(product.toJson()),
        });
        await db.insert('read_snapshots', {
          'scope_key': 'pos_active_product_catalog_v1',
          'payload': jsonEncode({
            'catalog_key': 'pos_product_catalog_v1:tenant:terminal:b',
          }),
          'cached_at': DateTime.now().toUtc().toIso8601String(),
        });
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            if (startsOffline) {
              throw StateError('No network call while offline');
            }
            throw ServerException(originalException: Exception('lost ACK'));
          }),
        );
        final result = await PosRepository(Provider(client), prefs)
            .submitTransaction(
              cart: {product: 1},
              receiptUnitPrices: {'p': 100},
              total: 95,
              paymentMethod: 'tunai',
              tokoId: 's',
              shiftId: 'shift',
              cashReceived: 100,
              diskon: 10,
              pajak: 5,
            );
        expect(result.isRight(), true, reason: result.toString());
        result.fold((_) {}, (tx) {
          expect(tx.subtotal, 100);
          expect(tx.subtotal - tx.discount + tx.tax, tx.total);
          expect(tx.total, 95);
          expect(tx.change, 5);
        });
        expect(await db.query('offline_transactions'), hasLength(1));
      },
    );
  }
}
