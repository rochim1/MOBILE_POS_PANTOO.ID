import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_transfer_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_operation_page.dart';
import 'pos_transfer_recovery_test.dart' show TransferProvider;
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_transfer_recovery_view.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'pos_transfer_editor_test.dart' show TransferFake;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'batch choice and box conversion preserve exact stock payload on save',
    (tester) async {
      final repo = _TraceReferences();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Pilih batch'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.tap(find.text('Pilih batch'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('BATCH-A ·'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Input satuan / kemasan'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.tap(find.text('Input satuan / kemasan'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'box (× 12.0)'),
        '1',
      );
      await tester.tap(find.text('Gunakan jumlah'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Simpan mutasi'),
        300,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await tester.tap(find.text('Simpan mutasi'));
      await tester.pumpAndSettle();
      final item = (repo.requests.single['input']['items'] as List).single;
      expect(item['qty'], 12);
      expect(item['batch_id'], 'new-lot');
      expect(item['unit_breakdown'], [
        {'unit': 'box', 'factor': 12.0, 'input_qty': 1.0},
      ]);
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'recovery is readable on a narrow English phone and disables repeat while busy',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PosTransferRecoveryView(
              intent: const {
                'root': 'ReceiveInventoryTransfer',
                'request_id':
                    'mobile-transfer-long-reference-for-audit-1234567890',
                'variables': {
                  'id': 'doc',
                  'items': [
                    {'item_id': 'item', 'qty': 1},
                  ],
                },
              },
              busy: true,
              onRecover: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Receive transfer'), findsOneWidget);
      expect(find.text('Checking...'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final mode in ['create', 'receive', 'report', 'decide']) {
    final receiving = mode != 'create';
    final root = switch (mode) {
      'create' => 'CreateInventoryTransfer',
      'receive' => 'ReceiveInventoryTransfer',
      'report' => 'ReportInventoryTransferDiscrepancy',
      _ => 'DecideInventoryTransferDiscrepancy',
    };
    final submit = switch (mode) {
      'create' => 'Simpan mutasi',
      'receive' => 'Terima jumlah ini',
      'report' => 'Ajukan laporan selisih',
      _ => 'Simpan keputusan',
    };
    testWidgets(
      '$mode lost response reopens recovery and replays exact intent once',
      (tester) async {
        final seen = <String>{};
        final sent = <Map<String, dynamic>>[];
        var lose = true, reads = 0, received = 0;
        Map<String, dynamic> doc() => {
          '_id': 'doc',
          'status': 'in_transit',
          'updatedAt': 'revision-$received',
          'tanggal_transfer': '2026-01-01',
          'ke': {'cabang_id': 'to'},
          'no_transfer': 'QA-RECOVER',
          'discrepancies': mode == 'decide'
              ? [
                  {
                    '_id': 'report',
                    'kind': 'lost',
                    'status': 'pending',
                    'reason': 'QA',
                    'items': [
                      {'item_id': 'line', 'qty': 1},
                    ],
                  },
                ]
              : [],
          'items': [
            {
              '_id': 'line',
              'nama_inventaris': 'QA product',
              'unit': 'pcs',
              'qty': 5.0,
              'received_qty': received.toDouble(),
            },
          ],
        };
        final provider = TransferProvider(
          await SharedPreferences.getInstance(),
          (r) async* {
            final op =
                (r.operation.document.definitions.first as dynamic).name?.value
                    as String? ??
                '';
            if ([
              'MobileTransferCreate',
              'MobileTransferReceive',
              'MobileTransferReport',
              'MobileTransferDecide',
            ].contains(op)) {
              sent.add(r.variables);
              final requestId =
                  (r.variables['request_id'] ??
                          r.variables['input']?['request_id'] ??
                          r.variables['discrepancy_id'])
                      as String;
              if (seen.add(requestId)) received++;
              if (lose) throw StateError('response lost after commit');
              yield Response(response: const {}, data: {root: doc()});
            } else if (op == 'MobileTransferWarehouses') {
              reads++;
              yield const Response(
                response: {},
                data: {
                  'getAllCabangs': {
                    'cabang': [
                      {'_id': 'from', 'nama_cabang': 'Asal'},
                      {'_id': 'to', 'nama_cabang': 'Tujuan'},
                    ],
                  },
                },
              );
            } else if (op == 'MobileTransferAvailable') {
              yield const Response(
                response: {},
                data: {
                  'GetInventarisAvailableInLocation': [
                    {
                      'inventaris_id': 'product',
                      'nama_inventaris': 'QA product',
                      'unit': 'pcs',
                      'qty': 10.0,
                    },
                  ],
                },
              );
            } else {
              yield Response(
                response: const {},
                data: {'GetOneInventoryTransfer': doc()},
              );
            }
          },
        );
        Widget page() => MaterialApp(
          key: UniqueKey(),
          home: receiving
              ? PosTransferOperationPage(
                  transfer: const {'_id': 'doc'},
                  mode: mode,
                  discrepancyId: mode == 'decide' ? 'report' : null,
                  repository: PosTransferRepository(provider),
                )
              : PosTransferEditorPage(
                  initialSourceId: 'from',
                  initialDestinationId: 'to',
                  initialInventoryId: 'product',
                  repository: PosTransferRepository(provider),
                ),
        );
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        if (mode == 'receive' || mode == 'report') {
          await tester.enterText(
            find.byType(TextFormField).at(mode == 'receive' ? 2 : 0),
            '1',
          );
          await tester.pump();
        }
        if (mode == 'report' || mode == 'decide') {
          final note = find.widgetWithText(
            TextField,
            mode == 'report'
                ? 'Alasan selisih (wajib)'
                : 'Catatan keputusan (wajib)',
          );
          await tester.scrollUntilVisible(
            note,
            350,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 40,
          );
          await tester.enterText(note, 'QA checked discrepancy');
          await tester.pump();
        }
        final save = find.text(submit);
        await tester.scrollUntilVisible(
          save,
          350,
          scrollable: find.byType(Scrollable).first,
          maxScrolls: 40,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 4));
        expect(received, 1);
        final readsBefore = reads;
        await tester.pumpWidget(page());
        await tester.pumpAndSettle();
        expect(
          reads,
          readsBefore,
          reason: 'Recovery does not depend on master-data loading',
        );
        expect(
          find.widgetWithText(FilledButton, 'Periksa transfer sebelumnya'),
          findsOneWidget,
        );
        expect(find.text(submit), findsNothing);
        lose = false;
        await tester.tap(
          find.widgetWithText(FilledButton, 'Periksa transfer sebelumnya'),
        );
        await tester.pumpAndSettle();
        expect(sent.length, 2);
        expect(sent[1], sent[0]);
        expect(received, 1);
        expect(
          PosTransferRepository(
            provider,
          ).pendingIntent(documentId: receiving ? 'doc' : null),
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('unsupported landed cost cannot be selected in transfer editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PosTransferEditorPage(
          existing: const {'_id': 'doc'},
          repository: TransferFake(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final mode = find.text('Beban langsung');
    await tester.scrollUntilVisible(
      mode,
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(mode);
    await tester.pumpAndSettle();
    await tester.tap(mode);
    await tester.pumpAndSettle();
    expect(find.text('Tambahkan ke nilai persediaan'), findsNothing);
  });
  testWidgets('system back cannot abandon transfer while saving', (
    tester,
  ) async {
    final repo = TransferFake()..pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PosTransferEditorPage(
                    existing: const {'_id': 'doc'},
                    repository: repo,
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Simpan mutasi'),
      450,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    await tester.tap(find.text('Simpan mutasi'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(PosTransferEditorPage), findsOneWidget);
    repo.pending!.complete({'_id': 'doc', 'status': 'draft'});
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
  });
}

class _TraceReferences extends TransferFake {
  @override
  Future<Map<String, dynamic>> detail(String id) async {
    final doc = await super.detail(id);
    (doc['items'] as List).single['serial_numbers'] = <String>[];
    return doc;
  }

  @override
  Future<Map<String, dynamic>> query(
    String document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    if (document.contains('MobileTransferUnits')) {
      return {
        'GetOneInventarisUmum': {
          'unit': 'unit',
          'base_unit': 'unit',
          'unit_conversions': [
            {'unit': 'box', 'factor': 12},
          ],
        },
      };
    }
    if (document.contains('MobileTransferBatches')) {
      return {
        'SearchInventoryBatchOptions': {
          'items': [
            {
              '_id': 'new-lot',
              'no_batch': 'BATCH-A',
              'tanggal_kadaluarsa': '2027-11-26',
              'qty': 20,
            },
          ],
        },
      };
    }
    return super.query(document, variables);
  }
}
