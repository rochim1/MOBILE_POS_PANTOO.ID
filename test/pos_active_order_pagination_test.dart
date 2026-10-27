import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_order_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_order_management/pos_order_management_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_order_management/pos_order_management_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_order_management/pos_order_management_state.dart';

class QaActiveOrders implements PosOrderRepository {
  final calls = <int>[];
  Completer<Either<Failure, PosActiveOrderPage>>? delayed;
  @override
  Future<Either<Failure, PosActiveOrderPage>> getActiveOrders({
    required String storeId,
    String search = '',
    String status = '',
    String fulfillment = '',
    String dateFrom = '',
    String dateTo = '',
    String sort = 'oldest',
    int page = 0,
  }) async {
    calls.add(page);
    if (search == 'slow') return (delayed = Completer()).future;
    final rows = List.generate(
      5005,
      (i) => PosOrderDetail(
        id: '$i',
        orderNumber: 'QA-$i',
        status: i % 2 == 0 ? 'Baru' : 'Siap',
      ),
    );
    final matched = rows
        .where(
          (row) =>
              (search.isEmpty || row.orderNumber == search) &&
              (status.isEmpty || row.status == status),
        )
        .toList();
    return Right(
      PosActiveOrderPage(
        matched.skip(page * 30).take(30).toList(),
        matched.length,
        const {'Baru': 2503, 'Siap': 2502},
      ),
    );
  }

  @override
  Future<Either<Failure, PosActiveOrderPage>> getKitchenPage({
    required String storeId,
    String stationId = '',
    String status = '',
    int page = 0,
  }) => getActiveOrders(storeId: storeId, status: status, page: page);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected call ${invocation.memberName}');
}

Future<PosOrderManagementState> load(
  PosOrderManagementBloc bloc,
  LoadActiveOrders event,
) {
  final future = bloc.stream.firstWhere(
    (state) => state.status == PosOrderManagementStatus.loaded,
  );
  bloc.add(event);
  return future;
}

void main() {
  test('realtime and pull-to-refresh retain the visible order page', () {
    final source = File(
      'lib/presentation/pages/pos/pos_table_order_page.dart',
    ).readAsStringSync();
    expect(source, contains('void _reloadCurrentPage()'));
    expect(
      source,
      contains(
        '_reload(page: context.read<PosOrderManagementBloc>().state.page)',
      ),
    );
    expect(
      source.replaceAll(RegExp(r'\s+'), ''),
      contains('Timer(constDuration(milliseconds:250),_reloadCurrentPage,'),
    );
    expect(source, contains('void _reload({int page = 0})'));
  });
  test('kitchen board uses bounded page totals and status filters', () async {
    final repository = QaActiveOrders(),
        bloc = PosOrderManagementBloc(repository: QaActiveOrders());
    addTearDown(bloc.close);
    Future<PosOrderManagementState> kitchen(LoadKitchenTickets event) {
      final ready = bloc.stream.firstWhere(
        (state) => state.status == PosOrderManagementStatus.loaded,
      );
      bloc.add(event);
      return ready;
    }

    final first = await kitchen(const LoadKitchenTickets(storeId: 'qa'));
    expect(first.total, 5005);
    expect(first.orders.length, 30);
    final last = await kitchen(
      const LoadKitchenTickets(storeId: 'qa', page: 166),
    );
    expect(last.orders.length, 25);
    expect(last.page, 166);
    final filtered = await kitchen(
      const LoadKitchenTickets(storeId: 'qa', status: 'Siap'),
    );
    expect(filtered.total, 2502);
    expect(filtered.orders.every((order) => order.status == 'Siap'), isTrue);
    expect(repository.calls, isEmpty);
  });
  test(
    '5,005 QA orders: first/last pages and status counts remain independent',
    () async {
      final repository = QaActiveOrders();
      final tested = PosOrderManagementBloc(repository: repository);
      addTearDown(tested.close);
      final first = await load(tested, const LoadActiveOrders(storeId: 'qa'));
      expect(first.orders.length, 30);
      expect(first.total, 5005);
      expect(first.statusCounts['Siap'], 2502);
      final last = await load(
        tested,
        const LoadActiveOrders(storeId: 'qa', page: 166),
      );
      expect(last.orders.length, 25);
      expect(last.orders.last.orderNumber, 'QA-5004');
      final search = await load(
        tested,
        const LoadActiveOrders(storeId: 'qa', search: 'QA-5004'),
      );
      expect(search.page, 0);
      expect(search.orders.single.orderNumber, 'QA-5004');
      expect(repository.calls, [0, 166, 0]);
    },
  );
  test('stale active-order response cannot overwrite a new search', () async {
    final repository = QaActiveOrders();
    final bloc = PosOrderManagementBloc(repository: repository);
    addTearDown(bloc.close);
    bloc.add(const LoadActiveOrders(storeId: 'qa', search: 'slow'));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await load(bloc, const LoadActiveOrders(storeId: 'qa', search: 'QA-5004'));
    repository.delayed!.complete(const Right(PosActiveOrderPage([], 0, {})));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.total, 1);
    expect(bloc.state.orders.single.orderNumber, 'QA-5004');
  });
  test(
    'active-order adapter makes one bounded request, not an exhaustive loop',
    () {
      final source = File(
        'lib/domain/repositories/pos_order_repository.dart',
      ).readAsStringSync();
      final active = source.substring(
        source.indexOf('getActiveOrders('),
        source.indexOf('getKitchenTickets('),
      );
      expect(active, isNot(contains('while (true)')));
      expect(active, contains("'limit': 30"));
      expect(active, contains("'active_only': true"));
      expect(active, contains("data?['status_counts']"));
    },
  );
}
