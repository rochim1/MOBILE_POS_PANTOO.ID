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
  Future<void> show(WidgetTester tester, {bool enabled = true, String step = 'product', String scope = 'tenant|owner', GlobalKey? target}) async {
    final key = target ?? GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PosFirstSaleGuide(
      preferences: prefs, scope: scope, stepId: step, enabled: enabled,
      title: 'Guide $step', stages: [PosSetupTourStage(title: 'Focus $step', description: 'Help for $step', target: key)],
      child: Center(child: FilledButton(key: key, onPressed: () {}, child: const Text('Target action'))),
    ))));
    await tester.pumpAndSettle();
  }
  testWidgets('new owner gets a focused popup once and can reopen after skipping', (tester) async {
    await show(tester);
    expect(find.text('Focus product'), findsOneWidget);
    expect(find.byKey(const ValueKey('pos_setup_spotlight_frame')), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await show(tester);
    expect(find.text('Focus product'), findsNothing);
    await tester.tap(find.text('Panduan langkah ini'));
    await tester.pumpAndSettle();
    expect(find.text('Focus product'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
  });
  testWidgets('each next step and different identity gets its own popup', (tester) async {
    for (final value in [('product', 'A'), ('opening', 'A'), ('cash', 'A'), ('cashier', 'A'), ('product', 'B')]) {
      await show(tester, step: value.$1, scope: value.$2);
      expect(find.text('Focus ${value.$1}'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    }
  });
  testWidgets('disabled legacy offline or locked flow has no popup or launcher', (tester) async {
    await show(tester, enabled: false);
    expect(find.text('Focus product'), findsNothing);
    expect(find.text('Panduan langkah ini'), findsNothing);
    expect(find.text('Target action'), findsOneWidget);
    expect(prefs.getKeys(), isEmpty);
  });
  testWidgets('locking or revoking guide eligibility dismisses only the guide', (tester) async {
    await show(tester);
    expect(find.text('Focus product'), findsOneWidget);
    await show(tester, enabled: false);
    expect(find.text('Focus product'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing focus area does not highlight a random area or block page', (tester) async {
    final missing = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: PosFirstSaleGuide(
      preferences: prefs, scope: 'A', stepId: 'product', enabled: true,
      title: 'Guide', stages: [PosSetupTourStage(title: 'Missing', description: 'Missing', target: missing)],
      child: const Text('Page available'),
    ))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Missing'), findsNothing);
    expect(find.text('Page available'), findsOneWidget);
  });
  test('shell uses focused first-sale guide instead of the old instruction banner', () {
    final shell = File('lib/presentation/pages/pos/pos_shell_page.dart').readAsStringSync();
    expect(shell, contains('PosFirstSaleGuide('));
    expect(shell, isNot(contains("'1. Tambahkan produk pertama'")));
    expect(shell, contains('_setupTourTargets.openingQuantity'));
  });
}
