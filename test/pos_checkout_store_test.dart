import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

void main() {
  const first = PosStore(
    id: 'first',
    name: 'First',
    status: 'active',
    branchId: 'a',
  );
  const second = PosStore(
    id: 'second',
    name: 'Second',
    status: 'active',
    branchId: 'b',
  );
  const inactive = PosStore(
    id: 'inactive',
    name: 'Inactive',
    status: 'inactive',
    branchId: 'c',
  );
  const unlinked = PosStore(id: 'unlinked', name: 'Unlinked', status: 'active');
  test(
    'Simple uses its default selling location rather than store sort order',
    () {
      final state = PosState(
        stores: [first, second],
        runtimeConfig: {
          'inventory_profile': 'simple',
          'inventory_policy': {'default_receiving_location_id': 'b'},
        },
      );
      expect(state.checkoutStore?.id, 'second');
    },
  );
  test(
    'Simple does not silently relocate a shift on a non-default location',
    () {
      final state = PosState(
        stores: [first, second],
        activeShift: {'toko_id': 'first'},
        runtimeConfig: {
          'inventory_policy': {
            'inventory_profile': 'simple',
            'default_receiving_location_id': 'b',
          },
        },
      );
      expect(state.checkoutStore, isNull);
    },
  );
  test('without shift resolves the same valid store as the catalog', () {
    final state = PosState(stores: [inactive, unlinked, first, second]);
    expect(state.checkoutStore?.id, 'first');
  });
  test('active shift takes priority over list ordering', () {
    final state = PosState(
      stores: [first, second],
      activeShift: {'toko_id': 'second'},
    );
    expect(state.checkoutStore?.id, 'second');
  });
  test('stale shift never silently bills a different store', () {
    final state = PosState(
      stores: [first],
      activeShift: {'toko_id': 'missing'},
    );
    expect(state.checkoutStore, isNull);
  });
  test('empty store id on an existing shift does not fallback', () {
    final state = PosState(stores: [first], activeShift: {'toko_id': ''});
    expect(state.checkoutStore, isNull);
  });
  test('inactive or unlinked shift store cannot be used', () {
    for (final store in [inactive, unlinked]) {
      final state = PosState(
        stores: [first, store],
        activeShift: {'toko_id': store.id},
      );
      expect(state.checkoutStore, isNull);
    }
  });
  test('no eligible store returns null rather than an empty server id', () {
    expect(const PosState(stores: [inactive, unlinked]).checkoutStore, isNull);
    expect(const PosState().checkoutStore, isNull);
  });
}
