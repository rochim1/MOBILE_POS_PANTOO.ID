import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_navigation_history.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_back_navigation.dart';

void main() {
  test('back follows actual menu visits, including primary tabs and cashier', () {
    final history = PosNavigationHistory();
    for (final page in [2, 4, 7, 19, 1]) { history.visit(page); }
    for (final page in [19, 7, 4, 2, 1, 1]) {
      expect(history.back(fallback: 1), page);
    }
    expect(history.canGoBack, false);
  });
  test('repeat visits do not grow history, reset removes previous operator pages', () {
    final history = PosNavigationHistory();
    history.visit(4); history.visit(4); history.visit(7);
    expect(history.back(fallback: 1), 4);
    expect(history.back(fallback: 1), 1);
    history.visit(19);
    history.reset(4);
    expect(history.canGoBack, false);
    expect(history.back(fallback: 4), 4);
  });
  test('back skips revoked permissions and uses safe primary destination', () {
    final history = PosNavigationHistory();
    for (final page in [4, 19, 7, 1]) { history.visit(page); }
    expect(history.back(fallback: 4, isAllowed: (page) => page == 4), 4);
    expect(history.back(fallback: 4, isAllowed: (page) => page == 4), 4);
    history.reset(11);
    expect(history.back(fallback: 4), 4);
  });
  test('shell wires all selected destinations to history and does not exit at root', () {
    final shell = File('lib/presentation/pages/pos/pos_shell_page.dart').readAsStringSync();
    expect(shell, contains('set _selectedIndex(int index) => _navigation.visit(index);'));
    expect(shell, contains('PosBackNavigation('));
    expect(shell, contains('onBack: _backWithinMobileShell'));
    expect(shell, contains('_navigation.reset(_selectedIndex)'));
    expect(shell, contains('_canReturnToDestination'));
    expect(shell, isNot(contains('canPop:\n          !isMobile')));
  });
  for (final size in [const Size(390, 844), const Size(1100, 800)]) {
    testWidgets('system and navbar back preserve real visit order and never exit $size', (tester) async {
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final platformCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call.method); return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
      final history = PosNavigationHistory();
      late StateSetter update;
      await tester.pumpWidget(MaterialApp(home: StatefulBuilder(builder: (context, setState) {
        update = setState;
        void back() => setState(() { history.back(fallback: 1); });
        return PosBackNavigation(onBack: back, child: Scaffold(
          appBar: AppBar(leading: IconButton(key: const Key('back'), onPressed: back, icon: const Icon(Icons.arrow_back))),
          body: Column(children: [
            Text('page-${history.current}'),
            TextButton(onPressed: () => showDialog<void>(context: context, builder: (_) => const AlertDialog(content: Text('Dialog'))), child: const Text('Open dialog')),
            TextButton(onPressed: () => Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Detail')))), child: const Text('Open detail')),
          ]),
        ));
      })));
      for (final page in [2, 4, 7, 19, 1]) { update(() => history.visit(page)); await tester.pumpAndSettle(); }
      await tester.tap(find.text('Open dialog')); await tester.pumpAndSettle();
      await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
      expect(find.text('Dialog'), findsNothing); expect(history.current, 1);
      await tester.tap(find.text('Open detail')); await tester.pumpAndSettle();
      await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
      expect(find.text('Detail'), findsNothing); expect(history.current, 1);
      await tester.tap(find.byKey(const Key('back'))); await tester.pumpAndSettle();
      expect(find.text('page-19'), findsOneWidget);
      for (final page in [7, 4, 2, 1, 1]) {
        await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
        expect(find.text('page-$page'), findsOneWidget);
      }
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('pushed payment route keeps its busy guard before returning to shell', (tester) async {
    var backs = 0;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => PosBackNavigation(
      onBack: () => backs++, child: Scaffold(body: TextButton(onPressed: () => Navigator.push<void>(context,
        MaterialPageRoute(builder: (_) => const PopScope(canPop: false, child: Scaffold(body: Text('Payment busy'))))),
        child: const Text('Pay'))),
    ))));
    await tester.tap(find.text('Pay')); await tester.pumpAndSettle();
    await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
    expect(find.text('Payment busy'), findsOneWidget); expect(backs, 0);
  });
}
