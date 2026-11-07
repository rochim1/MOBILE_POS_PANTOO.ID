import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_offline_queue_page.dart';

void main() {
  for (final submit in [true, false]) {
    testWidgets(
      'offline PIN dialog survives dismissal and parent rebuild: submit=$submit',
      (tester) async {
        String? result;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, rebuild) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showPosOfflineOperatorVerification(context);
                    rebuild(() {});
                  },
                  child: const Text('Recover'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Recover'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '123456');
        await tester.tap(find.text(submit ? 'Verifikasi & kirim' : 'Batal'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(AlertDialog), findsNothing);
        expect(result, submit ? '123456' : isNull);
        expect(find.text('Recover'), findsOneWidget);
      },
    );
  }
}
