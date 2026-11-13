import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/reports/pos_report_export.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_financial_report/pos_business_report_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_financial_report/pos_financial_report_cubit.dart';
import 'fixtures/pos_financial_report_fixture.dart';

PosBusinessReport sample(
  PosBusinessReportFilter filter, {
  String tenant = 'tenant-a',
  int page = 1,
}) => PosBusinessReport(
  filter: filter,
  instansiId: tenant,
  generatedAt: DateTime.utc(2026, 11, 13),
  fingerprint: 'hash',
  coverage: 'unknown',
  metrics: const [PosBusinessMetric('stock_value', null, 'money')],
  columns: const [PosBusinessColumn('reference', 'text')],
  rows: const [],
  notes: const [],
  noteCodes: const ['stock_evidence_missing'],
  totalCount: 0,
  page: page,
);

class BusinessRepository extends FakeFinancialRepository {
  final pending = <String, Completer<Either<Failure, PosBusinessReport>>>{};
  Either<Failure, PosBusinessReport>? businessResponse;
  @override
  Future<Either<Failure, PosBusinessReport>> getBusinessReport(
    PosBusinessReportFilter filter, {
    int page = 1,
    bool forExport = false,
    String? fingerprint,
  }) async =>
      pending[filter.search]?.future ??
      businessResponse ??
      Right(sample(filter, page: page));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'restock refresh rolls its cutoff forward when the server business day changes',
    () async {
      final repo = BusinessRepository();
      final cubit = PosBusinessReportCubit(repo, PosBusinessReportKind.restock);
      await cubit.initialize();
      expect(cubit.state.filter!.range.end, '2026-11-13');
      repo.options = const Right(
        FinancialReportOptions(instansiId: 'tenant-a', today: '2026-11-14'),
      );
      await cubit.initialize();
      expect(cubit.state.filter!.range.start, '2026-11-14');
      expect(cubit.state.filter!.range.end, '2026-11-14');
      await cubit.close();
    },
  );
  test(
    'latest filter wins and source denials clear amounts while preserving other tabs',
    () async {
      final repo = BusinessRepository();
      final c = PosBusinessReportCubit(repo, PosBusinessReportKind.receivables);
      await c.initialize();
      final f = c.state.filter!;
      repo.pending['old'] = Completer();
      final old = c.load(f.copyWith(search: 'old'));
      await c.load(f.copyWith(search: 'new'));
      repo.pending['old']!.complete(Right(sample(f.copyWith(search: 'old'))));
      await old;
      expect(c.state.report!.filter.search, 'new');
      repo.businessResponse = const Left(FinancialReportAccessFailure());
      await c.load(f);
      expect(c.state.report, isNull);
      expect(c.state.options, isNotNull);
      expect(c.state.status, FinancialReportStatus.denied);
      repo.businessResponse = const Left(AuthFailure());
      await c.load(f);
      expect(c.state.options, isNull);
      await c.close();
    },
  );
  test('tenant and pagination mismatches discard all report data', () async {
    final repo = BusinessRepository();
    final cubit = PosBusinessReportCubit(repo, PosBusinessReportKind.inventory);
    await cubit.initialize();
    final f = cubit.state.filter!;
    repo.businessResponse = Right(sample(f, tenant: 'other'));
    await cubit.load(f);
    expect(cubit.state.report, isNull);
    expect(cubit.state.options, isNull);
    await cubit.close();
  });
  test(
    'CSV preserves null, quotes, Unicode and numbers while neutralizing formulas',
    () {
      const doc = PosReportExportDocument(
        title: 'Report',
        fileStem: 'sample',
        metadata: [],
        metrics: [],
        headers: ['Name', 'Amount'],
        rows: [
          ['=SUM(A1)', null],
          ['Nama, "Toko"', -20],
          ['日本語', 30],
        ],
        displayRows: [],
        notes: [],
      );
      final csv = utf8.decode(doc.csv());
      expect(doc.csv().take(3).toList(), [239, 187, 191]);
      expect(csv, contains('"\'=SUM(A1)",'));
      expect(csv, contains('"Nama, ""Toko""",-20'));
      expect(csv, contains('日本語'));
      expect(csv, isNot(contains('null')));
    },
  );
  test(
    'PDF exports all sample rows with metadata; unsupported glyphs fail explicitly',
    () async {
      final doc = PosReportExportDocument(
        title: 'Laporan Arus Kas',
        fileStem: 'sample',
        metadata: const [
          ['Cakupan', 'Seluruh Usaha'],
          ['Periode', '2026-10-01 / 2026-10-31 WIB'],
        ],
        metrics: const [
          ['Saldo Awal', 100, 'IDR'],
          ['Uang Masuk', 300, 'IDR'],
          ['Uang Keluar', 50, 'IDR'],
          ['Saldo Akhir', 350, 'IDR'],
        ],
        headers: const ['Referensi', 'Keterangan', 'Jumlah'],
        rows: List.generate(
          70,
          (i) => ['REF-$i', 'Penerimaan pelanggan', i * 1000],
        ),
        displayRows: List.generate(
          70,
          (i) => ['REF-$i', 'Penerimaan pelanggan', 'Rp ${i * 1000}'],
        ),
        notes: const [
          'Sumber jurnal posted. Transfer antar rekening sendiri dikecualikan.',
        ],
      );
      final bytes = await doc.pdf();
      expect(ascii.decode(bytes.take(4).toList()), '%PDF');
      final out = Platform.environment['PANTOO_REPORT_QA_PDF'];
      if (out != null) await File(out).writeAsBytes(bytes);
      const unsupported = PosReportExportDocument(
        title: '日本語',
        fileStem: 'sample',
        metadata: [],
        metrics: [],
        headers: [],
        rows: [],
        displayRows: [],
        notes: [],
      );
      Object? failure;
      try {
        await unsupported.pdf();
      } catch (error) {
        failure = error;
      }
      expect(failure, isA<ReportExportUnsupportedGlyph>());
    },
  );
  test('oversized exports fail instead of silently dropping rows', () {
    final doc = PosReportExportDocument(
      title: 'Report',
      fileStem: 'sample',
      metadata: const [],
      metrics: const [],
      headers: const [],
      rows: List.generate(5001, (_) => []),
      displayRows: const [],
      notes: const [],
    );
    expect(doc.csv, throwsA(isA<ReportExportSizeFailure>()));
  });
}
