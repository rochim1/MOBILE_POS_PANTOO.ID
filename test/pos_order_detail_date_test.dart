import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('order detail uses the same date formatter as history and documents', () {
    final page = File(
      'lib/presentation/pages/pos/pos_order_page.dart',
    ).readAsStringSync();
    expect(
      page.replaceAll(RegExp(r'\s+'), ''),
      contains(
        'posLocale(context,).posee16580f1d1c((_formatDate(order.date)).toString())',
      ),
    );
    expect(page, isNot(contains(r'Waktu: ${order.date}')));
    expect(page, contains('PosOrder.parseDateValue(value)'));
  });
}
