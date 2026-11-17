import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';

void main() {
  for (final width in [360.0, 1024.0]) {
    testWidgets('business setup retains labels empty, filled and blurred at $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const BusinessSetupPage()));
      await tester.pumpAndSettle();
      void checkLabels() {
        final fields = tester.widgetList<InputDecorator>(find.byType(InputDecorator)).toList();
        expect(fields.length, 2);
        for (final field in fields) {
          expect(field.decoration.labelText, isNotEmpty);
          expect(field.decoration.floatingLabelBehavior, FloatingLabelBehavior.always,
            reason: '${field.decoration.labelText} must not become an unlabeled value');
        }
      }
      checkLabels();
      await tester.enterText(find.byType(TextFormField).at(0), 'Usaha Uji');
      await tester.enterText(find.byType(TextFormField).at(1), '081234567890');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      checkLabels();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profil usaha menjelaskan kontak dan menolak nomor tidak valid', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: BusinessSetupPage()));

    expect(find.text('Nama Usaha/Organisasi'), findsOneWidget);
    expect(find.text('Nomor Telepon Usaha/Organisasi'), findsOneWidget);
    expect(
      find.text('Boleh memakai nomor penanggung jawab sementara.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Koperasi Maju');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    final submit = find.text('Buat Profil & Lanjutkan');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(
      find.text('Gunakan nomor aktif yang diawali 0 atau 62'),
      findsOneWidget,
    );
  });
}
