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
    final rawQuantity = json['qty'] ?? json['quantity'];
    final rawPrice = json['harga_satuan'] ?? json['price'];
    return PosOrderItem(
      id: _text(json['_id']),
      productName: _text(json['nama'] ?? json['product_name']),
      quantity: rawQuantity is num
          ? rawQuantity.toInt()
          : int.tryParse(_text(rawQuantity) ?? ''),
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(_text(rawPrice) ?? ''),
      notes: _text(json['catatan'] ?? json['notes']),
      status: _text(json['status']),
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
  final String? tableName;
  final List<PosOrderItem> items;
  final String? createdAt;

  const PosOrderDetail({
    this.id,
    this.orderNumber,
    this.customerName,
    this.status,
    this.totalAmount,
    this.tableId,
    this.tableName,
    this.items = const [],
    this.createdAt,
  });

  factory PosOrderDetail.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['grand_total'] ?? json['total_amount'];
    final rawItems = json['items'];
    return PosOrderDetail(
      id: _text(json['_id']),
      orderNumber: _text(json['order_no'] ?? json['order_number']),
      customerName: _text(json['pelanggan_nama'] ?? json['customer_name']),
      status: _text(json['status']),
      totalAmount: rawTotal is num
          ? rawTotal.toDouble()
          : double.tryParse(_text(rawTotal) ?? ''),
      tableId: _text(json['table_id']),
      tableName: (json['table'] as Map?)?['name']?.toString(),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      PosOrderItem.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      createdAt: _text(json['createdAt']),
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
    tableName,
    items,
    createdAt,
  ];
}

String? _text(dynamic value) {
  if (value == null) return null;
  final text = switch (value) {
    String string => string.trim(),
    num number => number.toString(),
    bool boolean => boolean.toString(),
    _ => '',
  };
  return text.isEmpty || text == 'null' || text == 'undefined' ? null : text;
}
