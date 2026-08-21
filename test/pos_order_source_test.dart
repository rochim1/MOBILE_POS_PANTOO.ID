import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';

void main() {
  test('order lama tanpa source tetap dapat dibaca', () {
    final order = PosOrder.fromPendingOrderJson({
      '_id': 'legacy-order',
      'order_no': 'ORD-001',
      'source': null,
    });

    expect(order.source, 'kasir_mobile_invoice');
  });

  test('source order online dipertahankan dari backend', () {
    final order = PosOrder.fromPendingOrderJson({
      '_id': 'online-order',
      'order_no': 'ORD-002',
      'source': 'marketplace',
    });

    expect(order.source, 'marketplace');
  });
}
