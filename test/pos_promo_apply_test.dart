import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_info_panel.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_discount_dialog.dart';

const product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'Produk',
  price: 10000,
  stock: 10,
  category: 'QA',
);
const quote = <String, dynamic>{
  'subtotal': 10000,
  'promo_code': 'HEMAT',
  'promo_applied': true,
  'promo_discount': 1000,
  'total_after_discount': 9000,
  'promo_message': 'Kode promo valid',
};

class PromoRepo extends Fake implements PosRepository {
  final requests = <Completer<Either<Failure, Map<String, dynamic>>>>[];
  final codes = <String>[];
  final submissions = <Map<Symbol, dynamic>>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #previewPricing) {
      codes.add(invocation.namedArguments[#promoCode] as String);
      final request = Completer<Either<Failure, Map<String, dynamic>>>();
      requests.add(request);
      return request.future;
    }
    if (invocation.memberName == #submitTransaction) {
      submissions.add(invocation.namedArguments);
      return Future.value(const Left<Failure, PosTransactionResult>(ServerFailure('QA stopped before write')));
    }
    return super.noSuchMethod(invocation);
  }
}

class PromoBloc extends PosBloc {
  PromoBloc(PromoRepo repo, {bool previous = false, bool store = true, bool manager = false})
    : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: {product: 1},
        stores: store
            ? const [
                PosStore(id: 's', name: 'QA', branchId: 'b', status: 'active'),
              ]
            : [],
        promoCode: previous ? 'HEMAT' : '',
        pricingPreview: previous ? quote : null,
        runtimeConfig: {'permissions': {'manage_settings': manager}},
      ),
    );
  }
}

Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 20));
void apply(PosBloc bloc, String code) => bloc.add(
  UpdateDiscount(
    manualDiscountPercent: 0,
    promoCode: code,
    discountPolicy: 'stack',
  ),
);

