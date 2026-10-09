import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';

void main() {
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
