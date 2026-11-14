import 'package:flutter_test/flutter_test.dart';
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
