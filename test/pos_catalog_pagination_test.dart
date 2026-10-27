import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_product_panel.dart';

class QaCatalog extends Fake implements PosRepository {
  final calls = <(int, String)>[];
  @override
  Future<PosCatalogPage> getCatalogPage({
    String? branchId,
    String search = '',
    String category = 'Semua Kategori',
    Set<String> favorites = const {},
    int page = 1,
  }) async {
    calls.add((page, category));
    final items =
        List.generate(
              5005,
              (i) => PosProduct(
                id: '$i',
                name: 'QA Product ${i.toString().padLeft(5, '0')}',
                code: 'QA-$i',
                category: 'Category${i.toString().padLeft(5, '0')}',
                price: 1000,
                stock: 10,
              ),
            )
            .where(
              (row) =>
                  (search.isEmpty || row.name.contains(search)) &&
                  (category == 'Semua Kategori' ||
                      category == row.category ||
                      category == 'Favorit' && favorites.contains(row.id)),
            )
            .toList();
    return PosCatalogPage(
      items.skip((page - 1) * 30).take(30).toList(),
      items.length,
    );
  }

  @override
  Future<PosCatalogCategoryPage> getCatalogCategories({
    required String branchId,
    String search = '',
    int page = 1,
  }) async {
    final items = List.generate(
      5005,
      (i) => 'Category${i.toString().padLeft(5, '0')}',
    ).where((value) => value.contains(search)).toList();
    return PosCatalogCategoryPage(
      items.skip((page - 1) * 20).take(20).toList(),
      items.length,
    );
  }
}

class QaCatalogBloc extends PosBloc {
  QaCatalogBloc(QaCatalog repository) : super(posRepository: repository) {
    emit(
      state.copyWith(
        stores: const [
          PosStore(
            id: 'store',
            name: 'QA',
            status: 'active',
            branchId: 'branch',
          ),
        ],
        activeShift: {'toko_id': 'store'},
        favoriteProductIds: {'5004'},
      ),
    );
  }
}

void main() {
  testWidgets(
    '5,005 QA products/categories: server paging and category search reach records beyond first 1000',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = QaCatalog();
      final tested = QaCatalogBloc(repository);
      addTearDown(tested.close);
      var category = 'Semua Kategori';
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: tested,
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => PosProductPanel(
                  isMobile: true,
                  selectedCategory: category,
                  categories: const ['Semua Kategori'],
                  onCategorySelected: (value) =>
                      setState(() => category = value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repository.calls, [(1, 'Semua Kategori')]);
      await tester.scrollUntilVisible(
        find.byTooltip('Produk berikutnya'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Produk berikutnya'));
      await tester.pumpAndSettle();
      expect(repository.calls.last, (2, 'Semua Kategori'));
      await tester.scrollUntilVisible(
        find.byTooltip('Pilih kategori'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byTooltip('Pilih kategori'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Cari kategori'),
        'Category05004',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Category05004'));
      await tester.pumpAndSettle();
      expect(repository.calls.last, (1, 'Category05004'));
      expect(find.textContaining('QA Product 05004'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'partial catalog cache merges same scope and keeps unresolved-sale protection',
    () {
      final source = File(
        'lib/domain/repositories/pos_repository.dart',
      ).readAsStringSync();
      expect(source, contains('hasUnresolvedTransactionsForBranch'));
      expect(
        source,
        contains(
          "activePayload?['catalog_key'] != _productSnapshotKey(branchId)",
        ),
      );
      expect(source, contains("'complete': false"));
      final catalog = source.substring(
        source.indexOf('getCatalogPage({'),
        source.indexOf('searchProductsRemote({'),
      );
      expect(catalog, isNot(contains("'limit': 1000")));
      expect(catalog, contains("'limit': 30"));
    },
  );
}
