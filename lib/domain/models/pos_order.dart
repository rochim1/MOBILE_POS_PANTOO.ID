class PosOrder {
  final String id;
  final String invoice;
  final String date;
  final String customer;
  final String cashierName;
  final String paymentMethod;
  final double total;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final String note;
  final String status;
  final String paymentStatus;
  final bool isInvoice;
  final List<Map<String, dynamic>> items;

  const PosOrder({
    required this.id,
    required this.invoice,
    required this.date,
    required this.customer,
    required this.cashierName,
    required this.paymentMethod,
    required this.total,
    double? subtotal,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.note = '',
    required this.status,
    this.paymentStatus = 'lunas',
    this.isInvoice = false,
    this.items = const [],
  }) : subtotal = subtotal ?? total;

  static DateTime parseDateValue(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    final numeric = int.tryParse(raw);
    if (numeric != null) {
      // GraphQL's default Date serialization in this project can expose
      // Mongo dates as epoch milliseconds encoded as String.
      final milliseconds = raw.length <= 10 ? numeric * 1000 : numeric;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime get dateTime => parseDateValue(date);

  factory PosOrder.fromJson(Map<String, dynamic> json) {
    return PosOrder(
      id: json['_id'] ?? '',
      invoice: json['invoice'] ?? '-',
      date: (json['tanggal'] ?? json['createdAt'] ?? '-').toString(),
      customer: json['pelanggan'] ?? 'Retail',
      cashierName: json['kasir_name'] ?? 'Kasir',
      paymentMethod: json['metode_pembayaran']?.toString() ?? '-',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      subtotal:
          double.tryParse(json['subtotal']?.toString() ?? '') ??
          double.tryParse(json['total']?.toString() ?? '0') ??
          0,
      discountAmount: double.tryParse(json['diskon']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['pajak']?.toString() ?? '0') ?? 0,
      note: json['catatan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Selesai',
      paymentStatus: json['status_pembayaran']?.toString() ?? 'lunas',
      isInvoice: false,
      items: (json['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }

  factory PosOrder.fromPendingOrderJson(Map<String, dynamic> json) {
    return PosOrder(
      id: json['_id']?.toString() ?? '',
      invoice: json['order_no']?.toString() ?? '-',
      date: json['createdAt']?.toString() ?? '-',
      customer: (json['pelanggan_nama']?.toString().trim().isNotEmpty ?? false)
          ? json['pelanggan_nama'].toString()
          : 'Retail',
      cashierName: json['kasir_name']?.toString() ?? 'Kasir',
      paymentMethod: json['metode_pembayaran']?.toString() ?? '-',
      total: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0,
      subtotal:
          double.tryParse(json['subtotal']?.toString() ?? '') ??
          double.tryParse(json['grand_total']?.toString() ?? '0') ??
          0,
      discountAmount:
          double.tryParse(json['diskon_amount']?.toString() ?? '0') ?? 0,
      taxAmount: double.tryParse(json['pajak_amount']?.toString() ?? '0') ?? 0,
      note: json['catatan']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Baru',
      paymentStatus: json['status_pembayaran']?.toString() ?? 'belum_bayar',
      isInvoice: true,
      items: (json['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(),
    );
  }
}
