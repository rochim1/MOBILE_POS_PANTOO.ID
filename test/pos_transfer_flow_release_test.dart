import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_transfer_queries.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'pos_transfer_modes_ui_test.dart' show ModeFake;

class _DelayedReferences extends ModeFake {
  final initial = Completer<Map<String, dynamic>>();
  final units = Completer<Map<String, dynamic>>();
  int unitRequests = 0;
  @override
  Future<Map<String, dynamic>> query(
    String document, [
    Map<String, dynamic> variables = const {},
  ]) {
    if (document == PosTransferQueries.items) return initial.future;
    if (document == PosTransferQueries.units) {
      unitRequests++;
      return units.future;
    }
    return super.query(document, variables);
  }

  void finishUnits() => units.complete({
    'GetOneInventarisUmum': {
      'base_unit': 'unit',
      'unit_conversions': [
        {'unit': 'box', 'factor': 12},
      ],
    },
  });
}

Future<void> openUnits(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Input satuan / kemasan'),
    250,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Input satuan / kemasan'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Input satuan / kemasan'));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'optional initial product timeout preserves editable form and notes',
    (tester) async {
      final repo = _DelayedReferences();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            initialSourceId: 'from',
            initialDestinationId: 'to',
            initialInventoryId: 'product',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final notes = find.widgetWithText(TextFormField, 'Catatan transfer');
      await tester.enterText(notes, 'Jangan hilangkan catatan');
      repo.initial.completeError(TimeoutException('initial product slow'));
      await tester.pumpAndSettle();
      expect(find.text('Antar toko / gudang'), findsOneWidget);
      expect(find.text('Jangan hilangkan catatan'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'late unit response does not open dialog after movement mode changes',
    (tester) async {
      final repo = _DelayedReferences();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openUnits(tester);
      await tester.scrollUntilVisible(
        find.text('Mutasi internal'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Mutasi internal'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Ganti jenis'));
      await tester.pump(const Duration(milliseconds: 300));
      repo.finishUnits();
      await tester.pumpAndSettle();
      expect(find.text('Jumlah per satuan / kemasan'), findsNothing);
      expect(find.text('Gunakan jumlah'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('repeated unit taps share one request and one dialog', (
    tester,
  ) async {
    final repo = _DelayedReferences();
    await tester.pumpWidget(
      MaterialApp(
        home: PosTransferEditorPage(
          existing: const {'_id': 'doc'},
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await openUnits(tester);
    await tester.tap(find.text('Input satuan / kemasan'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.unitRequests, 1);
    repo.finishUnits();
    await tester.pumpAndSettle();
    expect(find.text('Jumlah per satuan / kemasan'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
  });
}
