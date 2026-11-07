import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_operation_page.dart';
import 'pos_transfer_editor_test.dart' show TransferFake;

class ReceiptFake extends TransferFake {
  String status = 'in_transit';
  @override
  Future<Map<String, dynamic>> detail(String id) async => {
    '_id': id,
    'status': status,
    'no_transfer': 'QA-RECEIPT',
    'updatedAt': 'revision-1',
    'tanggal_transfer': '2026-01-01',
    'ke': {'cabang_id': 'to', 'rak_nama': 'B'},
    'items': [
      {
        '_id': 'line',
        'nama_inventaris': 'Serial QA',
        'qty': 5.0,
        'received_qty': 1.0,
        'resolved_qty': 1.0,
        'serial_numbers': ['A', 'B', 'C', 'D', 'E'],
        'received_serial_numbers': ['A'],
        'resolved_serial_numbers': ['B'],
        'batch_allocations': [
          {'batch_id': 'lot', 'no_batch': 'LOT', 'qty': 5.0},
        ],
        'received_batch_allocations': [
          {'batch_id': 'lot', 'no_batch': 'LOT', 'qty': 1.0},
        ],
        'resolved_batch_allocations': [
          {'batch_id': 'lot', 'no_batch': 'LOT', 'qty': 1.0},
        ],
      },
    ],
    'discrepancies': [
      {
        '_id': 'pending',
        'status': 'pending',
        'kind': 'lost',
        'reason': 'QA hilang',
        'items': [
          {
            'item_id': 'line',
            'qty': 1.0,
            'serial_numbers': ['C'],
            'batch_allocations': [
              {'batch_id': 'lot', 'no_batch': 'LOT', 'qty': 1.0},
            ],
          },
        ],
      },
    ],
  };
}

void main() {
  testWidgets(
    'transfer-only reviewer may reject but cannot approve loss without scrap permission',
    (tester) async {
      final repo = ReceiptFake();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferOperationPage(
            transfer: const {'_id': 'doc'},
            mode: 'decide',
            discrepancyId: 'pending',
            canApproveLoss: false,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        false,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
        isNull,
      );
      expect(find.text('Kode akun beban kehilangan'), findsNothing);
    },
  );
  testWidgets(
    'receipt fills only free serials and batches, retains actual rack, blocks double submit',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ReceiptFake()..pending = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferOperationPage(
            transfer: const {'_id': 'doc'},
            mode: 'receive',
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Seri C'), findsNothing);
      await tester.tap(find.text('Isi seluruh sisa baris ini'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Terima jumlah ini'),
        500,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 20,
      );
      await tester.tap(find.text('Terima jumlah ini'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Memproses...'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );
      await tester.tapAt(tester.getCenter(find.text('Memproses...')));
      expect(repo.requests.length, 1);
      repo.pending!.complete({'_id': 'doc', 'status': 'in_transit'});
      await tester.pumpAndSettle();
      expect(repo.requests.length, 1);
      final line = (repo.requests.single['items'] as List).single;
      expect(line['qty'], 2);
      expect(line['serial_numbers'], ['D', 'E']);
      expect(line['batch_allocations'].single['qty'], 2);
      expect(line['location']['rak_nama'], 'B');
      expect(
        repo.requests.single['request_id'],
        startsWith('mobile-transfer-receive-'),
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 3));
    },
  );
  testWidgets('completed transfer cannot open receiving form from stale list', (
    tester,
  ) async {
    final repo = ReceiptFake()..status = 'posted';
    await tester.pumpWidget(
      MaterialApp(
        home: PosTransferOperationPage(
          transfer: const {'_id': 'doc'},
          mode: 'receive',
          repository: repo,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('tidak lagi dalam perjalanan'), findsOneWidget);
    expect(find.text('Terima jumlah ini'), findsNothing);
    expect(repo.requests, isEmpty);
  });
}
