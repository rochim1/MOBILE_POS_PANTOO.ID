import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

const product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'Product',
  price: 100,
  stock: 10,
  category: 'QA',
);

class Repo extends Fake implements PosRepository {
  final draftStarted = Completer<void>();
  final draftResult = Completer<void>();
  final started = Completer<void>();
  final result = Completer<Either<Failure, PosTransactionResult>>();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #saveHeldOrder || invocation.memberName == #deleteHeldOrder) {
      draftStarted.complete();
      return draftResult.future;
    }
    if (invocation.memberName == #submitTransaction) {
      started.complete();
      return result.future;
    }
    if (invocation.memberName == #previewPricing) {
      return Future.value(
        const Left<Failure, Map<String, dynamic>>(ServerFailure('QA offline')),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class Checkout extends PosBloc {
  Checkout(Repo repo) : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: {product: 1},
        stores: [
          PosStore(id: 's', name: 'Store', branchId: 'b', status: 'active'),
        ],
      ),
    );
  }
}

void main() {
  for (final restore in [true, false]) {
    test('payment waits for in-flight ${restore ? "restore" : "hold"} instead of racing its cart mutation', () async {
      final repo = Repo();
      final bloc = Checkout(repo);
      bloc.add(restore ? RestoreHeldOrder(HoldOrder(id: 'held', time: DateTime.now(),
        cart: {product: 2}, customer: null, manualDiscountPercent: 0, promoCode: '', discountPolicy: 'stack', orderType: 'take_away',
        store: const PosStore(id: 's', name: 'Store', branchId: 'b', status: 'active'), notes: 'QA'))
        : const HoldCurrentOrder('QA'));
      await repo.draftStarted.future;
      bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 100));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      try { expect(repo.started.isCompleted, false); }
      finally {
        repo.draftResult.complete();
        if (repo.started.isCompleted) repo.result.complete(const Left(ServerFailure('QA denied')));
        await Future<void>.delayed(Duration.zero);
        await bloc.close();
      }
    });
  }
  for (final change in <PosEvent>[
    ClearCart(),
    const AddToCart(product),
    const RemoveCartItem(product),
    const UpdateQuantity(product, 2),
    const UpdateOrderType('delivery'),
    const UpdateDiscount(
      manualDiscountPercent: 10,
      promoCode: '',
      discountPolicy: 'stack',
    ),
  ]) {
    test(
      'checkout freezes ${change.runtimeType} until the response arrives',
      () async {
        final repo = Repo();
        final bloc = Checkout(repo);
        bloc.add(
          const SubmitPayment(paymentMethod: 'tunai', cashReceived: 100),
        );
        await repo.started.future;
        final before = bloc.state;
        bloc.add(change);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.cart, before.cart);
        expect(bloc.state.orderType, before.orderType);
        expect(bloc.state.manualDiscountPercent, before.manualDiscountPercent);
        repo.result.complete(const Left(ServerFailure('QA rejected')));
        await bloc.close();
      },
    );
  }
}
