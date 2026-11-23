import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_translation_lookup.dart';

void main() {
  test('operational setup guidance has offline English copy', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final id = lookupAppLocalizations(const Locale('id'));
    const copy = {
      'Panduan mulai berjualan': 'Start selling guide',
      'Opsional. Tambahkan produk atau layanan; pengaturan lainnya bisa menyusul.':
          'Optional. Add products or services; other settings can wait.',
      'Lihat panduan': 'View guide',
      'Sembunyikan panduan': 'Hide guide',
      'Stok Awal': 'Opening stock',
    };
    for (final entry in copy.entries) {
      expect(translatePosText(entry.key, en), entry.value);
      expect(translatePosText(entry.key, id), entry.key);
    }
    expect(translatePosText('QA stock', en), 'QA stock');
  });
}
