import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_mobile_bottom_bar.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_system_safe_area.dart';

void main() {
  for (final width in [320.0, 360.0, 768.0]) {
    for (final showCashier in [true, false]) {
      testWidgets(
        'inline bottom bar protects content at $width, cashier=$showCashier',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1;
          tester.view.padding = const FakeViewPadding(bottom: 24);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);
          var pays = 0, opens = 0;
          final taps = List<int>.filled(4, 0);
          const labels = ['Laporan', 'Katalog', 'Transaksi', 'Lainnya'];
          Widget destination(int index) => TextButton(
            onPressed: () => taps[index]++,
            child: Text(
              labels[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.5)),
                child: PosSystemSafeArea(child: child!),
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const ValueKey('pay'),
                      onPressed: () => pays++,
                      child: const Text('Bayar'),
                    ),
                  ),
                ),
                bottomNavigationBar: PosMobileBottomBar(
                  reports: destination(0),
                  catalog: destination(1),
                  transactions: destination(2),
                  more: destination(3),
                  onOpenCashier: showCashier ? () => opens++ : null,
                ),
              ),
            ),
          );
          final bar = tester.getRect(find.byType(BottomAppBar));
          final pay = tester.getRect(find.byKey(const ValueKey('pay')));
          expect(bar.bottom, lessThanOrEqualTo(800 - 24));
          expect(
            pay.bottom,
            closeTo(bar.top, .01),
            reason: 'no grey spacer or covered last row',
          );
          final material = tester.widget<BottomAppBar>(
            find.byType(BottomAppBar),
          );
          expect(material.elevation, 0);
          expect(material.surfaceTintColor, Colors.transparent);
          expect(material.shape, isNull);
          if (showCashier) {
            final entry = tester.getRect(find.byType(FloatingActionButton));
            expect(entry.top, greaterThanOrEqualTo(bar.top));
            expect(entry.bottom, lessThanOrEqualTo(bar.bottom));
            expect(entry.overlaps(pay), isFalse);
            await tester.tap(find.byType(FloatingActionButton));
            expect(opens, 1);
          } else {
            expect(find.byType(FloatingActionButton), findsNothing);
          }
          await tester.tap(find.byKey(const ValueKey('pay')));
          expect(pays, 1);
          for (var i = 0; i < labels.length; i++) {
            final nav = tester.getRect(find.text(labels[i]));
            expect(nav.top, greaterThanOrEqualTo(bar.top));
            expect(nav.bottom, lessThanOrEqualTo(bar.bottom));
            expect(nav.bottom, lessThanOrEqualTo(800 - 24));
            await tester.tap(find.text(labels[i]));
            expect(taps[i], 1);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  test(
    'real shell uses the inline bar and no longer overlays a dock on content',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_shell_page.dart',
      ).readAsStringSync();
      expect(source, contains('PosMobileBottomBar('));
      expect(
        source,
        isNot(contains('FloatingActionButtonLocation.centerDocked')),
      );
      expect(source, isNot(contains('child: PosCashierDockBody(')));
      expect(source, contains('onOpenCashier:'));
    },
  );
}
