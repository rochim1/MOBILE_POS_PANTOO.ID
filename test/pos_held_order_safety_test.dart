import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

const product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'Produk QA',
  price: 100,
  stock: 20,
  category: 'QA',
);
const store = PosStore(
  id: 'store',
  name: 'Toko QA',
  branchId: 'branch',
  status: 'active',
);
const customer = PosCustomer(
  id: 'customer',
  name: 'Pelanggan QA',
  phone: '08000',
  priceLevel: 'retail',
);

HoldOrder held({PosCustomer? owner, PosStore location = store}) => HoldOrder(
  id: 'held',
  time: DateTime(2026, 11, 25),
  cart: {product: 2},
  customer: owner,
  store: location,
  notes: 'QA',
  manualDiscountPercent: 0,
  promoCode: '',
  discountPolicy: 'stack',
  orderType: 'take_away',
);

class HeldRepo extends Fake implements PosRepository {
  HoldOrder? saved;
  int deletes = 0;
  bool rejectDelete = false;
  bool rejectSave = false;
  final started = Completer<void>();
  Completer<void>? pending;
  @override
  Future<void> saveHeldOrder({
    required HoldOrder order,
    required String shiftId,
  }) async {
    saved = order;
    if (!started.isCompleted) started.complete();
    if (rejectSave) throw StateError('disk unavailable');
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> deleteHeldOrder(String id) async {
    deletes++;
    if (rejectDelete) throw StateError('disk unavailable');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #previewPricing) {
      return Future.value(
        const Left<Failure, Map<String, dynamic>>(NetworkFailure('offline')),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class HeldBloc extends PosBloc {
  HeldBloc(
    HeldRepo repo, {
    bool cart = true,
    PosCustomer? owner = customer,
    List<HoldOrder> drafts = const [],
  }) : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: cart ? {product: 1} : {},
        selectedCustomer: owner,
        taxPercent: 11,
        stores: const [store],
        heldOrders: drafts,
        runtimeConfig: const {
          'features': {'track_stock': true},
        },
      ),
    );
  }
  final errors = <Object>[];
  @override
  void onError(Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(error, stackTrace);
  }
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  test(
    'hold acknowledges only after persistence and preserves agreed tax in the saved payload',
    () async {
      final repo = HeldRepo()..pending = Completer<void>();
      final bloc = HeldBloc(repo);
      addTearDown(bloc.close);
      final completion = Completer<bool>();
      bloc.add(HoldCurrentOrder('QA', completion: completion));
      await repo.started.future;
      expect(completion.isCompleted, isFalse);
      repo.pending!.complete();
      expect(await completion.future, isTrue);
      expect(repo.saved?.toJson()['taxPercent'], 11);
    },
  );
  test(
    'failed persistence reports failure without clearing customer or cart and permits retry',
    () async {
      final repo = HeldRepo()..rejectSave = true;
      final bloc = HeldBloc(repo);
      addTearDown(bloc.close);
      final failed = Completer<bool>();
      bloc.add(HoldCurrentOrder('QA', completion: failed));
      expect(await failed.future, isFalse);
      expect(bloc.state.cart[product], 1);
      expect(bloc.state.selectedCustomer?.id, customer.id);
      repo.rejectSave = false;
      final retry = Completer<bool>();
      bloc.add(HoldCurrentOrder('QA retry', completion: retry));
      expect(await retry.future, isTrue);
    },
  );
  test(
    'restore preserves the serialized tax rate instead of a different cart rate',
    () async {
      final draft = HoldOrder.fromJson({...held().toJson(), 'taxPercent': 7});
      final bloc = HeldBloc(HeldRepo(), cart: false, drafts: [draft]);
      addTearDown(bloc.close);
      bloc.add(RestoreHeldOrder(draft));
      await settle();
      expect(bloc.state.taxPercent, 7);
      expect(draft.toJson()['taxPercent'], 7);
    },
  );
  test(
    'holding an order preserves its customer in storage and clears the next cart customer',
    () async {
      final repo = HeldRepo();
      final bloc = HeldBloc(repo);
      addTearDown(bloc.close);
      bloc.add(const HoldCurrentOrder('QA'));
      await settle();
      expect(repo.saved?.customer?.id, customer.id);
      expect(bloc.state.cart, isEmpty);
      expect(bloc.state.selectedCustomer, isNull);
    },
  );

  test(
    'restoring a general-customer draft clears the previous selected customer',
    () async {
      final draft = held();
      final bloc = HeldBloc(HeldRepo(), cart: false, drafts: [draft]);
      addTearDown(bloc.close);
      bloc.add(RestoreHeldOrder(draft));
      await settle();
      expect(bloc.state.cart[product], 2);
      expect(bloc.state.selectedCustomer, isNull);
    },
  );

  test(
    'restoring does not erase a nonempty current cart or delete its saved draft',
    () async {
      final repo = HeldRepo();
      final draft = held();
      final bloc = HeldBloc(repo, drafts: [draft]);
      addTearDown(bloc.close);
      bloc.add(RestoreHeldOrder(draft));
      await settle();
      expect(repo.deletes, 0);
      expect(bloc.state.cart[product], 1);
      expect(bloc.state.heldOrders, [draft]);
      expect(bloc.state.status, PosStatus.failure);
    },
  );

  test(
    'restore failure keeps draft available, produces a recoverable state and does not escape',
    () async {
      final repo = HeldRepo()..rejectDelete = true;
      final draft = held();
      final bloc = HeldBloc(repo, cart: false, drafts: [draft]);
      addTearDown(bloc.close);
      bloc.add(RestoreHeldOrder(draft));
      await settle();
      expect(bloc.errors, isEmpty);
      expect(bloc.state.status, PosStatus.failure);
      expect(bloc.state.heldOrders, [draft]);
      expect(bloc.state.cart, isEmpty);
    },
  );

  test('restore cannot move a saved cart to a different store', () async {
    final repo = HeldRepo();
    final draft = held(
      location: const PosStore(
        id: 'other',
        name: 'Other',
        branchId: 'other-branch',
        status: 'active',
      ),
    );
    final bloc = HeldBloc(repo, cart: false, drafts: [draft]);
    addTearDown(bloc.close);
    bloc.add(RestoreHeldOrder(draft));
    await settle();
    expect(repo.deletes, 0);
    expect(bloc.state.cart, isEmpty);
    expect(bloc.state.heldOrders, [draft]);
    expect(bloc.state.status, PosStatus.failure);
  });

  for (final change in <PosEvent>[
    ClearCart(),
    const AddToCart(product),
    const RemoveCartItem(product),
    const UpdateQuantity(product, 5),
    const SelectCustomer(null),
    const UpdateDiscount(
      manualDiscountPercent: 10,
      promoCode: '',
      discountPolicy: 'stack',
    ),
  ]) {
    test(
      'hold freezes ${change.runtimeType} until local persistence is confirmed',
      () async {
        final repo = HeldRepo()..pending = Completer<void>();
        final bloc = HeldBloc(repo);
        addTearDown(bloc.close);
        bloc.add(const HoldCurrentOrder('QA'));
        await repo.started.future;
        final before = bloc.state;
        bloc.add(change);
        await settle();
        try {
          expect(bloc.state.cart, before.cart);
          expect(bloc.state.selectedCustomer, before.selectedCustomer);
          expect(
            bloc.state.manualDiscountPercent,
            before.manualDiscountPercent,
          );
        } finally {
          repo.pending!.complete();
          await settle();
        }
      },
    );
  }
}
