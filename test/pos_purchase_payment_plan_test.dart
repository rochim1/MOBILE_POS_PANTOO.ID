import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_purchase_payment_plan_fields.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_payment_plan.dart';

class _POS extends Fake implements PosRepository {}

class _Bloc extends PosBloc {
  _Bloc() : super(posRepository: _POS());
}

class _Inventory extends Fake implements PosInventoryRepository {
  Map<String, dynamic>? saved;
  @override
  Future<Either<Failure, PosInventoryLookups>> getLookups({
    bool purchaseOnly = false,
  }) async => const Right(
    PosInventoryLookups(
      suppliers: [
        {'_id': 'supplier', 'nama_supplier': 'Supplier QA'},
      ],
      warehouses: [
        {
          '_id': 'warehouse',
          'nama_cabang': 'Gudang QA',
          'is_warehouse': true,
          'is_receiving_location': true,
          'alamat_cabang': 'Alamat QA',
        },
      ],
      activeWarehouseId: 'warehouse',
      inventoryItems: [
        {
          '_id': 'product',
          'inventaris_id': 'product',
          'nama_inventaris': 'Produk QA',
          'unit': 'unit',
          'base_unit': 'unit',
          'harga_beli': 100000,
        },
      ],
      scrapReasons: [],
      scrapIncidentTypes: [],
      scrapOccurrenceLocations: [],
      purchaseReturnReasons: [],
      purchaseReturnMethods: [],
    ),
  );
  @override
  Future<Either<Failure, dynamic>> saveDocument({
    required PosInventoryDocumentType type,
    required Map<String, dynamic> input,
    String? id,
  }) async {
    saved = input;
    return const Right({'_id': 'saved'});
  }
}

const schedule = [
  {'no_termin': 1, 'amount': 25000, 'due_date': '2026-12-03'},
  {'no_termin': 2, 'amount': 75000, 'due_date': '2027-02-10'},
];

void main() {
  tearDown(() => sl.reset());
  testWidgets('advanced PO copy is translated without changing user data', (tester) async {
    await tester.pumpWidget(MaterialApp(locale:const Locale('en'),localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales,home:const Scaffold(body:Column(children:[PosText('Jumlah cicilan (2–12)'),PosText('Dibutuhkan paling lambat'),Text('Nama supplier asli')]))));
    await tester.pumpAndSettle();
    expect(find.text('Installment count (2–12)'),findsOneWidget);
    expect(find.text('Required by'),findsOneWidget);
    expect(find.text('Nama supplier asli'),findsOneWidget);
  });
  test('edited schedule is copied without regenerating dates or amounts', () {
    final result = purchaseInstallmentSchedule(
      saved: schedule,
      count: 2,
      total: 100000,
      date: DateTime(2026, 11, 27),
    );
    expect(result, schedule);
    result[0]['amount'] = 50000;
    expect(schedule[0]['amount'], 25000);
    expect(validatePurchaseInstallments(schedule, 2, 100000), isNull);
    expect(validatePurchaseInstallments(schedule, 2, 90000), isNotNull);
  });
  test(
    'generated installments conserve fractional total and validate invalid rows',
    () {
      final rows = purchaseInstallmentSchedule(
        saved: [],
        count: 3,
        total: 100000.25,
        date: DateTime(2026, 11, 27),
      );
      expect(
        rows.fold<double>(
          0,
          (sum, row) => sum + (row['amount'] as num).toDouble(),
        ),
        100000.25,
      );
      expect(validatePurchaseInstallments(rows, 3, 100000.25), isNull);
      expect(validatePurchaseInstallments(rows, 13, 100000.25), isNotNull);
      rows[0]['due_date'] = '2026-02-30';
      expect(validatePurchaseInstallments(rows, 3, 100000.25), isNotNull);
      rows[0]['due_date'] = '2026-12-27';
      rows[0]['amount'] = double.nan;
      expect(validatePurchaseInstallments(rows, 3, 100000.25), isNotNull);
    },
  );
  for (final locale in ['id', 'en']) {
    for (final plan in ['tunai', 'saat_penerimaan', 'kredit', 'termin']) {
      testWidgets('basic plan $plan is readable at 320px in $locale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? changed;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: PosPurchasePaymentPlanFields(
                  plan: plan,
                  creditType: 'net14',
                  onPlanChanged: (v) => changed = v,
                  onCreditTypeChanged: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(DropdownButtonFormField<String>),
          findsNWidgets(plan == 'kredit' ? 2 : 1),
        );
        expect(find.byType(TextFormField), findsNothing);
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(ValueKey('po-plan-$plan')),
            )
            .onChanged!('kredit');
        expect(changed, 'kredit');
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final retainOld in [true, false]) {
    testWidgets(
      retainOld
          ? 'edit old PO preserves terms and DP in real editor'
          : 'NET14 basic choice saves without supplier estimates or fake installments',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _Inventory();
        sl.registerSingleton<PosInventoryRepository>(repo);
        final bloc = _Bloc();
        addTearDown(bloc.close);
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<PosBloc>.value(
              value: bloc,
              child: PosInventoryEditorPage(
                type: PosInventoryDocumentType.purchase,
                existing: {
                  '_id': 'draft',
                  'accounting_flow': 'vendor_bill',
                  'supplier_id': 'supplier',
                  'receiving_location_id': 'warehouse',
                  'alamat_pengiriman': 'Alamat QA',
                  'tanggal_po': '2026-11-01',
                  'required_by_date': '2026-12-01',
                  'syarat_pembayaran': 'kredit',
                  'tipe_kredit': 'termin',
                  'payment_term_type': 'termin',
                  'due_date_basis': 'fixed_date',
                  'due_date': '2027-02-10',
                  'jumlah_termin': 2,
                  'jadwal_termin': schedule,
                  'down_payment_percent': 20,
                  'items': [
                    {
                      'inventaris_id': 'product',
                      'nama_inventaris': 'Produk QA',
                      'unit': 'unit',
                      'qty_ordered': 1,
                      'harga_beli': 100000,
                    },
                  ],
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Estimasi tanggal kirim dari pemasok (opsional)'),
          findsNothing,
        );
        if (!retainOld) {
          tester
              .widget<PosPurchasePaymentPlanFields>(
                find.byType(PosPurchasePaymentPlanFields),
              )
              .onPlanChanged('kredit');
          await tester.pumpAndSettle();
          tester
              .widget<PosPurchasePaymentPlanFields>(
                find.byType(PosPurchasePaymentPlanFields),
              )
              .onCreditTypeChanged('net14');
          await tester.pumpAndSettle();
        }
        final save = find.ancestor(
          of: find.text('Simpan Perubahan'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        );
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -2200),
        );
        await tester.pumpAndSettle();
        expect(save, findsOneWidget);
        tester.widget<FilledButton>(save).onPressed!();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        expect(repo.saved, isNotNull);
        expect(repo.saved!['required_by_date'], '2026-12-01');
        expect(repo.saved!['down_payment_percent'], 20);
        expect(repo.saved!.containsKey('paid_amount'), false);
        if (retainOld) {
          expect(repo.saved!['jadwal_termin'], schedule);
          expect(repo.saved!['due_date_basis'], 'fixed_date');
        } else {
          expect(repo.saved!['tipe_kredit'], 'net14');
          expect(repo.saved!['term_days'], 14);
          expect(repo.saved!['jumlah_termin'], 1);
          expect(repo.saved!.containsKey('jadwal_termin'), false);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
