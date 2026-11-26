import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transfer_choices.dart';

Map<String, dynamic> location(String id, String type, [String? outlet]) => {
  '_id': id,
  'warehouse_type': type,
  'linked_toko_id': outlet,
  'gedung': [{'kode_gedung': 'G1'}],
};

void main() {
  final store = location('a', 'store', 'A');
  final other = location('b', 'store', 'B');
  final display = location('d', 'display', 'A');
  final wrong = location('w', 'display', 'B');
  final central = location('c', 'central');
  const inter = TransferEditorMode.between;
  const internal = TransferEditorMode.internal;
  test('same outlet store/display is internal, never inter-warehouse', () {
    const choices = TransferLocationChoices();
    expect(choices.allows(store, display, internal), isTrue);
    expect(choices.allows(display, store, internal), isTrue);
    expect(choices.allows(store, display, inter), isFalse);
    expect(choices.allows(store, wrong, internal), isFalse);
    expect(choices.allows(store, wrong, inter), isFalse);
    expect(choices.infer(store, wrong), internal);
  });
  test(
    'rack movement stays in same warehouse, inter transfer changes warehouse',
    () {
      const choices = TransferLocationChoices();
      expect(choices.allows(store, store, internal), isTrue);
      expect(choices.allows(store, store, inter), isFalse);
      expect(choices.allows(store, other, inter), isTrue);
      expect(choices.allows(store, other, internal), isFalse);
      expect(choices.infer(store, store), internal);
      expect(choices.infer(store, other), inter);
    },
  );
  for (final profile in ['centralized', 'advanced']) {
    test('$profile requires central endpoint except permitted own display', () {
      final choices = TransferLocationChoices(
        policy: {'inventory_profile': profile},
      );
      expect(choices.allows(store, other, inter), isFalse);
      expect(choices.allows(central, store, inter), isTrue);
      expect(choices.allows(store, central, inter), isTrue);
      expect(choices.allows(store, store, internal), isFalse);
      expect(choices.allows(central, central, internal), isTrue);
      expect(choices.allows(store, display, internal), profile == 'advanced');
    });
  }
  test('simple profile offers no transfers or internal stock moves', () {
    const choices = TransferLocationChoices(
      policy: {'inventory_profile': 'simple'},
    );
    expect(choices.allows(central, store, inter), isFalse);
    expect(choices.allows(central, central, internal), isFalse);
  });
  test(
    'custom explicit flags restrict warehouse types without forcing transit',
    () {
      const choices = TransferLocationChoices(
        policy: {
          'inventory_profile': 'custom',
          'use_store_warehouse': true,
          'use_display_stock': false,
        },
      );
      expect(choices.allows(store, other, inter), isTrue);
      expect(choices.allows(store, display, internal), isFalse);
      expect(choices.allows(store, store, internal), isTrue);
    },
  );
  for (final unavailable in [
    {'is_transfer_source': false},
    {'is_active': false},
    {'warehouse_type': 'in_transit'},
    {'warehouse_type': 'quarantine'},
  ]) {
    test('unusable source $unavailable is never offered', () {
      const choices = TransferLocationChoices();
      expect(choices.allows({...store, ...unavailable}, other, inter), isFalse);
    });
  }
  test('destination permission and unlinked display fail closed', () {
    const choices = TransferLocationChoices();
    expect(
      choices.allows(store, {
        ...other,
        'is_transfer_destination': false,
      }, inter),
      isFalse,
    );
    expect(choices.allows(store, location('u', 'display'), internal), isFalse);
    expect(choices.allows(null, other, inter), isFalse);
    expect(choices.allows(store, null, inter), isFalse);
  });
  test('warehouse without detail locations cannot offer a same-location dead end', () {
    const choices = TransferLocationChoices();
    final plain = {...store, 'gedung': <Map<String, dynamic>>[]};
    expect(choices.allows(plain, plain, internal), isFalse);
    expect(choices.sources([plain], internal), isEmpty);
    expect(choices.destinations([plain, other], plain, inter), [other]);
    expect(choices.usable({'_id': ''}, source: true), isFalse);
  });
}
