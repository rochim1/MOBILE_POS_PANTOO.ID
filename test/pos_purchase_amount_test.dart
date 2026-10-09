import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_amount.dart';

void main() {
  test('purchase preview formats finite amounts', () {
    expect(formatPosPurchaseCurrency(3100), '3.100');
    expect(formatPosPurchaseCurrency(0), '0');
  });

  test('purchase preview does not round incomplete numeric values', () {
    expect(formatPosPurchaseCurrency(double.nan), '—');
    expect(formatPosPurchaseCurrency(double.infinity), '—');
    expect(formatPosPurchaseCurrency(double.negativeInfinity), '—');
  });
}
