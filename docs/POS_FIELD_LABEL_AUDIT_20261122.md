# Audit label field Pantoo POS mobile

Tanggal: 22 November 2026 (Asia/Jakarta).

## Permintaan dan cakupan

Melengkapi label pada seluruh field POS mobile, bukan hanya placeholder yang hilang ketika pengguna mengetik. Audit mencakup seluruh kode Dart aplikasi di `lib`, tidak termasuk berkas terjemahan yang dihasilkan otomatis. Vue web admin, backend, database, dan APK tidak diubah/dibangun dalam pekerjaan ini.

## Temuan dan perbaikan

- Tema global sebelumnya menggunakan `FloatingLabelBehavior.never`, sehingga label yang sudah tersedia ikut tersembunyi. Diubah menjadi `always`: label tetap terlihat saat field kosong maupun terisi.
- Melengkapi 25 deklarasi dekorasi field yang belum memiliki label, antara lain pencarian kasir/produk/pelanggan, invoice retur, barcode manual, filter promo/status, catatan transaksi, uang diterima, tujuan pengiriman struk, meja dan riwayat shift.
- Melengkapi tiga selector native dengan `InputDecorator` berlabel: status penerimaan, toko shift aktif, dan satuan barang di keranjang. Binding dan perilaku pemilihan tidak diubah.
- Menyesuaikan tinggi kontrol ringkas agar label tidak berdesakan dengan isian pada HP. Menguji ulang filter, kasir, keranjang dan pembayaran pada layar kecil.
- Mempertahankan label eksternal yang memang sudah terlihat: sembilan field pelanggan menggunakan helper berlabel dan 13 konteks lain menggunakan judul di atas field atau header tabel. Tidak menambahkan label ganda di sel tabel pembelian/pembuangan barang.
- Menambah pemeriksaan berbasis sintaks Dart dan tes regresi agar dekorasi/selector tanpa label terdeteksi kembali.

## Hasil pemindaian

| Pemeriksaan | Hasil |
| --- | --- |
| Berkas Dart yang dipindai | 311 |
| Deklarasi input/selector/decorator | 389 |
| Deklarasi `InputDecoration` | 358 |
| Memiliki label internal | 336 |
| Menggunakan helper dengan label eksternal | 9 |
| Konteks label eksternal/header tabel yang ditinjau | 13 |
| Temuan tanpa label yang belum ditangani | 0 |

Jumlah deklarasi tidak sama dengan jumlah field unik saat aplikasi berjalan; wrapper `InputDecorator` juga dihitung. Sebelum perbaikan terdapat 47 dekorasi tanpa label internal: 22 sudah memiliki label eksternal yang sah, sedangkan 25 dilengkapi dalam pekerjaan ini. Tiga wrapper selector baru menambah tiga dekorasi berlabel.

Pemindai tersedia di `tool/audit_field_labels.dart.txt`, dengan konteks yang ditinjau di `tool/field_label_contexts.json`. Ekstensi `.txt` disengaja: pemindai dijalankan menggunakan paket analyzer bawaan Flutter SDK tanpa menambahkan dependensi aplikasi.

## Pengujian

| Tahap | Hasil | Bukti |
| --- | --- | --- |
| RED awal: label global/field pencarian/pemindaian | Gagal sesuai temuan | `output/field-labels-red.log`, commit `2793ff0` |
| GREEN label global dan input | 3 PASS | `output/field-labels-green.log`, commit `a9c8bcf` |
| RED selector native | Gagal pada tiga selector tanpa label | `output/field-labels-select-red.log`, commit `1660f85` |
| GREEN selector dan layout HP | 10 PASS | `output/field-labels-select-green.log`, commit `0a2875f` |
| Regresi terfokus lintas form | 62 PASS | `output/field-labels-regression.log` |
| Uji ulang label dan kasir setelah perapian terakhir | 5 PASS | `output/field-labels-final.log` |
| Analisis kode seluruh proyek | PASS: No issues found (229,1 detik) | `output/field-labels-analyze.log` |

Regresi mencakup label setelah mengetik; label setup toko/gudang; filter lebar 320/360/600; katalog kasir bahasa Indonesia/Inggris; validasi pelanggan; dialog jumlah/harga; harga layanan fleksibel; serta pembayaran, split, invoice tertunda dan keyboard. Pembayaran juga diuji pada layar kecil/landscape dengan skala teks diperbesar.

Perintah regresi yang dijalankan:

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/field-labels-lcov.info test/pos_field_labels_test.dart test/setup_operational_labels_test.dart test/pos_active_order_mobile_filters_test.dart test/pos_mobile_product_panel_test.dart test/pos_english_product_panel_test.dart test/pos_customer_form_validation_test.dart test/pos_cart_dialog_lifecycle_test.dart test/pos_flexible_service_test.dart test/pos_payment_mobile_layout_test.dart test/pos_payment_custom_cash_contract_test.dart test/pos_dashboard_language_test.dart test/pos_setup_language_test.dart test/pos_translation_rescan_test.dart --reporter expanded
flutter analyze --no-pub
```

## Batas bukti dan tindak lanjut

- Ini merupakan audit kode, tes widget dan analisis statis; bukan uji GUI seluruh layar di perangkat Android. Tidak ada klaim seluruh aksesibilitas pembaca layar telah teruji.
- Cakupan baris pada modul contoh: tema 49/56 (87,5%), panel keranjang 130/149 (87,2%), filter pesanan HP 32/32 (100%). Berkas panel produk memiliki banyak jalur lain yang tidak dieksekusi tes ini (217/745; 29,1%). Tidak mengklaim cakupan seluruh aplikasi 80%.
- APK terpasang sebelumnya belum memuat perubahan ini; perlu menjalankan ulang/build berikutnya untuk mencobanya di perangkat.
- Perubahan data, aturan transaksi, verifikasi PIN dan permission tidak termasuk pekerjaan ini. Perubahan pengguna yang sudah ada di worktree dipertahankan.

## Evaluasi akhir

| Aspek | Nilai / 5 | Alasan |
| --- | --- | --- |
| Akurasi | 5 | Hitungan berasal dari pemindaian sintaks dan log tes aktual. |
| Kelengkapan | 4 | Seluruh sumber field dipindai; belum semua layar dijalankan manual di Android. |
| Kejelasan | 5 | Label tetap terlihat; label eksternal/header tabel tidak diduplikasi. |
| Dapat ditindaklanjuti | 4 | Regresi tersedia; perubahan belum dipaketkan menjadi APK baru. |
| Keringkasan | 4 | Bukti dan batas pengujian dipisahkan dari ringkasan hasil. |

Rata-rata: 4,4/5. Pemeriksaan visual seluruh form di APK berikutnya tetap berguna, khususnya label panjang dan terjemahan pada perangkat pengguna.
