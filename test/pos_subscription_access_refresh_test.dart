import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

const product = PosProduct(
  id: 'qa-item',
  code: 'QA',
  name: 'Barang QA',
  price: 1000,
  stock: 50,
  category: 'Barang',
);

class RecoveryRepository extends Fake implements PosRepository {
  bool closed = false;
  int catalogueReads = 0;
  @override
  String get activeOperatorId => 'qa-cashier';
  @override
  String get terminalUserId => 'qa-terminal';
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'allow_out_of_shift': false,
    'permissions': {'view_shifts': true, 'use_cashier': true},
  };
  @override
  Future<List<PosStore>> getStores() async => const [
    PosStore(
      id: 'qa-store',
      name: 'Toko QA',
      branchId: 'qa-branch',
      status: 'active',
      shiftMode: 'per_operator',
    ),
  ];
  @override
  Future<Map<String, dynamic>?> getActiveShiftForStore(String tokoId) async =>
      closed
      ? null
      : {
          '_id': 'qa-shift',
          'toko_id': tokoId,
          'kasir_user_id': 'qa-cashier',
          'status': 'open',
          'shift_mode': 'per_operator',
        };
  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async {
    catalogueReads++;
    return [product];
  }
}

class DraftBloc extends PosBloc {
  DraftBloc(RecoveryRepository repo) : super(posRepository: repo);
  void seedDraft() => emit(
    PosState(
      cart: {product: 2},
      manualUnitPrices: {product.id: 1500},
      manualDiscountPercent: 5,
      activeShift: const {'_id': 'old-shift', 'toko_id': 'qa-store'},
    ),
  );
}

void main() {
  test(
    'recovery loads only permitted store and shift context without fetching catalog',
    () async {
      final repo = RecoveryRepository();
      final bloc = DraftBloc(repo);
      addTearDown(bloc.close);
      bloc.add(const RefreshPosAccess());
      await bloc.stream.firstWhere((s) => s.status == PosStatus.success);
      expect(bloc.state.stores.single.id, 'qa-store');
      expect(bloc.state.activeShift?['_id'], 'qa-shift');
      expect(repo.catalogueReads, 0);
    },
  );
  test(
    'renewal preserves draft and edited prices, and clears a shift closed during expiry',
    () async {
      final repo = RecoveryRepository()..closed = true;
      final bloc = DraftBloc(repo)..seedDraft();
      addTearDown(bloc.close);
      bloc.add(const RefreshPosAccess(refreshProducts: true));
      await bloc.stream.firstWhere((s) => s.status == PosStatus.success);
      expect(bloc.state.activeShift, isNull);
      expect(bloc.state.cart[product], 2);
      expect(bloc.state.manualUnitPrices[product.id], 1500);
      expect(bloc.state.manualDiscountPercent, 5);
      expect(bloc.state.checkoutSyncFailed, false);
      expect(repo.catalogueReads, 0);
    },
  );
}
