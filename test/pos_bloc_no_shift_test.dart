import 'dart:async';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

class _NoShiftRepository extends Fake implements PosRepository {
  _NoShiftRepository({this.allowOutOfShift = false});

  final bool allowOutOfShift;
  int customerFetches = 0;
  int dashboardFetches = 0;
  @override
  Future<Map<String, dynamic>> getDashboardData({int days = 7}) async {
    dashboardFetches++;
    return {};
  }

  @override
  String get activeOperatorId => 'qa-cashier';
  @override
  String get terminalUserId => 'qa-terminal';

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
  Future<Map<String, dynamic>?> getActiveShiftForStore(String tokoId) async =>
      null;

  @override
  Future<({List<PosOrder> items, bool hasMore})> getOrdersPage({
    int page = 0,
    int limit = 20,
  }) async => throw StateError('Riwayat tidak boleh diambil sebelum shift');
}

class _CatalogFailureRepository extends _NoShiftRepository {
  @override
  Future<({List<PosOrder> items, bool hasMore})> getOrdersPage({
    int page = 0,
    int limit = 20,
  }) async => (items: <PosOrder>[], hasMore: false);

  @override
  Future<Map<String, dynamic>?> getActiveShiftForStore(String tokoId) async => {
    '_id': 'shift-qa',
    'toko_id': tokoId,
    'kasir_user_id': activeOperatorId,
    'status': 'open',
  };

  @override
  Future<List<PosStore>> getStores() async => const [
    PosStore(
      id: 'store-qa',
      name: 'Toko QA',
      status: 'active',
      branchId: 'branch-qa',
      shiftMode: 'per_operator',
    ),
  ];

  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async =>
      throw StateError('Catalog rejected');
}

class _BeforeShiftCatalogRepository extends _CatalogFailureRepository {
  int catalogFetches = 0;
  @override
  Future<Map<String, dynamic>?> getActiveShiftForStore(String tokoId) async =>
      null;
  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async {
    catalogFetches++;
    throw StateError('Akses stok dibatasi ke lokasi toko pada shift aktif');
  }
}

class _ReturnApproverRepository extends _CatalogFailureRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'permissions': {
      'use_cashier': true,
      'view_shifts': false,
      'view_returns': true,
      'approve_returns': true,
    },
  };
  @override
  Future<Map<String, dynamic>?> getActiveShiftForStore(String tokoId) async =>
      throw StateError('Approver cannot read shifts');
}

class _StoreFailureRepository extends _NoShiftRepository {
  @override
  Future<List<PosStore>> getStores() async =>
      throw StateError('Store fetch failed');
}

class _ParallelLoadRepository extends _CatalogFailureRepository {
  final allStarted = Completer<void>();
  final release = Completer<void>();
  int started = 0;

  Future<void> waitForOtherRequests() async {
    if (++started == 4) allStarted.complete();
    await release.future;
  }

  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'permissions': {
      'view_shifts': true,
      'use_cashier': true,
      'view_customers': true,
      'view_transactions': true,
    },
  };

  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async {
    expect(branchId, 'branch-qa');
    await waitForOtherRequests();
    return [];
  }

  @override
  Future<List<PosCustomer>> getCustomers() async {
    await waitForOtherRequests();
    return [];
  }

  @override
  Future<({List<PosOrder> items, bool hasMore})> getOrdersPage({
    int page = 0,
    int limit = 20,
  }) async {
    await waitForOtherRequests();
    return (items: <PosOrder>[], hasMore: false);
  }

  @override
  Future<List<HoldOrder>> getHeldOrders({
    required String storeId,
    required String shiftId,
  }) async {
    expect(storeId, 'store-qa');
    expect(shiftId, 'shift-qa');
    await waitForOtherRequests();
    return [];
  }
}

void main() {
  test('verified checkout loads independent data concurrently', () async {
    final repository = _ParallelLoadRepository();
    final bloc = PosBloc(posRepository: repository);
    addTearDown(bloc.close);
    final loaded = bloc.stream.firstWhere((s) => s.status == PosStatus.success);
    bloc.add(LoadPosData());
    try {
      await repository.allStarted.future.timeout(const Duration(seconds: 2));
      expect(bloc.state.status, PosStatus.loading);
      expect(bloc.state.activeShift?['_id'], 'shift-qa');
    } finally {
      repository.release.complete();
    }
    expect((await loaded).checkoutSyncFailed, isFalse);
  });
  test(
    'restricted cashier can open shift before reading protected catalog',
    () async {
      final repository = _BeforeShiftCatalogRepository();
      final bloc = PosBloc(posRepository: repository);
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      final loaded = await bloc.stream.firstWhere(
        (s) => s.status == PosStatus.success || s.status == PosStatus.failure,
      );
      expect(loaded.status, PosStatus.success);
      await Future<void>.delayed(Duration.zero);
      expect(repository.dashboardFetches, 0);
      expect(repository.catalogFetches, 0);
      expect(loaded.stores.single.id, 'store-qa');
      expect(loaded.checkoutSyncFailed, isFalse);
      expect(loaded.activeShift, isNull);
    },
  );
  test(
    'return approver does not need shift permission to reach the approved workspace',
    () async {
      final bloc = PosBloc(posRepository: _ReturnApproverRepository());
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      final loaded = await bloc.stream.firstWhere(
        (s) => s.status == PosStatus.success || s.status == PosStatus.failure,
      );
      expect(loaded.status, PosStatus.success);
      expect(loaded.runtimeConfig['permissions']['approve_returns'], isTrue);
    },
  );
  test(
    'failed store discovery never erases already verified permission navigation',
    () async {
      final bloc = PosBloc(posRepository: _StoreFailureRepository());
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      final loaded = await bloc.stream.firstWhere(
        (s) => s.status == PosStatus.failure,
      );
      expect(loaded.runtimeConfig['permissions']['view_shifts'], isTrue);
    },
  );
  test(
    'kegagalan katalog tidak menghilangkan toko dan izin yang sudah dimuat',
    () async {
      final bloc = PosBloc(posRepository: _CatalogFailureRepository());
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      final failed = await bloc.stream.firstWhere(
        (state) => state.status == PosStatus.failure,
      );
      expect(failed.stores.single.id, 'store-qa');
      expect(failed.runtimeConfig['permissions']['view_shifts'], isTrue);
      expect(failed.runtimeConfig['permissions']['use_cashier'], isTrue);
      expect(failed.products, isEmpty);
    },
  );
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
