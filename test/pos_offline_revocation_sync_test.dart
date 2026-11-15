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
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';

class _Provider implements GraphQLClientProvider {
  _Provider(this.client, this.sharedPreferences);
  @override
  String endpointUrl = 'https://qa.invalid/graphql';
  String? subscriptionDenial;
  @override
  Future<String?> checkOfflineSubscription() async => subscriptionDenial;
  @override
  String resolveMediaUrl(dynamic value) => '';
  @override
  final GraphQLClient client;
  @override
  final SharedPreferences sharedPreferences;
  @override
  void setPOSOperatorToken(String? value) {}
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

  for (final profile in [
    'laundry',
    'bengkel',
    'salon',
    'jasa',
    'reservation',
    'flexible',
  ]) {
    test(
      'unpaid $profile persists service/reservation and deduplicates its original ID offline',
      () async {
        var requests = 0;
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            requests++;
            final definition =
                request.operation.document.definitions.single as dynamic;
            expect(definition.name.value, 'CreatePOSInvoice');
            final fields = (definition.selectionSet.selections as List)
                .map((dynamic field) => field.name.value)
                .toList();
            expect(fields, contains('CreatePOSOrder'));
            expect(fields, isNot(contains('PayPOSOrder')));
            // Match the transport exception emitted by HttpLink, not UnknownException.
            throw const ServerException(
              originalException: SocketException('Network is unreachable'),
            );
          }),
        );
        final repo = PosRepository(_Provider(client, prefs), prefs)
          ..setOperatorSessionToken(token('a'));
        final product = PosProduct(
          id: 'service',
          code: 'SERVICE-QA',
          name: 'QA Service',
          category: '',
          productType: 'service',
          servicePriceMode: profile == 'flexible' ? 'flexible' : 'fixed',
          tracksStock: false,
          price: 5000,
          stock: 0,
        );
        final service = <String, dynamic>{
          'service_type': profile == 'reservation' ? 'salon' : profile,
          'service_subject': 'QA $profile',
          'complaint': 'QA offline',
          if (profile == 'bengkel') 'vehicle_no': 'QA1311A',
          if (profile == 'laundry') ...{
            'service_mode': 'kiloan',
            'weight_kg': 1,
            'item_count': 1,
            'bag_tag': 'QA1311',
          },
        };
        final start = DateTime.parse('2026-11-20T11:00:00+07:00');
        for (var attempt = 0; attempt < 2; attempt++) {
          final result = await repo.createUnpaidInvoice(
            clientRequestId: 'unpaid-$profile-original',
            cart: {product: 1},
            tokoId: 'store',
            shiftId: 'shift-a',
            orderType: profile == 'reservation' ? 'reservation' : 'take_away',
            customerId: 'customer',
            serviceOrder: service,
            itemPrices: profile == 'flexible' ? {'service': 150000} : const {},
            expectedTotal: profile == 'flexible' ? 150000 : 5000,
            tableId: profile == 'reservation' ? 'qa-table' : null,
            reservationStartAt: profile == 'reservation' ? start : null,
            reservationEndAt: profile == 'reservation'
                ? start.add(const Duration(hours: 1))
                : null,
            reservationGuestCount: 2,
          );
          result.fold(
            (failure) => fail(failure.message),
            (value) => expect(value['offline_queued'], true),
          );
        }
        final row = (await db.query('offline_transactions')).single;
        expect(requests, 2);
        expect(row['operation_kind'], 'create_order');
        expect(row['client_transaction_id'], 'unpaid-$profile-original');
        expect(row['status'], 'pending');
        final payload = jsonDecode(row['payload'] as String) as Map;
        expect(payload['service_order'], service);
        if (profile == 'flexible') {
          expect((payload['items'] as List).single['harga_satuan'], 150000);
        }
        expect(payload['pelanggan_id'], 'customer');
        expect(payload['shift_id'], 'shift-a');
        expect(payload.containsKey('operator_session_token'), false);
        expect(payload.containsKey('metode_pembayaran'), false);
        expect(
          jsonDecode(row['client_snapshot'] as String)['operator_user_id'],
          'a',
        );
        if (profile == 'reservation') {
          expect(payload['reservation_start_at'], '2026-11-20T04:00:00.000Z');
          expect(payload['reservation_end_at'], '2026-11-20T05:00:00.000Z');
          expect(payload['table_id'], 'qa-table');
          expect(payload['reservation_guest_count'], 2);
          expect(payload['reservation_deposit_amount'], 0);
        }
      },
    );
  }
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
  test(
    'closed original shift stays reviewable and retry preserves original identity',
    () async {
      final rowId = await enqueue('a', 'closed-shift-sale');
      var requests = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          requests++;
          final input = request.variables['input'] as Map;
          expect(input['shift_id'], 'shift-a');
          expect(input['client_transaction_id'], 'closed-shift-sale');
          yield Response(
            data: {'__typename': 'Mutation'},
            errors: [
              const GraphQLError(
                message: 'Shift asal transaksi offline sudah ditutup',
                extensions: {'code': 'CONFLICT'},
              ),
            ],
            response: {},
          );
        }),
      );
      final sync = SyncService(_Provider(client, prefs))
        ..setOperatorSessionToken(token('a'));
      await sync.syncOfflineTransactions(force: true);
      await sync.syncOfflineTransactions(force: true);
      expect(requests, 1, reason: 'needs_review is not retried automatically');
      await sync.retryTransaction(rowId);
      expect(requests, 2);
      final saved = (await db.query(
        'offline_transactions',
        where: 'id = ?',
        whereArgs: [rowId],
      )).single;
      expect(saved['status'], 'needs_review');
      expect(saved['shift_id'], 'shift-a');
      expect(saved['client_transaction_id'], 'closed-shift-sale');
      expect(jsonDecode(saved['payload'] as String)['shift_id'], 'shift-a');
      expect(
        jsonDecode(saved['client_snapshot'] as String)['operator_user_id'],
        'a',
      );
    },
  );
  for (final scenario in [
    'unrelated',
    'referenced',
    'corrupt',
    'foreign-scope',
    'foreign-tenant',
    'foreign-branch',
    'empty-cache-pending',
    'empty-cache-bom-pending',
    'empty-cache-unknown-pending',
    'empty-cache-corrupt-pending',
    'same-stock-new-login',
    'same-stock-new-login-lower-stock',
  ]) {
    test('pending catalogue cache preserves stock and scope: $scenario', () async {
      final handover = scenario.startsWith('same-stock-new-login');
      final lowerStock = scenario == 'same-stock-new-login-lower-stock';
      final bootstrap = scenario.startsWith('empty-cache-');
      await db.insert('products', {
        'id': 'old',
        'code': 'old',
        'name': 'old',
        'category': '',
        'price': 1000,
        'stock': lowerStock ? 5 : 0,
      });
      if (handover) {
        await db.insert('products', {
          'id': 'private-old-login',
          'code': 'private',
          'name': 'private',
          'category': '',
          'price': 1,
          'stock': 4,
        });
      }
      await db.insert('read_snapshots', {
        'scope_key': 'pos_active_product_catalog_v1',
        'payload': jsonEncode({
          'catalog_key': scenario == 'foreign-scope'
              ? 'another-tenant-catalog'
              : scenario == 'foreign-tenant'
              ? 'pos_product_catalog_v1:other-tenant:previous-login:branch'
              : scenario == 'foreign-branch'
              ? 'pos_product_catalog_v1:tenant-qa:previous-login:other-branch'
              : handover
              ? 'pos_product_catalog_v1:tenant-qa:previous-login:branch'
              : 'pos_product_catalog_v1:tenant-qa:terminal-qa:branch',
        }),
        'cached_at': DateTime.now().toIso8601String(),
      });
      await db.insert('offline_transactions', {
        'instansi_id': 'tenant-qa',
        'client_transaction_id': 'prior-conflict',
        'status': 'needs_review',
        'timestamp': DateTime.now().toIso8601String(),
        'payload':
            scenario == 'corrupt' || scenario == 'empty-cache-corrupt-pending'
            ? '{'
            : jsonEncode({
                'items': [
                  {
                    'inventaris_id': scenario == 'referenced'
                        ? 'new'
                        : scenario == 'empty-cache-unknown-pending'
                        ? 'unknown'
                        : 'old',
                    'qty': 1,
                  },
                ],
              }),
        'client_snapshot': jsonEncode({'stock_branch_id': 'branch'}),
      });
      if (bootstrap) {
        // Auth clears read caches at logout but retains unresolved work.
        await db.delete('products');
        await db.delete('read_snapshots');
      }
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
        'pos_package_components':
            scenario == 'empty-cache-bom-pending' && id == 'old'
            ? [
                {
                  '__typename': 'POSPackageComponent',
                  'inventaris_id': 'new',
                  'qty_base': 1,
                },
              ]
            : [],
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
                'items': [
                  product('old', 1),
                  product('new', 10),
                  if (scenario == 'empty-cache-bom-pending')
                    product('unrelated', 10),
                ],
              },
            },
            response: {},
          );
        }),
      );
      final repo = PosRepository(_Provider(client, prefs), prefs);
      final page = await repo.getCatalogPage(branchId: 'branch');
      expect(
        page.offline,
        false,
        reason: 'Exercise a real online cache refresh, not fallback',
      );
      expect(page.items.map((p) => p.id), contains('new'));
      final added = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: ['new'],
      );
      expect(
        added,
        hasLength(
          scenario == 'unrelated' ||
                  handover ||
                  scenario == 'empty-cache-pending'
              ? 1
              : 0,
        ),
        reason:
            'Cache new unrelated products, but never restore queued/unknown stock or switch scope',
      );
      if (!bootstrap) {
        expect(
          (await db.query(
            'products',
            where: 'id = ?',
            whereArgs: ['old'],
          )).single['stock'],
          lowerStock ? 1 : 0,
        );
      } else {
        expect(
          await db.query('products', where: 'id = ?', whereArgs: ['old']),
          isEmpty,
        );
      }
      expect(
        (await db.query('offline_transactions')).single['status'],
        'needs_review',
      );
      if (scenario == 'empty-cache-bom-pending') {
        await repo.getCatalogPage(branchId: 'branch');
        expect(
          await db.query('products', where: 'id = ?', whereArgs: ['new']),
          isEmpty,
          reason: 'Refreshing again must not refill a held recipe ingredient',
        );
      }
      if (handover) {
        expect(
          await db.query(
            'products',
            where: 'id = ?',
            whereArgs: ['private-old-login'],
          ),
          isEmpty,
          reason:
              'Only metadata fetched online for the new login can be exposed',
        );
        final active = (await db.query(
          'read_snapshots',
          where: 'scope_key = ?',
          whereArgs: ['pos_active_product_catalog_v1'],
        )).single;
        expect(
          jsonDecode(active['payload'] as String)['catalog_key'],
          'pos_product_catalog_v1:tenant-qa:terminal-qa:branch',
        );
      }
    });
  }
  test(
    'subscription expiry preserves pending queue and activation syncs its original ID once',
    () async {
      final rowId = await enqueue('a', 'immutable-subscription-sale');
      var accepted = false, writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          final input = request.variables['input'] as Map;
          expect(input['client_transaction_id'], 'immutable-subscription-sale');
          if (!accepted) {
            yield Response(
              response: {},
              errors: [
                const GraphQLError(
                  message: 'Langganan tidak aktif',
                  extensions: {
                    'code': 'SUBSCRIPTION_REQUIRED',
                    'access_level': 'read_only',
                  },
                ),
              ],
            );
            return;
          }
          yield Response(
            response: {},
            data: {
              'ProcessPOSPenjualan': {
                '_id': 'sub-sale',
                'invoice': 'INV-SUB',
                'total': 1000,
                'sync_status': 'synced',
              },
            },
          );
        }),
      );
      final provider = _Provider(client, prefs);
      final sync = SyncService(provider)..setOperatorSessionToken(token('a'));
      await sync.syncOfflineTransactions(force: true);
      var saved = (await db.query(
        'offline_transactions',
        where: 'id = ?',
        whereArgs: [rowId],
      )).single;
      expect(saved['status'], 'pending');
      expect(saved['resolution'], 'subscription_required');
      expect(saved['client_transaction_id'], 'immutable-subscription-sale');
      provider.subscriptionDenial = 'Perpanjang langganan';
      await sync.syncOfflineTransactions(force: true);
      expect(writes, 1);
      provider.subscriptionDenial = null;
      accepted = true;
      await sync.syncOfflineTransactions(force: true);
      await sync.syncOfflineTransactions(force: true);
      saved = (await db.query(
        'offline_transactions',
        where: 'id = ?',
        whereArgs: [rowId],
      )).single;
      expect(saved['status'], 'synced');
      expect(writes, 2);
    },
  );
}
