import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_business_report_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_profit_loss_page.dart';

// Only the disposable local staging script serves this port. No production
// credential, app login or persistent preference is read or modified.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android reports reconcile with Finance and share complete files',
    (tester) async {
      await initializeDateFormatting();
      final http = HttpClient();
      final response = await (await http.getUrl(
        Uri.parse('http://127.0.0.1:18097/qa/session'),
      )).close();
      final session =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      http.close();
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: HttpLink(
          'http://127.0.0.1:18097/graphql',
          defaultHeaders: {
            'authorization': 'Bearer ${session['token']}',
            'apps': 'pos',
            'x-iid': session['tenant'] as String,
          },
        ),
      );
      final repo = GraphQLPosFinancialReportRepository.withClient(() => client);
      final options = (await repo.getOptions()).fold(
        (failure) => throw StateError(failure.message),
        (value) => value,
      );
      expect(options.canExport, true);
      final range = FinancialReportRange(
        session['start'] as String,
        session['today'] as String,
      );
      final pl = (await repo.getProfitLoss(
        range,
      )).fold((failure) => throw StateError(failure.message), (value) => value);
      expect(pl.netProfit, 70000);
      expect(pl.cogs, 120000);
      expect(pl.grossProfit, 80000);
      for (final entry in {
        PosBusinessReportKind.cashFlow: ('closing_cash', 160000),
        PosBusinessReportKind.receivables: ('outstanding', 60000),
        PosBusinessReportKind.payables: ('outstanding', 60000),
        PosBusinessReportKind.inventory: ('stock_value', 560000),
        PosBusinessReportKind.movement: ('closing_stock_value', 560000),
        PosBusinessReportKind.restock: ('low_stock', 1),
      }.entries) {
        final report =
            (await repo.getBusinessReport(
              PosBusinessReportFilter(kind: entry.key, range: range),
            )).fold(
              (failure) => throw StateError(failure.message),
              (value) => value,
            );
        expect(
          report.metrics.firstWhere((m) => m.key == entry.value.$1).value,
          entry.value.$2,
          reason: entry.key.code,
        );
        expect(report.coverage, 'complete');
      }
      final cutoff = session['yesterday'] as String;
      final past = (await repo.getBusinessReport(
        PosBusinessReportFilter(
          kind: PosBusinessReportKind.receivables,
          range: FinancialReportRange(cutoff, cutoff),
        ),
      )).fold((failure) => throw StateError(failure.message), (value) => value);
      expect(
        past.metrics.firstWhere((m) => m.key == 'outstanding').value,
        100000,
      );
      Widget app(Widget page) => MaterialApp(
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: page),
      );
      Future<void> settled() async {
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 120 &&
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await tester.pumpWidget(
        app(PosProfitLossPage(key: const ValueKey('pl'), repository: repo)),
      );
      await settled();
      expect(find.text('Laba Rugi'), findsOneWidget);
      expect(find.text('Rp 70.000'), findsWidgets);
      await tester.pumpWidget(
        app(
          PosBusinessReportPage(
            key: const ValueKey('cash'),
            repository: repo,
            initialKind: PosBusinessReportKind.cashFlow,
          ),
        ),
      );
      await settled();
      expect(find.text('Arus Kas'), findsOneWidget);
      expect(find.text('Rp 160.000'), findsWidgets);
      // A host-side QA watcher only dismisses Android's chooser, never selects a
      // recipient. It records the actual chooser and verifies the native cache.
      for (final label in ['CSV / Excel', 'PDF']) {
        await tester.tap(find.byIcon(Icons.file_download_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pump(const Duration(seconds: 2));
        for (
          var i = 0;
          i < 240 &&
              find.byIcon(Icons.file_download_outlined).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      }
      await tester.pumpWidget(
        app(
          PosBusinessReportPage(
            key: const ValueKey('aging'),
            repository: repo,
            initialKind: PosBusinessReportKind.receivables,
          ),
        ),
      );
      await settled();
      expect(find.text('Piutang Pelanggan'), findsWidgets);
      expect(find.text('Rp 60.000'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Utang Pemasok'));
      await settled();
      expect(find.text('Rp 60.000'), findsWidgets);
      await tester.pumpWidget(
        app(
          PosBusinessReportPage(
            key: const ValueKey('stock'),
            repository: repo,
            initialKind: PosBusinessReportKind.inventory,
          ),
        ),
      );
      await settled();
      expect(find.text('Rp 560.000'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pergerakan Stok'));
      await settled();
      expect(find.text('Rp 560.000'), findsWidgets);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Kebutuhan Restok'));
      await settled();
      expect(find.text('Produk Stok'), findsOneWidget);
      binding.reportData = {
        'status': 'pass',
        'scope': 'disposable authenticated staging',
        'reconciliation': [
          'profit_loss',
          'cash_flow',
          'ar',
          'ap',
          'historical_inventory',
          'movement',
          'restock',
        ],
        'historical_cutoff': 'pass',
        'native_share_requests': 2,
      };
    },
  );
}
