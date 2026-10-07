import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_progress.dart';

void main() {
  test('PO completed lama tetap memiliki sisa untuk penerimaan', () {
    final purchase = {
      'status': 'completed',
      'items': [
        {'qty_ordered': 5, 'qty_received': 2, 'conversion_factor': 1},
      ],
    };
    expect(PosPurchaseProgress.hasRemaining(purchase), isTrue);
    expect(PosPurchaseProgress.effectiveStatus(purchase), 'partially_received');
  });

  test('sisa PO kemasan dihitung dalam satuan dasar', () {
    final item = {'qty_ordered': 3, 'qty_received': 1, 'conversion_factor': 12};
    expect(PosPurchaseProgress.orderedBase(item), 36);
    expect(PosPurchaseProgress.receivedBase(item), 12);
    expect(PosPurchaseProgress.remainingInOrderedUnit(item), 2);
  });
}
