import 'package:equatable/equatable.dart';
import 'pos_financial_report.dart';

enum PosBusinessReportKind {
  cashFlow('cash_flow'),
  receivables('receivables'),
  payables('payables'),
  inventory('inventory'),
  movement('movement'),
  restock('restock');

  const PosBusinessReportKind(this.code);
  final String code;
  bool get cutoff => [receivables, payables, inventory, restock].contains(this);
  bool get searchable => [receivables, payables, restock].contains(this);
}

class PosBusinessReportFilter extends Equatable {
  const PosBusinessReportFilter({
    required this.kind,
    required this.range,
    this.search = '',
    this.sourceScope = 'all',
  });
  final PosBusinessReportKind kind;
  final FinancialReportRange range;
  final String search, sourceScope;
  PosBusinessReportFilter copyWith({
    FinancialReportRange? range,
    String? search,
    String? sourceScope,
  }) => PosBusinessReportFilter(
    kind: kind,
    range: range ?? this.range,
    search: search ?? this.search,
    sourceScope: sourceScope ?? this.sourceScope,
  );
  @override
  List<Object?> get props => [kind, range, search, sourceScope];
}

Map<String, dynamic> businessObject(dynamic value) {
  if (value is! Map) throw const FormatException('Invalid report object');
  return Map<String, dynamic>.from(value);
}

String businessText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Invalid report $key');
  return value;
}

double? businessNumber(dynamic value) {
  if (value == null) return null;
  if (value is! num || !value.isFinite) {
    throw const FormatException('Invalid report number');
  }
  return value.toDouble();
}

class PosBusinessMetric {
  const PosBusinessMetric(this.key, this.value, this.unit);
  final String key, unit;
  final double? value;
}

class PosBusinessColumn {
  const PosBusinessColumn(this.key, this.format);
  final String key, format;
}

class PosBusinessCell {
  const PosBusinessCell(this.key, {this.text, this.number});
  final String key;
  final String? text;
  final double? number;
}

class PosBusinessRow {
  const PosBusinessRow(this.id, this.cells);
  final String id;
  final List<PosBusinessCell> cells;
  PosBusinessCell cell(String key) => cells.firstWhere(
    (cell) => cell.key == key,
    orElse: () => PosBusinessCell(key),
  );
}

class PosBusinessReport {
  const PosBusinessReport({
    required this.filter,
    required this.instansiId,
    required this.generatedAt,
    required this.fingerprint,
    required this.coverage,
    required this.metrics,
    required this.columns,
    required this.rows,
    required this.notes,
    required this.noteCodes,
    required this.totalCount,
    this.page = 1,
    this.limit = 20,
  });
  final PosBusinessReportFilter filter;
  final String instansiId, fingerprint, coverage;
  final DateTime generatedAt;
  final List<PosBusinessMetric> metrics;
  final List<PosBusinessColumn> columns;
  final List<PosBusinessRow> rows;
  final List<String> notes, noteCodes;
  final int totalCount, page, limit;
  factory PosBusinessReport.fromJson(Map<String, dynamic> json) {
    if (json['scope'] != 'instansi' || json['currency'] != 'IDR') {
      throw const FormatException('Invalid report scope');
    }
    final kind = PosBusinessReportKind.values
        .where((kind) => kind.code == json['kind'])
        .firstOrNull;
    if (kind == null) throw const FormatException('Invalid report kind');
    final start = businessText(json, 'period_start'),
        end = businessText(json, 'period_end');
    reportDate(start);
    reportDate(end);
    List<dynamic> list(String key) {
      final value = json[key];
      if (value is! List) throw FormatException('Invalid report $key');
      return value;
    }

    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw FormatException('Invalid report $key');
      }
      return value;
    }

    List<String> texts(String key) => list(key).map((value) {
      if (value is! String) throw const FormatException('Invalid report note');
      return value;
    }).toList();
    final columns = list('columns').map((raw) {
      final row = businessObject(raw), format = businessText(row, 'format');
      if (!['text', 'money', 'number', 'date', 'label'].contains(format)) {
        throw const FormatException('Invalid report format');
      }
      return PosBusinessColumn(businessText(row, 'key'), format);
    }).toList();
    final rows = list('rows').map((raw) {
      final row = businessObject(raw);
      if (row['cells'] is! List) {
        throw const FormatException('Invalid report cells');
      }
      return PosBusinessRow(
        businessText(row, 'id'),
        (row['cells'] as List).map((raw) {
          final cell = businessObject(raw), text = cell['text'];
          if (text != null && text is! String) {
            throw const FormatException('Invalid report cell');
          }
          return PosBusinessCell(
            businessText(cell, 'key'),
            text: text as String?,
            number: businessNumber(cell['number']),
          );
        }).toList(),
      );
    }).toList();
    if (count('page') < 1 ||
        count('limit') < 1 ||
        rows.length > count('total_count')) {
      throw const FormatException('Invalid report pagination');
    }
    return PosBusinessReport(
      filter: PosBusinessReportFilter(
        kind: kind,
        range: FinancialReportRange(start, end),
        search: businessText(json, 'search'),
        sourceScope: businessText(json, 'source_scope'),
      ),
      instansiId: businessText(json, 'instansi_id'),
      generatedAt: DateTime.parse(businessText(json, 'generated_at')),
      fingerprint: businessText(json, 'fingerprint'),
      coverage: businessText(json, 'coverage'),
      metrics: list('metrics').map((raw) {
        final row = businessObject(raw);
        return PosBusinessMetric(
          businessText(row, 'key'),
          businessNumber(row['value']),
          businessText(row, 'unit'),
        );
      }).toList(),
      columns: columns,
      rows: rows,
      notes: texts('notes'),
      noteCodes: texts('note_codes'),
      totalCount: count('total_count'),
      page: count('page'),
      limit: count('limit'),
    );
  }
}
