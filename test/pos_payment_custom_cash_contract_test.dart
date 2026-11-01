import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'custom cash dialog keeps its input alive through dismiss animation',
    () {
      final page = File(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      ).readAsStringSync();
      final dialog = page
          .split('Future<void> _enterCustomCash() async {')
          .last
          .split('Future<void> _configureSplitPayment(')
          .first;
      expect(dialog, contains('onChanged: (value) => cashInput = value'));
      expect(dialog, isNot(contains('controller.dispose()')));
    },
  );
}
