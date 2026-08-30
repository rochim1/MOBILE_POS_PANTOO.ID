import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';

void main() {
  test('pelanggan menerima id GraphQL _id dan field harga snake_case', () {
    final customer = PosCustomer.fromJson({
      '_id': 'customer-1',
      'name': 'Budi',
      'phone': '08123456789',
      'price_level': 'grosir',
    });

    expect(customer.id, 'customer-1');
    expect(customer.priceLevel, 'grosir');
  });

  test('route pembayaran membawa snapshot pelanggan sampai submit', () {
    final cashier = File(
      'lib/presentation/pages/pos/pos_page.dart',
    ).readAsStringSync();
    final payment = File(
      'lib/presentation/pages/pos/pos_payment_page.dart',
    ).readAsStringSync();
    final bloc = File(
      'lib/presentation/bloc/pos/pos_bloc.dart',
    ).readAsStringSync();

    expect(cashier, contains('initialCustomer:'));
    expect(payment, contains('customerOverride: widget.initialCustomer'));
    expect(bloc, contains('state.selectedCustomer ?? event.customerOverride'));
  });
}
