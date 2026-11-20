import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_mobile_navigation_policy.dart';

void main() {
  Map<String, dynamic> fresh(String next) => {
    'initial_setup': {
      'automatic': true,
      'status': 'ready',
      'can_manage': true,
      'first_sale_pending': true,
    },
    'permissions': {
      'use_cashier': true,
      'view_shifts': true,
      'view_products': true,
      'manage_products': true,
      'view_stock': true,
      'initialize_stock': true,
    },
    'operational_readiness': {
      'has_products': next != 'product',
      'has_initial_stock': next == 'shift',
      'context_ready': true,
    },
  };
  test('new owner goes product then opening stock then own shift', () {
    expect(
      mobilePosUnlockDestination(
        fresh('product'),
        hasStore: true,
        hasShift: false,
        offline: false,
      ),
      2,
    );
    expect(
      mobilePosUnlockDestination(
        fresh('stock'),
        hasStore: true,
        hasShift: false,
        offline: false,
      ),
      7,
    );
    expect(
      mobilePosUnlockDestination(
        fresh('shift'),
        hasStore: true,
        hasShift: false,
        offline: false,
      ),
      11,
    );
  });
  test(
    'existing, restricted and offline operators are not forced through first sale',
    () {
      for (final patch in [
        {'automatic': false},
        {'can_manage': false},
        {'first_sale_pending': false},
      ]) {
        final runtime = fresh('product');
        runtime['initial_setup'] = {
          ...runtime['initial_setup'] as Map,
          ...patch,
        };
        expect(
          mobilePosUnlockDestination(
            runtime,
            hasStore: true,
            hasShift: true,
            offline: false,
          ),
          1,
        );
      }
      expect(
        mobilePosUnlockDestination(
          fresh('product'),
          hasStore: true,
          hasShift: false,
          offline: true,
        ),
        4,
      );
    },
  );
}
