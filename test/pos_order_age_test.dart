import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_order_age.dart';

void main() {
  final now = DateTime.utc(2026, 9, 26, 12);
  String ago(int minutes) => now.subtract(Duration(minutes: minutes)).toIso8601String();

  test('new kitchen item uses its queue time, not old order creation', () {
    final order = PosOrderDetail(
      status: 'Diproses',
      createdAt: ago(120),
      items: [PosOrderItem(
        preparationMode: 'station',
        productionStatus: 'queued',
        productionStatusHistory: [{'status': 'queued', 'at': ago(5)}],
      )],
    );
    final age = PosOrderAge.forOrder(order, now);
    expect(age.minutes, 5);
    expect(age.tone, PosOrderAgeTone.normal);
    expect(age.phase, 'Menunggu dapur');
  });

  test('ready order uses ready transition for handover SLA', () {
    final order = PosOrderDetail(
      status: 'Siap',
      createdAt: ago(90),
      statusHistory: [{'status': 'Siap', 'at': ago(16)}],
    );
    final age = PosOrderAge.forOrder(order, now,
        warningMinutes: 15, criticalMinutes: 25);
    expect(age.minutes, 16);
    expect(age.tone, PosOrderAgeTone.warning);
    expect(age.phase, 'Menunggu penyerahan');
  });

  test('preparing-only history falls back to its own transition', () {
    final order = PosOrderDetail(
      status: 'Diproses',
      createdAt: ago(120),
      items: [PosOrderItem(
        preparationMode: 'station',
        productionStatus: 'preparing',
        productionStatusHistory: [{'status': 'preparing', 'at': ago(8)}],
      )],
    );
    expect(PosOrderAge.forOrder(order, now).minutes, 8);
  });

  test('legacy ready order without phase timestamp is not falsely red', () {
    final age = PosOrderAge.forOrder(
      PosOrderDetail(status: 'Siap', createdAt: ago(90)), now);
    expect(age.minutes, isNull);
    expect(age.tone, PosOrderAgeTone.normal);
  });

  test('custom SLA threshold controls critical color', () {
    final age = PosOrderAge.forOrder(
      PosOrderDetail(status: 'Baru', createdAt: ago(27)), now,
      warningMinutes: 10, criticalMinutes: 25,
    );
    expect(age.tone, PosOrderAgeTone.critical);
  });

  test('epoch timestamps are accepted for older orders', () {
    final order = PosOrderDetail(
      status: 'Baru',
      createdAt: now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch.toString(),
    );
    expect(PosOrderAge.forOrder(order, now).minutes, 2);
  });
}
