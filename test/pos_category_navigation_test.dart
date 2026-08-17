import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_category_navigation.dart';

void main() {
  testWidgets('sidebar kategori dapat collapse menjadi icon rail dan expand', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerLeft,
            child: PosCategorySidebar<String>(
              title: 'Kategori',
              selected: 'satu',
              items: const [
                PosCategoryItem(
                  value: 'satu',
                  icon: Icons.inventory_2_outlined,
                  label: 'Menu Satu',
                ),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AnimatedContainer)).width, 220);
    expect(find.text('Menu Satu'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AnimatedContainer)).width, 68);
    expect(find.text('Menu Satu'), findsNothing);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(AnimatedContainer)).width, 220);
    expect(find.text('Menu Satu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
