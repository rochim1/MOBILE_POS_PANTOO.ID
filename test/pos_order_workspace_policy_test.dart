import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_order_workspace_policy.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_more_menu_page.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';

class _RuntimeRepository extends Fake implements PosRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'has_open_orders': true,
    'default_order_type': 'take_away',
    'default_price_level': 'retail',
    'default_sales_channel': 'retail',
  };
}

class _CheckoutBloc extends PosBloc {
  _CheckoutBloc() : super(posRepository: _RuntimeRepository()) {
    emit(
      state.copyWith(
        orderType: 'delivery',
        salesChannel: 'whatsapp',
        priceLevel: 'member',
        taxPercent: 11,
        selectedTableId: 'table-qa',
        cart: {
          const PosProduct(
            id: 'qa',
            code: 'qa',
            name: 'QA',
            category: '',
            price: 100,
            stock: 10,
          ): 2,
        },
      ),
    );
  }
}

void main() {
  test('settings accept every catalog feature, including optional queue', () {
    expect(
      PosSettings.featureFlagKeys,
      containsAll(posProfileFeatures('retail').keys),
    );
    expect(
      PosSettings.fromJson({
        'enabled_features': {'use_order_queue': true},
      }).enabledFeatures['use_order_queue'],
      isTrue,
    );
  });
  test('menu refresh never changes an in-progress checkout', () async {
    final bloc = _CheckoutBloc();
    addTearDown(bloc.close);
    final before = bloc.state;
    final updated = bloc.stream.firstWhere(
      (state) => state.runtimeConfig['has_open_orders'] == true,
    );
    bloc.add(const RefreshPosRuntimeConfig(preserveCheckout: true));
    final after = await updated;
    expect(after.cart, before.cart);
    expect(after.orderType, 'delivery');
    expect(after.salesChannel, 'whatsapp');
    expect(after.priceLevel, 'member');
    expect(after.taxPercent, 11);
    expect(after.selectedTableId, 'table-qa');
  });
  test(
    'retail compact, capability opt-in and legacy recovery do not override permission',
    () {
      const config = {
        'business_profile': 'retail',
        'features': <String, bool>{},
        'permissions': {'view_tables': true},
      };
      expect(PosOrderWorkspacePolicy(config).visible, isFalse);
      expect(
        PosMoreMenuPage.visibleSections(config)['Operasional'],
        isNot(contains(5)),
      );
      expect(
        PosMoreMenuPage.visibleSections({
          ...config,
          'has_open_orders': true,
        })['Operasional'],
        contains(5),
      );
      expect(
        PosMoreMenuPage.visibleSections({
          ...config,
          'has_open_orders': true,
          'permissions': <String, bool>{},
        })['Operasional'],
        isNot(contains(5)),
      );
      for (final key in [
        'use_order_queue',
        'use_delivery',
        'use_appointments',
        'use_service_order',
        'use_kitchen_flow',
        'use_tables',
      ]) {
        expect(
          PosOrderWorkspacePolicy({
            ...config,
            'features': {key: true},
          }).visible,
          isTrue,
        );
      }
    },
  );
  test('service and restaurant workspaces retain appropriate labels', () {
    for (final profile in ['laundry', 'bengkel', 'salon', 'jasa']) {
      final policy = PosOrderWorkspacePolicy({'business_profile': profile});
      expect(policy.visible, isTrue);
      expect(policy.stageLabel('Diproses'), 'Dikerjakan');
      expect(
        policy.actionLabel('Siap', const PosOrderDetail(serviceOrder: {})),
        'Kelola layanan',
      );
    }
    const restaurant = PosOrderWorkspacePolicy({
      'business_profile': 'restoran',
      'features': {'use_tables': true, 'use_kitchen_flow': true},
    });
    expect(restaurant.title, 'Pesanan & Meja');
    expect(restaurant.stageLabel('Siap'), 'Siap Disajikan');
    for (final profile in ['restoran', 'custom']) {
      final bookingPolicy = PosOrderWorkspacePolicy({
        'business_profile': profile,
        'features': {
          'use_tables': true,
          'use_kitchen_flow': true,
          'use_service_order': true,
        },
      });
      const booking = PosOrderDetail(
        orderType: 'reservation',
        serviceOrder: {'service_subject': 'Table booking'},
      );
      expect(bookingPolicy.isServiceOrder(booking), isFalse);
      expect(bookingPolicy.stageLabel('Siap', booking), 'Siap Disajikan');
    }
    expect(
      restaurant.isServiceOrder(
        const PosOrderDetail(
          serviceOrder: {'service_subject': 'Table booking'},
        ),
      ),
      isFalse,
    );
  });
  test('retail pickup and delivery never use restaurant terminology', () {
    const policy = PosOrderWorkspacePolicy({'business_profile': 'retail'});
    expect(policy.stageLabel('Diproses'), 'Disiapkan');
    expect(
      policy.stageLabel('Siap', const PosOrderDetail(orderType: 'delivery')),
      'Siap Dikirim',
    );
    expect(
      policy.stageLabel('Siap', const PosOrderDetail(orderType: 'take_away')),
      'Siap Diambil',
    );
    expect(
      policy.actionLabel(
        'Selesai',
        const PosOrderDetail(orderType: 'delivery'),
      ),
      'Konfirmasi diterima pelanggan',
    );
  });
}
