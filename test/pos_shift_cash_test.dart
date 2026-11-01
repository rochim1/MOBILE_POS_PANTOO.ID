import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_shift_cash.dart';

void main() {
  test('open shift adds opening cash to cash movements', () {
    expect(
      posShiftExpectedCash({
        'status': 'open',
        'opening_cash': 30000,
        'closing_cash_expected': 5500,
      }),
      35500,
    );
  });

  test('closed shift does not count opening cash twice', () {
    expect(
      posShiftExpectedCash({
        'status': 'closed',
        'opening_cash': 30000,
        'closing_cash_expected': 35500,
      }),
      35500,
    );
  });

  test('active shift query includes cash movements and transaction count', () {
    final queries = File(
      'lib/data/graphql/pos_queries.dart',
    ).readAsStringSync();
    final activeShift = queries
        .split('getMyActiveKasirShift = r\'\'\'')
        .last
        .split("''';")
        .first;
    expect(activeShift, contains('closing_cash_expected'));
    expect(activeShift, contains('total_transaksi'));
    expect(activeShift, contains('petty_cash_in'));
    expect(activeShift, contains('petty_cash_out'));
  });
}
