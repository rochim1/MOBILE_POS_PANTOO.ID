import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_service_quantity.dart';

void main() {
  test(
    'non-laundry service never inherits kiloan pricing from hidden fields',
    () {
      for (final profile in ['bengkel', 'salon', 'jasa', 'custom']) {
        for (final mode in ['kiloan', 'satuan', 'paket']) {
          expect(posServicePricingBasis(profile, mode), 'per_item');
        }
      }
      expect(posServicePricingBasis('laundry', 'kiloan'), 'per_kg');
      expect(posServicePricingBasis('laundry', 'satuan'), 'per_item');
      expect(posServicePricingBasis('laundry', 'paket'), 'package');
    },
  );
  test(
    'intake uses profile pricing and queries return the recorded operational context',
    () {
      final payment = File(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      ).readAsStringSync();
      expect(payment, contains('posServicePricingBasis(profile, mode)'));
      final queries = File(
        'lib/data/graphql/pos_table_order_queries.dart',
      ).readAsStringSync();
      expect(
        RegExp(
          'vehicle_no vehicle_model technician_id technician_name appointment_at complaint diagnosis',
        ).allMatches(queries).length,
        2,
      );
      final page = File(
        'lib/presentation/pages/pos/pos_table_order_page.dart',
      ).readAsStringSync();
      expect(page, contains("Teknisi / staf: \${service['technician_name']}"));
    },
  );
}
