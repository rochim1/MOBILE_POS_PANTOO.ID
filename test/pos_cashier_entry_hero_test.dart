import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_entry_button.dart';

void main() {
  testWidgets(
    'shell cashier button does not collide with nested screen FAB hero',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Scaffold(
              floatingActionButton: FloatingActionButton(onPressed: () {}),
            ),
            floatingActionButton: PosCashierEntryButton(
              showSetupGuide: false,
              onContinueSetup: (_) async {},
              onOpenCashier: () {},
            ),
          ),
        ),
      );
      final fabs = tester
          .widgetList<FloatingActionButton>(find.byType(FloatingActionButton))
          .toList();
      expect(fabs.where((b) => b.heroTag != null).length, 1);
    },
  );
}
