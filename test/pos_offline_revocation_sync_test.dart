import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_local_database.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';

class _Provider implements GraphQLClientProvider {
  _Provider(this.client, this.sharedPreferences);
  @override
  String endpointUrl = 'https://qa.invalid/graphql';
  @override
  String resolveMediaUrl(dynamic value) => '';
  @override
  final GraphQLClient client;
  @override
  final SharedPreferences sharedPreferences;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String token(String actor) {
  final body = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'type': 'pos_operator',
        'user_id': actor,
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
      }),
    ),
  );
  return 'qa.$body.unsigned-test-only';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late SharedPreferences prefs;
  setUpAll(() async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp(
      'pantoo-sync-revocation-',
    );
    await databaseFactoryFfi.setDatabasesPath(dir.path);
    db = await PosLocalDatabase.instance.database;
  });
  tearDownAll(() => PosLocalDatabase.instance.close());
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-qa',
      'user_id': 'terminal-qa',
    });
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );
    await db.delete('offline_transactions');
    await db.delete('products');
    await db.delete('read_snapshots');
  });
  Future<int> enqueue(String actor, String id) => db.insert(
    'offline_transactions',
    {
      'instansi_id': 'tenant-qa',
      'toko_id': 'store',
      'shift_id': 'shift-$actor',
      'client_transaction_id': id,
      'status': 'pending',
      'timestamp': DateTime.now().toIso8601String(),
      'payload': jsonEncode({
        'client_transaction_id': id,
        'shift_id': 'shift-$actor',
        'items': [
          {'inventaris_id': 'item', 'qty': 1},
        ],
      }),
      'client_snapshot': jsonEncode({'operator_user_id': actor, 'total': 1000}),
    },
  );
  test(
    'revoked offline sale stays reviewable; restored original actor syncs the same ID exactly once',
    () async {
      final rowId = await enqueue('a', 'immutable-revoked-sale');
      var permitted = false, writes = 0, committed = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          final input = request.variables['input'] as Map;
          expect(input['client_transaction_id'], 'immutable-revoked-sale');
          expect(input['shift_id'], 'shift-a');
          if (!permitted) {
            yield Response(
              data: {'__typename': 'Mutation'},
              errors: [
                const GraphQLError(
                  message: 'Izin kasir dicabut',
                  extensions: {'code': 'FORBIDDEN'},
                ),
              ],
              response: {},
            );
            return;
          }
          committed++;
          yield Response(
            data: {
              '__typename': 'Mutation',
              'ProcessPOSPenjualan': {
                '__typename': 'POSPenjualanResult',
                '_id': 'server-1',
                'invoice': 'INV-QA',
                'client_transaction_id': input['client_transaction_id'],
                'total': 1000,
                'sync_status': 'synced',
                'sync_conflict_reason': null,
              },
            },
            response: {},
          );
        }),
      );
      final sync = SyncService(_Provider(client, prefs))
        ..setOperatorSessionToken(token('a'));
      await sync.syncOfflineTransactions(force: true);
      var saved = (await db.query(
        'offline_transactions',
        where: 'id = ?',
        whereArgs: [rowId],
      )).single;
      expect(saved['status'], 'needs_review');
      expect(saved['client_transaction_id'], 'immutable-revoked-sale');
      expect(saved['payload'], contains('immutable-revoked-sale'));
      expect(committed, 0);
      permitted = true;
      await sync.retryTransaction(rowId);
      await sync.retryTransaction(rowId);
      saved = (await db.query(
        'offline_transactions',
        where: 'id = ?',
        whereArgs: [rowId],
      )).single;
      expect(saved['status'], 'synced');
      expect(committed, 1);
      expect(writes, 2);
    },
  );
  test(
    'cashier B cannot sync A payload; A can recover without ownership reassignment',
    () async {
      final rowId = await enqueue('a', 'original-a');
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          throw StateError('Must not submit under B');
        }),
      );
      final sync = SyncService(_Provider(client, prefs))
        ..setOperatorSessionToken(token('b'));
      await sync.syncOfflineTransactions(force: true);
      final saved = (await db.query(
        'offline_transactions',
        where: 'id = ?',
        whereArgs: [rowId],
      )).single;
      expect(writes, 0);
      expect(saved['status'], 'needs_review');
      expect(saved['resolution'], 'operator_reauthentication_required');
      expect(
        jsonDecode(saved['client_snapshot'] as String)['operator_user_id'],
        'a',
      );
      expect(saved['client_transaction_id'], 'original-a');
    },
  );
  for (final scenario in [
    'unrelated',
    'referenced',
    'corrupt',
    'foreign-scope',
  ]) {
    test('pending catalogue cache preserves stock and scope: $scenario', () async {
      await db.insert('products', {
        'id': 'old',
        'code': 'old',
        'name': 'old',
        'category': '',
        'price': 1000,
        'stock': 0,
      });
      await db.insert('read_snapshots', {
        'scope_key': 'pos_active_product_catalog_v1',
        'payload': jsonEncode({
          'catalog_key': scenario == 'foreign-scope'
              ? 'another-tenant-catalog'
              : 'pos_product_catalog_v1:tenant-qa:terminal-qa:branch',
        }),
        'cached_at': DateTime.now().toIso8601String(),
      });
      await db.insert('offline_transactions', {
        'instansi_id': 'tenant-qa',
        'client_transaction_id': 'prior-conflict',
        'status': 'needs_review',
        'timestamp': DateTime.now().toIso8601String(),
        'payload': scenario == 'corrupt'
            ? '{'
            : jsonEncode({
                'items': [
                  {
                    'inventaris_id': scenario == 'referenced' ? 'new' : 'old',
                    'qty': 1,
                  },
                ],
              }),
        'client_snapshot': jsonEncode({'stock_branch_id': 'branch'}),
      });
      Map<String, dynamic> product(String id, int stock) => {
        for (final k
            in 'kategori merchandise_category_id merchandise_category_name composition_type sku barcode foto brand deskripsi harga_beli_source stok_minimum stok_maksimum titik_reorder lead_time_pengadaan production_station_id prep_time_minutes'
                .split(' '))
          k: null,
        '__typename': 'POSCatalogItem',
        '_id': id,
        'inventaris_id': id,
        'kode_inventaris': id,
        'nama_inventaris': id,
        'pos_product_type': 'product',
        'tracks_stock': true,
        'promo_eligible': false,
        'harga_beli': 100,
        'harga_jual': 1000,
        'pos_package_components': [],
        'base_unit': 'unit',
        'unit': 'unit',
        'unit_conversions': [],
        'preparation_mode': 'instant',
        'allow_station_override': false,
        'qty': stock,
      };
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield Response(
            data: {
              '__typename': 'Query',
              'GetPOSCatalogPage': {
                '__typename': 'POSCatalogPage',
                'totalCount': 2,
                'items': [product('old', 1), product('new', 10)],
              },
            },
            response: {},
          );
        }),
      );
      final repo = PosRepository(_Provider(client, prefs), prefs);
      final page = await repo.getCatalogPage(branchId: 'branch');
      expect(page.items.map((p) => p.id), contains('new'));
      final added = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['new'],
      );
      expect(
        added,
        hasLength(scenario == 'unrelated' ? 1 : 0),
        reason:
            'Cache new unrelated products, but never restore queued/unknown stock or switch scope',
      );
      expect(
        (await db.query(
          'products',
          where: 'id = ?',
          whereArgs: ['old'],
        )).single['stock'],
        0,
      );
      expect(
        (await db.query('offline_transactions')).single['status'],
        'needs_review',
      );
    });
  }
}
