import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';

void main() {
  test('web order bayar dahulu terbaca dari respons GraphQL', () {
    final order = PosOrderDetail.fromJson(const {
      '_id': 'order-1',
      'status': 'Baru',
      'status_pembayaran': 'belum_bayar',
      'web_order_pay_before_processing': true,
    });
    expect(order.webOrderPayBeforeProcessing, isTrue);
    expect(order.paymentStatus, 'belum_bayar');
  });

  test('order biasa tidak dipaksa bayar sebelum proses', () {
    final order = PosOrderDetail.fromJson(const {'_id': 'order-2'});
    expect(order.webOrderPayBeforeProcessing, isFalse);
  });
}
