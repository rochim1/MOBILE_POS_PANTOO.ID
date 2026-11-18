import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_product_management_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_product_page.dart';

class _Pos extends Cubit<PosState> implements PosBloc {
  _Pos() : super(const PosState(runtimeConfig: {
    'permissions': {'manage_products': true},
  }));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Catalog extends Fake implements PosProductManagementRepository {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getCategories({String search = ''}) async => const Right([]);
  @override
  Future<List<String>> getUnitOptions() async => ['unit', 'pcs'];
  @override
  Future<List<Map<String, dynamic>>> getProductionStations({String? storeId}) async => [];
  @override
  Future<Either<Failure, Map<String, String>>> generateProductIdentifiers() async => const Right({'sku': 'QA-1811', 'barcode': '2018110000015'});
}

void main() {
  for (final language in ['id', 'en']) {
    testWidgets('new catalog form opens safely in $language with canonical unit', (tester) async {
      await sl.reset();
      final pos = _Pos();
      sl.registerFactory<PosProductManagementBloc>(() => PosProductManagementBloc(_Catalog()));
      addTearDown(() async { await pos.close(); await sl.reset(); });
      await tester.binding.setSurfaceSize(const Size(411, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(BlocProvider<PosBloc>.value(value: pos, child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PosProductPage()),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.text(language == 'id' ? 'Tambah Produk' : 'Add Product'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsWidgets);
      expect(find.text('QA-1811'), findsOneWidget);
      // Persisted unit keys must not depend on the UI language.
      expect(find.text('unit'), findsWidgets);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
