import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_product_panel.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cart_panel.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_service_price_dialog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

class _Repo extends Fake implements PosRepository {}

class _DelayedPricingRepo extends Fake implements PosRepository {
  final requests = <Completer<Either<Failure, Map<String, dynamic>>>>[];
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #previewPricing) {
      final request = Completer<Either<Failure, Map<String, dynamic>>>();
      requests.add(request);
      return request.future;
    }
    return super.noSuchMethod(invocation);
  }
}

class _SeededPosBloc extends PosBloc {
  _SeededPosBloc(PosRepository repository, PosState value)
    : super(posRepository: repository) {
    emit(value);
  }
}

void main() {
  const transport = PosProduct(
    id: 't',
    code: 'T',
    name: 'Transport',
    category: 'Jasa',
    price: 0,
    stock: 0,
    productType: 'service',
    servicePriceMode: 'flexible',
    priceFloor: 50000,
    tracksStock: false,
  );
  test('late pricing response cannot restore the tariff before cashier edit', () async {
    final repo = _DelayedPricingRepo();
    final bloc = _SeededPosBloc(repo, PosState(
      stores: const [PosStore(id: 'store', name: 'QA', status: 'active', branchId: 'warehouse')],
      activeShift: const {'_id': 'shift', 'toko_id': 'store'},
      cart: {transport: 1}, manualUnitPrices: {'t': 150000},
    ));
    addTearDown(bloc.close);
    bloc.add(RefreshPricingPreview());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.requests, hasLength(1));
    bloc.add(const UpdateCartUnitPrice(transport, 175000));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.requests, hasLength(2));
    repo.requests[1].complete(const Right({'subtotal': 175000, 'total_after_discount': 175000}));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    repo.requests[0].complete(const Right({'subtotal': 150000, 'total_after_discount': 150000}));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.unitPriceFor(transport), 175000);
    expect(bloc.state.grandTotal, 175000, reason: 'A stale preview must not change the amount collected at checkout');
  });
  test('opening a saved order restores agreed prices instead of master or unrelated cart prices', () async {
    final bloc = _SeededPosBloc(_Repo(), const PosState(
      products: [transport], manualUnitPrices: {'t': 999000, 'unrelated': 12},
    ));
    addTearDown(bloc.close);
    bloc.add(const EditActiveOrder(PosOrderDetail(
      id: 'saved', orderNumber: 'QA', orderType: 'take_away',
      items: [PosOrderItem(productId: 't', quantity: 2, price: 175000, unit: 'unit')],
    )));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(bloc.state.unitPriceFor(transport), 175000);
    expect(bloc.state.baseSubtotal, 350000);
    expect(bloc.state.manualUnitPrices, {'t': 175000});
    expect(bloc.state.orderType, 'take_away');
  });
  testWidgets(
    'mobile catalogue → tariff → cart → edit works with price override disabled',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final bloc = PosBloc(posRepository: _Repo());
      addTearDown(bloc.close);
      bloc.add(const UpsertProductLocally(transport));
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: bloc,
          child: MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: PosProductPanel(
                      isMobile: true,
                      selectedCategory: 'Semua Kategori',
                      categories: const ['Semua Kategori'],
                      onCategorySelected: (_) {},
                    ),
                  ),
                  const Expanded(child: PosCartPanel()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Isi tarif'), findsOneWidget);
      await tester.tap(find.text('Transport').first);
      await tester.pumpAndSettle();
      expect(find.text('Tarif layanan'), findsOneWidget);
      expect(bloc.state.cart, isEmpty);
      await tester.enterText(find.byType(TextFormField), '150000');
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(bloc.state.unitPriceFor(transport), 150000);
      expect(bloc.state.cart[transport], 1);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '175000');
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(bloc.state.unitPriceFor(transport), 175000);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );
  test(
    'bloc requires valid tariff but does not require general override permission',
    () async {
      final bloc = PosBloc(posRepository: _Repo());
      addTearDown(bloc.close);
      bloc.add(const AddToCart(transport));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.cart, isEmpty);
      bloc.add(const AddToCart(transport, unitPrice: 150000));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.cart[transport], 1);
      expect(bloc.state.unitPriceFor(transport), 150000);
      bloc.add(const UpdateCartUnitPrice(transport, 10000));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.unitPriceFor(transport), 150000);
      bloc.add(const UpdateCartUnitPrice(transport, 175000));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.unitPriceFor(transport), 175000);
      const fixed = PosProduct(
        id: 'p',
        code: 'P',
        name: 'Barang',
        category: '',
        price: 100,
        stock: 1,
      );
      bloc.add(const AddToCart(fixed));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const UpdateCartUnitPrice(fixed, 999));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.unitPriceFor(fixed), 100);
    },
  );
  testWidgets(
    'tariff dialog validates minimum and closes safely without asking HPP',
    (tester) async {
      double? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showServicePriceDialog(context, transport);
                },
                child: const Text('Pilih layanan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Pilih layanan'));
      await tester.pumpAndSettle();
      expect(find.text('Tarif layanan'), findsOneWidget);
      expect(find.textContaining('HPP'), findsNothing);
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Tarif wajib'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '150000');
      await tester.tap(find.text('Terapkan'));
      await tester.pumpAndSettle();
      expect(selected, 150000);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Pilih layanan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  test('flexible service and minimum survive cached JSON roundtrip', () {
    final p = PosProduct.fromJson({
      'id': 'transport',
      'code': 'T',
      'name': 'Transport',
      'category': 'Jasa',
      'pos_product_type': 'service',
      'service_price_mode': 'flexible',
      'price_floor': 50000,
      'price': 0,
      'stock': 0,
    });
    expect(p.isFlexibleService, isTrue);
    expect(p.priceFloor, 50000);
    expect(PosProduct.fromJson(p.toJson()).isFlexibleService, isTrue);
    final state = PosState(manualUnitPrices: {p.id: 150000});
    expect(state.unitPriceFor(p), 150000);
  });
  test('legacy and stock product cannot become flexible from a mode flag', () {
    const p = PosProduct(
      id: 'p',
      code: 'p',
      name: 'Item',
      category: '',
      price: 100,
      stock: 0,
    );
    expect(p.isFlexibleService, isFalse);
    final stock = PosProduct.fromJson({
      ...p.toJson(),
      'service_price_mode': 'flexible',
    });
    expect(stock.isFlexibleService, isFalse);
  });
}
