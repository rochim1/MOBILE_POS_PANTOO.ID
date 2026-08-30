class PosTransactionResult {
  final String id;
  final String invoice;
  final double subtotal;
  final double discount;
  final double promoDiscount;
  final double tax;
  final double total;
  final double cashReceived;
  final double change;
  final String paymentMethod;
  final bool pendingSync;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String date;
  final String cashierName;
  final String storeName;
  final String salesChannel;
  final String customerSegment;
  final String promoCode;
  final String note;
  final List<Map<String, dynamic>> items;

  const PosTransactionResult({
    required this.id,
    required this.invoice,
    required this.subtotal,
    required this.discount,
    required this.promoDiscount,
    required this.tax,
    required this.total,
    required this.cashReceived,
    required this.change,
    required this.paymentMethod,
    this.pendingSync = false,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.date = '',
    this.cashierName = '',
    this.storeName = '',
    this.salesChannel = '',
    this.customerSegment = '',
    this.promoCode = '',
    this.note = '',
    this.items = const [],
  });

  factory PosTransactionResult.fromJson(
    Map<String, dynamic> json, {
    String customerName = '',
    String customerPhone = '',
    String customerEmail = '',
    String cashierName = '',
    String storeName = '',
    String salesChannel = '',
    String customerSegment = '',
    String promoCode = '',
    String note = '',
    List<Map<String, dynamic>> items = const [],
  }) => PosTransactionResult(
    id: json['_id']?.toString() ?? '',
    invoice: json['invoice']?.toString() ?? '',
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    discount: (json['diskon'] as num?)?.toDouble() ?? 0,
    promoDiscount: (json['promo_discount'] as num?)?.toDouble() ?? 0,
    tax: (json['pajak'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    cashReceived: (json['uang_diterima'] as num?)?.toDouble() ?? 0,
    change: (json['kembalian'] as num?)?.toDouble() ?? 0,
    paymentMethod: json['metode_pembayaran']?.toString() ?? '',
    customerName: customerName,
    customerPhone: customerPhone,
    customerEmail: customerEmail,
    date: (json['tanggal'] ?? json['createdAt'] ?? '').toString(),
    cashierName: cashierName,
    storeName: storeName,
    salesChannel: salesChannel,
    customerSegment: customerSegment,
    promoCode: promoCode,
    note: note,
    items: items.isNotEmpty
        ? items
        : (json['items'] as List? ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
  );
}
