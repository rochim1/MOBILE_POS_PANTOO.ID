import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';

void main() {
  testWidgets(
    'queue load failure persists with retry and fits a narrow short viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 150,
                child: PosQueueLoadError(onRetry: () => attempts++),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Antrean belum berhasil dimuat'), findsOneWidget);
      expect(find.text('Tidak ada pesanan aktif'), findsNothing);
      await tester.scrollUntilVisible(find.text('Muat ulang antrean'), 80);
      await tester.tap(find.text('Muat ulang antrean'));
      expect(attempts, 1);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'active orders and kitchen render persistent failures before empty queues',
    () {
      for (final file in [
        'pos_table_order_page.dart',
        'pos_kitchen_display_page.dart',
      ]) {
        final source = File(
          'lib/presentation/pages/pos/$file',
        ).readAsStringSync();
        expect(source, contains('return PosQueueLoadError(onRetry:'));
        expect(
          source.replaceAll(RegExp(r'\s+'), ''),
          contains(
            'state.status==PosOrderManagementStatus.failure&&state.orders.isEmpty',
          ),
        );
      }
    },
  );
}
