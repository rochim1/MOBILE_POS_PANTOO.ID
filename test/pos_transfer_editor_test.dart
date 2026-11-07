import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_transfer_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';

class TransferFake extends Fake implements PosTransferRepository {
  String? failure;
  final requests = <Map<String, dynamic>>[];
  Completer<Map<String, dynamic>>? pending;
  @override
  Future<List<Map<String, dynamic>>> warehouses() async => [
    {'_id': 'from', 'nama_cabang': 'Asal'},
    {'_id': 'to', 'nama_cabang': 'Tujuan'},
  ];
  @override
  Future<Map<String, dynamic>> detail(String id) async {
    if (failure != null) throw Exception(failure);
    return {
      '_id': id,
      'status': 'draft',
      'tanggal_transfer': '2026-11-05',
      'requires_approval': true,
      'dari': {'__typename': 'Location', 'cabang_id': 'from', 'rak_nama': 'A'},
      'ke': {'cabang_id': 'to', 'rak_nama': 'B'},
      'items': [
        {
          '_id': 'line',
          'inventaris_id': 'product',
          'nama_inventaris': 'Barang transfer QA',
          'qty': 2.0,
          'unit': 'unit',
          'batch_id': 'lot',
          'no_batch': 'LOT-QA',
          'serial_numbers': ['S1', 'S2'],
          'catatan_item': 'Hati-hati',
        },
      ],
      'biaya_transfer': [
        {'jenis_biaya': 'ongkir', 'nominal': 1000.0},
      ],
      'biaya_mode': 'expense',
      'biaya_alokasi': 'per_qty',
      'payment_bank_account_id': 'bank',
      'payment_branch_id': 'branch',
      'branch_id': 'branch',
      'project_id': 'project',
    };
  }

  @override
  Future<Map<String, dynamic>> query(
    String document, [
    Map<String, dynamic> variables = const {},
  ]) async => {
    'GetInventoryTransferPaymentAccounts': [
      {'_id': 'bank', 'label': 'Kas QA'},
    ],
    'GetFinanceDimensionOptions': [
      {'_id': 'branch', 'kind': 'branch', 'code': 'B', 'name': 'Cabang QA'},
      {'_id': 'project', 'kind': 'project', 'code': 'P', 'name': 'Proyek QA'},
    ],
  };
  @override
  Future<Map<String, dynamic>> mutate(
    String document,
    Map<String, dynamic> variables,
    String root,
  ) async {
    requests.add(variables);
    return pending == null
        ? {'_id': 'doc', 'status': 'draft'}
        : pending!.future;
  }
}

void main() {
  testWidgets(
    'reference picker sends one-based pages and reaches the next product or batch page',
    (tester) async {
      final pages = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) => TextButton(
              onPressed: () => showTransferReferencePicker(
                c,
                title: 'Pilih QA',
                loader: (search, page) async {
                  pages.add(page);
                  return [
                    for (var i = 0; i < (pages.length == 1 ? 30 : 1); i++)
                      {'name': 'Page $page row $i'},
                  ];
                },
                label: (r) => r['name'].toString(),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(pages, [1]);
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(pages, [1, 2]);
      expect(find.text('Page 2 row 0'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'editing web transfer on phone retains exact scope, serials, lot and cost on save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = TransferFake();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.text('Simpan mutasi');
      await tester.scrollUntilVisible(
        save,
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 35,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.requests.length, 1);
      final input = repo.requests.single['input'];
      expect(input['dari']['rak_nama'], 'A');
      expect(input['ke']['rak_nama'], 'B');
      expect(input['items'].single['batch_id'], 'lot');
      expect(input['items'].single['serial_numbers'], ['S1', 'S2']);
      expect(input['biaya_transfer'].single['nominal'], 1000);
      expect(input['payment_bank_account_id'], 'bank');
      expect(input['project_id'], 'project');
      expect(input.toString(), isNot(contains('__typename')));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets(
    'failed fresh load blocks editing instead of saving cached web data',
    (tester) async {
      final repo = TransferFake()..failure = 'Jaringan QA putus';
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc', 'status': 'draft'},
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Jaringan QA putus'), findsOneWidget);
      expect(find.text('Simpan mutasi'), findsNothing);
      expect(repo.requests, isEmpty);
    },
  );
}
