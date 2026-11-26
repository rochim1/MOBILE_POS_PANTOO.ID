import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

final first = PosProduct(id: 'a', code: 'A', name: 'Paid item', price: 100, stock: 10, category: 'QA');
final second = PosProduct(id: 'b', code: 'B', name: 'Next cart item', price: 200, stock: 10, category: 'QA');

class Repo extends Fake implements PosRepository {
  final submitted = Completer<void>();
  final pending = Completer<Either<Failure, PosTransactionResult>>();
  Map<PosProduct, double>? sentCart;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #submitTransaction) {
      sentCart = Map.of(invocation.namedArguments[#cart] as Map<PosProduct, double>);
      submitted.complete();
      return pending.future;
    }
    if (invocation.memberName == #previewPricing) {
      return Future.value(const Left<Failure, Map<String, dynamic>>(ServerFailure('QA no pricing server')));
    }
    return super.noSuchMethod(invocation);
  }
}

class Provider extends Fake implements GraphQLClientProvider {
  Provider(this.client);
  @override
  final GraphQLClient client;
}

class Checkout extends PosBloc {
  Checkout(Repo repo) : super(posRepository: repo) {
    emit(PosState(status: PosStatus.success, cart: {first: 1},
      stores: [PosStore(id: 's', name: 'Store', branchId: 'b', status: 'active')]));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('AUDIT: retry after lost non-cash response currently changes transaction ID', () async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => ['wifi']);
    final ids = <String>[];
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
      final input = request.variables['input'] as Map;
      ids.add(input['client_transaction_id'] as String);
      throw ServerException(originalException: Exception('QA response lost after server commit'));
    }));
    final repo = PosRepository(Provider(client), await SharedPreferences.getInstance());
    for (var i = 0; i < 2; i++) {
      final result = await repo.submitTransaction(cart: {first: 1}, total: 100,
        paymentMethod: 'transfer', tokoId: 's', shiftId: 'shift', cashReceived: 0);
      expect(result.isLeft(), true);
    }
    expect(ids.length, 2);
    expect(ids.toSet().length, 2,
      reason: 'BUG reproduced: retry is a new financial request, not an idempotent replay');
  });
  test('AUDIT: success of old payment currently erases a replacement cart', () async {
    final repo = Repo();
    final bloc = Checkout(repo);
    bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 100));
    await repo.submitted.future;
    final cleared = bloc.stream.firstWhere((s) => s.cart.isEmpty);
    bloc.add(ClearCart());
    await cleared;
    final changed = bloc.stream.firstWhere((s) => s.cart.containsKey(second));
    bloc.add(AddToCart(second));
    await changed;
    expect(repo.sentCart, {first: 1}, reason: 'Only old cart was submitted');
    expect(bloc.state.cart, {second: 1}, reason: 'A new cart was accepted while payment was pending');
    final succeeded = bloc.stream.firstWhere((s) => s.status == PosStatus.paymentSuccess);
    repo.pending.complete(const Right(PosTransactionResult(id: 'tx', invoice: 'QA',
      subtotal: 100, discount: 0, promoDiscount: 0, tax: 0, total: 100,
      cashReceived: 100, change: 0, paymentMethod: 'tunai')));
    await succeeded;
    expect(bloc.state.cart, isEmpty,
      reason: 'BUG reproduced: unpaid replacement cart is silently erased');
    await bloc.close();
  });
}
