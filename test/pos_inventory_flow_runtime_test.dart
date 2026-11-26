import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';

class SeededPosBloc extends PosBloc {
  SeededPosBloc(PosRepository repository) : super(posRepository: repository) {
    emit(
      state.copyWith(
        cart: {
          const PosProduct(
            id: 'service',
            code: 'SVC',
            name: 'Service',
            category: 'Service',
            price: 1000,
            stock: 0,
          ): 2,
        },
        manualUnitPrices: const {'service': 1750},
        selectedUnits: const {'service': 'unit'},
        orderType: 'service',
        salesChannel: 'retail',
        priceLevel: 'retail',
      ),
    );
  }
}

class RuntimeRepository extends Fake implements PosRepository {
  String actor = 'cashier';
  Map<String, dynamic> runtime = {
    'inventory_policy': {'inventory_profile': 'custom'},
    'default_sales_channel': 'other',
    'default_price_level': 'other',
  };
  Completer<Map<String, dynamic>>? pending;
  bool fail = false;
  @override
  String get activeOperatorId => actor;
  @override
  String get terminalUserId => 'owner';
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async {
    if (fail) throw StateError('network');
    return pending?.future ?? runtime;
  }
}

void main() {
  test(
    'verified refresh rebuilds inventory menu configuration without resetting checkout',
    () async {
      final repo = RuntimeRepository(), done = Completer<bool>();
      final bloc = SeededPosBloc(repo);
      final before = bloc.state;
      bloc.add(
        RefreshPosRuntimeConfig(preserveCheckout: true, completion: done),
      );
      expect(await done.future, true);
      expect(bloc.state.runtimeConfig, repo.runtime);
      expect(bloc.state.cart, before.cart);
      expect(bloc.state.cart.values.single, 2);
      expect(bloc.state.manualUnitPrices, before.manualUnitPrices);
      expect(bloc.state.selectedUnits, before.selectedUnits);
      expect(bloc.state.orderType, before.orderType);
      expect(bloc.state.salesChannel, before.salesChannel);
      expect(bloc.state.priceLevel, before.priceLevel);
      await bloc.close();
    },
  );
  for (final offline in [false, true]) {
    test(
      'failed or cached runtime ($offline) does not acknowledge menu synchronization',
      () async {
        final repo = RuntimeRepository()..fail = !offline;
        repo.runtime = {'_offline_snapshot': true};
        final bloc = PosBloc(posRepository: repo), done = Completer<bool>();
        bloc.add(
          RefreshPosRuntimeConfig(preserveCheckout: true, completion: done),
        );
        expect(await done.future, false);
        expect(bloc.state.runtimeConfig, isEmpty);
        await bloc.close();
      },
    );
  }
  test(
    'late runtime for a previous operator cannot update the current menu',
    () async {
      final repo = RuntimeRepository()..pending = Completer();
      final bloc = PosBloc(posRepository: repo), done = Completer<bool>();
      bloc.add(
        RefreshPosRuntimeConfig(preserveCheckout: true, completion: done),
      );
      await Future<void>.delayed(Duration.zero);
      repo.actor = 'another-cashier';
      repo.pending!.complete(repo.runtime);
      expect(await done.future, false);
      expect(bloc.state.runtimeConfig, isEmpty);
      await bloc.close();
    },
  );
}
