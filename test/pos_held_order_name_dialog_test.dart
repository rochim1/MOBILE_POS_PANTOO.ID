import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_held_order_name_dialog.dart';

void main() {
  for (final action in ['save', 'cancel', 'escape', 'barrier', 'back']) {
    testWidgets('held order name stays safe during $action transition', (
      tester,
    ) async {
      String? result = 'not returned';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<String>(
                    context: context,
                    builder: (_) => const PosHeldOrderNameDialog(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        '  QA Resto Campuran  ',
      );
      if (action == 'save') {
        await tester.tap(find.text('Simpan', skipOffstage: false).last);
      } else if (action == 'cancel') {
        await tester.tap(find.text('Batal'));
      } else if (action == 'escape') {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      } else if (action == 'barrier') {
        await tester.tapAt(const Offset(5, 5));
      } else {
        await tester.binding.handlePopRoute();
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(result, action == 'save' ? 'QA Resto Campuran' : null);
      expect(find.byType(PosHeldOrderNameDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
