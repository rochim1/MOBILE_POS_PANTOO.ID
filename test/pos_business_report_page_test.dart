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
import 'package:mobile_pos_pantoo/presentation/widgets/pos_category_navigation.dart';
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
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      tester
          .widget<PosCategoryDropdown<PosBusinessReportKind>>(
            find.byType(PosCategoryDropdown<PosBusinessReportKind>),
          )
          .onSelected(PosBusinessReportKind.restock);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.tap(find.byKey(const Key('business_report_filter_toggle')));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'export requires explicit permission and English aging remains usable with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      expect(
        tester
            .widget<PosCategoryDropdown<PosBusinessReportKind>>(
              find.byType(PosCategoryDropdown<PosBusinessReportKind>),
            )
            .items
            .length,
        2,
      );
      expect(tester.takeException(), isNull);
      tester
          .widget<PosCategoryDropdown<PosBusinessReportKind>>(
            find.byType(PosCategoryDropdown<PosBusinessReportKind>),
          )
          .onSelected(PosBusinessReportKind.payables);
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
