import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_outlet_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_warehouse_page.dart';

class _Repository extends Fake implements PosRepository {
  @override
  Future<List<PosStore>> getStores() async => const [];
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getStoreWarehouseOptions() async => const Right([
    {'_id': 'warehouse', 'nama_cabang': 'Lokasi uji', 'is_sellable_location': true},
  ]);
}
class _Inventory extends Fake implements PosInventoryRepository {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getWarehouses({String search = ''}) async => const Right([]);
}

void main() {
  tearDown(() async => sl.reset());
  for (final warehouse in [true, false]) {
    testWidgets('${warehouse ? 'warehouse' : 'outlet'} form keeps all six labels after typing', (tester) async {
      final repository = _Repository();
      sl.registerSingleton<PosRepository>(repository);
      sl.registerSingleton<PosInventoryRepository>(_Inventory());
      final bloc = PosBloc(posRepository: repository);
      addTearDown(bloc.close);
      await tester.binding.setSurfaceSize(const Size(390, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(BlocProvider.value(value: bloc,
        child: MaterialApp(theme: AppTheme.light(), home: Scaffold(body: warehouse
          ? const PosWarehousePage(canCreate: true, canUpdate: true, canDelete: true)
          : const PosOutletPage()))));
      await tester.pumpAndSettle();
      await tester.tap(find.text(warehouse ? 'Tambah Warehouse' : 'Tambah'));
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      void check() {
        final decorators = tester.widgetList<InputDecorator>(find.descendant(of: sheet, matching: find.byType(InputDecorator))).toList();
        expect(decorators.length, 6);
        for (final input in decorators) {
          expect(input.decoration.labelText, isNotEmpty);
          expect(input.decoration.floatingLabelBehavior, FloatingLabelBehavior.always,
            reason: input.decoration.labelText);
        }
      }
      check();
      final first = find.descendant(of: sheet, matching: find.byType(TextField)).first;
      await tester.enterText(first, 'Lokasi Uji');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      check();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 600));
    });
  }
}
