import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_info_panel.dart';

const product = PosProduct(
  id: 'p', code: 'P', name: 'Produk', price: 10000, stock: 10, category: 'QA',
);
const quote = <String, dynamic>{
  'subtotal': 10000, 'promo_code': 'HEMAT', 'promo_applied': true,
  'promo_discount': 1000, 'total_after_discount': 9000,
  'promo_message': 'Kode promo valid',
};

class PromoRepo extends Fake implements PosRepository {
  final requests = <Completer<Either<Failure, Map<String, dynamic>>>>[];
  final codes = <String>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #previewPricing) {
      codes.add(invocation.namedArguments[#promoCode] as String);
      final request = Completer<Either<Failure, Map<String, dynamic>>>();
      requests.add(request);
      return request.future;
    }
    return super.noSuchMethod(invocation);
  }
}

class PromoBloc extends PosBloc {
  PromoBloc(PromoRepo repo, {bool previous = false, bool store = true})
    : super(posRepository: repo) {
    emit(PosState(
      status: PosStatus.success, cart: {product: 1},
      stores: store ? const [PosStore(id: 's', name: 'QA', branchId: 'b', status: 'active')] : [],
      promoCode: previous ? 'HEMAT' : '',
      pricingPreview: previous ? quote : null,
    ));
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 20));
void apply(PosBloc bloc, String code) => bloc.add(UpdateDiscount(
  manualDiscountPercent: 0, promoCode: code, discountPolicy: 'stack',
));

void main() {
  test('normalizes pasted code and invalidates previous discount immediately', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, previous: true);
    addTearDown(bloc.close);
    apply(bloc, '  baru  ');
    await tick();
    expect(repo.codes, ['BARU']);
    expect(bloc.state.promoApplied, isFalse);
    expect(bloc.state.grandTotal, 10000);
    repo.requests.single.complete(const Right(quote));
    await tick();
  });

  test('removing code clears old discount before server responds', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, previous: true);
    addTearDown(bloc.close);
    apply(bloc, '');
    await tick();
    expect(bloc.state.promoApplied, isFalse);
    expect(bloc.state.grandTotal, 10000);
    repo.requests.single.complete(const Right({'subtotal': 10000, 'total_after_discount': 10000}));
    await tick();
  });

  test('network failure explains verification failure and allows retry of same code', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    apply(bloc, 'HEMAT');
    await tick();
    repo.requests.single.complete(const Left(NetworkFailure('QA offline')));
    await tick();
    expect(bloc.state.pricingPreview?['promo_message'], contains('Sambungkan internet'));
    expect(bloc.state.promoApplied, isFalse);
    apply(bloc, 'HEMAT');
    await tick();
    repo.requests.last.complete(const Right(quote));
    await tick();
    expect(bloc.state.promoApplied, isTrue);
    expect(bloc.state.grandTotal, 9000);
  });

  test('server rejection is visible instead of generic ineligible message', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    apply(bloc, 'HEMAT');
    await tick();
    repo.requests.single.complete(const Left(ServerFailure('Akses promo ditolak')));
    await tick();
    expect(bloc.state.pricingPreview?['promo_message'], 'Akses promo ditolak');
  });

  test('missing store explains why verification cannot start', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, store: false);
    addTearDown(bloc.close);
    apply(bloc, 'HEMAT');
    await tick();
    expect(repo.requests, isEmpty);
    expect(bloc.state.pricingPreview?['promo_message'], contains('toko'));
    expect(bloc.state.promoApplied, isFalse);
  });

  for (final staleFailure in [false, true]) {
    test('late ${staleFailure ? 'failure' : 'success'} cannot replace latest promo result', () async {
      final repo = PromoRepo();
      final bloc = PromoBloc(repo);
      addTearDown(bloc.close);
      apply(bloc, 'OLD');
      await tick();
      apply(bloc, 'NEW');
      await tick();
      repo.requests.last.complete(const Right({'promo_applied': false, 'promo_message': 'Pilih pelanggan', 'subtotal': 10000}));
      await tick();
      repo.requests.first.complete(staleFailure ? const Left(NetworkFailure()) : const Right(quote));
      await tick();
      expect(bloc.state.promoCode, 'NEW');
      expect(bloc.state.promoApplied, isFalse);
      expect(bloc.state.pricingPreview?['promo_message'], 'Pilih pelanggan');
    });
  }

  testWidgets('Enter applies promo and displays server eligibility reason', (tester) async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider<PosBloc>.value(
      value: bloc,
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: PosInfoPanel(isMobile: true)))),
    ));
    final field = find.widgetWithText(TextField, 'Kode promo');
    await tester.enterText(field, 'hemat');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(repo.codes, ['HEMAT']);
    repo.requests.single.complete(const Right({'promo_applied': false, 'promo_message': 'Pilih pelanggan untuk menggunakan kode promo ini'}));
    await tester.pumpAndSettle();
    expect(find.text('Pilih pelanggan untuk menggunakan kode promo ini'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
