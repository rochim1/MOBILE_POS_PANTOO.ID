import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_translation_lookup.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  for (final entry in {
    'Toko dan lokasi stok awal dibuat otomatis. Setelah ini cukup tambahkan produk atau layanan. Pengaturan lain bisa menyusul.': 'Your first store and stock location are created automatically. Next, add products or services. Other settings can wait.',
    'Logo usaha': 'Business logo',
    'Pilih logo usaha': 'Choose business logo',
    'Opsional · JPG, PNG, WebP · maksimal 5 MB': 'Optional · JPG, PNG, WebP · up to 5 MB',
    'Lengkapi langkah wajib yang belum selesai.': 'Complete the remaining required steps.',
  }.entries) {
    test('new setup English copy: ${entry.key}', () {
      expect(translatePosText(entry.key, english), entry.value);
    });
  }
}
