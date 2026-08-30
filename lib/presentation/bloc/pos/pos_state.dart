import 'package:equatable/equatable.dart';
import '../../../domain/models/pos_product.dart';
import '../../../domain/models/pos_customer.dart';
import '../../../domain/models/pos_store.dart';
import '../../../domain/models/hold_order.dart';
import '../../../domain/models/pos_order.dart';
import '../../../domain/models/pos_transaction_result.dart';

enum PosStatus { initial, loading, success, failure, paymentSuccess }

class PosState extends Equatable {
  final PosStatus status;
  final List<PosProduct> products;
  final List<PosCustomer> customers;
  final List<PosStore> stores;
  final List<PosOrder> orders;
  final int ordersPage;
  final bool ordersHasMore;
  final bool ordersLoadingMore;
  final PosCustomer? selectedCustomer;

  final Map<PosProduct, int> cart;
  final List<HoldOrder> heldOrders;

  final double manualDiscountPercent;
  final String promoCode;
  final String discountPolicy; // stack, promo_only, manual_only, best_of
  final String orderType;
  final String salesChannel;
  final String customerSegment;
  final String priceLevel;
  final double taxPercent;
  final Set<String> favoriteProductIds;

  final Map<String, dynamic>? activeShift;

  final Map<String, dynamic>? dashboardData;
  final Map<String, dynamic> runtimeConfig;

  final bool isGridView;

  final String errorMessage;
  final PosTransactionResult? lastTransaction;
  final Map<String, dynamic>? pricingPreview;

  const PosState({
    this.status = PosStatus.initial,
    this.products = const [],
    this.customers = const [],
    this.stores = const [],
    this.orders = const [],
    this.ordersPage = 0,
    this.ordersHasMore = false,
    this.ordersLoadingMore = false,
    this.selectedCustomer,
    this.cart = const {},
    this.heldOrders = const [],
    this.manualDiscountPercent = 0,
    this.promoCode = '',
    this.discountPolicy = 'stack',
    this.orderType = 'take_away',
    this.salesChannel = 'retail',
    this.customerSegment = 'regular',
    this.priceLevel = 'retail',
    this.taxPercent = 0,
    this.favoriteProductIds = const {},
    this.activeShift,
    this.dashboardData,
    this.runtimeConfig = const {},
    this.isGridView = false,
    this.errorMessage = '',
    this.lastTransaction,
    this.pricingPreview,
  });

  PosState copyWith({
    PosStatus? status,
    List<PosProduct>? products,
    List<PosCustomer>? customers,
    List<PosStore>? stores,
    List<PosOrder>? orders,
    int? ordersPage,
    bool? ordersHasMore,
    bool? ordersLoadingMore,
    PosCustomer? selectedCustomer,
    bool clearSelectedCustomer = false,
    Map<PosProduct, int>? cart,
    List<HoldOrder>? heldOrders,
    double? manualDiscountPercent,
    String? promoCode,
    String? discountPolicy,
    String? orderType,
    String? salesChannel,
    String? customerSegment,
    String? priceLevel,
    double? taxPercent,
    Set<String>? favoriteProductIds,
    Map<String, dynamic>? activeShift,
    bool clearActiveShift = false,
    Map<String, dynamic>? dashboardData,
    Map<String, dynamic>? runtimeConfig,
    bool? isGridView,
    String? errorMessage,
    PosTransactionResult? lastTransaction,
    Map<String, dynamic>? pricingPreview,
    bool clearPricingPreview = false,
  }) {
    return PosState(
      status: status ?? this.status,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      stores: stores ?? this.stores,
      orders: orders ?? this.orders,
      ordersPage: ordersPage ?? this.ordersPage,
      ordersHasMore: ordersHasMore ?? this.ordersHasMore,
      ordersLoadingMore: ordersLoadingMore ?? this.ordersLoadingMore,
      selectedCustomer: clearSelectedCustomer
          ? null
          : (selectedCustomer ?? this.selectedCustomer),
      cart: cart ?? this.cart,
      heldOrders: heldOrders ?? this.heldOrders,
      manualDiscountPercent:
          manualDiscountPercent ?? this.manualDiscountPercent,
      promoCode: promoCode ?? this.promoCode,
      discountPolicy: discountPolicy ?? this.discountPolicy,
      orderType: orderType ?? this.orderType,
      salesChannel: salesChannel ?? this.salesChannel,
      customerSegment: customerSegment ?? this.customerSegment,
      priceLevel: priceLevel ?? this.priceLevel,
      taxPercent: taxPercent ?? this.taxPercent,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      dashboardData: dashboardData ?? this.dashboardData,
      runtimeConfig: runtimeConfig ?? this.runtimeConfig,
      isGridView: isGridView ?? this.isGridView,
      errorMessage: errorMessage ?? this.errorMessage,
      lastTransaction: lastTransaction ?? this.lastTransaction,
      pricingPreview: clearPricingPreview
          ? null
          : (pricingPreview ?? this.pricingPreview),
    );
  }

