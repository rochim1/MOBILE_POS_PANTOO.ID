import '../../../../domain/models/pos_order_detail.dart';

/// Mirrors the allowed aggregate transitions enforced by UpdatePOSOrderStatus.
String? nextPosOrderStatus(String? current) => switch (current) {
  'Baru' => 'Diproses',
  'Diproses' => 'Siap',
  'Siap' => 'Disajikan',
  'Disajikan' => 'Selesai',
  _ => null,
};

bool shouldPayBeforeOrderTransition(PosOrderDetail order, String target) =>
    order.paymentStatus != 'lunas' &&
    (target == 'Selesai' || order.webOrderPayBeforeProcessing);
