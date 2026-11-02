import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';

void main() {
  test('pelanggan menerima seluruh field POS GraphQL snake_case', () {
    final customer = PosCustomer.fromJson({
      '_id': 'customer-1',
      'name': 'Budi',
      'phone': '08123456789',
      'price_level': 'grosir',
      'address': 'Jl. Pantoo No. 1',
      'catatan': 'Pelanggan prioritas',
      'membership_status': 'member',
      'membership_tier': 'gold',
      'customer_type': 'reseller',
    });

    expect(customer.id, 'customer-1');
    expect(customer.priceLevel, 'grosir');
    expect(customer.address, 'Jl. Pantoo No. 1');
    expect(customer.note, 'Pelanggan prioritas');
    expect(customer.membershipStatus, 'member');
    expect(customer.membershipTier, 'gold');
    expect(customer.customerType, 'reseller');
  });

  test('mutation pelanggan membawa alamat dan catatan', () {
    final queries = File(
      'lib/data/graphql/pos_queries.dart',
    ).readAsStringSync();
    expect(queries, contains('address catatan price_level'));
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
    expect(
      payment,
      matches(
        RegExp(
          r'customerOverride:\s*_paymentCustomer\s*\?\?\s*widget.initialCustomer',
        ),
      ),
    );
    expect(bloc, contains('stateCustomer.id.trim().isNotEmpty'));
    expect(bloc, contains(': event.customerOverride'));
  });

  test(
    'new order uses the customer just selected, not an older bloc snapshot',
    () {
      final payment = File(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      ).readAsStringSync();
      final start = payment.indexOf('Future<void> _createInvoice(');
      final end = payment.indexOf('Future<void> _enterCustomCash', start);
      final create = payment.substring(start, end);
      expect(
        create,
        matches(
          RegExp(
            r'final checkoutCustomer\s*=\s*_paymentCustomer\s*\?\?\s*state.selectedCustomer\s*\?\?\s*widget.initialCustomer',
          ),
        ),
      );
      expect(create, contains('customerId: checkoutCustomer?.id'));
      expect(create, contains('customerName: checkoutCustomer?.name'));
    },
  );

  test('memilih pelanggan membersihkan kegagalan pembayaran sebelumnya', () {
    final bloc = File(
      'lib/presentation/bloc/pos/pos_bloc.dart',
    ).readAsStringSync();

    final handlerStart = bloc.indexOf('void _onSelectCustomer');
    final handlerEnd = bloc.indexOf('void _onUpdateSalesContext', handlerStart);
    final handler = bloc.substring(handlerStart, handlerEnd);

    expect(handler, contains('status: PosStatus.success'));
    expect(handler, contains("errorMessage: ''"));
  });
}
