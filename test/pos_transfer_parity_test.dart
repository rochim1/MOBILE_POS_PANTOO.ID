import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transfer.dart';

void main() {
  test(
    'draft rejects mismatched conversion total and duplicate serial across lines',
    () {
      final draft = <String, dynamic>{
        'dari': {'cabang_id': 'a'},
        'ke': {'cabang_id': 'b'},
        'items': [
          {
            'inventaris_id': 'p',
            'qty': 1.0,
            'unit_breakdown': [
              {'unit': 'box', 'factor': 12.0, 'input_qty': 1.0},
            ],
          },
        ],
      };
      expect(validateTransferDraft(draft), isNotNull);
      draft['items'] = [
        for (var i = 0; i < 2; i++)
          {
            'inventaris_id': 'p',
            'qty': 1.0,
            'serial_numbers': ['S1'],
          },
      ];
      expect(validateTransferDraft(draft), isNotNull);
    },
  );
  test(
    'receipt dates match Jakarta business dates and reject stale/future/invalid dates',
    () {
      expect(transferToday(DateTime.utc(2026, 11, 4, 18)), '2026-11-05');
      final doc = {
        'dispatch_posting_date': '2026-11-04',
        'receipts': [
          {'posting_date': '2026-11-05'},
        ],
      };
      expect(
        transferReceiptDatesError(
          doc,
          '2026-11-04',
          '2026-11-05',
          today: '2026-11-05',
        ),
        isNull,
      );
      expect(
        transferReceiptDatesError(
          doc,
          '2026-11-03',
          '2026-11-05',
          today: '2026-11-05',
        ),
        isNotNull,
      );
      expect(
        transferReceiptDatesError(
          doc,
          '2026-11-05',
          '2026-11-04',
          today: '2026-11-05',
        ),
        isNotNull,
      );
      expect(
        transferReceiptDatesError(
          doc,
          '2026-02-30',
          '2026-11-05',
          today: '2026-11-05',
        ),
        isNotNull,
      );
      expect(
        transferReceiptDatesError(
          doc,
          '2026-11-06',
          '2026-11-06',
          today: '2026-11-05',
        ),
        isNotNull,
      );
    },
  );
  final document = <String, dynamic>{
    '_id': 'doc',
    'status': 'draft',
    'tanggal_transfer': '2026-11-05',
    'requires_approval': true,
    'dari': {
      '__typename': 'InventoryTransferLocation',
      'cabang_id': 'origin',
      'gedung_kode': 'G',
      'ruangan_kode': 'R',
      'rak_nama': 'A',
    },
    'ke': {
      'cabang_id': 'destination',
      'gedung_kode': 'D',
      'ruangan_kode': 'R2',
      'rak_nama': 'B',
    },
    'items': [
      {
        '__typename': 'InventoryTransferItem',
        '_id': 'line',
        'inventaris_id': 'product',
        'nama_inventaris': 'QA',
        'qty': 3.0,
        'unit': 'unit',
        'batch_id': 'lot',
        'no_batch': 'SAME',
        'tanggal_kadaluarsa': '2027-11-05',
        'serial_numbers': ['S1', 'S2', 'S3'],
        'catatan_item': 'Fragile',
        'unit_breakdown': [
          {
            '__typename': 'UnitBreakdown',
            'unit': 'box',
            'factor': 3.0,
            'input_qty': 1.0,
          },
        ],
      },
    ],
    'biaya_transfer': [
      {
        '__typename': 'TransferCost',
        '_id': 'fee',
        'jenis_biaya': 'ongkir',
        'nominal': 1000.0,
        'akun_beban': '6100',
      },
    ],
    'biaya_mode': 'expense',
    'biaya_alokasi': 'per_qty',
    'payment_bank_account_id': 'bank',
    'payment_branch_id': 'pay-branch',
    'branch_id': 'branch',
    'project_id': 'project',
    'catatan': 'QA',
  };
  test(
    'web draft round-trip preserves scope, traceability, conversions and finance, never GraphQL metadata',
    () {
      final payload = transferInput(document);
      expect(payload['dari']['rak_nama'], 'A');
      expect(payload['ke']['rak_nama'], 'B');
      final item = (payload['items'] as List).single;
      expect(item['batch_id'], 'lot');
      expect(item['serial_numbers'], ['S1', 'S2', 'S3']);
      expect(item['catatan_item'], 'Fragile');
      expect(item['unit_breakdown'].single['factor'], 3);
      expect(payload['payment_bank_account_id'], 'bank');
      expect(payload['payment_branch_id'], 'pay-branch');
      expect(payload['branch_id'], 'branch');
      expect(payload['project_id'], 'project');
      expect(payload.toString(), isNot(contains('__typename')));
      expect(item, isNot(contains('_id')));
    },
  );
  test(
    'remaining receipt excludes received, resolved and pending reports by exact batch and serial identity',
    () {
      final rows = transferRemainingRows({
        'items': [
          {
            '_id': 'line',
            'qty': 5.0,
            'received_qty': 1.0,
            'resolved_qty': 1.0,
            'serial_numbers': ['A', 'B', 'C', 'D', 'E'],
            'received_serial_numbers': ['A'],
            'resolved_serial_numbers': ['B'],
            'batch_allocations': [
              {'batch_id': 'lot', 'no_batch': 'SAME', 'qty': 5.0},
            ],
            'received_batch_allocations': [
              {'batch_id': 'lot', 'no_batch': 'SAME', 'qty': 1.0},
            ],
            'resolved_batch_allocations': [
              {'batch_id': 'lot', 'no_batch': 'SAME', 'qty': 1.0},
            ],
          },
        ],
        'discrepancies': [
          {
            'status': 'pending',
            'items': [
              {
                'item_id': 'line',
                'qty': 1.0,
                'serial_numbers': ['C'],
                'batch_allocations': [
                  {'batch_id': 'lot', 'no_batch': 'SAME', 'qty': 1.0},
                ],
              },
            ],
          },
        ],
      });
      expect(rows.single['qty'], 2);
      expect(rows.single['serials'], ['D', 'E']);
      expect((rows.single['batches'] as List).single['qty'], 2);
    },
  );
  test(
    'receipt cannot silently guess serials or accept invalid quantities and foreign lots',
    () {
      final item = {
        'item_id': 'line',
        'qty': 2.0,
        'serials': ['D', 'E'],
        'batches': <Map<String, dynamic>>[],
      };
      expect(validateTransferSelection(item, 1, [], []), isNotNull);
      expect(validateTransferSelection(item, 1, ['D'], []), isNull);
      expect(validateTransferSelection(item, double.nan, [], []), isNotNull);
      expect(validateTransferSelection(item, 3, ['D', 'E'], []), isNotNull);
      expect(
        validateTransferSelection(
          {
            'qty': 2.0,
            'serials': [],
            'batches': [
              {'batch_id': 'lot', 'no_batch': 'SAME', 'qty': 2.0},
            ],
          },
          1,
          [],
          [
            {'batch_id': 'foreign', 'no_batch': 'SAME', 'qty': 1.0},
          ],
        ),
        isNotNull,
      );
    },
  );
  test(
    'location input whitelists all seven fields and zero receipt selection remains safe',
    () {
      expect(
        transferLocation({
          '__typename': 'Location',
          'cabang_id': 'x',
          'gedung_nama': 'Gedung',
          'ruangan_nama': 'Ruang',
          'rak_nama': 'Rak',
        })['rak_nama'],
        'Rak',
      );
      expect(
        validateTransferSelection(
          {'qty': 2.0, 'serials': [], 'batches': []},
          0,
          [],
          [],
        ),
        isNull,
      );
    },
  );
}
