# Penyiapan transit langsung dari pengaturan inventori

Tanggal: 26 November 2026. Lingkup: Flutter POS mobile, pengaturan inventori Vue web, dan backend bersama.

## Masalah dan keputusan

Pesan sebelumnya menyuruh pengguna keluar dari pengaturan untuk membuat warehouse berjenis transit. Hal ini mudah membuat pengguna tersesat: transit adalah lokasi penampung internal selama pengiriman, bukan toko atau rak yang harus diisi melalui form panjang.

Pengaturan kini menyediakan penyiapan langsung, dengan persetujuan pengguna. Tidak ada lokasi dibuat hanya karena halaman dibuka atau pilihan alur diganti.

## Alur pengguna

1. Buka pengaturan inventori dan pilih **Pakai perpindahan stok**.
2. Jika belum ada lokasi perjalanan/transit, centang **Siapkan otomatis saat disimpan**.
3. Simpan pengaturan. Mobile menampilkan konfirmasi yang juga menjelaskan pembuatan lokasi internal.
4. Server menyiapkan **Barang dalam perjalanan** sekaligus menyimpan default transit. Daftar lokasi dimuat ulang untuk memakai ID yang benar-benar tersimpan.

Jika satu lokasi aktif sudah tersedia, tombol **Gunakan lokasi perjalanan yang tersedia** memilihnya tanpa membuat lokasi baru. Jika ada beberapa, pengguna harus memilih; sistem tidak menebak. Lokasi nonaktif atau milik instansi lain tidak diaktifkan/dipakai diam-diam.

Akun tanpa izin membuat warehouse tidak mendapat opsi pembuatan; bantuan meminta admin menyiapkan lokasi. Akun yang memiliki izin mengubah pengaturan tetap dapat memilih lokasi yang sudah tersedia. Profil **Stok langsung dijual** tidak membuat transit. Tidak ada pemaksaan profil Terpusat atau penggantian rute menjadi Direct untuk melewati validasi.

## Pengaman implementasi

- Flag opsional `auto_prepare_transfer_transit` memakai mutasi `UpdateInventorySettings` yang sudah ada; bukan endpoint pembuatan baru yang bebas diakses.
- Izin pengaturan tetap diperiksa server. Pembuatan baru memerlukan `warehouse.create` atau `cabang.create`; kemampuan membuat lokasi bukan pengganti izin mengubah pengaturan.
- Pembuatan lokasi dan penyimpanan pengaturan berada dalam satu transaksi dengan `expected_revision`. Gagal validasi/tulis berarti seluruhnya dibatalkan, termasuk lokasi yang sempat dibuat.
- Dua editor dari revisi sama hanya dapat menyelesaikan satu perubahan. Respons hilang tidak memicu retry tulis otomatis; pengguna perlu memuat ulang hasil server. Tidak membuat lokasi kedua.
- Transaksi database wajib untuk penyiapan otomatis; tidak diam-diam memakai operasi parsial pada database standalone.
- Lokasi internal bukan lokasi penjualan, penerimaan barang biasa, asal transfer manual, atau tujuan transfer manual. Tidak ditautkan ke toko lain.
- Tidak memindahkan stok, mengganti snapshot transfer yang sudah dikirim, mereset penerima notifikasi, atau menimpa pengaturan POS tersembunyi.
- Field transit otomatis hanya melewati validasi transit yang memang akan disiapkan. Ketergantungan fitur, tracking stok, toleransi, dan lokasi penerimaan tetap divalidasi.
- Bila simpan sudah diakui tetapi pembacaan lokasi terbaru gagal, mobile meminta muat ulang; web mengunci perubahan operasional melalui status lookup. Tidak menganggap data lokasi kosong sebagai konfigurasi siap.
- Bantuan tersedia dalam Indonesia/Inggris. Nama lokasi yang tersimpan adalah data bisnis, bukan nilai profil/ID yang diterjemahkan.

## Pengujian

| Paket | Hasil | Bukti yang diperiksa |
|---|---|---|
| Mobile, 8 file fitur dan pemulihan transfer | 70 PASS, 0 FAIL | Widget, repository, validasi, navigasi, refresh runtime, pemulihan respons hilang |
| Web, 8 file regresi | 96 PASS, 0 FAIL, 0 skipped | Opt-in, pemilihan lokasi, izin, konflik/response loss, routing transfer, template ID/EN dan katalog |
| Backend, 4 file regresi | 58 PASS, 0 FAIL, 0 skipped | Transaksi Mongo replica set sementara, rollback, concurrency, multi-tenant, izin, kontrak GraphQL mobile, transisi transfer |
| Analisis Dart pada 8 file perubahan | PASS, No issues found | Termasuk peringatan info sebagai kegagalan |

