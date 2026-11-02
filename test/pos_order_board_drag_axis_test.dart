import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Kanban Pesanan Aktif hanya memulai drag horizontal', () {
    final source = File(
      'lib/presentation/pages/pos/pos_table_order_page.dart',
    ).readAsStringSync();
    final start = source.indexOf('return Draggable<PosOrderDetail>(');
    expect(start, greaterThanOrEqualTo(0));
    final draggable = source.substring(
      start,
      source.indexOf('feedback:', start),
    );
    expect(draggable, contains('affinity: Axis.horizontal'));
    expect(draggable, contains('axis: Axis.horizontal'));
  });

  test('Tampilan Dapur membedakan scroll vertikal dan drag horizontal', () {
    final source = File(
      'lib/presentation/pages/pos/pos_kitchen_display_page.dart',
    ).readAsStringSync();
    final start = source.indexOf('return Draggable<PosOrderDetail>(');
    expect(start, greaterThanOrEqualTo(0));
    final draggable = source.substring(
      start,
      source.indexOf('feedback:', start),
    );
    expect(draggable, contains('affinity: Axis.horizontal'));
    expect(draggable, contains('axis: Axis.horizontal'));
    expect(source, contains('horizontalTravel < 72'));
    expect(source, contains('compact: true'));
  });

  testWidgets('geser vertikal scroll daftar, geser horizontal memindah kartu', (
    tester,
  ) async {
    final scroll = ScrollController();
    var drops = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 300,
            child: ListView(
              controller: scroll,
              children: [
                Row(
                  children: [
                    Draggable<int>(
                      data: 1,
                      affinity: Axis.horizontal,
                      axis: Axis.horizontal,
                      feedback: const Material(child: Text('Kartu')),
                      child: const SizedBox(
                        key: ValueKey('order-card'),
                        width: 140,
                        height: 140,
                        child: ColoredBox(color: Colors.teal),
                      ),
                    ),
                    DragTarget<int>(
                      onAcceptWithDetails: (_) => drops++,
                      builder: (_, _, _) => const SizedBox(
                        width: 140,
                        height: 140,
                        child: ColoredBox(color: Colors.amber),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('order-card')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(drops, 0);

    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('order-card')),
      const Offset(165, 0),
    );
    await tester.pumpAndSettle();
    expect(drops, 1);
    scroll.dispose();
  });
}
