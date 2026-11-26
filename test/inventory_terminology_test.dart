import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations_id.dart';
import 'package:mobile_pos_pantoo/l10n/pos_inventory_flow_copy.dart';
import 'package:mobile_pos_pantoo/l10n/inventory_terminology.dart';
import 'package:mobile_pos_pantoo/l10n/pos_translation_lookup.dart';

void main() {
  test(
    'Indonesian transfer labels and legacy aliases use goods-in-transit wording',
    () {
      final locale = AppLocalizationsId();
      expect(locale.pos273a69e49c76, 'Lokasi barang dalam perjalanan');
      expect(
        locale.pos1a266eba7d88('Gudang A'),
        'Barang dalam perjalanan: Gudang A',
      );
      expect(
        translatePosText('Lokasi Transit', locale),
        'Lokasi barang dalam perjalanan',
      );
      expect(
        inventoryFlowCopy['transit']!.$1,
        'Lokasi barang dalam perjalanan',
      );
      expect(
        inventoryFlowCopy['use_in_transit']!.$1,
        'Barang dalam perjalanan',
      );
      for (final copy in inventoryFlowCopy.values) {
        expect(
          RegExp(r'\btransit\b', caseSensitive: false).hasMatch(copy.$1),
          false,
        );
      }
    },
  );
  test(
    'old routing descriptions are displayed with new terms without changing data',
    () {
      const reason =
          'Bawaan sistem untuk antar cabang: wajib transit dan penerimaan tujuan.';
      expect(
        inventoryTransferReasonText(reason),
        contains('barang dalam perjalanan'),
      );
      expect(reason, contains('wajib transit'));
      expect(
        inventoryTransferReasonText('Langsung selesai saat dikirim'),
        'Langsung selesai saat dikirim',
      );
    },
  );
}
