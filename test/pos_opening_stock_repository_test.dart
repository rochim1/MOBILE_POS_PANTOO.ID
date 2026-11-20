import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_opening_stock_repository.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  String scope = 'server|tenant|owner|operator';
  final SharedPreferences prefs;
  final GraphQLClient graph;
  _Provider(this.prefs, this.graph);
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
  final payload = {
    'tanggal': '2026-11-20',
    'items': [
      {
        'inventaris_id': 'item',
        'lokasi_cabang_id': 'wh',
        'qty': 12,
        'hpp': 3000,
      },
    ],
  };
  Future<_Provider> provider(Stream<Response> Function(Request) run) async =>
      _Provider(
        await SharedPreferences.getInstance(),
        GraphQLClient(
          link: Link.function((request, [forward]) => run(request)),
          cache: GraphQLCache(),
        ),
      );
  test(
    'real repository preserves request on transport error, replays exactly once and clears only confirmed success',
    () async {
      final sent = <Map<String, dynamic>>[];
      var fail = true;
      final p = await provider((request) async* {
        sent.add(Map<String, dynamic>.from(request.variables['input'] as Map));
        if (fail) throw StateError('network');
        yield const Response(
          response: {},
          data: {'SubmitInventoryOpeningBalance': true},
        );
      });
      final repo = PosOpeningStockRepository(p);
      await expectLater(repo.submit(payload), throwsA(anything));
      final id = repo.draft.pending!['request_id'];
      fail = false;
      await repo.submit(payload);
      expect(sent.length, 2);
      expect(sent.last, sent.first);
      expect(sent.last['request_id'], id);
      expect(repo.draft.pending, isNull);
    },
  );
  test(
    'real repository coalesces double submit while showing one in-flight mutation',
    () async {
      final gate = Completer<void>();
      var writes = 0;
      final p = await provider((request) async* {
        writes++;
        await gate.future;
        yield const Response(
          response: {},
          data: {'SubmitInventoryOpeningBalance': true},
        );
      });
      final repo = PosOpeningStockRepository(p);
      final a = repo.submit(payload);
      final b = repo.submit(payload);
      expect(identical(a, b), true);
      gate.complete();
      await Future.wait([a, b]);
      expect(writes, 1);
    },
  );
  test(
    'definitive server rejection permits correcting form, unknown success does not',
    () async {
      var definite = true;
      final p = await provider((request) async* {
        yield definite
            ? const Response(
                response: {},
                errors: [
                  GraphQLError(
                    message: 'Tidak memiliki izin',
                    extensions: {'code': 'FORBIDDEN'},
                  ),
                ],
              )
            : const Response(
                response: {},
                data: {'SubmitInventoryOpeningBalance': false},
              );
      });
      final repo = PosOpeningStockRepository(p);
      await expectLater(repo.submit(payload), throwsA(anything));
      expect(repo.draft.pending, isNull);
      definite = false;
      await expectLater(repo.submit(payload), throwsA(isA<StateError>()));
      expect(repo.draft.pending, isNotNull);
    },
  );
  test('detail query returns master and rejects missing product', () async {
    var exists = true;
    final p = await provider((request) async* {
      yield Response(
        response: {},
        data: {
          '__typename': 'Query',
          'GetOneInventarisUmum': exists
              ? {
                  '__typename': 'InventarisUmum',
                  '_id': 'item',
                  'nama_inventaris': 'Produk',
                  'kategori': 'barang_dagangan',
                  'tracks_stock': true,
                  'pos_product_type': 'product',
                  'composition_type': null,
                  'stok': 0,
                  'harga_beli': 3000,
                  'base_unit': 'pcs',
                  'unit': 'pcs',
                  'unit_conversions': [],
                  'wajib_batch_number': false,
                  'wajib_serial_number': false,
                  'valuation_method': 'average',
                }
              : null,
        },
      );
    });
    final repo = PosOpeningStockRepository(p);
    expect((await repo.detail('item'))['_id'], 'item');
    exists = false;
    await expectLater(repo.detail('missing'), throwsStateError);
  });
  test('internal server failure retains exact draft for confirmation', () async {
    var failed = true;
    final sent = <Map<String, dynamic>>[];
    final p = await provider((request) async* {
      sent.add(Map<String, dynamic>.from(request.variables['input'] as Map));
      yield failed
          ? const Response(response: {}, errors: [GraphQLError(
              message: 'Outcome unknown', extensions: {'code': 'INTERNAL_SERVER_ERROR'},
            )])
          : const Response(response: {}, data: {'SubmitInventoryOpeningBalance': true});
    });
    final repo = PosOpeningStockRepository(p);
    await expectLater(repo.submit(payload), throwsA(anything));
    expect(repo.draft.pending, isNotNull);
    failed = false;
    await repo.submit(payload);
    expect(sent.last, sent.first);
    expect(repo.draft.pending, isNull);
  });
}
