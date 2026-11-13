import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'payment state uses stable business keys, translating only presentation',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      ).readAsStringSync();
      final mapping = source
          .split('String _paymentMethodLabel')
          .last
          .split('@override')
          .first;
      expect(
        mapping,
        isNot(contains('.trCurrent()')),
        reason:
            'English Cash must not replace the Tunai key used by validation and submission',
      );
      expect(source, contains("_buildPaymentMethodTile('Tunai')"));
      for (final key in [
        'Tunai',
        'Kartu Debit',
        'Transfer',
        'QRIS',
        'E-Wallet',
        'Kartu Kredit',
        'Tempo / Piutang',
      ]) {
        expect(
          source,
          matches(
            RegExp(
              "_buildPaymentMethodTile\\(\\s*'${RegExp.escape(key)}'\\s*,?\\s*\\)",
            ),
          ),
        );
      }
      final tile = source
          .split('Widget _buildPaymentMethodTile')
          .last
          .split('Widget _buildCashOption')
          .first;
      expect(tile, contains('method.tr(context)'));
      expect(tile, contains('_paymentMethod = method'));
    },
  );
}
