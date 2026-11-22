import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_service_intake_fields.dart';

const work = PosProduct(
  id: 'work',
  code: 'W',
  name: 'Perbaikan',
  category: 'Jasa',
  price: 100,
  stock: 0,
  productType: 'service',
  serviceIntakeMode: 'work_order',
  tracksStock: false,
);

void main() {
  testWidgets('work details block blank save but technician is optional', (
    tester,
  ) async {
    Map<String, dynamic>? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPosServiceIntakeDialog(
                  context,
                  cart: {work: 1},
                  profile: 'jasa',
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
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(
      find.text('Isi objek layanan atau catatan pekerjaan.'),
      findsOneWidget,
    );
    expect(find.text('Teknisi / staf penanggung jawab'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Laptop QA');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(result?['service_subject'], 'Laptop QA');
    expect(result?['appointment_at'], isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'separate objects keep identifiers and render updated quantities',
    (tester) async {
      final draft = PosServiceIntakeDraft({work: 2}, 'jasa');
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PosServiceIntakeFields(draft: draft),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Detail per objek (opsional)'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pisahkan 1 ke objek lain'));
      await tester.tap(find.text('Pisahkan 1 ke objek lain'));
      await tester.pumpAndSettle();
      expect(draft.lines, hasLength(2));
      expect(draft.lines.map((line) => line['quantity']), [1.0, 1.0]);
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(6));
      final quantities = tester
          .widgetList<TextField>(find.byType(TextField))
          .where((field) => field.decoration?.labelText == 'Jumlah objek');
      expect(quantities.map((field) => field.controller?.text), ['1.0', '1.0']);
      draft.lines[0]['tag_code'] = 'A';
      draft.lines[1]['tag_code'] = 'B';
      expect(draft.validate(), isNull);
      expect(
        (draft.build()!['service_lines'] as List).map(
          (line) => line['tag_code'],
        ),
        ['A', 'B'],
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'a changed multi-object cart cannot be saved without quantity review',
    () {
      final draft = PosServiceIntakeDraft(
        {work: 3},
        'jasa',
        initial: {
          'service_lines': [
            {'product_id': 'work', 'quantity': 1, 'tag_code': 'A'},
            {'product_id': 'work', 'quantity': 1, 'tag_code': 'B'},
          ],
        },
      );
      addTearDown(draft.dispose);
      expect(draft.validate(), contains('tidak sesuai keranjang'));
      draft.lines.first['quantity'] = 2;
      expect(draft.validate(), isNull);
    },
  );
}
