import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_inventory_barcode_match.dart';

void main() {
  final items = <Map<String, dynamic>>[
    {'inventaris_id': 'a', 'barcode': '8991234567890', 'sku': 'SABUN-1'},
    {'inventaris_id': 'b', 'barcode': '8991234567891', 'sku': 'SABUN-2'},
  ];

  test('barcode lookup is exact, not a partial name or code match', () {
    expect(
      matchInventoryBarcode(items, '8991234567890').single['inventaris_id'],
      'a',
    );
    expect(matchInventoryBarcode(items, '899123'), isEmpty);
    expect(
      matchInventoryBarcode(items, ' SABUN-2 ').single['inventaris_id'],
      'b',
    );
  });

  test('duplicate codes remain visible so caller can refuse ambiguity', () {
    final duplicates = [
      ...items,
      {'inventaris_id': 'c', 'barcode': '8991234567890'},
    ];
    expect(matchInventoryBarcode(duplicates, '8991234567890'), hasLength(2));
    expect(matchInventoryBarcode(items, '  '), isEmpty);
  });
}
