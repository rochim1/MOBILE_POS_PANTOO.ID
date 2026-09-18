import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readProjectFile(String path) => File(path).readAsStringSync();

void main() {
  test('service catalog and weighted cart support decimal quantities', () {
    final productPage = readProjectFile(
      'lib/presentation/pages/pos/pos_product_page.dart',
    );
    final state = readProjectFile('lib/presentation/bloc/pos/pos_state.dart');
    final cart = readProjectFile(
      'lib/presentation/pages/pos/widgets/pos_cart_panel.dart',
    );

    expect(productPage, contains("value: 'service'"));
    expect(state, contains('Map<PosProduct, double> cart'));
    expect(cart, contains('numberWithOptions(decimal: true)'));
    expect(cart, contains('quantity - currentQuantity'));
  });

  test(
    'service intake sends priced lines and active orders manage each line',
    () {
      final payment = readProjectFile(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      );
      final query = readProjectFile(
        'lib/data/graphql/pos_table_order_queries.dart',
      );
      final repository = readProjectFile(
        'lib/domain/repositories/pos_order_repository.dart',
      );
      final activeOrders = readProjectFile(
        'lib/presentation/pages/pos/pos_table_order_page.dart',
      );

      expect(payment, contains("'service_lines': serviceLines"));
      expect(payment, contains("'pricing_basis': pricingBasis"));
      expect(query, contains('UpdatePOSServiceLineStatus'));
      expect(repository, contains('updateServiceLineStatus'));
      expect(activeOrders, contains('_serviceLineCard'));
      expect(activeOrders, contains('_serviceLineNext'));
    },
  );
}
