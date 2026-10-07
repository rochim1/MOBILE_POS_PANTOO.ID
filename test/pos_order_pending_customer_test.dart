import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_queries.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';

void main() {
  test('pending Web Order keeps customer profile request for payment', () {
    final order = PosOrder.fromPendingOrderJson({
      '_id': 'order-1',
      'order_no': 'PO-1',
      'pelanggan_nama': 'Ayu',
      'pelanggan_telepon': '081234567890',
      'customer_profile_requested': true,
      'grand_total': 25000,
      'items': <Map<String, dynamic>>[],
    });

    expect(order.customer, 'Ayu');
    expect(order.customerPhone, '081234567890');
    expect(order.customerProfileRequested, isTrue);
  });

  test('pending order query includes fulfillment type used by payment policy', () {
    expect(PosQueries.getPendingPOSOrders, contains('tipe_pesanan'));
  });
}
