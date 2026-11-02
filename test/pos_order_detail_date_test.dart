import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'order detail uses the same date formatter as history and documents',
    () {
      final page = File(
        'lib/presentation/pages/pos/pos_order_page.dart',
      ).readAsStringSync();
      expect(page, contains(r'Waktu: ${_formatDate(order.date)}'));
      expect(page, isNot(contains(r'Waktu: ${order.date}')));
      expect(page, contains('PosOrder.parseDateValue(value)'));
    },
  );
}
