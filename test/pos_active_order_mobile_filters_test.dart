import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_active_order_mobile_filters.dart';

void main() {
  for (final width in <double>[320, 360, 600]) {
    testWidgets('filter pesanan aktif ringkas di lebar ${width.toInt()} dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var opened = false;
      var search = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(12),
              child: PosActiveOrderMobileFilters(
                searchController: controller,
                onSearchChanged: (value) => search = value,
                onOpenFilters: () => opened = true,
                activeLabels: const ['Meja', 'Sedang Dibuat'],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Filter aktif: Meja · Sedang Dibuat'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('active-order-mobile-filter')),
      );
      expect(opened, isTrue);
      await tester.enterText(find.byType(TextField), 'ORD-123');
      expect(search, 'ORD-123');
      expect(tester.takeException(), isNull);
    });
  }
}
