import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_stock_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_state.dart';

class QaStockRepository implements PosStockRepository {
  final calls = <(int, String)>[];
  Completer<Either<Failure, PosStockPageResult>>? delayed;
  final rows = List.generate(
    5005,
    (i) => PosStock.fromJson({
      '_id': '$i',
      'nama_inventaris': 'QA-$i',
      'kode_inventaris': '$i',
      'stok': 10,
      'harga_beli': 100,
      'tracks_stock': true,
    }),
  );
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getStockLocations() async => const Right([]);
  @override
  Future<Either<Failure, PosStockPageResult>> getStockPage({
    String? search,
    String? stockFilter,
    String? locationId,
    int page = 1,
    int limit = 20,
  }) async {
    calls.add((page, search ?? ''));
    if (search == 'slow') return (delayed = Completer()).future;
    final filtered = rows
        .where((row) => row.namaInventaris.contains(search ?? ''))
        .toList();
    return Right(
      PosStockPageResult(
        filtered.skip((page - 1) * limit).take(limit).toList(),
        filtered.length,
        PosStockStatistics(
          totalInventaris: filtered.length,
          totalNilaiInventaris: filtered.length * 1000,
          lowStockCount: 0,
          outOfStockCount: 0,
        ),
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected unpaged request: ${invocation.memberName}');
}

Future<PosStockState> load(PosStockBloc bloc, LoadStocks event) async {
  final result = bloc.stream.firstWhere(
    (state) => state.status == PosStockStatus.success,
  );
  bloc.add(event);
  return result;
}

void main() {
  test(
    '5,005 QA stocks stay in 20-row pages, last page and server search are reachable',
    () async {
      final repository = QaStockRepository();
      final bloc = PosStockBloc(repository: repository);
      addTearDown(bloc.close);
      final first = await load(bloc, const LoadStocks());
      expect(first.stocks.length, 20);
      expect(first.total, 5005);
      expect(first.statistics?.totalInventaris, 5005);
      final last = await load(bloc, const LoadStocks(page: 251));
      expect(last.stocks.length, 5);
      expect(last.stocks.last.namaInventaris, 'QA-5004');
      final searched = await load(bloc, const LoadStocks(search: 'QA-5004'));
      expect(searched.page, 1);
      expect(searched.total, 1);
      expect(repository.calls, [(1, ''), (251, ''), (1, 'QA-5004')]);
    },
  );
  test('late search response cannot overwrite a newer filter', () async {
    final repository = QaStockRepository();
    final bloc = PosStockBloc(repository: repository);
    addTearDown(bloc.close);
    bloc.add(const LoadStocks(search: 'slow'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final latest = await load(bloc, const LoadStocks(search: 'QA-5004'));
    expect(latest.total, 1);
    repository.delayed!.complete(
      Right(PosStockPageResult([], 0, latest.statistics!)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.search, 'QA-5004');
    expect(bloc.state.total, 1);
  });
}
