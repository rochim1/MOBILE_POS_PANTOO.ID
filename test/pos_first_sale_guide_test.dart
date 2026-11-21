import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_first_sale_guide.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  Future<void> show(
    WidgetTester tester, {
    bool enabled = true,
    String step = 'product',
    String scope = 'tenant|owner',
    GlobalKey? target,
  }) async {
    final key = target ?? GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosFirstSaleGuide(
            preferences: prefs,
            scope: scope,
            stepId: step,
            enabled: enabled,
            title: 'Guide $step',
            stages: [
              PosSetupTourStage(
                title: 'Focus $step',
                description: 'Help for $step',
                target: key,
              ),
            ],
            child: Center(
              child: FilledButton(
                key: key,
                onPressed: () {},
                child: const Text('Target action'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'new owner gets a focused popup once and can reopen after skipping',
    (tester) async {
      await show(tester);
      expect(find.text('Focus product'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pos_setup_spotlight_frame')),
        findsOneWidget,
      );
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      await show(tester);
      expect(find.text('Focus product'), findsNothing);
      final launcher = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Panduan langkah ini'),
      );
      expect(
        launcher.style?.backgroundColor?.resolve({}),
        const Color(0xFFFFE082),
      );
      expect(
        launcher.style?.foregroundColor?.resolve({}),
        const Color(0xFF3E3300),
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'Panduan langkah ini')).height,
        greaterThanOrEqualTo(44),
      );
      await tester.tap(find.text('Panduan langkah ini'));
      await tester.pumpAndSettle();
      expect(find.text('Focus product'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('each next step and different identity gets its own popup', (
    tester,
  ) async {
    for (final value in [
      ('product', 'A'),
      ('opening', 'A'),
      ('cash', 'A'),
      ('cashier', 'A'),
      ('product', 'B'),
    ]) {
      await show(tester, step: value.$1, scope: value.$2);
      expect(find.text('Focus ${value.$1}'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'disabled legacy offline or locked flow has no popup or launcher',
    (tester) async {
      await show(tester, enabled: false);
      expect(find.text('Focus product'), findsNothing);
      expect(find.text('Panduan langkah ini'), findsNothing);
      expect(find.text('Target action'), findsOneWidget);
      expect(prefs.getKeys(), isEmpty);
    },
  );
  testWidgets(
    'locking or revoking guide eligibility dismisses only the guide',
    (tester) async {
      await show(tester);
      expect(find.text('Focus product'), findsOneWidget);
      await show(tester, enabled: false);
      expect(find.text('Focus product'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'missing focus area does not highlight a random area or block page',
    (tester) async {
      final missing = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosFirstSaleGuide(
              preferences: prefs,
              scope: 'A',
              stepId: 'product',
              enabled: true,
              title: 'Guide',
              stages: [
                PosSetupTourStage(
                  title: 'Missing',
                  description: 'Missing',
                  target: missing,
                ),
              ],
              child: const Text('Page available'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Missing'), findsNothing);
      expect(find.text('Page available'), findsOneWidget);
    },
  );
  test(
    'shell uses focused first-sale guide instead of the old instruction banner',
    () {
      final shell = File(
        'lib/presentation/pages/pos/pos_shell_page.dart',
      ).readAsStringSync();
      expect(shell, contains('PosFirstSaleGuide('));
      expect(shell, isNot(contains("'1. Tambahkan produk pertama'")));
      expect(shell, contains('_setupTourTargets.openingQuantity'));
    },
  );
  testWidgets('spotlight popup fits a short phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: PosFirstSaleGuide(
            preferences: prefs,
            scope: 'small',
            stepId: 'stock',
            enabled: true,
            title: 'Panduan penjualan pertama',
            stages: [
              PosSetupTourStage(
                title: 'Isi jumlah stok awal',
                description:
                    'Masukkan barang yang sudah Anda miliki dan biaya per satuan. Untuk barang baru datang, gunakan Pembelian & Penerimaan.',
                target: key,
              ),
            ],
            child: Center(
              child: TextButton(
                key: key,
                onPressed: () {},
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final card = tester.getRect(find.byType(Card));
    expect(card.bottom, lessThanOrEqualTo(480));
    expect(card.top, greaterThanOrEqualTo(0));
    final close = find.byTooltip('Tutup panduan');
    await tester.ensureVisible(close);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(find.text('Isi jumlah stok awal'), findsNothing);
  });
  testWidgets('only currently mounted fields become spotlight stages', (
    tester,
  ) async {
    final present = GlobalKey(), absent = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosFirstSaleGuide(
            preferences: prefs,
            scope: 'stock',
            stepId: 'opening',
            enabled: true,
            title: 'Opening',
            stages: [
              PosSetupTourStage(
                title: 'Choose product',
                description: 'Choose first',
                target: present,
              ),
              PosSetupTourStage(
                title: 'Quantity not mounted',
                description: 'Not yet',
                target: absent,
              ),
            ],
            child: Center(
              child: TextButton(
                key: present,
                onPressed: () {},
                child: const Text('Product'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
  });
  testWidgets('next and back move the spotlight to the actual control', (
    tester,
  ) async {
    final first = GlobalKey(), second = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosFirstSaleGuide(
            preferences: prefs,
            scope: 'two',
            stepId: 'stock',
            title: 'Guide',
            enabled: true,
            stages: [
              PosSetupTourStage(
                title: 'First target',
                description: 'First',
                target: first,
              ),
              PosSetupTourStage(
                title: 'Second target',
                description: 'Second',
                target: second,
              ),
            ],
            child: Column(
              children: [
                TextButton(
                  key: first,
                  onPressed: () {},
                  child: const Text('First action'),
                ),
                const Spacer(),
                TextButton(
                  key: second,
                  onPressed: () {},
                  child: const Text('Second action'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final next = find.text('Berikutnya');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Second target'), findsOneWidget);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('pos_setup_spotlight_frame')))
          .contains(tester.getCenter(find.byKey(second))),
      isTrue,
    );
    final back = find.text('Kembali');
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.text('First target'), findsOneWidget);
    await tester.tap(find.byTooltip('Tutup panduan'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'tapping the highlighted product action closes guide and calls handler once',
    (tester) async {
      final key = GlobalKey();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosFirstSaleGuide(
              preferences: prefs,
              scope: 'action',
              stepId: 'product',
              title: 'Guide',
              enabled: true,
              stages: [
                PosSetupTourStage(
                  title: 'Add first product',
                  description: 'Open form',
                  target: key,
                  onTargetTap: () async {
                    calls++;
                  },
                ),
              ],
              child: Center(
                child: TextButton(
                  key: key,
                  onPressed: () {},
                  child: const Text('Add'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pos_setup_spotlight_frame')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Add first product'), findsNothing);
    },
  );
}
