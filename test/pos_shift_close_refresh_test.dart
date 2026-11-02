import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'closing a shift refreshes the parent cashier state just like opening',
    () {
      final page = File(
        'lib/presentation/pages/pos/pos_shift_page.dart',
      ).readAsStringSync();
      final shell = File(
        'lib/presentation/pages/pos/pos_shell_page.dart',
      ).readAsStringSync();
      expect(page, contains('onShiftClosed?.call()'));
      expect(page, contains("contains('ditutup')"));
      expect(
        shell,
        matches(
          RegExp(
            r'onShiftClosed:\s*\(\)\s*=>\s*_posBloc\.add\(LoadPosData\(\)\)',
          ),
        ),
      );
    },
  );
}
