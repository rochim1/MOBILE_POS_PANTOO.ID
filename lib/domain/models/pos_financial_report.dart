import 'package:equatable/equatable.dart';

Map<String, dynamic> _object(dynamic raw) {
  if (raw is! Map) throw const FormatException('Invalid report object');
  return Map<String, dynamic>.from(raw);
}

String _text(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('Invalid report field: $key');
  }
  return value;
}

double? _amount(
  Map<String, dynamic> json,
  String key, {
  bool nullable = false,
}) {
  final value = json[key];
  if (value == null && nullable) return null;
  if (value is! num || !value.isFinite) {
    throw FormatException('Invalid report amount: $key');
  }
  return value.toDouble();
}

DateTime reportDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    throw const FormatException('Invalid report date');
  }
  final parsed = DateTime.parse(value);
  if (parsed.toIso8601String().substring(0, 10) != value) {
    throw const FormatException('Invalid report date');
  }
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

String reportDateText(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

enum FinancialPeriod { today, lastSevenDays, thisMonth, lastMonth, custom }

class FinancialReportRange extends Equatable {
  const FinancialReportRange(this.start, this.end);
  final String start;
  final String end;
  int get days => reportDate(end).difference(reportDate(start)).inDays + 1;
  bool validFor(FinancialReportOptions options) {
    try {
      return days > 0 &&
          days <= options.maxPeriodDays &&
          end.compareTo(options.today) <= 0;
    } on FormatException {
      return false;
    }
  }

  factory FinancialReportRange.forPeriod(FinancialPeriod period, String today) {
    final date = reportDate(today);
    final startOfMonth = DateTime.utc(date.year, date.month, 1);
    final start = switch (period) {
      FinancialPeriod.today => date,
      FinancialPeriod.lastSevenDays => date.subtract(const Duration(days: 6)),
      FinancialPeriod.lastMonth => DateTime.utc(date.year, date.month - 1, 1),
      _ => startOfMonth,
    };
    final end = period == FinancialPeriod.lastMonth
        ? startOfMonth.subtract(const Duration(days: 1))
        : date;
    return FinancialReportRange(reportDateText(start), reportDateText(end));
  }
  @override
  List<Object?> get props => [start, end];
}

class FinancialReportOptions {
  const FinancialReportOptions({
    required this.instansiId,
    required this.today,
    this.maxPeriodDays = 366,
    this.canExport = false,
    this.scope = 'instansi',
    this.currency = 'IDR',
    this.timezone = 'Asia/Jakarta',
  });
  final String instansiId, today, scope, currency, timezone;
  final int maxPeriodDays;
  final bool canExport;
  factory FinancialReportOptions.fromJson(Map<String, dynamic> json) {
    final days = json['max_period_days'];
    final today = _text(json, 'today');
    reportDate(today);
    if (days is! int ||
        days < 1 ||
        days > 366 ||
        json['scope'] != 'instansi' ||
        json['currency'] != 'IDR' ||
        json['timezone'] != 'Asia/Jakarta') {
      throw const FormatException('Unsupported financial report context');
    }
    return FinancialReportOptions(
      instansiId: _text(json, 'instansi_id'),
      today: today,
      maxPeriodDays: days,
      canExport: json['can_export'] == true,
    );
  }
}

class FinancialReportAccount {
  const FinancialReportAccount(this.code, this.name, this.amount);
  final String code, name;
  final double amount;
  factory FinancialReportAccount.fromJson(Map<String, dynamic> json) =>
      FinancialReportAccount(
        _text(json, 'account_code'),
        _text(json, 'account_name'),
        _amount(json, 'amount')!,
      );
}

class FinancialReportSection {
  const FinancialReportSection(this.key, this.amount, this.accounts);
  final String key;
  final double amount;
  final List<FinancialReportAccount> accounts;
  factory FinancialReportSection.fromJson(Map<String, dynamic> json) {
    if (json['accounts'] is! List) {
      throw const FormatException('Invalid report accounts');
    }
    return FinancialReportSection(
      _text(json, 'key'),
      _amount(json, 'amount')!,
      List.unmodifiable(
        (json['accounts'] as List).map(
          (row) => FinancialReportAccount.fromJson(_object(row)),
        ),
      ),
    );
  }
}

class FinancialReportIssue {
  const FinancialReportIssue(this.code, this.count);
  final String code;
  final int count;
  factory FinancialReportIssue.fromJson(Map<String, dynamic> json) {
    final count = json['count'];
    if (count is! int || count < 0) {
      throw const FormatException('Invalid report issue count');
    }
    return FinancialReportIssue(_text(json, 'code'), count);
  }
}

class PosProfitLossReport {
  const PosProfitLossReport({
    required this.instansiId,
    required this.range,
    required this.generatedAt,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.sections,
    required this.issues,
    this.netSales,
    this.cogs,
    this.grossProfit,
    this.grossMarginPercent,
    this.netProfit,
    this.fingerprint = '',
  });
  final String instansiId;
  final String fingerprint;
  final FinancialReportRange range;
  final DateTime generatedAt;
  final double totalRevenue, totalExpenses;
  final double? netSales, cogs, grossProfit, grossMarginPercent, netProfit;
  final List<FinancialReportSection> sections;
  final List<FinancialReportIssue> issues;
  factory PosProfitLossReport.fromJson(Map<String, dynamic> json) {
    final context = _object(json['context']);
    if (context['scope'] != 'instansi' ||
        context['currency'] != 'IDR' ||
        json['sections'] is! List ||
        json['issues'] is! List) {
      throw const FormatException('Invalid profit loss context');
    }
    return PosProfitLossReport(
      instansiId: _text(context, 'instansi_id'),
      fingerprint: _text(json, 'fingerprint'),
      range: FinancialReportRange(
        _text(json, 'period_start'),
        _text(json, 'period_end'),
      ),
      generatedAt: DateTime.parse(_text(json, 'generated_at')),
      totalRevenue: _amount(json, 'total_revenue')!,
      totalExpenses: _amount(json, 'total_expenses')!,
      netSales: _amount(json, 'net_sales', nullable: true),
      cogs: _amount(json, 'cogs', nullable: true),
      grossProfit: _amount(json, 'gross_profit', nullable: true),
      grossMarginPercent: _amount(json, 'gross_margin_percent', nullable: true),
      netProfit: _amount(json, 'net_profit', nullable: true),
      sections: List.unmodifiable(
        (json['sections'] as List).map(
          (row) => FinancialReportSection.fromJson(_object(row)),
        ),
      ),
      issues: List.unmodifiable(
        (json['issues'] as List).map(
          (row) => FinancialReportIssue.fromJson(_object(row)),
        ),
      ),
    );
  }
}

class FinancialJournalEntry {
  const FinancialJournalEntry({
    required this.date,
    required this.number,
    required this.description,
    required this.debit,
    required this.credit,
    this.reference = '',
  });
  final DateTime date;
  final String number, description, reference;
  final double debit, credit;
  factory FinancialJournalEntry.fromJson(Map<String, dynamic> json) {
    final rawDate = _text(json, 'date');
    final epoch = int.tryParse(rawDate);
    final date = epoch == null
        ? DateTime.parse(rawDate)
        : DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true);
    return FinancialJournalEntry(
      date: date,
      number: _text(json, 'journal_number'),
      description: json['description']?.toString() ?? '',
      reference: json['reference_number']?.toString() ?? '',
      debit: _amount(json, 'debit')!,
      credit: _amount(json, 'credit')!,
    );
  }
}

class FinancialLedgerPage {
  const FinancialLedgerPage(this.instansiId, this.total, this.entries);
  final String instansiId;
  final int total;
  final List<FinancialJournalEntry> entries;
  factory FinancialLedgerPage.fromJson(Map<String, dynamic> json) {
    final context = _object(json['context']);
    if (context['scope'] != 'instansi' ||
        json['total_count'] is! int ||
        json['entries'] is! List) {
      throw const FormatException('Invalid ledger response');
    }
    return FinancialLedgerPage(
      _text(context, 'instansi_id'),
      json['total_count'] as int,
      List.unmodifiable(
        (json['entries'] as List).map(
          (row) => FinancialJournalEntry.fromJson(_object(row)),
        ),
      ),
    );
  }
}