  // Computed properties
  double get baseSubtotal => cart.entries.fold(
    0,
    (sum, entry) => sum + (entry.key.price * entry.value),
  );

  double get subTotal =>
      (pricingPreview?['subtotal'] as num?)?.toDouble() ?? baseSubtotal;

  int get totalItems => cart.values.fold(0, (sum, qty) => sum + qty);

  double get manualDiscount => subTotal * (manualDiscountPercent / 100);

  bool get promoApplied => pricingPreview?['promo_applied'] == true;
  double get promoDiscount =>
      (pricingPreview?['promo_discount'] as num?)?.toDouble() ?? 0;

  double get totalDiscount {
    if (discountPolicy == 'promo_only') return promoDiscount;
    if (discountPolicy == 'manual_only') return manualDiscount;
    if (discountPolicy == 'best_of_manual_or_promo') {
      return manualDiscount > promoDiscount ? manualDiscount : promoDiscount;
    }
    // stack
    return manualDiscount + promoDiscount;
  }

  double get grandTotal {
    final serverTotal = (pricingPreview?['total_after_discount'] as num?)
        ?.toDouble();
    if (serverTotal != null) return serverTotal + taxAmount;
    final total = subTotal - totalDiscount;
    return total > 0 ? total + taxAmount : 0;
  }

  double get taxableAmount {
    final serverTotal = (pricingPreview?['total_after_discount'] as num?)
        ?.toDouble();
    if (serverTotal != null) return serverTotal.clamp(0, double.infinity);
    return (subTotal - totalDiscount).clamp(0, double.infinity);
  }

  double get taxAmount => (taxableAmount * taxPercent / 100).roundToDouble();

  double unitPriceFor(PosProduct product) {
    final items = pricingPreview?['items'] as List?;
    final match = items?.whereType<Map>().where(
      (item) => item['inventaris_id']?.toString() == product.id,
    );
    if (match != null && match.isNotEmpty) {
      return (match.first['harga_jual'] as num?)?.toDouble() ?? product.price;
    }
    return product.price;
  }

  String get defaultSalesChannel =>
      runtimeConfig['default_sales_channel']?.toString() ?? 'retail';
  // Field legacy tetap ada pada snapshot/order lama, tetapi tidak lagi menjadi
  // konteks harga yang dapat dikonfigurasi.
  String get defaultCustomerSegment => 'regular';
  String get defaultPriceLevel =>
      runtimeConfig['default_price_level']?.toString() ?? 'retail';
  List<String> get salesChannelOptions =>
      <dynamic>[
            ...((runtimeConfig['sales_channel_options'] as List?) ??
                const ['retail']),
            salesChannel,
          ]
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
  List<String> get priceLevelOptions =>
      <dynamic>[
            ...((runtimeConfig['price_level_options'] as List?) ??
                const ['retail']),
            priceLevel,
          ]
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
  double get configuredTaxPercent =>
      (runtimeConfig['tax_percent'] as num?)?.toDouble() ?? 0;

  @override
  List<Object?> get props => [
    status,
    products,
    customers,
    stores,
    orders,
    ordersPage,
    ordersHasMore,
    ordersLoadingMore,
    selectedCustomer,
    cart,
    heldOrders,
    manualDiscountPercent,
    promoCode,
    discountPolicy,
    orderType,
    salesChannel,
    customerSegment,
    priceLevel,
    taxPercent,
    favoriteProductIds,
    activeShift,
    dashboardData,
    runtimeConfig,
    isGridView,
    errorMessage,
    lastTransaction,
    pricingPreview,
  ];
}
