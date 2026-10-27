import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_active_order_status_tabs.dart';

void main() {
  for (final width in <double>[320, 360, 600]) {
    testWidgets('status antrean muat di ${width.toInt()} dp', (tester) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosActiveOrderStatusTabs(
              selectedStatus: '',
              counts: const {
                '': 35,
                'Baru': 31,
                'Diproses': 2,
                'Siap': 1,
                'Disajikan': 1,
              },
              onSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      expect(find.text('Semua 35'), findsOneWidget);
      expect(find.text('Baru 31'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('order-status-Baru')));
      expect(selected, 'Baru');
      expect(tester.takeException(), isNull);
    });
  }
}
