import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/reports/pos_report_export.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/financial_report_export_button.dart';

const doc = PosReportExportDocument(
  title: 'Arus Kas',
  fileStem: 'pantoo-cash-flow-2026-11-13',
  metadata: [],
  metrics: [],
  headers: ['Jumlah'],
  rows: [
    [140000],
  ],
  displayRows: [
    ['Rp 140.000'],
  ],
  notes: [],
);
Widget app(FinancialReportExportButton button) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(body: Center(child: button)),
);
Future<void> selectCsv(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.file_download_outlined));
  await tester.pumpAndSettle();
  await tester.tap(find.text('CSV / Excel'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'share preserves the CSV filename, MIME and complete report bytes',
    (tester) async {
      ShareParams? sent;
      await tester.pumpWidget(
        app(
          FinancialReportExportButton(
            enabled: true,
            isCurrent: () => true,
            load: () async => const Right(doc),
            share: (params) async {
              sent = params;
              return const ShareResult('', ShareResultStatus.dismissed);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await selectCsv(tester);
      expect(sent!.fileNameOverrides, ['pantoo-cash-flow-2026-11-13.csv']);
      expect(sent!.files!.single.mimeType, 'text/csv');
      expect(
        utf8.decode(await sent!.files!.single.readAsBytes()),
        contains('140000'),
      );
      expect(sent!.sharePositionOrigin!.width, greaterThan(0));
    },
  );
  testWidgets(
    'operator or filter changes while export is loading prevent sharing',
    (tester) async {
      final pending = Completer<Either<Failure, PosReportExportDocument>>();
      var current = true, shared = false;
      await tester.pumpWidget(
        app(
          FinancialReportExportButton(
            enabled: true,
            isCurrent: () => current,
            load: () => pending.future,
            share: (params) async {
              shared = true;
              return const ShareResult('', ShareResultStatus.dismissed);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.file_download_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CSV / Excel'));
      await tester.pump();
      current = false;
      pending.complete(const Right(doc));
      await tester.pumpAndSettle();
      expect(shared, false);
    },
  );
  testWidgets('stale report does not even start an export request', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      app(
        FinancialReportExportButton(
          enabled: true,
          isCurrent: () => false,
          load: () async {
            calls++;
            return const Right(doc);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await selectCsv(tester);
    expect(calls, 0);
  });
}
