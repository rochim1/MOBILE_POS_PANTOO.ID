import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_inventory_detail_format.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  test(
    'GraphQL milliseconds, ISO and DateTime all show readable inventory date',
    () {
      expect(inventoryDocumentDate('1793798606614'), '04 Nov 2026');
      expect(inventoryDocumentDate(1793798606614), '04 Nov 2026');
      expect(inventoryDocumentDate('2026-11-04'), '04 Nov 2026');
      expect(inventoryDocumentDate(DateTime(2026, 11, 4)), '04 Nov 2026');
      expect(inventoryDocumentDate('20261104'), '04 Nov 2026');
    },
  );
  test('missing, invalid and out-of-range dates never crash detail UI', () {
    expect(inventoryDocumentDate(null), '-');
    expect(inventoryDocumentDate(''), '-');
    expect(inventoryDocumentDate('not a date'), 'not a date');
    expect(inventoryDocumentDate('9000000000000000'), '9000000000000000');
  });
  test('two racks of one product are not called two product types', () {
    expect(
      opnameRowsSummary([
        {'inventaris_id': 'p', 'stock_balance_id': 'a'},
        {'inventaris_id': 'p', 'stock_balance_id': 'b'},
      ]),
      '2 saldo lokasi • 1 jenis barang',
    );
    expect(
      opnameRowsSummary([
        {'inventaris_id': 'p'},
        {'inventaris_id': 'q'},
      ]),
      '2 saldo lokasi • 2 jenis barang',
    );
  });
}
