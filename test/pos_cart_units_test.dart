import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

void main() {
  const product = PosProduct(
    id: 'p1',
    code: 'P1',
    name: 'Air mineral',
    category: 'Minuman',
    price: 2000,
    stock: 24,
    baseUnit: 'botol',
    unitConversions: [
      {'unit': 'botol', 'factor': 1},
      {'unit': 'dus', 'factor': 12},
    ],
  );

  test('pilihan satuan mengubah jumlah dasar dan harga offline', () {
    final state = PosState(
      cart: {product: 2},
      selectedUnits: const {'p1': 'dus'},
    );
    expect(product.saleUnits, ['botol', 'dus']);
    expect(state.unitFor(product), 'dus');
    expect(state.baseQuantityFor(product, 2), 24);
    expect(state.unitPriceFor(product), 24000);
    expect(state.baseSubtotal, 48000);
  });

  test('pesanan tertahan mempertahankan satuan pilihan', () {
    const store = PosStore(
      id: 's1',
      name: 'Toko',
      status: 'active',
      branchId: 'b1',
    );
    final order = HoldOrder(
      id: 'h1',
      time: DateTime(2026),
      cart: {product: 1},
      selectedUnits: const {'p1': 'dus'},
      customer: null,
      store: store,
      notes: '',
      manualDiscountPercent: 0,
      promoCode: '',
      discountPolicy: 'stack',
      orderType: 'take_away',
    );
    final restored = HoldOrder.fromJson(order.toJson());
    expect(restored.selectedUnits['p1'], 'dus');
  });
}
