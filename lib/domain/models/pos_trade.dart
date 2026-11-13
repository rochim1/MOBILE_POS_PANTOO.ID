enum PosTradeKind { receivable, payable }

class PosTradePayment {
  const PosTradePayment({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.reference,
    required this.status,
    required this.verified,
    this.journalNumber,
  });
  final String id, date, method, reference, status;
  final double amount;
  final bool verified;
  final String? journalNumber;
  factory PosTradePayment.fromJson(Map<String, dynamic> j) => PosTradePayment(
    id: tradeText(j, 'id'),
    date: tradeText(j, 'date'),
    amount: tradeMoney(j, 'amount'),
    method: tradeText(j, 'method'),
    reference: tradeText(j, 'reference'),
    status: tradeText(j, 'status'),
    verified: j['verified'] == true,
    journalNumber: j['journal_number'] as String?,
  );
}

class PosTradeDocument {
  const PosTradeDocument({
    required this.instansiId,
    required this.id,
    required this.kind,
    required this.number,
    required this.reference,
    required this.party,
    required this.date,
    required this.amount,
    required this.paid,
    required this.credited,
    required this.withheld,
    required this.outstanding,
    required this.status,
    required this.source,
    required this.basis,
    required this.notes,
    required this.canPay,
    required this.paymentCount,
    required this.payments,
    this.terms = const [],
    this.dueDate,
  });
  final String instansiId,
      id,
      number,
      reference,
      party,
      date,
      status,
      source,
      basis,
      notes;
  final PosTradeKind kind;
  final String? dueDate;
  final double amount, paid, credited, withheld, outstanding;
  final bool canPay;
  final int paymentCount;
  final List<PosTradePayment> payments;
  final List<Map<String, dynamic>> terms;
  factory PosTradeDocument.fromJson(Map<String, dynamic> j) => PosTradeDocument(
    instansiId: tradeText(j, 'instansi_id'),
    id: tradeText(j, 'id'),
    kind: PosTradeKind.values.byName(tradeText(j, 'kind')),
    number: tradeText(j, 'number'),
    reference: tradeText(j, 'reference'),
    party: tradeText(j, 'party'),
    date: tradeText(j, 'date'),
    dueDate: j['due_date'] as String?,
    amount: tradeMoney(j, 'amount'),
    paid: tradeMoney(j, 'paid'),
    credited: tradeMoney(j, 'credited'),
    withheld: tradeMoney(j, 'withheld'),
    outstanding: tradeMoney(j, 'outstanding'),
    status: tradeText(j, 'status'),
    source: tradeText(j, 'source'),
    basis: tradeText(j, 'basis'),
    notes: tradeText(j, 'notes'),
    canPay: j['can_pay'] == true,
    paymentCount: j['payment_count'] as int,
    terms: (j['terms'] as List? ?? [])
        .map((t) => Map<String, dynamic>.from(t as Map))
        .toList(),
    payments: (j['payments'] as List)
        .map(
          (p) => PosTradePayment.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .toList(),
  );
}

class PosTradePage {
  const PosTradePage(
    this.items,
    this.totalCount,
    this.outstanding,
    this.page,
    this.limit,
  );
  final List<PosTradeDocument> items;
  final int totalCount, page, limit;
  final double outstanding;
  factory PosTradePage.fromJson(Map<String, dynamic> j) => PosTradePage(
    (j['items'] as List)
        .map(
          (p) => PosTradeDocument.fromJson(Map<String, dynamic>.from(p as Map)),
        )
        .toList(),
    j['total_count'] as int,
    tradeMoney(j, 'outstanding'),
    j['page'] as int,
    j['limit'] as int,
  );
}

class PosTradeOptions {
  const PosTradeOptions(this.data);
  final Map<String, dynamic> data;
  String get today => tradeText(data, 'today');
  String get arScope => tradeText(data, 'ar_scope');
  bool get viewAR => data['view_ar'] == true;
  bool get viewAP => data['view_ap'] == true;
  bool canCreate(PosTradeKind k) =>
      data[k == PosTradeKind.receivable ? 'create_ar' : 'create_ap'] == true;
  bool canPay(PosTradeKind k) =>
      data[k == PosTradeKind.receivable ? 'receive_ar' : 'pay_ap'] == true;
  bool get apCashAvailable => data['ap_cash_available'] == true;
  List<Map<String, dynamic>> list(String key) => (data[key] as List? ?? [])
      .map((p) => Map<String, dynamic>.from(p as Map))
      .toList();
}

String tradeText(Map<String, dynamic> j, String key) {
  final value = j[key];
  if (value is! String) throw FormatException('Invalid trade $key');
  return value;
}

double tradeMoney(Map<String, dynamic> j, String key) {
  final value = j[key];
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      value > 9007199254740991) {
    throw FormatException('Invalid trade $key');
  }
  return value.toDouble();
}
