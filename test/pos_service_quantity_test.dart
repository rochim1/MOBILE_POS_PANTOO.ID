import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_service_quantity.dart';

void main() {
  test('satuan/package ignore stale default weight; kiloan retains weight', () {
    for (final mode in ['satuan', 'paket']) {
      expect(
        posServiceQuantitySummary({
          'service_mode': mode,
          'weight_kg': 1,
          'item_count': 2,
        }),
        '2 item',
      );
    }
    expect(
      posServiceQuantitySummary({
        'service_mode': 'kiloan',
        'weight_kg': 1.5,
        'item_count': 2,
      }),
      '1.5 kg · 2 item',
    );
    expect(
      posServiceQuantitySummary({'weight_kg': 1, 'item_count': 2}),
      '1 kg · 2 item',
    );
  });
}
