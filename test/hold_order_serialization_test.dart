import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';

void main() {
  test('held order dapat disimpan dan dipulihkan tanpa kehilangan scope', () {
    const product = PosProduct(
      id: 'product-1',
      code: 'SKU-001',
      name: 'Produk Test',
      category: 'barang_dagangan',
      price: 15000,
      stock: 12,
      barcode: '8990001',
      imageUrl: 'https://example.test/product.jpg',
    );
    const store = PosStore(
      id: 'store-1',
      name: 'Toko Utama',
      status: 'active',
      branchId: 'warehouse-1',
    );
    const customer = PosCustomer(
      id: 'customer-1',
      name: 'Pelanggan Test',
      phone: '08123456789',
      priceLevel: 'regular',
    );
    final source = HoldOrder(
      id: 'HOLD-TEST',
      time: DateTime.utc(2026, 8, 13, 10),
      cart: {product: 3},
      customer: customer,
      store: store,
      notes: 'Tanpa plastik',
      manualDiscountPercent: 5,
      promoCode: 'PROMO5',
      discountPolicy: 'best_of_manual_or_promo',
      orderType: 'take_away',
      salesChannel: 'marketplace',
      customerSegment: 'reseller',
      priceLevel: 'grosir',
    );

    final restored = HoldOrder.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.store.id, 'store-1');
    expect(restored.customer?.id, 'customer-1');
    expect(restored.cart.keys.single.id, 'product-1');
    expect(restored.cart.keys.single.imageUrl, product.imageUrl);
    expect(restored.cart.values.single, 3);
    expect(restored.discountPolicy, 'best_of_manual_or_promo');
    expect(restored.salesChannel, 'marketplace');
    expect(restored.customerSegment, 'reseller');
    expect(restored.priceLevel, 'grosir');
  });
}
