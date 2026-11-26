import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_transfer_queries.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_transfer_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_stock_repository.dart';
import 'package:mobile_pos_pantoo/core/network/pos_transfer_intent_store.dart';
import 'pos_checkout_request_store_test.dart' show FlakyPreferences;

class TransferPreferences extends FlakyPreferences {
  @override
  bool containsKey(String key) => values.containsKey(key);
}

class TransferProvider extends Fake implements GraphQLClientProvider {
  String scope = 'endpoint|tenant|owner|operator';
  final SharedPreferences prefs;
  final GraphQLClient graph;
  TransferProvider(this.prefs, Stream<Response> Function(Request) run)
    : graph = GraphQLClient(
        link: Link.function((r, [f]) => run(r)),
        cache: GraphQLCache(partialDataPolicy: PartialDataCachePolicy.accept),
      );
  @override
  String get subscriptionScope => scope;
  @override
  SharedPreferences get sharedPreferences => prefs;
  @override
  GraphQLClient get client => graph;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('partial success with field errors retains proof instead of allowing replacement', () async {
    final p=TransferProvider(await SharedPreferences.getInstance(),(r) async* {
      yield const Response(response:{},data:{'CreateInventoryTransfer':{'_id':'committed'}},
        errors:[GraphQLError(message:'nested field failure',extensions:{'code':'BAD_REQUEST'})]);
    });
    final repo=PosTransferRepository(p);
    await expectLater(repo.execute(PosTransferQueries.create,{'input':{},'request_id':'partial'},'CreateInventoryTransfer'),throwsA(anything));
    expect(repo.pendingIntent(),isNotNull);
  });
  test('receipt response for a different document cannot acknowledge original proof', () async {
    final p=TransferProvider(await SharedPreferences.getInstance(),(r) async* {
      yield const Response(response:{},data:{'ReceiveInventoryTransfer':{'_id':'other'}});
    });
    final repo=PosTransferRepository(p);
    await expectLater(repo.execute(PosTransferQueries.receive,{'id':'doc','request_id':'receipt','items':[]},'ReceiveInventoryTransfer'),throwsA(anything));
    expect(repo.pendingIntent(documentId:'doc'),isNotNull);
  });
  const root = 'CreateInventoryTransfer';
  final variables = {
    'request_id': 'first-request',
    'input': {
      'dari': {'cabang_id': 'from'},
      'ke': {'cabang_id': 'to'},
      'items': [
        {'inventaris_id': 'product', 'qty': 1},
      ],
    },
  };
  for (final lose in [false, true]) {
    test(
      'failed or unreadable durable write ($lose) never transmits',
      () async {
        final prefs = TransferPreferences()
          ..rejectWrite = !lose
          ..loseWrite = lose;
        var calls = 0;
        final p = TransferProvider(prefs, (r) async* {
          calls++;
          yield const Response(response: {}, data: {});
        });
        await expectLater(
          PosTransferRepository(
            p,
          ).execute(PosTransferQueries.create, variables, root),
          throwsA(anything),
        );
        expect(calls, 0);
      },
    );
  }
  test(
    'failed acknowledgement retains proof and recovery reuses same ID',
    () async {
      final prefs = TransferPreferences()..rejectRemove = true;
      final sent = <String>[];
      final p = TransferProvider(prefs, (r) async* {
        sent.add(r.variables['request_id'] as String);
        yield const Response(
          response: {},
          data: {
            root: {'_id': 'doc'},
          },
        );
      });
      final repo = PosTransferRepository(p);
      await expectLater(
        repo.execute(PosTransferQueries.create, variables, root),
        throwsA(anything),
      );
      expect(repo.pendingIntent(), isNotNull);
      prefs.rejectRemove = false;
      await repo.recoverPending();
      expect(sent[1], sent[0]);
      expect(repo.pendingIntent(), isNull);
    },
  );
  test('corrupt proof cannot be silently overwritten', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      PosTransferIntentStore(prefs, 'endpoint|tenant|owner|operator').key(null),
      'broken',
    );
    var calls = 0;
    final p = TransferProvider(prefs, (r) async* {
      calls++;
      yield const Response(response: {}, data: {});
    });
    await expectLater(
      PosTransferRepository(
        p,
      ).execute(PosTransferQueries.create, variables, root),
      throwsStateError,
    );
    expect(calls, 0);
  });
  test('operator changes while storage awaits cannot transmit', () async {
    final prefs = await SharedPreferences.getInstance();
    var calls = 0;
    final p = TransferProvider(prefs, (r) async* {
      calls++;
      yield const Response(response: {}, data: {});
    });
    final repo = PosTransferRepository(p);
    final request = repo.execute(PosTransferQueries.create, variables, root);
    p.scope = 'other';
    await expectLater(request, throwsStateError);
    expect(calls, 0);
  });
  test('cancel cannot silently execute another pending operation', () async {
    var calls = 0;
    final p = TransferProvider(await SharedPreferences.getInstance(), (
      r,
    ) async* {
      calls++;
      throw StateError('lost');
    });
    final repo = PosTransferRepository(p);
    await expectLater(
      repo.execute(PosTransferQueries.receive, {
        'id': 'doc',
        'request_id': 'receipt',
        'items': [],
      }, 'ReceiveInventoryTransfer'),
      throwsA(anything),
    );
    await expectLater(
      repo.action('cancel', {'_id': 'doc'}, reason: 'wrong action'),
      throwsStateError,
    );
    expect(calls, 1);
  });
  for (final report in [true, false]) {
    test(
      '${report ? 'report' : 'decision'} retains identity after uncertain response',
      () async {
        final sent = <Map<String, dynamic>>[];
        var fail = true;
        final r = report
            ? 'ReportInventoryTransferDiscrepancy'
            : 'DecideInventoryTransferDiscrepancy';
        final p = TransferProvider(await SharedPreferences.getInstance(), (
          req,
        ) async* {
          sent.add(req.variables);
          if (fail) throw StateError('lost');
          yield Response(
            response: const {},
            data: {
              r: {'_id': 'doc'},
            },
          );
        });
        final repo = PosTransferRepository(p);
        final v = report
            ? {
                'id': 'doc',
                'input': {
                  'request_id': 'report',
                  'kind': 'lost',
                  'reason': 'QA',
                  'items': [],
                },
              }
            : {
                'id': 'doc',
                'discrepancy_id': 'report',
                'approve': false,
                'note': 'QA',
              };
        await expectLater(
          repo.execute(
            report ? PosTransferQueries.report : PosTransferQueries.decide,
            v,
            r,
          ),
          throwsA(anything),
        );
        fail = false;
        await PosTransferRepository(p).recoverPending(documentId: 'doc');
        expect(sent[1], sent[0]);
      },
    );
  }
  test(
    'lost create response survives repository recreation and exact recovery clears proof',
    () async {
      var fail = true;
      final sent = <Map<String, dynamic>>[];
      final p = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        sent.add(r.variables);
        if (fail) throw StateError('response lost');
        yield const Response(
          response: {},
          data: {
            root: {'_id': 'doc', 'status': 'draft'},
          },
        );
      });
      final repo = PosTransferRepository(p);
      await expectLater(
        repo.execute(PosTransferQueries.create, variables, root),
        throwsA(anything),
      );
      final reopened = PosTransferRepository(p);
      expect(reopened.pendingIntent()?['variables'], variables);
      fail = false;
      expect((await reopened.recoverPending())['_id'], 'doc');
      expect(sent[1], sent[0]);
      expect(reopened.pendingIntent(), isNull);
    },
  );
  test(
    'pending receipt blocks changed payload and survives account switch',
    () async {
      var calls = 0;
      final p = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        calls++;
        throw StateError('lost');
      });
      final repo = PosTransferRepository(p);
      final payload = {
        'id': 'doc',
        'request_id': 'receipt-1',
        'items': [
          {'item_id': 'line', 'qty': 1},
        ],
      };
      await expectLater(
        repo.execute(
          PosTransferQueries.receive,
          payload,
          'ReceiveInventoryTransfer',
        ),
        throwsA(anything),
      );
      await expectLater(
        repo.execute(PosTransferQueries.receive, {
          ...payload,
          'items': [
            {'item_id': 'line', 'qty': 2},
          ],
        }, 'ReceiveInventoryTransfer'),
        throwsA(anything),
      );
      expect(calls, 1);
      p.scope = 'endpoint|tenant|owner|other';
      expect(repo.pendingIntent(documentId: 'doc'), isNull);
      p.scope = 'endpoint|tenant|owner|operator';
      expect(repo.pendingIntent(documentId: 'doc'), isNotNull);
    },
  );
  test(
    'double submit across repository instances shares one request',
    () async {
      final gate = Completer<void>();
      var calls = 0;
      final p = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        calls++;
        await gate.future;
        yield const Response(
          response: {},
          data: {
            root: {'_id': 'doc'},
          },
        );
      });
      final a = PosTransferRepository(
        p,
      ).execute(PosTransferQueries.create, variables, root);
      final b = PosTransferRepository(
        p,
      ).execute(PosTransferQueries.create, variables, root);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      gate.complete();
      await Future.wait([a, b]);
      expect(calls, 1);
    },
  );
  test(
    'fresh validation rejection unlocks editing, replay rejection retains proof',
    () async {
      var lost = false;
      final p = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        if (lost) throw StateError('lost');
        yield const Response(
          response: {},
          errors: [
            GraphQLError(
              message: 'invalid',
              extensions: {'code': 'BAD_REQUEST'},
            ),
          ],
        );
      });
      final repo = PosTransferRepository(p);
      await expectLater(
        repo.execute(PosTransferQueries.create, variables, root),
        throwsA(anything),
      );
      expect(repo.pendingIntent(), isNull);
      lost = true;
      await expectLater(
        repo.execute(PosTransferQueries.create, variables, root),
        throwsA(anything),
      );
      lost = false;
      await expectLater(repo.recoverPending(), throwsA(anything));
      expect(repo.pendingIntent(), isNotNull);
    },
  );
  test('stock locations and rack balances continue past 200 rows', () async {
    final pages = <String>[];
    final p = TransferProvider(await SharedPreferences.getInstance(), (
      r,
    ) async* {
      final balances = r.variables.containsKey('inventoryId');
      final page = r.variables['page'] as int? ?? 0;
      pages.add('${balances ? 'balance' : 'warehouse'}:$page');
      final rows = List.generate(
        page == 0 ? 200 : 1,
        (i) => {'_id': '$page-$i', 'qty': 1},
      );
      yield Response(
        response: const {},
        data: balances
            ? {
                'GetInventoryLocationBalances': {'items': rows},
              }
            : {
                'getAllCabangs': {'cabang': rows},
              },
      );
    });
    final repo = PosStockRepository(p);
    final locations = await repo.getStockLocations();
    final balances = await repo.getLocationBalances(inventoryId: 'product');
    expect(locations.getOrElse(() => []).length, 201);
    expect(balances.getOrElse(() => []).length, 201);
    expect(pages, ['warehouse:0', 'warehouse:1', 'balance:0', 'balance:1']);
  });
}
