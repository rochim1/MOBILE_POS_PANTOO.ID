import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_product_panel.dart';

PosProduct product(String name, {double stock = 5}) => PosProduct(
  id: name,
  code: 'SKU-$name',
  name: name,
  category: 'QA',
  price: 1000,
  stock: stock,
);

class CatalogRepo extends Fake implements PosRepository {
  final pages = <int>[];
  Completer<PosCatalogPage>? refresh;
  int fullLoads = 0;
  bool reject = false;
  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async {
    fullLoads++;
    return [product('Full catalogue')];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #submitTransaction) {
      return Future.value(
        reject
            ? const Left<Failure, PosTransactionResult>(
                ServerFailure('Rejected'),
              )
            : const Right<Failure, PosTransactionResult>(
                PosTransactionResult(
                  id: 'tx',
                  invoice: 'INV',
                  subtotal: 1000,
                  discount: 0,
                  promoDiscount: 0,
                  tax: 0,
                  total: 1000,
                  cashReceived: 1000,
                  change: 0,
                  paymentMethod: 'tunai',
                ),
              ),
      );
    }
    return super.noSuchMethod(invocation);
  }

  @override
  Future<PosCatalogPage> getCatalogPage({
    String? branchId,
    String search = '',
    String category = 'Semua Kategori',
    Set<String> favorites = const {},
    int page = 1,
  }) async {
    pages.add(page);
    if (refresh != null) return refresh!.future;
    return PosCatalogPage([product('Page $page')], 90);
  }
}

class CatalogBloc extends PosBloc {
  CatalogBloc(CatalogRepo repo) : super(posRepository: repo) {
    emit(
      state.copyWith(
        stores: const [
          PosStore(id: 's', name: 'QA', status: 'active', branchId: 'branch'),
        ],
      ),
    );
  }
  void updatedProducts() =>
      emit(state.copyWith(products: [product('Updated master')]));
  void seedCart() => emit(state.copyWith(cart: {product('Paid item'): 1}));
  void switchStore() => emit(
    state.copyWith(
      stores: const [
        PosStore(
          id: 'other',
          name: 'Other',
          status: 'active',
          branchId: 'other-branch',
        ),
      ],
    ),
  );
}

void main() {
  for (final reject in [false, true]) {
    test(
      'checkout ${reject ? 'rejection does not refresh' : 'success schedules page refresh before leaving receipt'}',
      () async {
        final repo = CatalogRepo()..reject = reject;
        final bloc = CatalogBloc(repo)..seedCart();
        addTearDown(bloc.close);
        bloc.add(
          const SubmitPayment(paymentMethod: 'tunai', cashReceived: 1000),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(bloc.state.catalogRevision, reject ? 0 : 1);
        expect(repo.fullLoads, 0);
        expect(
          bloc.state.status,
          reject ? PosStatus.failure : PosStatus.paymentSuccess,
        );
        bloc.add(AcknowledgePaymentSuccess());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.catalogRevision, reject ? 0 : 1);
        expect(
          bloc.state.status,
          reject ? PosStatus.failure : PosStatus.success,
        );
        expect(repo.fullLoads, 0);
      },
    );
  }

  testWidgets(
    'same-store stock refresh preserves visible page while current page revalidates',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = CatalogRepo();
      final bloc = CatalogBloc(repo);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: bloc,
          child: MaterialApp(
            home: Scaffold(
              body: PosProductPanel(
                isMobile: true,
                selectedCategory: 'Semua Kategori',
                categories: const ['Semua Kategori'],
                onCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Produk berikutnya'));
      await tester.pumpAndSettle();
      expect(repo.pages, [1, 2]);
      expect(find.text('Page 2'), findsOneWidget);
      repo.refresh = Completer<PosCatalogPage>();
      bloc.updatedProducts();
      await tester.pump();
      await tester.pump();
      expect(
        repo.pages.last,
        2,
        reason: 'Refresh must not jump back to page one',
      );
      expect(
        find.text('Page 2'),
        findsOneWidget,
        reason: 'Cached products must remain usable during refresh',
      );
      repo.refresh!.complete(PosCatalogPage([product('Page 2', stock: 4)], 90));
      await tester.pumpAndSettle();
      expect(find.text('Page 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'recovery invalidations coalesce and failed background fetch retains products',
    (tester) async {
      final repo = CatalogRepo();
      final bloc = CatalogBloc(repo);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: bloc,
          child: MaterialApp(
            home: Scaffold(
              body: PosProductPanel(
                isMobile: true,
                selectedCategory: 'Semua Kategori',
                categories: const ['Semua Kategori'],
                onCategorySelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      repo.refresh = Completer<PosCatalogPage>();
      bloc.add(RefreshCashierCatalog());
      bloc.add(RefreshCashierCatalog());
      await tester.pump();
      await tester.pump();
      expect(repo.pages, [1, 1]);
      expect(repo.fullLoads, 0);
      expect(find.text('Page 1'), findsOneWidget);
      repo.refresh!.completeError(StateError('QA offline'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);
      final old = Completer<PosCatalogPage>();
      repo.refresh = old;
      bloc.add(RefreshCashierCatalog());
      await tester.pump();
      await tester.pump();
      final latest = Completer<PosCatalogPage>();
      repo.refresh = latest;
      bloc.switchStore();
      await tester.pump();
      await tester.pump();
      expect(find.text('Page 1'), findsNothing);
      latest.complete(PosCatalogPage([product('Other store')], 1));
      await tester.pumpAndSettle();
      old.complete(PosCatalogPage([product('Wrong old store')], 1));
      await tester.pumpAndSettle();
      expect(find.text('Other store'), findsOneWidget);
      expect(find.text('Wrong old store'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
