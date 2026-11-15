import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';

typedef Page = ({List<PosOrder> items, bool hasMore});

class OrdersRepository extends Fake implements PosRepository {
  final response = Completer<Page>();
  String operator = 'cashier';
  @override
  String get activeOperatorId => operator;
  @override
  String get terminalUserId => 'terminal';
  @override
  Future<Page> getOrdersPage({int page = 0, int limit = 20}) => response.future;
}

const order = PosOrder(
  id: '1',
  invoice: 'TEST-1',
  date: '2026-11-15',
  customer: 'QA',
  cashierName: 'QA',
  paymentMethod: 'cash',
  total: 1000,
  status: 'Selesai',
);
void main() {
  test('history stays refreshing until delayed request finishes', () async {
    final repo = OrdersRepository();
    final bloc = PosBloc(posRepository: repo);
    addTearDown(bloc.close);
    final started = bloc.stream.firstWhere((s) => s.ordersRefreshing);
    bloc.add(RefreshOrders());
    await started;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(bloc.state.ordersRefreshing, true);
    final done = bloc.stream.firstWhere((s) => !s.ordersRefreshing);
    repo.response.complete((items: [order], hasMore: false));
    await done;
    expect(bloc.state.orders.single.invoice, 'TEST-1');
  });
  test('history refresh failure stops loading and reports an error', () async {
    final repo = OrdersRepository();
    final bloc = PosBloc(posRepository: repo);
    addTearDown(bloc.close);
    final started = bloc.stream.firstWhere((s) => s.ordersRefreshing);
    bloc.add(RefreshOrders());
    await started;
    final done = bloc.stream.firstWhere((s) => !s.ordersRefreshing);
    repo.response.completeError(StateError('offline'));
    await done;
    expect(bloc.state.errorMessage, contains('Gagal memuat riwayat'));
  });
  test(
    'late history response from old operator is not displayed after operator change',
    () async {
      final repo = OrdersRepository();
      final bloc = PosBloc(posRepository: repo);
      addTearDown(bloc.close);
      final started = bloc.stream.firstWhere((s) => s.ordersRefreshing);
      bloc.add(RefreshOrders());
      await started;
      repo.operator = 'another';
      final done = bloc.stream.firstWhere((s) => !s.ordersRefreshing);
      repo.response.complete((items: [order], hasMore: false));
      await done;
      expect(bloc.state.orders, isEmpty);
    },
  );
}
