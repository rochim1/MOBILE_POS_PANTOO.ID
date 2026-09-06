import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('login dan daftar membuka dokumen legal publik Pantoo', () {
    final links = File(
      'lib/presentation/widgets/login/legal_links.dart',
    ).readAsStringSync();
    final login = File(
      'lib/presentation/widgets/login/login_form.dart',
    ).readAsStringSync();
    expect(links, contains('https://app.pantoo.id/kebijakan-privasi'));
    expect(links, contains('https://app.pantoo.id/ketentuan-layanan'));
    expect(login, contains('PantooLegalLinks'));
  });

  test('pendaftaran mewajibkan dan mengirim persetujuan legal', () {
    final page = File(
      'lib/presentation/pages/login/register_page.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/domain/repositories/auth_repository.dart',
    ).readAsStringSync();
    expect(page, contains('_acceptedLegal'));
    expect(page, contains('CheckboxListTile'));
    expect(repository, contains("'legal_consent': true"));
    expect(repository, contains("'privacy_policy_version'"));
    expect(repository, contains("'terms_of_service_version'"));
  });
}
