# Ringkasan stok inventori lebih ringkas

Tanggal: 23 November 2026. Skenario diturunkan dari screenshot pengguna: kartu statistik terlalu tinggi dan mendorong daftar barang ke bawah.

## Perubahan

- Minimum tinggi kartu stok turun dari 180 menjadi 92 dp, padding 18 menjadi 12 dp, jarak judul–nilai 16 menjadi 8 dp, dan teks nilai 26 menjadi 22 sp. Tinggi tetap dapat bertambah untuk teks besar, bukan dipaksa sehingga terpotong.
- Area konten minimal 800 dp menampilkan empat kartu dalam satu baris; area minimal 280 dp menampilkan dua kolom. Lebar mengikuti ruang halaman setelah sidebar/padding, bukan hanya lebar perangkat.
- Mode ringkas bersifat opt-in (`compact: true`) khusus ringkasan stok. Kartu dashboard/laporan dan skeleton bersama mempertahankan default sebelumnya.
- Nilai lengkap, semantik pembacaan nilai, keadaan loading dan izin melihat stok tetap dipertahankan. Tidak mengubah query, perhitungan stok/nilai atau data server.

## Pembuktian

| Skenario | Bukti |
| --- | --- |
| Halaman stok pada 320, 360, 700 dan 958 dp | Kartu ringkas; dua kolom di HP dan empat kolom pada area lebar. |
| Teks diperbesar 1,5 pada HP/tablet | Tidak overflow; nilai stok lengkap tetap tersedia. |
| Loading pada HP/tablet | Tetap menggunakan ukuran ringkas dan tidak menampilkan nilai nol/palsu. |
| Tanpa izin stok | Statistik tidak ditampilkan. |
| Default kartu lain, pertumbuhan/penurunan, angka panjang dan skeleton | Regresi komponen bersama tetap lulus. |
| Paginasi/filter, metadata stok dan handoff koreksi per batch/multi-rak | Regresi alur stok tetap lulus. |

RED: delapan tes layout gagal karena tinggi aktual 180 dp; satu tes izin lulus. Log `output/stock-summary-red.log`, checkpoint `e19f04d`.

GREEN: 17 tes layout/komponen lulus. Log `output/stock-summary-green-verified.log`, checkpoint `96e3528`.

Pada pengujian ditemukan satu assertion lama yang mencari kartu statistik di skeleton kasir, padahal kasir sekarang memakai skeleton katalog tanpa kartu statistik. Ekspektasi diperbaiki untuk katalog saat ini, dan pengujian kartu skeleton ringkasan ditambahkan terpisah. Kode skeleton aplikasi tidak diubah.

Render sebelum/sesudah diperiksa: `output/stock-summary-before.png` dan `output/stock-summary-after.png`. Render menggunakan fixture pengujian, bukan transaksi/perubahan pada database.

## Verifikasi akhir

**25 PASS**, 22 detik (`output/stock-summary-regression.log`). Cakupan komponen bersama `pos_metric_card.dart`: **74/75 baris (98,7%)**, bukan cakupan seluruh aplikasi. Analisis empat berkas yang diubah: **No issues found**, 25 detik (`output/stock-summary-analyze.log`).

```powershell
flutter test --no-pub --concurrency=1 --timeout=2m --dart-define=STOCK_SUMMARY_PREVIEW=after --coverage --coverage-path=output/stock-summary-lcov.info test/pos_stock_summary_layout_test.dart test/pos_metric_card_test.dart test/pos_stock_pagination_test.dart test/pos_stock_model_test.dart test/pos_opname_stock_handoff_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/widgets/pos_metric_card.dart lib/presentation/pages/pos/pos_stock_page.dart test/pos_stock_summary_layout_test.dart test/pos_metric_card_test.dart
```

Batas bukti: tes widget/unit dan pemeriksaan render, bukan GUI pada APK Android terpasang. APK tidak dibangun ulang. Web Vue, backend, database dan perubahan pengguna yang sudah ada tidak diubah.

## Evaluasi hasil

Akurasi 5/5: ukuran dan render dibuktikan oleh tes. Kelengkapan 4/5: HP/tablet, loading dan izin diuji, belum GUI perangkat. Kejelasan 5/5: mode ringkas dibatasi pada stok agar laporan lain tidak berubah. Dapat digunakan 4/5: kode/tes tersedia, APK lama belum diperbarui. Keringkasan 4/5: rincian bukti disimpan di laporan. Rata-rata 4,4/5, tanpa isu kritis; konfirmasi visual pada APK berikutnya tetap menjadi tindak lanjut yang berguna.
