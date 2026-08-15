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
  });

  factory PosTransactionResult.fromJson(Map<String, dynamic> json) =>
      PosTransactionResult(
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
      );
}
