import 'package:equatable/equatable.dart';

class PosOrderItem extends Equatable {
  final String? id;
  final String? productName;
  final int? quantity;
  final double? price;
  final String? notes;
  final String? status; // e.g., 'pending', 'preparing', 'served', 'cancelled'

  const PosOrderItem({
    this.id,
    this.productName,
    this.quantity,
    this.price,
    this.notes,
    this.status,
  });

  factory PosOrderItem.fromJson(Map<String, dynamic> json) {
    return PosOrderItem(
      id: json['_id'] as String?,
      productName: (json['nama'] ?? json['product_name']) as String?,
      quantity: (json['qty'] as num?)?.toInt() ?? json['quantity'] as int?,
      price: (json['harga_satuan'] as num? ?? json['price'] as num?)
          ?.toDouble(),
      notes: (json['catatan'] ?? json['notes']) as String?,
      status: json['status'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, productName, quantity, price, notes, status];
}

class PosOrderDetail extends Equatable {
  final String? id;
  final String? orderNumber;
  final String? customerName;
  final String? status; // e.g., 'active', 'completed', 'cancelled'
  final double? totalAmount;
  final String? tableId;
  final List<PosOrderItem> items;
  final String? createdAt;

  const PosOrderDetail({
    this.id,
    this.orderNumber,
    this.customerName,
    this.status,
    this.totalAmount,
    this.tableId,
    this.items = const [],
    this.createdAt,
  });

  factory PosOrderDetail.fromJson(Map<String, dynamic> json) {
    return PosOrderDetail(
      id: json['_id'] as String?,
      orderNumber: (json['order_no'] ?? json['order_number']) as String?,
      customerName:
          (json['pelanggan_nama'] ?? json['customer_name']) as String?,
      status: json['status'] as String?,
      totalAmount: (json['grand_total'] as num? ?? json['total_amount'] as num?)
          ?.toDouble(),
      tableId: json['table_id'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map((e) => PosOrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerName,
    status,
    totalAmount,
    tableId,
    items,
    createdAt,
  ];
}
