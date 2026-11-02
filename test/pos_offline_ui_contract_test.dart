import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'payment connection badge observes connectivity rather than promising Online',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      ).readAsStringSync();
      expect(source, contains('PosPaymentConnectionBadge('));
      expect(source, isNot(contains("'Online'")));
    },
  );
  test('active/history shift timestamps use the same local-time parser', () {
    for (final file in [
      'pos_active_shift_tab.dart',
      'pos_shift_history_tab.dart',
    ]) {
      final source = File(
        'lib/presentation/pages/pos/widgets/$file',
      ).readAsStringSync();
      expect(source, contains("posShiftLocalTime(shift['opened_at']"));
      expect(source, isNot(contains("DateTime.tryParse(shift['opened_at']")));
    }
  });
}
