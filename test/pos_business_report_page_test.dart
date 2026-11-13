import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_business_report_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/financial_report_export_button.dart';
import 'pos_business_report_test.dart' show BusinessRepository;

Widget app(
  BusinessRepository repo,
  PosBusinessReportKind kind, {
  Locale locale = const Locale('id'),
  double textScale = 1,
}) => MaterialApp(
  locale: locale,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  home: Scaffold(
    body: RepaintBoundary(
      key: const ValueKey('report-qa'),
      child: PosBusinessReportPage(repository: repo, initialKind: kind),
    ),
  ),
);
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    await font.load();
  });
  testWidgets(
    'inventory on a narrow phone exposes unavailable evidence and consistent tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = BusinessRepository();
      await tester.pumpWidget(app(repo, PosBusinessReportKind.inventory));
      await tester.pumpAndSettle();
      expect(find.text('Persediaan'), findsWidgets);
      expect(find.text('—'), findsOneWidget);
      expect(find.byType(FinancialReportExportButton), findsNothing);
      expect(tester.takeException(), isNull);
      final path = Platform.environment['PANTOO_REPORT_QA_PHONE'];
      if (path != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('report-qa')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byType(ChoiceChip).last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'export requires explicit permission and English aging remains usable with enlarged text',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = BusinessRepository()
        ..options = const Right(
          FinancialReportOptions(
            instansiId: 'tenant-a',
            today: '2026-11-13',
            canExport: true,
          ),
        );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: app(
            repo,
            PosBusinessReportKind.receivables,
            locale: const Locale('en'),
            textScale: 1.4,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FinancialReportExportButton), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(ChoiceChip).last);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
