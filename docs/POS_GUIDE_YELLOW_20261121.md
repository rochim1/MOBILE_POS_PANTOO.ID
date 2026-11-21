# Tombol panduan kuning — 21 November 2026

Permintaan: blok latar tombol “Panduan langkah ini” dengan warna kuning.

- Komponen bersama `PosFirstSaleGuide` memakai latar `#FFE082`, teks/ikon gelap `#3E3300`, radius 10, dan tinggi sentuh minimal 44.
- Berlaku pada semua langkah yang memakai komponen tersebut. Mekanisme popup, urutan panduan, dan transaksi tidak diubah.
- RED: `flutter test test/pos_first_sale_guide_test.dart --no-pub --concurrency=1 --reporter expanded` gagal pada assertion warna latar (aktual null). Checkpoint `b78c31b`.
- GREEN: tes panduan pertama dan panduan shift (12 tes) lulus setelah style ditambahkan. Tes memeriksa warna, tinggi tombol, buka ulang, next/back, target yang belum siap, dan layar kecil dengan teks besar.
- Perintah: `flutter test test/pos_first_sale_guide_test.dart test/pos_shift_guide_test.dart --no-pub --concurrency=1 --coverage --coverage-path=../output/pos-google-access-20261120/guide-yellow-coverage.info --reporter expanded`.
- Cakupan komponen: 86/86 baris (100%). APK dan pengujian GUI perangkat belum dilakukan untuk perubahan warna ini.
