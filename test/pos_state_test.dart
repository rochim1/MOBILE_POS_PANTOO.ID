import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

void main() {
  const product = PosProduct(
    id: 'p1',
    code: 'SKU-1',
    name: 'Produk',
    category: 'Umum',
    price: 10000,
    stock: 5,
  );

  test('grand total uses authoritative server pricing preview', () {
    final state = PosState(
      cart: {product: 2},
      pricingPreview: const {
        'subtotal': 20000,
        'promo_discount': 5000,
        'total_after_discount': 15000,
      },
    );
    expect(state.subTotal, 20000);
    expect(state.grandTotal, 15000);
  });

  test('local total remains available before pricing preview', () {
    final state = PosState(cart: {product: 2}, manualDiscountPercent: 10);
    expect(state.manualDiscount, 2000);
    expect(state.grandTotal, 18000);
  });

  test('server price level and configured tax form the payable total', () {
    final state = PosState(
      cart: {product: 2},
      salesChannel: 'marketplace',
      customerSegment: 'reseller',
      priceLevel: 'grosir',
      taxPercent: 11,
      pricingPreview: const {
        'subtotal': 18000,
        'total_after_discount': 18000,
        'items': [
          {'inventaris_id': 'p1', 'harga_jual': 9000},
        ],
      },
    );
    expect(state.unitPriceFor(product), 9000);
    expect(state.taxAmount, 1980);
    expect(state.grandTotal, 19980);
  });

  test('promo and cashier selections use server-backed state', () {
    const state = PosState(
      orderType: 'delivery',
      favoriteProductIds: {'p1'},
      pricingPreview: {
        'promo_applied': true,
        'promo_discount': 2500,
        'total_after_discount': 7500,
      },
    );
    expect(state.promoApplied, isTrue);
    expect(state.promoDiscount, 2500);
    expect(state.orderType, 'delivery');
    expect(state.favoriteProductIds, contains('p1'));
  });

  test('non-stock service and deposit remain sellable with zero stock', () {
    const service = PosProduct(
      id: 'service-1',
      code: 'SVC-1',
      name: 'Layanan',
      category: 'Layanan',
      productType: 'service',
      tracksStock: false,
      price: 50000,
      stock: 0,
    );
    expect(service.isUnavailableForSale(trackStock: true), isFalse);
    expect(product.isUnavailableForSale(trackStock: true), isFalse);
    const emptyPhysicalProduct = PosProduct(
      id: 'empty-1',
      code: 'EMPTY-1',
      name: 'Produk Habis',
      category: 'Umum',
      price: 10000,
      stock: 0,
    );
    expect(emptyPhysicalProduct.isUnavailableForSale(trackStock: true), isTrue);
    expect(
      emptyPhysicalProduct.isUnavailableForSale(trackStock: false),
      isFalse,
    );
  });
}
