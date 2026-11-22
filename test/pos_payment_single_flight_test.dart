import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

class _Repository extends Fake implements PosRepository {
  int submissions = 0;
  var pending = Completer<Either<Failure, PosTransactionResult>>();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #submitTransaction) {
      submissions++;
      return pending.future;
    }
    return super.noSuchMethod(invocation);
  }
}

class _Bloc extends PosBloc {
  _Bloc(_Repository repository) : super(posRepository: repository) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: {
          PosProduct(
            id: 'p',
            code: 'P',
            name: 'Product',
            price: 100,
            stock: 10,
            category: 'QA',
          ): 1,
        },
        stores: [
          PosStore(id: 's', name: 'Store', branchId: 'b', status: 'active'),
        ],
      ),
    );
  }
}

void main() {
  test(
    'rapid duplicate payment events only submit one financial transaction',
    () async {
      final repository = _Repository();
      final bloc = _Bloc(repository);
      const event = SubmitPayment(paymentMethod: 'tunai', cashReceived: 100);
      bloc.add(event);
      bloc.add(event);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      try {
        expect(repository.submissions, 1);
      } finally {
        repository.pending.complete(
          const Right(
            PosTransactionResult(
              id: 'tx',
              invoice: 'QA',
              subtotal: 100,
              discount: 0,
              promoDiscount: 0,
              tax: 0,
              total: 100,
              cashReceived: 100,
              change: 0,
              paymentMethod: 'tunai',
            ),
          ),
        );
        await bloc.close();
      }
      expect(bloc.state.status, PosStatus.paymentSuccess);
      expect(bloc.state.cart, isEmpty);
    },
  );
  test(
    'failed payment releases the single-flight guard and retains the cart',
    () async {
      final repository = _Repository();
      final bloc = _Bloc(repository);
      const event = SubmitPayment(paymentMethod: 'tunai', cashReceived: 100);
      final failed = bloc.stream.firstWhere(
        (state) => state.status == PosStatus.failure,
      );
      bloc.add(event);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      repository.pending.complete(const Left(ServerFailure('QA rejected')));
      await failed;
      expect(bloc.state.cart, isNotEmpty);
      repository.pending = Completer();
      bloc.add(event);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      try {
        expect(repository.submissions, 2);
      } finally {
        repository.pending.complete(
          const Right(
            PosTransactionResult(
              id: 'tx',
              invoice: 'QA',
              subtotal: 100,
              discount: 0,
              promoDiscount: 0,
              tax: 0,
              total: 100,
              cashReceived: 100,
              change: 0,
              paymentMethod: 'tunai',
            ),
          ),
        );
        await bloc.close();
      }
      expect(bloc.state.status, PosStatus.paymentSuccess);
    },
  );
}
