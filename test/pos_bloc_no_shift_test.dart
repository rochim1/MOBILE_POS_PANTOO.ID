import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

class _NoShiftRepository extends Fake implements PosRepository {
  _NoShiftRepository({this.allowOutOfShift = false});

  final bool allowOutOfShift;
  int customerFetches = 0;

  @override
  String get activeOperatorId => 'qa-cashier';

  @override
  Future<List<PosCustomer>> getCustomers() async {
    customerFetches += 1;
    return const [
      PosCustomer(
        id: 'customer-qa',
        name: 'Pelanggan QA',
        phone: '081234567899',
        priceLevel: 'retail',
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'allow_out_of_shift': allowOutOfShift,
    'permissions': {
      'view_shifts': true,
      'use_cashier': true,
      'view_customers': true,
    },
  };

  @override
  Future<List<PosStore>> getStores() async => [];

  @override
  Future<Map<String, dynamic>?> getActiveShift([String? tokoId]) async => null;

  @override
  Future<({List<PosOrder> items, bool hasMore})> getOrdersPage({
    int page = 0,
    int limit = 20,
  }) async => throw StateError('Riwayat tidak boleh diambil sebelum shift');
}

void main() {
  test(
    'kasir tanpa shift tetap memuat izin dan dapat membuka halaman shift',
    () async {
      final repository = _NoShiftRepository();
      final bloc = PosBloc(posRepository: repository);
      addTearDown(bloc.close);

      bloc.add(LoadPosData());
      final loaded = await bloc.stream.firstWhere(
        (state) => state.status == PosStatus.success,
      );

      expect(loaded.runtimeConfig['permissions']['view_shifts'], isTrue);
      expect(loaded.orders, isEmpty);
      expect(loaded.activeShift, isNull);
      expect(loaded.customers, isEmpty);
      expect(repository.customerFetches, 0);
    },
  );

  test(
    'pelanggan dimuat saat kebijakan mengizinkan kasir tanpa shift',
    () async {
      final repository = _NoShiftRepository(allowOutOfShift: true);
      final bloc = PosBloc(posRepository: repository);
      addTearDown(bloc.close);

      bloc.add(LoadPosData());
      final loaded = await bloc.stream.firstWhere(
        (state) => state.status == PosStatus.success,
      );

      expect(loaded.activeShift, isNull);
      expect(loaded.customers.single.name, 'Pelanggan QA');
      expect(repository.customerFetches, 1);
    },
  );
}
