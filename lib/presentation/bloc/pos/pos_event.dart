import 'package:equatable/equatable.dart';
import '../../../domain/models/pos_product.dart';
import '../../../domain/models/pos_customer.dart';
import '../../../domain/models/hold_order.dart';
import '../../../domain/models/pos_order_detail.dart';

abstract class PosEvent extends Equatable {
  const PosEvent();

  @override
  List<Object?> get props => [];
}

class LoadPosData extends PosEvent {}

class RefreshProducts extends PosEvent {}

class UpsertProductLocally extends PosEvent {
  final PosProduct product;
  const UpsertProductLocally(this.product);
  @override
  List<Object> get props => [product];
}

class RemoveProductLocally extends PosEvent {
  final String productId;
  const RemoveProductLocally(this.productId);
  @override
  List<Object> get props => [productId];
}

class RefreshOrders extends PosEvent {}

class LoadMoreOrders extends PosEvent {}

class AddToCart extends PosEvent {
  final PosProduct product;
  const AddToCart(this.product);
  @override
  List<Object> get props => [product];
}

class RemoveFromCart extends PosEvent {
  final PosProduct product;
  const RemoveFromCart(this.product);
  @override
  List<Object> get props => [product];
}

class RemoveCartItem extends PosEvent {
  final PosProduct product;
  const RemoveCartItem(this.product);
  @override
  List<Object> get props => [product];
}

class UpdateQuantity extends PosEvent {
  final PosProduct product;
  final double delta;
  const UpdateQuantity(this.product, this.delta);
  @override
  List<Object> get props => [product, delta];
}

class UpdateCartUnitPrice extends PosEvent {
  final PosProduct product;
  final double price;
  const UpdateCartUnitPrice(this.product, this.price);
  @override
  List<Object> get props => [product, price];
}

class ClearCart extends PosEvent {}

class EditActiveOrder extends PosEvent {
  final PosOrderDetail order;
  const EditActiveOrder(this.order);
  @override
  List<Object?> get props => [order];
}

class SelectCustomer extends PosEvent {
  final PosCustomer? customer;
  const SelectCustomer(this.customer);
  @override
  List<Object?> get props => [customer];
}

class HoldCurrentOrder extends PosEvent {
  final String notes;
  const HoldCurrentOrder(this.notes);
  @override
  List<Object> get props => [notes];
}

class RestoreHeldOrder extends PosEvent {
  final HoldOrder order;
  const RestoreHeldOrder(this.order);
  @override
  List<Object> get props => [order];
}

class RemoveHeldOrder extends PosEvent {
  final HoldOrder order;
  const RemoveHeldOrder(this.order);
  @override
  List<Object> get props => [order];
}

class SubmitPayment extends PosEvent {
  final String paymentMethod;
  final double cashReceived;
  final List<Map<String, dynamic>> payments;
  final String note;
  final String expiredSaleReason;
  final String expiredSaleAuthorizerUsername;
  final String expiredSaleAuthorizerPin;
  final PosCustomer? customerOverride;
  final Map<String, dynamic>? serviceOrder;
  const SubmitPayment({
    required this.paymentMethod,
    this.cashReceived = 0,
    this.payments = const [],
    this.note = '',
    this.expiredSaleReason = '',
    this.expiredSaleAuthorizerUsername = '',
    this.expiredSaleAuthorizerPin = '',
    this.customerOverride,
    this.serviceOrder,
  });
  @override
  List<Object?> get props => [
    paymentMethod,
    cashReceived,
    payments,
    note,
    expiredSaleReason,
    expiredSaleAuthorizerUsername,
    expiredSaleAuthorizerPin,
    customerOverride,
    serviceOrder,
  ];
}

class UpdateDiscount extends PosEvent {
  final double manualDiscountPercent;
  final String promoCode;
  final String discountPolicy;
  const UpdateDiscount({
    required this.manualDiscountPercent,
    required this.promoCode,
    required this.discountPolicy,
  });
  @override
  List<Object> get props => [manualDiscountPercent, promoCode, discountPolicy];
}

class ToggleGridView extends PosEvent {}

class RefreshPricingPreview extends PosEvent {}

class UpdateOrderType extends PosEvent {
  final String orderType;
  const UpdateOrderType(this.orderType);
  @override
  List<Object> get props => [orderType];
}

class SelectOrderTable extends PosEvent {
  final String? tableId;
  final String? tableName;
  const SelectOrderTable({this.tableId, this.tableName});
  @override
  List<Object?> get props => [tableId, tableName];
}

class UpdateSalesContext extends PosEvent {
  final String salesChannel;
  final String customerSegment;
  final String priceLevel;
  final double taxPercent;
  const UpdateSalesContext({
    required this.salesChannel,
    required this.customerSegment,
    required this.priceLevel,
    required this.taxPercent,
  });
  @override
  List<Object> get props => [
    salesChannel,
    customerSegment,
    priceLevel,
    taxPercent,
  ];
}

class ToggleFavoriteProduct extends PosEvent {
  final String productId;
  const ToggleFavoriteProduct(this.productId);
  @override
  List<Object> get props => [productId];
}

class LoadDashboardData extends PosEvent {
  final int days;

  const LoadDashboardData({this.days = 7});

  @override
  List<Object> get props => [days];
}
