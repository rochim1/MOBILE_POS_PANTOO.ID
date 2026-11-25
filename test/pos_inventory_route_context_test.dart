import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_editor_page.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

class _POS extends Fake implements PosRepository {}

class _Bloc extends PosBloc {
  _Bloc() : super(posRepository: _POS()) {
    emit(
      state.copyWith(
        runtimeConfig: {
          'features': {'track_stock': true},
          'permissions': {
            'view_inventory_purchases': true,
            'create_inventory_purchases': true,
            'submit_inventory_purchases': true,
          },
          'inventory_policy': {
            'inventory_profile': 'simple',
            'default_receiving_location_id': 'dest',
          },
        },
      ),
    );
  }
}

class _Inventory extends Fake implements PosInventoryRepository {
  _Inventory({this.documents = const []});
  final List<Map<String, dynamic>> documents;
  @override
  Future<Either<Failure, Map<String, dynamic>>>
  getDirectPurchaseWorkspace() async => const Right({});
  @override
  Future<Either<Failure, Map<String, dynamic>>> getPurchaseAdvanceWorkspace({
    String search = '',
    int page = 1,
  }) async => const Right({});
  @override
  Future<Either<Failure, PosInventoryDocumentPage>> getDocuments({
    required PosInventoryDocumentType type,
    String search = '',
    String status = '',
    List<String> statuses = const [],
    String inventoryId = '',
    bool receivableOnly = false,
    bool openQuantityOnly = false,
    String workflowView = '',
    String locationId = '',
    String dateFrom = '',
    String dateTo = '',
    String reason = '',
    int page = 1,
    int limit = 20,
  }) async => Right(PosInventoryDocumentPage(documents, documents.length));
  @override
  Future<Either<Failure, PosInventoryLookups>> getLookups({
    bool purchaseOnly = false,
  }) async => const Right(
    PosInventoryLookups(
      suppliers: [],
      warehouses: [
        {
          '_id': 'dest',
          'nama_cabang': 'QA destination',
          'alamat_cabang': 'QA address',
          'is_receiving_location': true,
        },
      ],
      activeWarehouseId: 'dest',
      inventoryItems: [
        {
          '_id': 'stock',
          'inventaris_id': 'stock',
          'nama_inventaris': 'QA stock',
          'kode_inventaris': 'QA-STOCK',
          'base_unit': 'unit',
          'unit': 'unit',
          'harga_beli': 3000,
          'unit_conversions': [
            {'unit': 'box', 'factor': 12},
          ],
        },
      ],
      scrapReasons: [],
      scrapIncidentTypes: [],
      scrapOccurrenceLocations: [],
      purchaseReturnReasons: [],
      purchaseReturnMethods: [],
    ),
  );
}

void main() {
  testWidgets('phone procurement filters collapse but Add stays available', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    sl.registerSingleton<PosInventoryRepository>(_Inventory());
    final bloc = _Bloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PosBloc>.value(value: bloc,
        child: const Scaffold(body: PosInventoryPage(initialSection: 'purchase'))),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Tambah'), findsOneWidget);
    final toggle = find.byKey(const Key('inventory_filter_toggle'));
    await tester.tap(toggle); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'PO-QA');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(toggle); await tester.pumpAndSettle();
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.text('PO-QA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  tearDown(() => sl.reset());
  testWidgets(
    'English PO confirmation translates actions and summary without translating supplier data',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      await AppLanguageController.instance.select('en');
      addTearDown(() => AppLanguageController.instance.select('id'));
      sl.registerSingleton<PosInventoryRepository>(
        _Inventory(
          documents: const [
            {
              '_id': 'draft',
              'no_po': 'PO-QA',
              'status': 'draft',
              'supplier_name': 'Pemasok Uji',
              'branch_name': 'Gudang Uji',
              'grand_total': 36000,
              'items': [],
            },
          ],
        ),
      );
      final bloc = _Bloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider<PosBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: PosInventoryPage(initialSection: 'purchase'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Document actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit').last);
      await tester.pumpAndSettle();
      expect(find.text('Submit PO-QA?'), findsOneWidget);
      expect(
        find.textContaining(
          'Supplier: Pemasok Uji\nBranch: Gudang Uji\nTotal:',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('The PO will be submitted for approval.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'changing purchase unit updates the real price field without losing per-base-unit manual price',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      sl.registerSingleton<PosInventoryRepository>(_Inventory());
      final bloc = _Bloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PosBloc>.value(
            value: bloc,
            child: const PosInventoryEditorPage(
              type: PosInventoryDocumentType.purchase,
              existing: {
                '_id': 'draft',
                'supplier_id': 'supplier',
                'receiving_location_id': 'dest',
                'alamat_pengiriman': 'QA address',
                'items': [
                  {
                    'inventaris_id': 'stock',
                    'nama_inventaris': 'QA stock',
                    'unit': 'unit',
                    'qty_ordered': 1,
                    'harga_beli': 3000,
                  },
                ],
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Barang').first);
      await tester.pumpAndSettle();
      final units = find.byKey(const ValueKey('purchase-unit-stock'));
      tester.widget<DropdownButtonFormField<String>>(units).onChanged!('box');
      await tester.pumpAndSettle();
      final prices = find.byWidgetPredicate(
        (w) =>
            w is TextFormField &&
            w.key is ValueKey &&
            (w.key as ValueKey).value.toString().startsWith(
              'purchase-price-stock',
            ),
      );
      expect(tester.widget<TextFormField>(prices).initialValue, '36.000');
      await tester.enterText(prices, '36.012');
      await tester.pump();
      tester.widget<DropdownButtonFormField<String>>(units).onChanged!('unit');
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(prices).initialValue, '3.001');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'purchase editor pushed outside home route keeps the exact POS context and finishes loading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<PosInventoryRepository>(_Inventory());
      final bloc = _Bloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PosBloc>.value(
            value: bloc,
            child: const Scaffold(
              body: PosInventoryPage(initialSection: 'purchase'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 4),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Tambah'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      final editor = find.byType(PosInventoryEditorPage);
      expect(editor, findsOneWidget);
      expect(tester.element(editor).read<PosBloc>(), same(bloc));
      expect(find.text('QA destination'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(bloc.isClosed, isFalse);
    },
  );
}
