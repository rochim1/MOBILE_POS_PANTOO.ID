import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_paged_reference_picker.dart';

void main() {
  testWidgets(
    '5,005 eligible POs: bounded pages and late search return the selected snapshot',
    (tester) async {
      final rows = List.generate(
        5005,
        (i) => <String, dynamic>{
          '_id': '$i',
          'no_po': 'PO ${i.toString().padLeft(5, '0')}',
        },
      );
      final calls = <(String, int)>[];
      Map<String, dynamic>? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  selected = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => Dialog(
                      child: SizedBox(
                        width: 350,
                        height: 500,
                        child: PosPagedReferencePicker(
                          label: (row) => row['no_po'],
                          loader: (search, page) async {
                            calls.add((search, page));
                            final matched = rows
                                .where(
                                  (row) =>
                                      (row['no_po'] as String).contains(search),
                                )
                                .toList();
                            return PosInventoryDocumentPage(
                              matched.skip((page - 1) * 20).take(20).toList(),
                              matched.length,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Pilih PO'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pilih PO'));
      await tester.pumpAndSettle();
      expect(find.text('PO 00000'), findsOneWidget);
      expect(find.text('PO 00020'), findsNothing);
      await tester.tap(find.byTooltip('Halaman berikutnya'));
      await tester.pumpAndSettle();
      expect(find.text('PO 00020'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'PO 05004');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'PO 05004'));
      await tester.pumpAndSettle();
      expect(selected?['_id'], '5004');
      expect(calls, contains(('', 2)));
      expect(calls.last, ('PO 05004', 1));
    },
  );
}
