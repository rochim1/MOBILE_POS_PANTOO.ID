import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_navbar_action_policy.dart';

void main() {
  Map<String, dynamic> runtime({
    bool lock = true,
    Map<String, bool>? permissions,
    bool queue = false,
    bool stock = true,
  }) => {
    'pos_lock_enabled': lock,
    'features': {'track_stock': stock, 'use_order_queue': queue},
    'permissions':
        permissions ??
        {
          'use_cashier': true,
          'view_products': true,
          'view_transactions': true,
          'view_stock': true,
          'view_tables': true,
        },
  };

  for (var page = 0; page < 20; page++) {
    test(
      'page $page only gets cashier-specific actions when it is cashier',
      () {
        final p = PosNavbarActionPolicy(runtime(), page: page);
        expect(p.keyboardHelp, page == 1);
        expect(p.customerDisplay, page == 1);
        expect(p.setupGuide, false);
        expect(p.notifications, true);
        expect(p.lock, true);
      },
    );
  }
  test('layout toggle follows the page and its permission', () {
    for (final page in [1, 2, 3, 5, 6, 7]) {
      expect(PosNavbarActionPolicy(runtime(), page: page).layoutToggle, true);
      expect(
        PosNavbarActionPolicy(
          runtime(permissions: {}),
          page: page,
        ).layoutToggle,
        false,
      );
    }
    for (final page in [0, 4, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]) {
      expect(PosNavbarActionPolicy(runtime(), page: page).layoutToggle, false);
    }
  });
  test(
    'inventory layout is only relevant to stock, not PO/warehouse/transfer/opname',
    () {
      for (final section in [
        null,
        'purchase',
        'warehouse',
        'opname',
        'transfer',
        'scrap',
        'purchaseReturn',
      ]) {
        expect(
          PosNavbarActionPolicy(
            runtime(),
            page: 7,
            inventorySection: section,
          ).layoutToggle,
          false,
        );
      }
      expect(
        PosNavbarActionPolicy(
          runtime(),
          page: 7,
          inventorySection: 'stock',
        ).layoutToggle,
        true,
      );
      expect(
        PosNavbarActionPolicy(runtime(stock: false), page: 7).layoutToggle,
        false,
      );
    },
  );
  test(
    'guide overlay hides underlying page actions and exposes its close action',
    () {
      final p = PosNavbarActionPolicy(runtime(), page: 1, showSetupGuide: true);
      expect(p.setupGuide, true);
      expect(p.customerDisplay, false);
      expect(p.keyboardHelp, false);
      expect(p.layoutToggle, false);
      expect(p.orderDestination, isNull);
    },
  );
  test('disabled PIN lock leaves no empty overflow on non-cashier pages', () {
    final p = PosNavbarActionPolicy(runtime(lock: false), page: 17);
    expect(p.lock, false);
    expect(p.hasOverflow, false);
    expect(p.notifications, true);
  });
  test('locked app exposes no interactive navbar actions', () {
    final p = PosNavbarActionPolicy(
      runtime(),
      page: 1,
      locked: true,
      showSetupGuide: true,
    );
    expect([
      p.keyboardHelp,
      p.customerDisplay,
      p.setupGuide,
      p.notifications,
      p.lock,
      p.layoutToggle,
      p.hasOverflow,
    ], everyElement(false));
    expect(p.orderDestination, isNull);
  });
  test('subscription/restricted body never keeps cashier controls visible', () {
    final p = PosNavbarActionPolicy(runtime(), page: 1, pageBodyEnabled: false);
    expect(p.keyboardHelp, false);
    expect(p.customerDisplay, false);
    expect(p.layoutToggle, false);
    expect(p.orderDestination, isNull);
    expect(p.lock, true);
  });
  test(
    'orders shortcut honors profile and permissions, with safe history fallback',
    () {
      expect(PosNavbarActionPolicy(runtime(), page: 1).orderDestination, 3);
      expect(
        PosNavbarActionPolicy(runtime(queue: true), page: 1).orderDestination,
        5,
      );
      expect(
        PosNavbarActionPolicy(
          runtime(permissions: {'use_cashier': true}),
          page: 1,
        ).orderDestination,
        isNull,
      );
      expect(
        PosNavbarActionPolicy(
          runtime(permissions: {'view_transactions': true}),
          page: 1,
        ).orderDestination,
        isNull,
      );
    },
  );
}
