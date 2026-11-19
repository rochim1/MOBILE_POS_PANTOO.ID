import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_entry_button.dart';

void main() {
  testWidgets(
    'cashier shortcut navigates directly without optional setup work',
    (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: PosCashierEntryButton(
              onOpenCashier: () => opened++,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Buka kasir'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
