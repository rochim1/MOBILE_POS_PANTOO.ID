import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_discount_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_info_panel.dart';
import 'pos_promo_apply_test.dart' show PromoRepo, product, tick;

const store = PosStore(id: 's', name: 'QA', branchId: 'b', status: 'active');

class PolicyRepo extends PromoRepo {
  final previewInputs = <Map<Symbol, dynamic>>[];
  @override
  Future<void> deleteHeldOrder(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #previewPricing) {
      previewInputs.add(invocation.namedArguments);
    }
    return super.noSuchMethod(invocation);
  }
}

class PolicyBloc extends PosBloc {
  PolicyBloc(
    PolicyRepo repo, {
    String policy = 'promo_only',
    bool manager = true,
    bool empty = false,
  }) : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: empty ? {} : {product: 1},
        stores: const [store],
        runtimeConfig: {
          'default_discount_policy': policy,
          'permissions': {'manage_settings': manager},
        },
      ),
    );
  }
}

void main() {
  test(
    'configured promo-only ignores stale manual value and stale manual quote',
    () {
      final state = PosState(
        cart: {product: 1},
        manualDiscountPercent: 20,
        discountPolicy: 'stack',
        runtimeConfig: const {'default_discount_policy': 'promo_only'},
        pricingPreview: const {
          'subtotal': 10000,
          'total_after_discount': 8000,
          'discount_policy': 'stack',
        },
      );
      expect(state.manualDiscount, 0);
      expect(state.grandTotal, 10000);
    },
  );
  test(
    'manager cannot inject manual discount or change configured promo-only via event',
    () async {
      final repo = PolicyRepo();
      final subject = PolicyBloc(repo);
      addTearDown(subject.close);
      subject.add(
        const UpdateDiscount(
          manualDiscountPercent: 25,
          promoCode: ' hemat ',
          discountPolicy: 'stack',
        ),
      );
      await tick();
      expect(subject.state.manualDiscountPercent, 0);
      expect(subject.state.discountPolicy, 'promo_only');
      expect(repo.previewInputs.single[#manualDiscount], 0);
      expect(repo.previewInputs.single[#discountPolicy], 'promo_only');
      repo.requests.single.complete(
        const Right({
          'subtotal': 10000,
          'discount_policy': 'promo_only',
          'total_after_discount': 9000,
          'promo_applied': true,
          'promo_discount': 1000,
        }),
      );
      await tick();
      expect(subject.state.grandTotal, 9000);
    },
  );
  test(
    'cashier cannot inject manual percentage when lacking authorization',
    () async {
      final repo = PolicyRepo();
      final subject = PolicyBloc(repo, policy: 'stack', manager: false);
      addTearDown(subject.close);
      subject.add(
        const UpdateDiscount(
          manualDiscountPercent: 30,
          promoCode: '',
          discountPolicy: 'stack',
        ),
      );
      await tick();
      expect(subject.state.manualDiscountPercent, 0);
      repo.requests.single.complete(
        const Right({'subtotal': 10000, 'total_after_discount': 10000}),
      );
      await tick();
    },
  );
  test(
    'restored held order follows current policy instead of its old manual discount',
    () async {
      final repo = PolicyRepo();
      final bloc = PolicyBloc(repo, empty: true);
      addTearDown(bloc.close);
      bloc.add(
        RestoreHeldOrder(
          HoldOrder(
            id: 'hold',
            time: DateTime(2026, 11, 26),
            cart: {product: 1},
            customer: null,
            store: store,
            notes: '',
            manualDiscountPercent: 20,
            promoCode: '',
            discountPolicy: 'stack',
            orderType: 'take_away',
          ),
        ),
      );
      await tick();
      expect(bloc.state.discountPolicy, 'promo_only');
      expect(bloc.state.manualDiscountPercent, 0);
      expect(repo.previewInputs.single[#manualDiscount], 0);
      repo.requests.single.complete(
        const Right({
          'subtotal': 10000,
          'discount_policy': 'promo_only',
          'total_after_discount': 10000,
        }),
      );
      await tick();
    },
  );
  for (final panel in [false, true]) {
    testWidgets(
      'promo-only manager sees promo but no manual field (${panel ? 'inline' : 'dialog'})',
      (tester) async {
        final bloc = PolicyBloc(PolicyRepo());
        addTearDown(bloc.close);
        await tester.pumpWidget(
          BlocProvider<PosBloc>.value(
            value: bloc,
            child: MaterialApp(
              home: Scaffold(
                body: panel
                    ? const PosInfoPanel(isMobile: false)
                    : const PosDiscountDialog(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Diskon manual (%)'), findsNothing);
        expect(find.text('Diskon manual (otorisasi)'), findsNothing);
        expect(find.widgetWithText(TextField, 'Kode promo'), findsOneWidget);
      },
    );
  }
  testWidgets(
    'manual-only hides promo entry but keeps authorized manual field',
    (tester) async {
      final bloc = PolicyBloc(PolicyRepo(), policy: 'manual_only');
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: bloc,
          child: const MaterialApp(home: Scaffold(body: PosDiscountDialog())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kode promo'), findsNothing);
      expect(find.text('Diskon manual (%)'), findsOneWidget);
    },
  );
}
