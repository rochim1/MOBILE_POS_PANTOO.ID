import 'package:equatable/equatable.dart';

class PosOrderItem extends Equatable {
  final String? id;
  final String? productId;
  final String? productName;
  final String? productCode;
  final double? quantity;
  final double? price;
  final String? notes;
  final String? unit;
  final String? status; // e.g., 'pending', 'preparing', 'served', 'cancelled'

  const PosOrderItem({
    this.id,
    this.productId,
    this.productName,
    this.productCode,
    this.quantity,
    this.price,
    this.notes,
    this.unit,
    this.status,
  });

  factory PosOrderItem.fromJson(Map<String, dynamic> json) {
    final rawQuantity = json['qty'] ?? json['quantity'];
    final rawPrice = json['harga_satuan'] ?? json['price'];
    return PosOrderItem(
      id: _text(json['_id']),
      productId: _text(json['produk_id']),
      productName: _text(json['nama'] ?? json['product_name']),
      productCode: _text(json['kode']),
      quantity: rawQuantity is num
          ? rawQuantity.toDouble()
          : double.tryParse(_text(rawQuantity) ?? ''),
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(_text(rawPrice) ?? ''),
      notes: _text(json['catatan'] ?? json['notes']),
      unit: _text(json['unit']),
      status: _text(json['status']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    productName,
    productCode,
    quantity,
    price,
    notes,
    unit,
    status,
  ];
}

class PosOrderDetail extends Equatable {
  final String? id;
  final String? orderNumber;
  final String? customerName;
  final String? customerId;
  final String? orderType;
  final String? status; // e.g., 'active', 'completed', 'cancelled'
  final String? _paymentStatus;
  String get paymentStatus => _paymentStatus ?? 'belum_bayar';
  final double? totalAmount;
  final double? subtotal;
  final double? discountAmount;
  final double? taxAmount;
  final String? note;
  final String? kitchenNote;
  final String? handoverNote;
  final String? internalNote;
  final List<Map<String, dynamic>> statusHistory;
  final String? tableId;
  final String? tableName;
  final List<PosOrderItem> items;
  final String? createdAt;
  final Map<String, dynamic>? serviceOrder;

  const PosOrderDetail({
    this.id,
    this.orderNumber,
    this.customerName,
    this.customerId,
    this.orderType,
    this.status,
    String? paymentStatus = 'belum_bayar',
    this.totalAmount,
    this.subtotal,
    this.discountAmount,
    this.taxAmount,
    this.note,
    this.kitchenNote,
    this.handoverNote,
    this.internalNote,
    this.statusHistory = const [],
    this.tableId,
    this.tableName,
    this.items = const [],
    this.createdAt,
    this.serviceOrder,
  }) : _paymentStatus = paymentStatus;

  factory PosOrderDetail.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['grand_total'] ?? json['total_amount'];
    final rawSubtotal = json['subtotal'];
    final rawDiscount = json['diskon_amount'];
    final rawTax = json['pajak_amount'];
    final rawItems = json['items'];
    return PosOrderDetail(
      id: _text(json['_id']),
      orderNumber: _text(json['order_no'] ?? json['order_number']),
      customerName: _text(json['pelanggan_nama'] ?? json['customer_name']),
      customerId: _text(json['pelanggan_id']),
      orderType: _text(json['tipe_pesanan']) ?? 'take_away',
      status: _text(json['status']),
      paymentStatus: _text(json['status_pembayaran']) ?? 'belum_bayar',
      totalAmount: rawTotal is num
          ? rawTotal.toDouble()
          : double.tryParse(_text(rawTotal) ?? ''),
      subtotal: rawSubtotal is num
          ? rawSubtotal.toDouble()
          : double.tryParse(_text(rawSubtotal) ?? ''),
      discountAmount: rawDiscount is num
          ? rawDiscount.toDouble()
          : double.tryParse(_text(rawDiscount) ?? ''),
      taxAmount: rawTax is num
          ? rawTax.toDouble()
          : double.tryParse(_text(rawTax) ?? ''),
      note: _text(json['catatan']),
      kitchenNote: _text(json['kitchen_note']),
      handoverNote: _text(json['handover_note']),
      internalNote: _text(json['internal_note']),
      statusHistory: (json['status_history'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
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
      serviceOrder: json['service_order'] is Map
          ? Map<String, dynamic>.from(json['service_order'] as Map)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    customerName,
    customerId,
    orderType,
    status,
    paymentStatus,
    totalAmount,
    subtotal,
    discountAmount,
    taxAmount,
    note,
    kitchenNote,
    handoverNote,
    internalNote,
    statusHistory,
    tableId,
    tableName,
    items,
    createdAt,
    serviceOrder,
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
