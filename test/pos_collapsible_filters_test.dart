import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_collapsible_filters.dart';

void main() {
  Future<void> open(WidgetTester tester, {double width = 390,
    double height = 844, String language = 'id', bool forceExpanded = false,
    double scale = 1}) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: Column(children: [
        PosCollapsibleFilters(
          toggleKey: const Key('toggle'), activeCount: 2,
          forceExpanded: forceExpanded,
          actions: [TextButton(onPressed: () {}, child: const Text('Tambah'))],
          child: Column(children: [
            const TextField(decoration: InputDecoration(labelText: 'Cari')),
            DropdownButtonFormField<String>(
              initialValue: 'all',
              items: const [DropdownMenuItem(value: 'all', child: Text('Semua')),
                DropdownMenuItem(value: 'open', child: Text('Buka'))],
              onChanged: (_) {},
            ),
            const SizedBox(height: 220),
            const Text('Akhir panel'),
          ]),
        ),
        const Expanded(child: Center(child: Text('Data'))),
      ])),
    ));
    await tester.pumpAndSettle();
  }

  for (final language in ['id', 'en']) {
    testWidgets('phone collapsed, translated toggle and actions visible $language', (tester) async {
      await open(tester, language: language);
      expect(find.byType(TextField), findsNothing);
      expect(find.text(language == 'id' ? 'Filter' : 'Filter'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('toggle'))).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('collapse preserves text and selection but removes hidden focus', (tester) async {
    await open(tester);
    final toggle = find.byKey(const Key('toggle'));
    await tester.tap(toggle); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'INV-42');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buka').last); await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(FocusManager.instance.primaryFocus?.context?.widget, isNot(isA<EditableText>()));
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.text('INV-42'), findsOneWidget);
    expect(find.text('Buka'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resize retains input and phone collapse preference', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('toggle'))); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'stock');
    await tester.tap(find.byKey(const Key('toggle'))); await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1280, 900); await tester.pumpAndSettle();
    expect(find.byKey(const Key('toggle')), findsNothing);
    expect(find.text('stock'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844); await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const Key('toggle'))); await tester.pumpAndSettle();
    expect(find.text('stock'), findsOneWidget);
  });

  testWidgets('guidance forces filter target visible', (tester) async {
    await open(tester, forceExpanded: true);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const Key('toggle')), findsNothing);
  });

  testWidgets('short phone large text scrolls panel without crowding data', (tester) async {
    await open(tester, width: 320, height: 420, scale: 1.4);
    await tester.tap(find.byKey(const Key('toggle'))); await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(SingleChildScrollView)).height, lessThanOrEqualTo(160));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Akhir panel').hitTestable(), findsOneWidget);
    expect(find.text('Data').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet filters and actions remain visible', (tester) async {
    await open(tester, width: 800);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tambah'), findsOneWidget);
    expect(find.byKey(const Key('toggle')), findsNothing);
  });
}
