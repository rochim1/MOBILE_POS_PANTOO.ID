import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_product_panel.dart';

PosProduct product(String name, {double stock = 5}) => PosProduct(
  id: name, code: 'SKU-$name', name: name, category: 'QA', price: 1000, stock: stock,
);

class CatalogRepo extends Fake implements PosRepository {
  final pages = <int>[];
  Completer<PosCatalogPage>? refresh;
  @override
  Future<PosCatalogPage> getCatalogPage({String? branchId, String search = '',
    String category = 'Semua Kategori', Set<String> favorites = const {}, int page = 1}) async {
    pages.add(page);
    if (refresh != null) return refresh!.future;
    return PosCatalogPage([product('Page $page')], 90);
  }
}

class CatalogBloc extends PosBloc {
  CatalogBloc(CatalogRepo repo) : super(posRepository: repo) {
    emit(state.copyWith(stores: const [PosStore(id: 's', name: 'QA', status: 'active', branchId: 'branch')]));
  }
  void updatedProducts() => emit(state.copyWith(products: [product('Updated master')]));
}

void main() {
  testWidgets('same-store stock refresh preserves visible page while current page revalidates', (tester) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = CatalogRepo();
    final bloc = CatalogBloc(repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc,
      child: MaterialApp(home: Scaffold(body: PosProductPanel(isMobile: true,
        selectedCategory: 'Semua Kategori', categories: const ['Semua Kategori'], onCategorySelected: (_) {})))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Produk berikutnya'));
    await tester.pumpAndSettle();
    expect(repo.pages, [1, 2]);
    expect(find.text('Page 2'), findsOneWidget);
    repo.refresh = Completer<PosCatalogPage>();
    bloc.updatedProducts();
    await tester.pump();
    await tester.pump();
    expect(repo.pages.last, 2, reason: 'Refresh must not jump back to page one');
    expect(find.text('Page 2'), findsOneWidget, reason: 'Cached products must remain usable during refresh');
    repo.refresh!.complete(PosCatalogPage([product('Page 2', stock: 4)], 90));
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
