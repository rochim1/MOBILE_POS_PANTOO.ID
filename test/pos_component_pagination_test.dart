import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_product_management_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_component_picker.dart';

void main() {
  testWidgets(
    '5,005 components: selection survives paging and late server search',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Set<String>? selected;
      final calls = <(String, int)>[];
      final rows = List.generate(
        5005,
        (i) => PosProduct(
          id: '$i',
          name: 'QA ${i.toString().padLeft(5, '0')}',
          code: 'P-$i',
          category: 'Bahan',
          price: 1,
          stock: 10,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showDialog<Set<String>>(
                    context: context,
                    builder: (_) => Dialog(
                      child: SizedBox(
                        width: 360,
                        height: 600,
                        child: PosComponentPicker(
                          selected: const {},
                          onRecords: (_) {},
                          loader: (search, page) async {
                            calls.add((search, page));
                            final matched = rows
                                .where((row) => row.name.contains(search))
                                .toList();
                            return PosComponentPage(
                              matched.skip((page - 1) * 20).take(20).toList(),
                              matched.length,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Buka'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(find.text('QA 00000'), findsOneWidget);
      expect(find.text('QA 00020'), findsNothing);
      await tester.tap(find.text('QA 00000'));
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA 00020'));
      await tester.enterText(find.byType(TextField), 'QA 05004');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'QA 05004'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Terapkan (3)'));
      await tester.pumpAndSettle();
      expect(selected, {'0', '20', '5004'});
      expect(calls, contains(('', 2)));
      expect(calls.last, ('QA 05004', 1));
    },
  );
}