Perintah mobile:

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path output/inventory-flow-20261126/transit-preparation-lcov.info test/pos_inventory_flow_settings_test.dart test/pos_inventory_flow_page_test.dart test/pos_inventory_flow_runtime_test.dart test/pos_inventory_flow_navigation_test.dart test/pos_inventory_transit_preparation_test.dart test/pos_inventory_transit_repository_test.dart test/pos_transfer_recovery_test.dart test/pos_transfer_recovery_ui_test.dart
```

Perintah web:

```powershell
node --test --test-concurrency=1 --experimental-test-coverage --test-coverage-include=src/pages/inventory/inventory-stock-flow.mjs tests/inventory-stock-flow.test.mjs tests/inventory-settings-safe-save.test.mjs tests/transfer-dynamic-rules.test.mjs tests/transfer-mobile-parity.test.mjs tests/transfer-form-guidance.test.mjs tests/transfer-workflow.test.mjs tests/ui-i18n-catalog.test.mjs tests/ui-i18n-runtime.test.mjs
```

Perintah backend:

```powershell
node --test --test-concurrency=1 --experimental-test-coverage --test-coverage-include=graphql/inventaris_umum/inventory_transit_setup.service.js tests/inventory_settings_safe_save.integration.test.js tests/inventory_mobile_graphql.contract.test.js tests/inventory_transfer_dynamic_rules.integration.test.js tests/inventory_operation_guard.test.js
```

Helper server baru: 100% baris, 85,71% cabang, 100% fungsi. Helper pemetaan alur web: 100% baris/cabang/fungsi. Angka ini bukan cakupan keseluruhan aplikasi.

Cakupan baris mobile pada paket di atas: model 98/98 (100%), repository 105/106 (99,1%), halaman 282/313 (90,1%), widget bantuan transit 31/31 (100%), helper bahasa 4/5 (80%). Laporan cakupan disimpan pada path `output` di perintah mobile, tidak menimpa `coverage/lcov.info` pengguna.

Pengujian backend mengeluarkan peringatan `punycode` dan `ECONNRESET` ketika replica set sementara dihentikan; semua 58 kasus selesai lulus dan proses keluar 0. Pengujian pemulihan mobile sengaja mensimulasikan respons hilang sehingga log kegagalan link bukan dengan sendirinya kegagalan tes.

## Checkpoint RED/GREEN

- Backend RED `85ef6dee`, GREEN `cddec0e7`; kontrak mutasi mobile dan pengaman tanpa transaksi dilengkapi pada `0dd217ef`.
- Web RED `b1eb316b`, GREEN `638750da`; RED bahasa `3fb9bb65`, GREEN bahasa/katalog `3905e2f0`.
- Mobile RED `dd083cd`, GREEN `d4f01d1`.
- Selama penguatan tes widget, penunjuk scroll pada field transit diperbaiki agar tes benar-benar menunjuk field yang ada; peringatan klik di luar layar tidak disembunyikan.

## Batas dan cara rilis

Tidak menjalankan build APK/AAB, deployment, atau perubahan produksi. Uji mobile berupa widget/navigasi otomatis; web berupa kompilasi/render template dan metode halaman. GUI Android/browser nyata belum diulang pada pekerjaan ini.

Backend dengan flag baru perlu dirilis sebelum web/mobile terbaru; setelah itu rilis web dan build mobile. APK yang sudah terpasang tidak berubah hanya karena kode sumber diperbaiki. Tidak diperlukan migrasi stok atau penghapusan konfigurasi lama.

## Evaluasi hasil

Ringkasan: kebutuhan membuat lokasi transit sekarang dapat diselesaikan tanpa keluar dari pengaturan, dengan hasil otomatis yang terverifikasi dan batas rilis yang eksplisit.

| Aspek | Skor | Bukti dan perbaikan berikutnya |
|---|---|---|
| Akurasi | 5/5 | 224 pemeriksaan dalam tiga paket lulus; kontrak mobile dieksekusi terhadap skema/resolver server sebenarnya, rollback dan concurrency diperiksa. |
| Kelengkapan | 4/5 | Izin, lokasi lama/ganda, response loss, bahasa dan layar sempit tercakup; GUI perangkat/browser nyata belum dijalankan. Ulang visual setelah QA dirilis. |
| Kejelasan | 5/5 | Ada pilihan penyiapan di tempat, tombol memakai lokasi lama, dan instruksi memilih jika lebih dari satu; tidak lagi hanya menyuruh pindah menu. |
| Keterpakaian | 4/5 | Kode dan tes tersedia, tetapi aplikasi terpasang memerlukan backend dan build mobile terbaru. Ikuti urutan rilis di atas. |
| Keringkasan | 4/5 | Reuse mutasi pengaturan/revisi lama; report memuat perintah panjang agar hasil dapat diulang. Pembaca operasional cukup mengikuti bagian Alur pengguna. |

Rata-rata 4,4/5. Tidak ada isu kritis pada paket yang dijalankan. Prioritas berikutnya: verifikasi GUI QA terbaru, lalu rilis backend sebelum klien. Penilaian ini tidak menyatakan aplikasi terpasang atau seluruh operasional produksi sudah diuji ulang; pengguna semestinya dapat menilai perubahan dari alur dan batas tersebut.
