import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_profit_loss_page.dart';
import 'fixtures/pos_financial_report_fixture.dart';

Widget app(FakeFinancialRepository repo) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: PosProfitLossPage(repository: repo)),
);
void main() {
  testWidgets(
    'profit loss shows organization scope and posted-data limits on a narrow phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = FakeFinancialRepository();
      await tester.pumpWidget(app(repo));
      await tester.pumpAndSettle();
      expect(find.text('Laba Rugi'), findsOneWidget);
      expect(find.text('Seluruh usaha dalam instansi ini'), findsOneWidget);
      expect(find.text('Rp 100.000'), findsWidgets);
      expect(
        find.textContaining('Biaya atau transaksi yang belum dicatat'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Rincian per akun'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Rincian per akun'), findsOneWidget);
      expect(repo.ledgerCalls, 0);
      await tester.ensureVisible(find.byType(ExpansionTile).first);
      await tester.tap(find.byType(ExpansionTile).first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('4100 · Penjualan'));
      await tester.tap(find.text('4100 · Penjualan'));
      await tester.pumpAndSettle();
      expect(repo.ledgerCalls, 1);
      await tester.scrollUntilVisible(
        find.text('Rincian jurnal memerlukan izin buku besar Finance.'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('Rincian jurnal memerlukan izin buku besar Finance.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('denied access shows no financial values', (tester) async {
    final repo = FakeFinancialRepository()
      ..options = const Left(FinancialReportAccessFailure());
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('Akses laporan keuangan belum tersedia'), findsOneWidget);
    expect(find.text('Rp 100.000'), findsNothing);
    expect(repo.calls, isEmpty);
  });
  testWidgets('missing HPP is displayed as unavailable rather than zero', (
    tester,
  ) async {
    final repo = FakeFinancialRepository()
      ..response = Right(
        PosProfitLossReport(
          instansiId: 'tenant-a',
          range: financialRange,
          generatedAt: DateTime.parse('2026-11-13T00:00:00Z'),
          totalRevenue: 100000,
          totalExpenses: 0,
          netSales: 100000,
          netProfit: 100000,
          sections: const [],
          issues: const [FinancialReportIssue('cogs_not_configured', 1)],
        ),
      );
    await tester.pumpWidget(app(repo));
    await tester.pumpAndSettle();
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('Rp 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'financial report remains usable with large text on a small phone',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: PosProfitLossPage(repository: FakeFinancialRepository()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Rincian per akun'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Rincian per akun'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
