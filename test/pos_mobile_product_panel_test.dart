import 'package:flutter/material.dart';
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
      'daftar produk kasir ringkas tanpa overflow pada ${width.toInt()} dp',
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
          name: 'Air Mineral 600 ml Kemasan Khusus',
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

        await tester.pumpWidget(
          BlocProvider<PosBloc>.value(
            value: bloc,
            child: const MaterialApp(
              home: Scaffold(
                body: PosProductPanel(
                  isMobile: true,
                  selectedCategory: 'Semua Kategori',
                  categories: ['Semua Kategori'],
                  onCategorySelected: _ignoreCategory,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Produk'), findsNothing);
        expect(find.text('Rp 1.250.000'), findsOneWidget);
        expect(find.text('· 1 tersedia'), findsOneWidget);
        expect(find.text('· Habis'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('${soldOut.name} tidak tersedia'));
        await tester.pump();
        expect(bloc.state.cart.containsKey(soldOut), isFalse);

        await tester.tap(find.byTooltip('Tambah ${product.name} ke keranjang'));
        await tester.pump();
        expect(bloc.state.cart[product], 1);
        await tester.tap(find.byTooltip('Tambah ${product.name} ke keranjang'));
        await tester.pump();
        expect(bloc.state.cart[product], 1);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      },
    );
  }
}

void _ignoreCategory(String _) {}