void main() {
  test(
    'normalizes pasted code and invalidates previous discount immediately',
    () async {
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
    },
  );

  test('clear cart ends verification even if old request never finishes', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    apply(bloc, 'HEMAT');
    await tick();
    expect(bloc.state.pricingPreviewLoading, isTrue);
    bloc.add(ClearCart());
    await tick();
    expect(bloc.state.cart, isEmpty);
    expect(bloc.state.pricingPreviewLoading, isFalse);
    repo.requests.single.complete(const Right(quote));
    await tick();
    expect(bloc.state.promoApplied, isFalse);
  });

  test('removing code clears old discount before server responds', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, previous: true);
    addTearDown(bloc.close);
    apply(bloc, '');
    await tick();
    expect(bloc.state.promoApplied, isFalse);
    expect(bloc.state.grandTotal, 10000);
    repo.requests.single.complete(
      const Right({'subtotal': 10000, 'total_after_discount': 10000}),
    );
    await tick();
  });

  test(
    'network failure explains verification failure and allows retry of same code',
    () async {
      final repo = PromoRepo();
      final bloc = PromoBloc(repo);
      addTearDown(bloc.close);
      apply(bloc, 'HEMAT');
      await tick();
      repo.requests.single.complete(const Left(NetworkFailure('QA offline')));
      await tick();
      expect(
        bloc.state.pricingPreview?['promo_message'],
        contains('Sambungkan internet'),
      );
      expect(bloc.state.promoApplied, isFalse);
      apply(bloc, 'HEMAT');
      await tick();
      repo.requests.last.complete(const Right(quote));
      await tick();
      expect(bloc.state.promoApplied, isTrue);
      expect(bloc.state.grandTotal, 9000);
    },
  );

  test(
    'server rejection is visible instead of generic ineligible message',
    () async {
      final repo = PromoRepo();
      final bloc = PromoBloc(repo);
      addTearDown(bloc.close);
      apply(bloc, 'HEMAT');
      await tick();
      repo.requests.single.complete(
        const Left(ServerFailure('Akses promo ditolak')),
      );
      await tick();
      expect(
        bloc.state.pricingPreview?['promo_message'],
        'Akses promo ditolak',
      );
    },
  );

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
    test(
      'late ${staleFailure ? 'failure' : 'success'} cannot replace latest promo result',
      () async {
        final repo = PromoRepo();
        final bloc = PromoBloc(repo);
        addTearDown(bloc.close);
        apply(bloc, 'OLD');
        await tick();
        apply(bloc, 'NEW');
        await tick();
        repo.requests.last.complete(
          const Right({
            'promo_applied': false,
            'promo_message': 'Pilih pelanggan',
            'subtotal': 10000,
          }),
        );
        await tick();
        repo.requests.first.complete(
          staleFailure ? const Left(NetworkFailure()) : const Right(quote),
        );
        await tick();
        expect(bloc.state.promoCode, 'NEW');
        expect(bloc.state.promoApplied, isFalse);
        expect(bloc.state.pricingPreview?['promo_message'], 'Pilih pelanggan');
      },
    );
  }

  test('unverified promo blocks payment rather than using previous discount', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, previous: true);
    addTearDown(bloc.close);
    apply(bloc, 'NEW');
    await tick();
    bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 10000));
    await tick();
    expect(repo.submissions, isEmpty);
    expect(bloc.state.errorMessage, contains('belum terverifikasi'));
    repo.requests.single.complete(const Left(NetworkFailure()));
    await tick();
  });

  test('verified promo passes its code and discounted total to payment', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, previous: true);
    addTearDown(bloc.close);
    bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 9000));
    await tick();
    expect(repo.submissions, hasLength(1));
    expect(repo.submissions.single[#promoCode], 'HEMAT');
    expect(repo.submissions.single[#total], 9000);
  });

  test('normal payment ends a pending background quote even when payment is rejected', () async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    bloc.add(RefreshPricingPreview());
    await tick();
    expect(bloc.state.pricingPreviewLoading, isTrue);
    bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 10000));
    await tick();
    expect(repo.submissions, hasLength(1));
    expect(bloc.state.pricingPreviewLoading, isFalse);
    repo.requests.single.complete(const Right(quote));
    await tick();
  });

  Future<void> showPromo(WidgetTester tester, PromoBloc bloc) async {
    await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc,
      child: const MaterialApp(home: Scaffold(body: PosDiscountDialog()))));
  }

  testWidgets('compact promo dialog shows progress and eligibility result without closing', (tester) async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    await showPromo(tester, bloc);
    expect(find.widgetWithText(TextField, 'Diskon manual (%)'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Kode promo'), 'hemat');
    await tester.tap(find.text('Terapkan'));
    await tester.pump();
    expect(find.text('Diskon & Promo'), findsOneWidget);
    expect(find.text('Memverifikasi kode promo…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    repo.requests.single.complete(const Right(quote));
    await tester.pumpAndSettle();
    expect(find.text('Kode promo valid'), findsOneWidget);
    expect(bloc.state.grandTotal, 9000);
    await tester.tap(find.text('Hapus'));
    await tester.pump();
    expect(bloc.state.promoCode, '');
    expect(bloc.state.grandTotal, 10000);
    repo.requests.last.complete(const Right({'subtotal': 10000, 'total_after_discount': 10000}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual discount remains manager-only and rejects invalid values', (tester) async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo, manager: true);
    addTearDown(bloc.close);
    await showPromo(tester, bloc);
    final discount = find.widgetWithText(TextField, 'Diskon manual (%)');
    await tester.enterText(discount, '101');
    await tester.tap(find.text('Terapkan'));
    await tester.pumpAndSettle();
    expect(find.text('Diskon harus antara 0–100%'), findsOneWidget);
    expect(repo.requests, isEmpty);
    await tester.enterText(discount, '10');
    await tester.tap(find.text('Terapkan'));
    await tester.pump();
    expect(bloc.state.manualDiscountPercent, 10);
    repo.requests.single.complete(const Right({'subtotal': 10000, 'total_after_discount': 9000}));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone dialog stays usable with keyboard and can retry after offline', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    await showPromo(tester, bloc);
    await tester.enterText(find.widgetWithText(TextField, 'Kode promo'), 'HEMAT');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    repo.requests.single.complete(const Left(NetworkFailure()));
    await tester.pumpAndSettle();
    expect(find.text('Kode promo belum terverifikasi. Sambungkan internet atau hapus promo.'), findsOneWidget);
    await tester.tap(find.text('Terapkan'));
    await tester.pump();
    expect(repo.requests, hasLength(2));
    // Leaving while a query runs must not use disposed text controllers.
    await tester.pumpWidget(const SizedBox());
    repo.requests.last.complete(const Right(quote));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter applies promo and displays server eligibility reason', (
    tester,
  ) async {
    final repo = PromoRepo();
    final bloc = PromoBloc(repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PosInfoPanel(isMobile: true)),
          ),
        ),
      ),
    );
    final field = find.widgetWithText(TextField, 'Kode promo');
    await tester.enterText(field, 'hemat');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(repo.codes, ['HEMAT']);
    repo.requests.single.complete(
      const Right({
        'promo_applied': false,
        'promo_message': 'Pilih pelanggan untuk menggunakan kode promo ini',
      }),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Pilih pelanggan untuk menggunakan kode promo ini'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
