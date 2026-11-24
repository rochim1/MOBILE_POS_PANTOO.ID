import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_entry_button.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_dock_body.dart';
import 'dart:io';

void main() {
  for (final width in [360.0, 768.0]) {
    testWidgets(
      'docked cashier entry never covers the payment action at ${width}px',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var payments = 0, opens = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: PosCashierDockBody(
                  enabled: true,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey('pay'),
                        onPressed: () => payments++,
                        child: const Text('Pay'),
                      ),
                    ),
                  ),
                ),
              ),
              floatingActionButton: PosCashierEntryButton(
                onOpenCashier: () => opens++,
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              bottomNavigationBar: const BottomAppBar(
                height: 60,
                padding: EdgeInsets.zero,
                child: SizedBox.expand(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final pay = tester.getRect(find.byKey(const ValueKey('pay'))),
            fab = tester.getRect(find.byType(FloatingActionButton));
        expect(
          pay.overlaps(fab),
          isFalse,
          reason: 'the bottom action must not sit under the cashier FAB',
        );
        await tester.tapAt(pay.center);
        await tester.pump();
        expect(payments, 1);
        expect(opens, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'the real POS shell keeps cashier access guarded inside the bottom bar',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_shell_page.dart',
      ).readAsStringSync();
      expect(source, contains('PosMobileBottomBar('));
      expect(source, contains('_mobilePrimaryIndex == 1 &&'));
      expect(source, contains('MediaQuery.of(context).viewInsets.bottom == 0'));
      expect(
        source,
        isNot(contains('FloatingActionButtonLocation.centerDocked')),
      );
    },
  );
  testWidgets('a hidden dock reserves no body height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PosCashierDockBody(enabled: false, child: SizedBox.expand()),
        ),
      ),
    );
    final padding = tester.widget<Padding>(
      find
          .descendant(
            of: find.byType(PosCashierDockBody),
            matching: find.byType(Padding),
          )
          .first,
    );
    expect(padding.padding, EdgeInsets.zero);
  });
}
