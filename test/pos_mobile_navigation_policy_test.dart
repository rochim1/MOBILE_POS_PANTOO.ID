import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_mobile_navigation_policy.dart';

void main() {
  test('primary bottom navigation dismisses the setup body overlay', () {
    final shell = File(
      'lib/presentation/pages/pos/pos_shell_page.dart',
    ).readAsStringSync();
    final callback = shell.substring(
      shell.indexOf('Widget _buildBottomNavItem'),
    );
    expect(callback, contains('_showSetupGuide = false;'));
  });
  test(
    'unlock never forces a returns/Finance operator into a shift/store page they cannot use',
    () {
      final restricted = {
        'permissions': {
          'use_cashier': true,
          'view_dashboard': true,
          'view_returns': true,
        },
      };
      expect(
        mobilePosUnlockDestination(
          restricted,
          hasStore: true,
          hasShift: false,
          offline: false,
        ),
        0,
      );
      expect(
        mobilePosUnlockDestination(
          {
            'permissions': {'view_receivables': true},
          },
          hasStore: false,
          hasShift: false,
          offline: false,
        ),
        4,
      );
      expect(
        mobilePosUnlockDestination(
          {
            'permissions': {
              'use_cashier': true,
              'view_shifts': true,
              'view_dashboard': true,
            },
          },
          hasStore: true,
          hasShift: false,
          offline: true,
        ),
        0,
      );
      expect(
        mobilePosUnlockDestination(
          {
            'permissions': {'use_cashier': true, 'view_shifts': true},
          },
          hasStore: true,
          hasShift: false,
          offline: false,
        ),
        11,
      );
      expect(
        mobilePosUnlockDestination(
          {
            'permissions': {'use_cashier': true, 'view_shifts': true},
          },
          hasStore: true,
          hasShift: true,
          offline: false,
        ),
        1,
      );
    },
  );
  test('Back dari halaman sekunder kembali ke asal', () {
    expect(mobilePosBackDestination(5, 4), 4); // Lainnya → Pesanan
    expect(mobilePosBackDestination(5, 1), 1); // Kasir → Pesanan
    expect(mobilePosBackDestination(7, 0), 0); // Beranda → Inventori
  });

  test('Back dari tab utama kembali ke beranda lalu keluar', () {
    expect(mobilePosBackDestination(4, 4), 0);
    expect(mobilePosBackDestination(1, 4), 0);
    expect(mobilePosBackDestination(0, 4), isNull);
  });

  test('asal halaman sekunder yang tidak valid jatuh ke Lainnya', () {
    expect(mobilePosBackDestination(18, -1), 4);
    expect(mobilePosBackDestination(18, 9), 4);
  });
}
