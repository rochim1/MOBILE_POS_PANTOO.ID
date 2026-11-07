import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_opname.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_opname_batch_fields.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_inventory_barcode_match.dart';

Map<String, dynamic> row(String rack, {bool batch = false}) => {
  'inventaris_id': 'product',
  'stock_balance_id': 'balance-$rack',
  'nama_inventaris': 'Barang QA',
  'unit': 'unit',
  'lokasi': {
    'cabang_id': 'warehouse',
    'cabang_nama': 'Gudang QA',
    'gedung_kode': 'G',
    'ruangan_kode': 'R',
    'rak_nama': rack,
  },
  'qty_system': 10,
  'qty_fisik': 10,
  'qty_unbatched_system': batch ? 2 : 10,
  'qty_unbatched_fisik': batch ? 2 : 10,
  'batch_counts': batch
      ? [
          {
            'batch_id': 'lot-$rack',
            'no_batch': 'SAME',
            'tanggal_kadaluarsa': '2027-11-04',
            'qty_system': 8,
            'qty_fisik': 8,
          },
        ]
      : [],
  'catatan_item': 'QA hasil hitung',
};
Map<String, dynamic> doc({bool batch = false}) => {
  '_id': 'doc',
  'status': 'draft',
  'no_opname': 'QA-OP',
  'tanggal_opname': '2026-11-04',
  'lokasi': {
    '__typename': 'InventoryOpnameLocation',
    'cabang_id': 'warehouse',
    'cabang_nama': 'Gudang QA',
  },
  'items': [row('A', batch: batch), row('B', batch: batch)],
};
Map<String, dynamic> clone(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

class QaOpnameRepository implements PosInventoryRepository {
  Map<String, dynamic> document = doc();
  final calls = <Map<String, dynamic>>[];
  String? failure;
  Completer<Either<Failure, dynamic>>? pending;
  @override
  Future<Either<Failure, Map<String, dynamic>>> getOpname(String id) async =>
      failure == null ? Right(clone(document)) : Left(ServerFailure(failure!));
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getWarehouses({
    String search = '',
  }) async => const Right([
    {'_id': 'warehouse', 'nama_cabang': 'Gudang QA'},
  ]);
  @override
  Future<Either<Failure, dynamic>> saveDocument({
    required PosInventoryDocumentType type,
    required Map<String, dynamic> input,
    String? id,
  }) async {
    calls.add({'type': type.name, 'input': input, 'id': id});
    if (pending != null) return pending!.future;
    if (failure != null) return Left(ServerFailure(failure!));
    return Right(clone(document));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected dependency ${invocation.memberName}');
}

void main() {
  test(
    'location inputs preserve exact scope but never copy GraphQL response metadata',
    () {
      final input = opnameLocationInput({
        '__typename': 'InventoryOpnameLocation',
        '_id': 'response-only',
        'cabang_id': 'warehouse',
        'cabang_nama': 'Gudang QA',
        'gedung_kode': 'G',
        'gedung_nama': 'Gedung',
        'ruangan_kode': 'R',
        'ruangan_nama': 'Ruang',
        'rak_nama': 'A',
      });
      expect(input.length, 7);
      expect(input['rak_nama'], 'A');
      expect(input, isNot(contains('__typename')));
      expect(input, isNot(contains('_id')));
    },
  );
  test(
    'same product in two racks retains distinct identities and physical zero',
    () {
      final rows = [
        editableOpnameRow({...row('A'), 'qty_fisik': 0}),
        editableOpnameRow({...row('B'), 'qty_fisik': 8}),
      ];
      final map = {for (final (i, r) in rows.indexed) opnameRowKey(r, i): r};
      expect(map.length, 2);
      expect(rows.map((r) => r['input_qty']), [0, 8]);
      expect(rows.map(opnameCountInput).map((r) => r['stock_balance_id']), [
        'balance-A',
        'balance-B',
      ]);
      expect(validateOpnameRows(rows), isNull);
    },
  );
  test(
    'mixed batch count, identities and zero survive payload and require reason at equal total',
    () {
      final item = editableOpnameRow(row('A', batch: true));
      (item['batch_counts'] as List)[0]['qty_fisik'] = 0.0;
      item['qty_unbatched_fisik'] = 0.0;
      item['input_qty'] = opnamePhysicalTotal(item);
      final payload = opnameCountInput(item);
      expect(payload['qty_fisik'], 0);
      expect(payload['qty_unbatched_fisik'], 0);
      expect((payload['batch_counts'] as List).first['batch_id'], 'lot-A');
      (item['batch_counts'] as List)[0]['qty_fisik'] = 7;
      item['qty_unbatched_fisik'] = 3;
      item['input_qty'] = opnamePhysicalTotal(item);
      item['catatan_item'] = '';
      expect(item['input_qty'], 10);
      expect(opnameHasDifference(item), isTrue);
      expect(validateOpnameRows([item]), contains('alasan'));
    },
  );
  test(
    'ambiguous legacy, duplicates, empty and invalid numbers cannot be submitted',
    () {
      final a = editableOpnameRow(row('A')), b = editableOpnameRow(row('B'));
      expect(
        validateOpnameRows([
          {...a, 'stock_balance_id': null},
          {...b, 'stock_balance_id': null},
        ]),
        contains('ambigu'),
      );
      expect(validateOpnameRows([a, a]), contains('duplikat'));
      for (final q in [null, -1, double.nan, double.infinity, '']) {
        expect(
          validateOpnameRows([
            {...a, 'input_qty': q},
          ]),
          isNotNull,
        );
      }
      expect(
        validateOpnameRows([
          {...a, 'stock_balance_id': null},
        ]),
        isNull,
      );
    },
  );
  test(
    'stock policy is rack-specific and selected handoff contains no quantities',
    () {
      final stock = PosStock.fromJson({
        '_id': 'product',
        'requires_batch_adjustment': true,
        'nama_inventaris': 'QA',
      });
      final balance = {
        '_id': 'balance-A',
        'lokasi_cabang_id': 'warehouse',
        'lokasi_gedung_kode': 'G',
        'lokasi_ruangan_kode': 'R',
        'lokasi_rak_nama': 'A',
        'qty': 10,
        'batches': [],
      };
      expect(stock.needsBatchCountAt(balance), isFalse);
      expect(
        PosStock.fromJson({
          ...stock.toJson(),
          'wajib_batch_number': true,
        }).needsBatchCountAt(balance),
        isTrue,
      );
      final target = PosOpnameTarget.fromBalance(stock, balance);
      expect(target.balanceId, 'balance-A');
      expect(target.location['rak_nama'], 'A');
      expect(target.location.containsKey('qty'), isFalse);
      expect(
        () => PosOpnameTarget.fromBalance(stock, {}),
        throwsFormatException,
      );
    },
  );
  test('scan deduplicates product identity but keeps both rack choices', () {
    final rows = [
      editableOpnameRow({...row('A'), 'barcode': '12345'}),
      editableOpnameRow({...row('B'), 'barcode': '12345'}),
    ];
    final matches = matchInventoryBarcode(opnameScanCatalog(rows), '12345');
    expect(matches.length, 1);
    expect(
      rows
          .where((r) => r['inventaris_id'] == matches.single['inventaris_id'])
          .length,
      2,
    );
  });
  test(
    'conversion cannot hide negative package count behind a positive total',
    () {
      final item = {
        ...editableOpnameRow(row('A')),
        'use_conversion': true,
        'input_qty': 14.0,
        'available_units': [
          {'unit': 'unit', 'factor': 1.0, 'input_qty': -10.0},
          {'unit': 'box', 'factor': 12.0, 'input_qty': 2.0},
        ],
      };
      expect(validateOpnameRows([item]), contains('kemasan'));
      (item['available_units'] as List)[0]['input_qty'] = 2.0;
      item['input_qty'] = 26.0;
      expect(validateOpnameRows([item]), isNull);
      final payload = opnameCountInput(item);
      expect(payload['qty_fisik'], 26);
      expect((payload['unit_breakdown'] as List)[1]['factor'], 12);
    },
  );
  testWidgets(
    'phone batch form handles zero, mixed remainder and keyboard without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(375, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var item = editableOpnameRow(row('A', batch: true));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, update) => PosOpnameBatchFields(
                  item: item,
                  onChanged: (next) => update(() => item = next),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField).at(0), '0');
      await tester.enterText(find.byType(TextFormField).at(1), '0');
      await tester.pump();
      expect(item['input_qty'], 0);
      expect(find.text('Total fisik: 0 unit'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  group('real opname editor', () {
    late QaOpnameRepository repository;
    setUp(() {
      sl.pushNewScope();
      repository = QaOpnameRepository();
      sl.registerSingleton<PosInventoryRepository>(repository);
    });
    tearDown(() async {
      await sl.popScope();
    });
    testWidgets(
      'fresh server detail keeps two rack rows and saving sends both exact balances',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: PosInventoryEditorPage(
              type: PosInventoryDocumentType.opname,
              existing: {'_id': 'doc'},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Gudang QA / G / R / A'), findsOneWidget);
        expect(find.text('Gudang QA / G / R / B'), findsOneWidget);
        expect(find.text('Lokasi snapshot (terkunci)'), findsOneWidget);
        final quantities = find.widgetWithText(TextFormField, 'Jumlah fisik');
        expect(quantities, findsNWidgets(2));
        await tester.enterText(quantities.at(0), '0');
        await tester.enterText(quantities.at(1), '8');
        final save = find.text('Simpan Perubahan');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(repository.calls.length, 1);
        expect(
          repository.calls.single['input']['lokasi'],
          isNot(contains('__typename')),
        );
        final items = repository.calls.single['input']['items'] as List;
        expect(items.map((r) => r['stock_balance_id']), [
          'balance-A',
          'balance-B',
        ]);
        expect(items.map((r) => r['qty_fisik']), [0, 8]);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      },
    );
    testWidgets(
      'snapshot conversions work without catalog permission and displayed physical total stays current',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        repository.document = {
          ...doc(),
          'items': [
            {
              ...row('A'),
              'unit_conversions': [
                {'unit': 'box', 'factor': 12.0},
              ],
            },
          ],
        };
        await tester.pumpWidget(
          MaterialApp(
            home: PosInventoryEditorPage(
              type: PosInventoryDocumentType.opname,
              existing: {'_id': 'doc'},
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hitung dengan konversi'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Jumlah unit'),
          '2',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Jumlah box'),
          '1',
        );
        await tester.pumpAndSettle();
        final physical = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Jumlah fisik'),
        );
        expect(physical.initialValue, '14.0');
        final save = find.text('Simpan Perubahan');
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        final item = (repository.calls.single['input']['items'] as List).single;
        expect(item['qty_fisik'], 14);
        expect(item['stock_balance_id'], 'balance-A');
        expect((item['unit_breakdown'] as List)[1]['input_qty'], 1);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      },
    );
    testWidgets(
      'targeted start waits for server, fences repeat saves, then enters count editor',
      (tester) async {
        repository.document = {
          ...doc(batch: true),
          'items': [row('A', batch: true)],
        };
        final target = PosOpnameTarget(
          inventoryId: 'product',
          balanceId: 'balance-A',
          name: 'Barang QA',
          location: Map<String, dynamic>.from(row('A')['lokasi'] as Map),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: PosInventoryEditorPage(
              type: PosInventoryDocumentType.opname,
              opnameTarget: target,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(repository.calls, isEmpty);
        repository.pending = Completer<Either<Failure, dynamic>>();
        final start = find.text('Mulai hitung barang ini');
        await tester.ensureVisible(start);
        await tester.tap(start);
        await tester.pump();
        expect(repository.calls.length, 1);
        expect(
          repository.calls.single['input']['stock_balance_id'],
          'balance-A',
        );
        repository.pending!.complete(Right(repository.document));
        await tester.pumpAndSettle();
        expect(find.byType(PosOpnameBatchFields), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Simpan Perubahan'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Simpan Perubahan'), findsOneWidget);
        expect(repository.calls.single['id'], isNull);
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(seconds: 3));
      },
    );
    testWidgets(
      'failed fresh detail never silently restores stale offline document',
      (tester) async {
        repository.failure = 'Perlu koneksi untuk memverifikasi snapshot';
        await tester.pumpWidget(
          MaterialApp(
            home: PosInventoryEditorPage(
              type: PosInventoryDocumentType.opname,
              existing: doc(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Perlu koneksi untuk memverifikasi snapshot'),
          findsWidgets,
        );
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.byType(PosOpnameBatchFields), findsNothing);
        expect(repository.calls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
