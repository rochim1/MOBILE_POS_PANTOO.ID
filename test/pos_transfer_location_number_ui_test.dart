import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_operation_page.dart';
import 'pos_transfer_editor_test.dart' show TransferFake;
import 'pos_transfer_operation_test.dart' show ReceiptFake;

class _Outlets extends TransferFake {
  @override
  Future<List<Map<String, dynamic>>> warehouses() async => [
    {
      '_id': 'from',
      'nama_cabang': 'Gudang A',
      'warehouse_type': 'store',
      'linked_toko_id': 'A',
    },
    {
      '_id': 'to',
      'nama_cabang': 'Display B',
      'warehouse_type': 'display',
      'linked_toko_id': 'B',
    },
    {
      '_id': 'own',
      'nama_cabang': 'Display A',
      'warehouse_type': 'display',
      'linked_toko_id': 'A',
    },
  ];
}

class _Packaging extends TransferFake {
  @override
  Future<Map<String, dynamic>> query(
    String document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    if (document.contains('MobileTransferUnits')) {
      return {
        'GetOneInventarisUmum': {
          'base_unit': 'unit',
          'unit_conversions': [
            {'unit': 'box', 'factor': 12},
          ],
        },
      };
    }
    return super.query(document, variables);
  }
}

void main() {
  testWidgets(
    'zero packaging fields are empty and typing 025 converts exactly 25 boxes',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: _Packaging(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Input satuan / kemasan'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Input satuan / kemasan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Input satuan / kemasan'));
      await tester.pumpAndSettle();
      final box = find.widgetWithText(TextFormField, 'box (× 12.0)');
      expect(tester.widget<TextFormField>(box).initialValue, '');
      await tester.enterText(box, '025');
      await tester.pump();
      expect(find.text('025'), findsNothing);
      await tester.tap(find.text('Gunakan jumlah'));
      await tester.pumpAndSettle();
      final quantity = find.widgetWithText(TextFormField, 'Jumlah unit');
      expect(tester.widget<TextFormField>(quantity).initialValue, '300');
    },
  );
  testWidgets(
    'invalid saved store/display pair is explained before save and cannot send',
    (tester) async {
      final repo = _Outlets();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Display harus milik'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      expect(find.textContaining('Display harus milik'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Simpan mutasi'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Simpan mutasi'),
            )
            .onPressed,
        isNull,
      );
      expect(repo.requests, isEmpty);
    },
  );
  testWidgets(
    'destination offers own display and disables mismatched legacy selection',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: _Outlets(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final current = find.text('Display B · Tidak tersedia');
      await tester.scrollUntilVisible(
        current,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(current);
      await tester.pumpAndSettle();
      await tester.tap(current);
      await tester.pumpAndSettle();
      final own = find.text('Display A · Display');
      expect(own, findsWidgets);
      expect(find.text('Display B · Display'), findsNothing);
      await tester.tap(own.last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Display harus milik'), findsNothing);
    },
  );
  testWidgets('main quantity displays integer and typing 025 displays 25', (
    tester,
  ) async {
    final repo = TransferFake();
    await tester.pumpWidget(
      MaterialApp(
        home: PosTransferEditorPage(
          existing: const {'_id': 'doc'},
          repository: repo,
        ),
      ),
    );
    // Main quantity also has the formatter, without changing saved metadata.
    await tester.pumpAndSettle();
    final qty = find.widgetWithText(TextFormField, 'Jumlah unit');
    await tester.scrollUntilVisible(
      qty,
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    expect(tester.widget<TextFormField>(qty).initialValue, '2');
    await tester.enterText(qty, '025');
    await tester.pump();
    expect(find.text('25'), findsOneWidget);
    expect(find.text('025'), findsNothing);
  });
  testWidgets(
    'receipt zero is empty; typing quantity and valid serial batch data keeps exact amount',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferOperationPage(
            transfer: const {'_id': 'doc'},
            mode: 'receive',
            repository: ReceiptFake(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final qty = find.widgetWithText(TextFormField, 'Jumlah diproses');
      await tester.scrollUntilVisible(
        qty,
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      expect(tester.widget<TextFormField>(qty).initialValue, '');
      await tester.enterText(qty, '02');
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      expect(find.text('02'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
