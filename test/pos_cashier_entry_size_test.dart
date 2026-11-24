import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_entry_button.dart';

void main() {
  for (final width in [320.0, 360.0, 768.0]) {
    testWidgets('cashier entry stays compact at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var opens = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PosCashierEntryButton(onOpenCashier: () => opens++),
            ),
          ),
        ),
      );
      final entry = find.byType(FloatingActionButton);
      expect(tester.getSize(entry).longestSide, lessThanOrEqualTo(48));
      expect(tester.widget<Icon>(find.byIcon(Icons.point_of_sale)).size, 20);
      await tester.tap(entry);
      expect(opens, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
