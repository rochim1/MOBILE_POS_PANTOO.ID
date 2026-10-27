import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_order_transition_policy.dart';

void main() {
  test(
    'transisi status pesanan mengikuti backend dan tidak melompati tahap',
    () {
      expect(nextPosOrderStatus('Baru'), 'Diproses');
      expect(nextPosOrderStatus('Diproses'), 'Siap');
      expect(nextPosOrderStatus('Siap'), 'Disajikan');
      expect(nextPosOrderStatus('Disajikan'), 'Selesai');
      expect(nextPosOrderStatus('Selesai'), isNull);
    },
  );

  test('web order bayar dahulu tidak dapat diproses sebelum lunas', () {
    const unpaid = PosOrderDetail(
      paymentStatus: 'belum_bayar',
      webOrderPayBeforeProcessing: true,
    );
    const paid = PosOrderDetail(
      paymentStatus: 'lunas',
      webOrderPayBeforeProcessing: true,
    );
    expect(shouldPayBeforeOrderTransition(unpaid, 'Diproses'), isTrue);
    expect(shouldPayBeforeOrderTransition(paid, 'Diproses'), isFalse);
  });

  test(
    'pesanan biasa boleh diproses dulu, tetapi harus lunas untuk selesai',
    () {
      const order = PosOrderDetail(paymentStatus: 'belum_bayar');
      expect(shouldPayBeforeOrderTransition(order, 'Diproses'), isFalse);
      expect(shouldPayBeforeOrderTransition(order, 'Selesai'), isTrue);
    },
  );
}
