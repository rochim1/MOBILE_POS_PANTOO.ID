import 'pos_product.dart';
import 'pos_customer.dart';
import 'pos_store.dart';

class HoldOrder {
  final String id;
  final DateTime time;
  final Map<PosProduct, int> cart;
  final PosCustomer? customer;
  final PosStore store;
  final String notes;
  final double manualDiscountPercent;
  final String promoCode;
  final String discountPolicy;
  final String orderType;
  final String salesChannel;
  final String customerSegment;
  final String priceLevel;

  HoldOrder({
    required this.id,
    required this.time,
    required this.cart,
    required this.customer,
    required this.store,
    required this.notes,
    required this.manualDiscountPercent,
    required this.promoCode,
    required this.discountPolicy,
    required this.orderType,
    this.salesChannel = 'retail',
    this.customerSegment = 'regular',
    this.priceLevel = 'retail',
  });

  factory HoldOrder.fromJson(Map<String, dynamic> json) {
    final cartRows = json['cart'] as List<dynamic>? ?? const [];
    return HoldOrder(
      id: json['id']?.toString() ?? '',
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      cart: {
        for (final row in cartRows)
          PosProduct.fromJson(Map<String, dynamic>.from(row['product'] as Map)):
              (row['quantity'] as num?)?.toInt() ?? 0,
      },
      customer: json['customer'] == null
          ? null
          : PosCustomer.fromJson(
              Map<String, dynamic>.from(json['customer'] as Map),
            ),
      store: PosStore.fromJson(Map<String, dynamic>.from(json['store'] as Map)),
      notes: json['notes']?.toString() ?? '',
      manualDiscountPercent:
          (json['manualDiscountPercent'] as num?)?.toDouble() ?? 0,
      promoCode: json['promoCode']?.toString() ?? '',
      discountPolicy: json['discountPolicy']?.toString() ?? 'stack',
      orderType: json['orderType']?.toString() ?? 'take_away',
      salesChannel: json['salesChannel']?.toString() ?? 'retail',
      customerSegment: json['customerSegment']?.toString() ?? 'regular',
      priceLevel: json['priceLevel']?.toString() ?? 'retail',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time.toIso8601String(),
    'cart': cart.entries
        .map(
          (entry) => {'product': entry.key.toJson(), 'quantity': entry.value},
        )
        .toList(),
    'customer': customer?.toJson(),
    'store': store.toJson(),
    'notes': notes,
    'manualDiscountPercent': manualDiscountPercent,
    'promoCode': promoCode,
    'discountPolicy': discountPolicy,
    'orderType': orderType,
    'salesChannel': salesChannel,
    'customerSegment': customerSegment,
    'priceLevel': priceLevel,
  };
}
