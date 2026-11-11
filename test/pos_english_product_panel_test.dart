import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_product_panel.dart';

class _FakePosRepository extends Fake implements PosRepository {}

void main() {
  for (final width in <double>[320, 360]) {
    testWidgets(
      'English cashier preserves cart without overflow pada ${width.toInt()} dp',
      (tester) async {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final bloc = PosBloc(posRepository: _FakePosRepository());
        addTearDown(bloc.close);
        const product = PosProduct(
          id: 'product-1',
          code: 'POS-TEST-003-LONG',
          name: 'Bayar',
          category: 'Minuman',
          price: 1250000,
          stock: 1,
        );
        const soldOut = PosProduct(
          id: 'product-2',
          code: 'POS-EMPTY-001',
          name: 'Produk Stok Habis',
          category: 'Minuman',
          price: 5000,
          stock: 0,
        );
        bloc.add(const UpsertProductLocally(product));
        bloc.add(const UpsertProductLocally(soldOut));
        final locale = ValueNotifier(const Locale('en'));
        addTearDown(locale.dispose);

        await tester.pumpWidget(
          BlocProvider<PosBloc>.value(
            value: bloc,
            child: ValueListenableBuilder<Locale>(
              valueListenable: locale,
              builder: (_, language, child) => MaterialApp(
                locale: language,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const Scaffold(
                  body: PosProductPanel(
                    isMobile: true,
                    selectedCategory: 'Semua Kategori',
                    categories: ['Semua Kategori'],
                    onCategorySelected: _ignoreCategory,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Produk'), findsNothing);
        expect(find.text('Rp 1.250.000'), findsOneWidget);
        expect(find.text('· 1 available'), findsOneWidget);
        expect(find.text('· Out of stock'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('${soldOut.name} unavailable'));
        await tester.pump();
        expect(bloc.state.cart.containsKey(soldOut), isFalse);

        await tester.tap(find.byTooltip('Add ${product.name} to cart'));
        await tester.pump();
        expect(bloc.state.cart[product], 1);
        await tester.tap(find.byTooltip('Add ${product.name} to cart'));
        await tester.pump();
        expect(bloc.state.cart[product], 1);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
        final state = bloc.state;
        locale.value = const Locale('id');
        await tester.pumpAndSettle();
        expect(find.text('Bayar'), findsOneWidget);
        expect(find.byTooltip('Tambah Bayar ke keranjang'), findsOneWidget);
        expect(identical(bloc.state, state), isTrue);
        expect(bloc.state.cart[product], 1);
      },
    );
  }
}

void _ignoreCategory(String _) {}
