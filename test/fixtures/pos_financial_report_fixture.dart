import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';

const financialOptions = FinancialReportOptions(
  instansiId: 'tenant-a',
  today: '2026-11-13',
);
const financialRange = FinancialReportRange('2026-11-01', '2026-11-13');
PosProfitLossReport financialReport({
  FinancialReportRange range = financialRange,
  String tenant = 'tenant-a',
}) => PosProfitLossReport(
  instansiId: tenant,
  range: range,
  generatedAt: DateTime.parse('2026-11-13T07:00:00Z'),
  totalRevenue: 100000,
  totalExpenses: 70000,
  netSales: 100000,
  cogs: 60000,
  grossProfit: 40000,
  grossMarginPercent: 40,
  netProfit: 30000,
  sections: const [
    FinancialReportSection('net_sales', 100000, [
      FinancialReportAccount('4100', 'Penjualan', 100000),
    ]),
  ],
  issues: const [],
);

class FakeFinancialRepository extends PosFinancialReportRepository {
  Either<Failure, FinancialReportOptions> options = const Right(
    financialOptions,
  );
  Either<Failure, PosProfitLossReport>? response;
  final calls = <FinancialReportRange>[];
  final delayed =
      <FinancialReportRange, Completer<Either<Failure, PosProfitLossReport>>>{};
  int ledgerCalls = 0;
  @override
  Future<Either<Failure, FinancialReportOptions>> getOptions() async => options;
  @override
  Future<Either<Failure, PosProfitLossReport>> getProfitLoss(
    FinancialReportRange range, {bool forExport = false, String? fingerprint}
  ) async {
    calls.add(range);
    if (delayed.containsKey(range)) return delayed[range]!.future;
    return response ?? Right(financialReport(range: range));
  }

  @override
  Future<Either<Failure, FinancialLedgerPage>> getAccountEntries({
    required String code,
    required FinancialReportRange range,
    required String instansiId,
    int page = 1,
  }) async {
    ledgerCalls++;
    return const Left(FinancialReportAccessFailure());
  }
}
