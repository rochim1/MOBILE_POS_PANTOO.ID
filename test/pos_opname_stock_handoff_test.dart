import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_opname.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_stock_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_stock_page.dart';

class _FakePosRepository extends Fake implements PosRepository {}

class _ConfiguredBloc extends PosBloc {
  _ConfiguredBloc() : super(posRepository: _FakePosRepository()) {
    emit(
      state.copyWith(
        runtimeConfig: {
          'features': {'track_stock': true},
          'permissions': {
            'view_stock': true,
            'adjust_stock': true,
            'view_inventory_opnames': true,
            'create_inventory_opnames': true,
          },
        },
      ),
    );
  }
}

class _StockRepository extends Fake implements PosStockRepository {
  final stock = PosStock.fromJson({
    '_id': 'item',
    'nama_inventaris': 'Barang batch QA',
    'unit': 'unit',
    'tracks_stock': true,
    'stok': 20,
    'requires_batch_adjustment': true,
  });
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getStockLocations() async => const Right([
    {'_id': 'wh', 'nama_cabang': 'Gudang QA'},
  ]);
  @override
  Future<Either<Failure, PosStockPageResult>> getStockPage({
    String? search,
    String? stockFilter,
    String? locationId,
    int page = 1,
    int limit = 20,
  }) async => Right(
    PosStockPageResult(
      [stock],
      1,
      const PosStockStatistics(
        totalInventaris: 1,
        totalNilaiInventaris: 20,
        lowStockCount: 0,
        outOfStockCount: 0,
      ),
    ),
  );
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getLocationBalances({
    required String inventoryId,
    String warehouseId = '',
  }) async => Right([
    for (final rack in ['A', 'B'])
      {
        '_id': 'balance-$rack',
        'inventaris_id': 'item',
        'lokasi_cabang_id': 'wh',
        'lokasi_cabang_nama': 'Gudang QA',
        'lokasi_gedung_kode': 'G',
        'lokasi_ruangan_kode': 'R',
        'lokasi_rak_nama': rack,
        'qty': 10,
        'batches': [
          {
            'batch_id': 'lot-$rack',
            'no_batch': 'SAME',
            'tanggal_kadaluarsa': '2027-11-04',
            'qty': 10,
          },
        ],
      },
  ]);
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  setUp(() {
    sl.pushNewScope();
    final repository = _StockRepository();
    sl.registerSingleton<PosStockRepository>(repository);
    sl.registerFactory<PosStockBloc>(
      () => PosStockBloc(repository: repository),
    );
  });
  tearDown(() async {
    await sl.popScope();
  });
  for (final permitted in [true, false]) {
    testWidgets(
      permitted
          ? 'stock sheet returns exact second rack to count editor'
          : 'adjust-only user cannot bypass batch tracking',
      (tester) async {
        tester.view.physicalSize = const Size(375, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bloc = _ConfiguredBloc();
        addTearDown(bloc.close);
        PosOpnameTarget? target;
        await tester.pumpWidget(
          BlocProvider<PosBloc>.value(
            value: bloc,
            child: MaterialApp(
              home: Scaffold(
                body: PosStockPage(
                  onCountStock: permitted
                      ? (selected) => target = selected
                      : null,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final detail = find.text('Barang batch QA');
        await tester.scrollUntilVisible(
          detail,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(detail);
        await tester.pumpAndSettle();
        final second = find.text('Hitung/koreksi per batch').at(1);
        await tester.ensureVisible(second);
        await tester.tap(second);
        await tester.pumpAndSettle();
        if (permitted) {
          expect(target?.balanceId, 'balance-B');
          expect(target?.inventoryId, 'item');
          expect(target?.location['rak_nama'], 'B');
          expect(find.byType(BottomSheet), findsNothing);
        } else {
          expect(target, isNull);
          expect(find.text('Perlu akses Stock Opname'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
