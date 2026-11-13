import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/financial_report_labels.dart';

class ReportExportUnsupportedGlyph implements Exception {
  ReportExportUnsupportedGlyph([this.rune]);
  final int? rune;
  @override
  String toString() => "Unsupported PDF glyph U+${rune?.toRadixString(16)}";
}

class ReportExportSizeFailure implements Exception {}

class PosReportExportDocument {
  const PosReportExportDocument({
    required this.title,
    required this.fileStem,
    required this.metadata,
    required this.metrics,
    required this.headers,
    required this.rows,
    required this.displayRows,
    required this.notes,
  });
  final String title, fileStem;
  final List<List<String>> metadata;
  final List<List<Object?>> metrics, rows;
  final List<List<String>> displayRows;
  final List<String> headers, notes;
  static List<List<String>> _metadata(
    AppLocalizations l,
    FinancialReportRange range,
    DateTime at,
    String coverage,
  ) => [
    [l.businessExportScope, l.financialScope],
    [l.financialPeriod, '${range.start} / ${range.end} (WIB)'],
    [
      l.financialUpdated,
      '${DateFormat('yyyy-MM-dd HH:mm').format(at.toUtc().add(const Duration(hours: 7)))} WIB',
    ],
    [l.businessExportCurrency, 'IDR'],
    [l.businessExportCoverage, coverage],
    [l.financialUnavailable, '— / blank'],
  ];
  factory PosReportExportDocument.business(
    PosBusinessReport report,
    AppLocalizations l,
    String locale,
  ) {
    final title = businessReportLabel(l, report.filter.kind.code);
    return PosReportExportDocument(
      title: title,
      fileStem:
          'pantoo-${report.filter.kind.code}-${report.filter.range.start}-${report.filter.range.end}',
      metadata: [
        ..._metadata(
          l,
          report.filter.range,
          report.generatedAt,
          businessReportLabel(l, report.coverage),
        ),
        if ([
          PosBusinessReportKind.receivables,
          PosBusinessReportKind.payables,
        ].contains(report.filter.kind))
          [
            l.businessSources,
            report.filter.sourceScope == 'pos'
                ? l.businessPosSources
                : l.businessAllSources,
          ],
        [l.businessSearch, report.filter.search],
      ],
      metrics: report.metrics
          .map(
            (metric) => [
              businessReportLabel(l, metric.key),
              metric.value,
              metric.unit == 'money' ? 'IDR' : l.businessRows,
            ],
          )
          .toList(),
      headers: report.columns
          .map((column) => businessReportLabel(l, column.key))
          .toList(),
      rows: report.rows
          .map(
            (row) => report.columns.map((column) {
              final cell = row.cell(column.key);
              return ['number', 'money'].contains(column.format)
                  ? cell.number
                  : column.format == 'label' && cell.text != null
                  ? businessReportLabel(l, cell.text!)
                  : cell.text;
            }).toList(),
          )
          .toList(),
      displayRows: report.rows
          .map(
            (row) => report.columns
                .map(
                  (column) => businessReportCell(
                    l,
                    column,
                    row.cell(column.key),
                    locale,
                  ),
                )
                .toList(),
          )
          .toList(),
      notes: [
        ...report.noteCodes.map((code) => businessReportLabel(l, code)),
        ...report.notes,
      ],
    );
  }
  factory PosReportExportDocument.profitLoss(
    PosProfitLossReport report,
    AppLocalizations l,
    String locale,
  ) {
    String section(String key) =>
        {
          'net_sales': l.financialNetSales,
          'cogs': l.financialCogs,
          'operating_expenses': l.financialOperatingExpenses,
          'other_revenue': l.financialOtherRevenue,
          'other_expenses': l.financialOtherExpenses,
          'unclassified_revenue': l.financialUnclassifiedRevenue,
          'unclassified_expenses': l.financialUnclassifiedExpenses,
        }[key] ??
        l.financialDetails;
    final rows = <List<Object?>>[
      for (final group in report.sections)
        for (final account in group.accounts)
          [section(group.key), account.code, account.name, account.amount],
    ];
    return PosReportExportDocument(
      title: l.financialProfitLoss,
      fileStem: 'pantoo-profit-loss-${report.range.start}-${report.range.end}',
      metadata: _metadata(
        l,
        report.range,
        report.generatedAt,
        report.issues.isEmpty ? l.financialRecorded : l.financialReview,
      ),
      metrics: [
        [l.financialNetSales, report.netSales, 'IDR'],
        [l.financialCogs, report.cogs, 'IDR'],
        [l.financialGrossProfit, report.grossProfit, 'IDR'],
        [l.financialNetProfit, report.netProfit, 'IDR'],
        [l.financialTotalRevenue, report.totalRevenue, 'IDR'],
        [l.financialTotalExpenses, report.totalExpenses, 'IDR'],
      ],
      headers: [
        l.financialDetails,
        l.businessAccount,
        l.businessName,
        l.businessAmount,
      ],
      rows: rows,
      displayRows: rows
          .map(
            (row) => [
              row[0].toString(),
              row[1].toString(),
              row[2].toString(),
              businessReportNumber(row[3] as double?, 'money', locale),
            ],
          )
          .toList(),
      notes: [
        l.financialBasisNote,
        l.financialCostNote,
        ...report.issues.map((issue) => profitLossIssueLabel(l, issue)),
      ],
    );
  }
  Uint8List csv() {
    if (rows.length > 5000) throw ReportExportSizeFailure();
    String field(Object? value) {
      if (value == null) return '';
      if (value is num) return value.toString();
      var text = value.toString();
      if (RegExp(r'^[\s\x00-\x1f]*[=+\-@]').hasMatch(text)) text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final table = <List<Object?>>[
      [title],
      ...metadata,
      [],
      ...metrics,
      [],
      headers,
      ...rows,
      [],
      ...notes.map((note) => [note]),
    ];
    return Uint8List.fromList(
      utf8.encode(
        '\ufeff${table.map((row) => row.map(field).join(',')).join('\r\n')}',
      ),
    );
  }

  Future<Uint8List> pdf() async {
    if (rows.length > 1000 || notes.length > 100) {
      throw ReportExportSizeFailure();
    }
    final regular = await Future<ByteData>.value(
          rootBundle.load('assets/fonts/roboto-regular.ttf'),
        ),
        bold = await Future<ByteData>.value(
          rootBundle.load('assets/fonts/roboto-bold.ttf'),
        );
    final document = pw.Document(title: title, author: 'Pantoo POS');
    final glyphs = PdfTtfFont(document.document, regular);
    final texts = [
      title,
      ...metadata.expand((row) => row),
      ...headers,
      ...displayRows.expand((row) => row),
      ...notes,
      ...metrics.expand((row) => row.map((value) => value?.toString() ?? '')),
    ];
    for (final text in texts) {
      if (text.length > 4000) throw ReportExportSizeFailure();
      for (final rune in text.runes) {
        if (rune > 32 && !glyphs.isRuneSupported(rune)) {
          throw ReportExportUnsupportedGlyph(rune);
        }
      }
    }
    final font = pw.Font.ttf(regular), strong = pw.Font.ttf(bold);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        maxPages: 1000,
        theme: pw.ThemeData.withFont(base: font, bold: strong),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          ...metadata.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '${row[0]}: ${row[1]}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['', 'IDR / #'],
            data: metrics
                .map(
                  (row) => [
                    row[0],
                    row[1] == null
                        ? '—'
                        : NumberFormat('#,##0.######', 'id_ID').format(row[1]),
                  ],
                )
                .toList(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            border: pw.TableBorder.all(color: PdfColors.grey300, width: .4),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 16),
          if (displayRows.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: displayRows,
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: .4),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          pw.SizedBox(height: 14),
          ...notes.map(
            (note) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(note, style: const pw.TextStyle(fontSize: 8)),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }
}
