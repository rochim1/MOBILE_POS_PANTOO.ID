import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_financial_report/pos_financial_report_cubit.dart';
import 'fixtures/pos_financial_report_fixture.dart';

void main() {
  test(
    'periods follow the server business date including leap years and year boundaries',
    () {
      expect(
        FinancialReportRange.forPeriod(FinancialPeriod.lastMonth, '2024-03-01'),
        const FinancialReportRange('2024-02-01', '2024-02-29'),
      );
      expect(
        FinancialReportRange.forPeriod(FinancialPeriod.lastMonth, '2026-01-15'),
        const FinancialReportRange('2025-12-01', '2025-12-31'),
      );
      expect(
        FinancialReportRange.forPeriod(
          FinancialPeriod.lastSevenDays,
          '2026-01-03',
        ),
        const FinancialReportRange('2025-12-28', '2026-01-03'),
      );
      expect(
        const FinancialReportRange(
          '2026-11-13',
          '2026-11-14',
        ).validFor(financialOptions),
        false,
      );
      expect(
        const FinancialReportRange(
          '2026-11-13',
          '2026-11-01',
        ).validFor(financialOptions),
        false,
      );
      expect(
        const FinancialReportRange(
          '2020-01-01',
          '2026-11-13',
        ).validFor(financialOptions),
        false,
      );
      expect(
        const FinancialReportRange(
          '2026-02-30',
          '2026-11-13',
        ).validFor(financialOptions),
        false,
      );
    },
  );
  test(
    'responses missing monetary totals are rejected instead of converted to zero',
    () {
      expect(
        () => PosProfitLossReport.fromJson({
          'context': {
            'instansi_id': 'tenant-a',
            'scope': 'instansi',
            'currency': 'IDR',
          },
          'sections': [],
          'issues': [],
          'period_start': '2026-11-01',
          'period_end': '2026-11-13',
          'generated_at': '2026-11-13T00:00:00Z',
        }),
        throwsFormatException,
      );
      expect(
        () => FinancialReportOptions.fromJson({
          'instansi_id': 'tenant-a',
          'scope': 'store',
          'currency': 'IDR',
          'timezone': 'Asia/Jakarta',
          'today': '2026-11-13',
          'max_period_days': 366,
        }),
        throwsFormatException,
      );
    },
  );
  test(
    'late period response cannot overwrite the most recent selection',
    () async {
      final repo = FakeFinancialRepository();
      final cubit = PosFinancialReportCubit(repo);
      addTearDown(cubit.close);
      await cubit.initialize();
      const slow = FinancialReportRange('2026-11-01', '2026-11-02');
      const fast = FinancialReportRange('2026-11-03', '2026-11-04');
      repo.delayed[slow] = Completer();
      final pending = cubit.load(slow);
      expect(cubit.state.report, isNull);
      await cubit.load(fast);
      repo.delayed[slow]!.complete(Right(financialReport(range: slow)));
      await pending;
      expect(cubit.state.range, fast);
      expect(cubit.state.report?.range, fast);
    },
  );
  test(
    'failure and revoked permissions remove the previous financial snapshot',
    () async {
      final repo = FakeFinancialRepository();
      final cubit = PosFinancialReportCubit(repo);
      addTearDown(cubit.close);
      await cubit.initialize();
      expect(cubit.state.report, isNotNull);
      repo.response = const Left(NetworkFailure());
      await cubit.load(financialRange);
      expect(cubit.state.status, FinancialReportStatus.failure);
      expect(cubit.state.report, isNull);
      repo.response = null;
      await cubit.initialize();
      repo.options = const Left(FinancialReportAccessFailure());
      await cubit.initialize();
      expect(cubit.state.status, FinancialReportStatus.denied);
      expect(cubit.state.report, isNull);
      expect(cubit.state.options, isNull);
    },
  );
  test('denied options never request financial amounts', () async {
    final repo = FakeFinancialRepository()
      ..options = const Left(FinancialReportAccessFailure());
    final cubit = PosFinancialReportCubit(repo);
    addTearDown(cubit.close);
    await cubit.initialize();
    expect(repo.calls, isEmpty);
    expect(cubit.state.status, FinancialReportStatus.denied);
  });
  test('cross-tenant or wrong-period responses are discarded', () async {
    final repo = FakeFinancialRepository()
      ..response = Right(financialReport(tenant: 'tenant-b'));
    final cubit = PosFinancialReportCubit(repo);
    addTearDown(cubit.close);
    await cubit.initialize();
    expect(cubit.state.status, FinancialReportStatus.denied);
    expect(cubit.state.report, isNull);
    repo.response = Right(
      financialReport(
        range: const FinancialReportRange('2026-10-01', '2026-10-31'),
      ),
    );
    await cubit.initialize();
    expect(cubit.state.status, FinancialReportStatus.denied);
  });
}
