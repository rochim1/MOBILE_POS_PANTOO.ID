import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_success_page.dart';

const _product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'QA item',
  category: 'QA',
  price: 100,
  stock: 10,
);
const _transaction = PosTransactionResult(
  id: 'sale',
  invoice: 'INV-QA',
  subtotal: 100,
  discount: 0,
  promoDiscount: 0,
  tax: 0,
  total: 100,
  cashReceived: 100,
  change: 0,
  paymentMethod: 'tunai',
);

class _Repo extends Fake implements PosRepository {
  Map<String, dynamic>? record = {
    'input': {
      'client_transaction_id': 'original-request-1234',
      'toko_id': 'store',
      'tipe_pesanan': 'take_away',
      'channel_penjualan': 'retail',
      'price_level': 'retail',
      'customer_segment': 'regular',
    },
    'receipt': {
      'receipt_items': [
        {'inventaris_id': 'p', 'qty': 1.0, 'unit': 'unit', 'harga_jual': 100.0},
      ],
      'total': 100.0,
      'manual_discount': 0.0,
      'tax': 0.0,
    },
  };
  int recoveries = 0;
  Completer<Either<Failure, PosTransactionResult>> response = Completer();
  @override
  Map<String, dynamic>? get pendingCheckout => record;
  @override
  Future<Either<Failure, PosTransactionResult>> recoverPendingCheckout() {
    recoveries++;
    return response.future.then((result) {
      if (result.isRight()) record = null;
      return result;
    });
  }
}

class _Receipt extends Fake implements PosReceiptRepository {
  @override
  Future<Either<Failure, PosReceiptPrintData>>
  preloadReceiptPrintData() async => const Left(ServerFailure('QA no printer'));
}

class _Display extends Fake implements PosCustomerDisplayService {
  @override
  final state = ValueNotifier(const PosCustomerDisplayState());
}

class _Bloc extends PosBloc {
  _Bloc(_Repo repo, {bool matching = false}) : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: matching ? {_product: 1} : {},
        products: const [_product],
        activeShift: const {'_id': 'shift', 'toko_id': 'store'},
        stores: const [
          PosStore(
            id: 'store',
            name: 'QA',
            status: 'active',
            branchId: 'branch',
          ),
        ],
        orderType: 'take_away',
      ),
    );
  }
  final events = <PosEvent>[];
  void changeCart() => emit(state.copyWith(cart: {_product: 2}));
  @override
  void add(PosEvent event) => events.add(event);
}

void main() {
  Future<(_Repo, _Bloc)> open(
    WidgetTester tester, {
    bool matching = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    final repo = _Repo();
    final display = _Display();
    sl.registerSingleton<PosReceiptRepository>(_Receipt());
    sl.registerSingleton<PosCustomerDisplayService>(display);
    final bloc = _Bloc(repo, matching: matching);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(bloc.close);
      display.state.dispose();
      await sl.reset();
    });
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PosPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (repo, bloc);
  }

  testWidgets(
    'recovery immediately shows progress, prevents duplicate taps and shows failure',
    (tester) async {
      final (repo, _) = await open(tester);
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.pump();
      expect(repo.recoveries, 1);
      expect(find.text('Memulihkan pembayaran...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('recover_checkout')))
            .onPressed,
        isNull,
      );
      repo.response.complete(
        const Left(NetworkFailure('Koneksi QA belum tersedia')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Koneksi QA belum tersedia'), findsOneWidget);
      expect(find.byKey(const Key('checkout_recovery_error')), findsOneWidget);
      expect(
        find.textContaining('Jangan terima pembayaran kedua'),
        findsOneWidget,
      );
      expect(find.text('Pulihkan pembayaran'), findsOneWidget);
      expect(repo.record, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid receipt comparison reports an error without sending a payment',
    (tester) async {
      final (repo, _) = await open(tester, matching: true);
      (repo.record!['receipt'] as Map)['receipt_items'] = [1];
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('checkout_recovery_error')), findsOneWidget);
      expect(find.text('Pulihkan pembayaran'), findsOneWidget);
      expect(repo.recoveries, 0);
      expect(repo.record, isNotNull);
    },
  );

  testWidgets(
    'unexpected recovery exception releases loading and keeps payment proof retryable',
    (tester) async {
      final (repo, _) = await open(tester);
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.pump();
      repo.response.completeError(StateError('QA unexpected transport'));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Pulihkan pembayaran'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(repo.record, isNotNull);
      repo.response = Completer();
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.pump();
      expect(repo.recoveries, 2);
      repo.response.complete(
        const Left(ServerFailure('QA retry failed safely')),
      );
      await tester.pumpAndSettle();
    },
  );

  for (final matching in [false, true]) {
    testWidgets(
      'recovered sale opens receipt and clears only matching cart=$matching',
      (tester) async {
        final (repo, bloc) = await open(tester, matching: matching);
        await tester.tap(find.byKey(const Key('recover_checkout')));
        await tester.pump();
        repo.response.complete(const Right(_transaction));
        await tester.pumpAndSettle();
        expect(find.byType(PosSuccessPage), findsOneWidget);
        expect(find.text('INV-QA'), findsOneWidget);
        expect(bloc.events.whereType<ClearCart>().length, matching ? 1 : 0);
        expect(repo.recoveries, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('recovery never clears a different active cart', (tester) async {
    final (repo, bloc) = await open(tester);
    bloc.changeCart();
    await tester.pump();
    await tester.tap(find.byKey(const Key('recover_checkout')));
    await tester.pump();
    repo.response.complete(const Right(_transaction));
    await tester.pumpAndSettle();
    expect(find.byType(PosSuccessPage), findsOneWidget);
    expect(bloc.state.cart[_product], 2);
    expect(bloc.events.whereType<ClearCart>(), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late failure after leaving the page does not update disposed UI',
    (tester) async {
      final (repo, _) = await open(tester);
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      repo.response.complete(const Left(NetworkFailure()));
      await tester.pumpAndSettle();
      expect(repo.record, isNotNull);
      expect(repo.recoveries, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
