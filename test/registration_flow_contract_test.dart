import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registrasi mobile selalu membawa konteks produk POS dan trial', () {
    final source = File(
      'lib/domain/repositories/auth_repository.dart',
    ).readAsStringSync();
    expect(source, contains("'primary_product': 'pos'"));
    expect(source, contains("'registration_source': 'mobile_pos'"));
    expect(source, contains("'requested_trial': 'pantoo_unlimited'"));
  });

  test('akun baru tanpa tenant diarahkan ke bootstrap workspace', () {
    final repository = File(
      'lib/domain/repositories/auth_repository.dart',
    ).readAsStringSync();
    final onboarding = File(
      'lib/presentation/pages/pos/pos_onboarding_page.dart',
    ).readAsStringSync();
    final app = File('lib/app.dart').readAsStringSync();

    expect(repository, contains("setBool('needs_workspace_setup', true)"));
    expect(
      repository,
      contains('if (instansiId == null || instansiId.isEmpty)'),
    );
    expect(onboarding, contains('const BusinessSetupPage()'));
    expect(app, contains('if (needsWorkspace)'));
    expect(app, contains('context.read<AppLockCubit>().reset()'));
  });

  test('setelah workspace dibuat alur kembali ke PIN lalu onboarding', () {
    final setup = File(
      'lib/presentation/pages/login/business_setup_page.dart',
    ).readAsStringSync();
    expect(setup, contains('createWorkspace'));
    expect(setup, contains('context.read<AppLockCubit>().lock()'));
    expect(setup, contains('const PosOnboardingGate()'));
  });
}
