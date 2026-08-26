import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tour kasir memakai target widget nyata dan spotlight interaktif', () {
    final tour = File(
      'lib/presentation/pages/pos/widgets/pos_cashier_tour.dart',
    ).readAsStringSync();
    final cashier = File(
      'lib/presentation/pages/pos/pos_page.dart',
    ).readAsStringSync();
    final productPanel = File(
      'lib/presentation/pages/pos/widgets/pos_product_panel.dart',
    ).readAsStringSync();

    expect(tour, contains('PosCashierTourTargets'));
    expect(tour, contains('_SpotlightPainter'));
    expect(tour, contains('Ketuk area yang disorot untuk melanjutkan'));
    expect(cashier, contains('tourTargets?.salesContext'));
    expect(cashier, contains('tourTargets?.saveOrder'));
    expect(cashier, contains('tourTargets?.payment'));
    expect(productPanel, contains('searchTourKey'));
  });
}
