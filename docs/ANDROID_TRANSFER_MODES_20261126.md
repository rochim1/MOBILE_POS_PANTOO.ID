# Pemisahan transfer dan mutasi internal Android

Tanggal: 26 November 2026. Sumber kebutuhan: pengguna meminta dua tab dengan pilihan lokasi yang sesuai agar tidak salah memilih.

## Alur yang diterapkan

1. **Antar toko / gudang**: dokumen untuk mengirim stok ke lokasi stok lain. Tujuan tidak menawarkan lokasi stok asal yang sama. Pasangan gudang toko–display berada di tab internal, bukan menjadi jalan pintas transfer lintas outlet.
2. **Mutasi internal**: pindah detail gedung/ruangan/rak dalam satu lokasi stok, atau gudang toko ↔ display yang terhubung ke outlet POS yang sama. Perpindahan dalam lokasi yang sama hanya ditawarkan bila master lokasi mempunyai detail gedung yang dapat dipilih; asal dan tujuan fisik identik ditolak.
3. **Isi Rak Display** otomatis membuka tab internal. Draf lama dikenali berdasarkan pasangan lokasinya, tanpa migrasi atau penulisan ulang data.
4. Gudang tidak aktif, transit/karantina, serta lokasi yang tidak mengizinkan menjadi asal/tujuan tidak ditawarkan sebagai pilihan baru. Data lama yang tidak sesuai tetap terlihat untuk ditinjau, bukan diam-diam dipindahkan ke lokasi lain; penyimpanan diblokir sampai diperbaiki.
5. Pergantian tab ketika sudah ada tujuan/barang meminta konfirmasi. Tujuan dan barang dibersihkan setelah disetujui; asal dipertahankan hanya bila masih sesuai. Catatan dan biaya tetap dipertahankan, sebagaimana dijelaskan dalam konfirmasi.
6. Respons pemuatan barang awal yang datang setelah pengguna mengganti tab/asal diabaikan. Barang dari alur lama tidak boleh masuk kembali setelah daftar dibersihkan.

## Pemetaan profil dan batas keamanan

| Profil inventori | Pilihan lokasi |
|---|---|
| Sederhana | Tidak membuka transfer; bila rute editor dibuka langsung, tidak menawarkan pasangan lokasi dan menjelaskan pengaturan yang perlu ditinjau. |
| Terpusat | Transfer harus melibatkan gudang pusat. Display tidak ditawarkan. Mutasi detail lokasi mengikuti pembatasan gudang pusat yang sama. |
| Lanjutan | Tetap memerlukan gudang pusat untuk transfer umum. Pengecualian hanya pasangan gudang toko–display dalam outlet yang sama. |
| Kustom | Mengikuti sakelar gudang pusat, gudang toko dan display dari konfigurasi. Tidak mengaktifkan fitur baru secara otomatis. |

Tab adalah pengelompokan antarmuka, **bukan** pengaturan proses langsung/transit atau cara melewati persetujuan. Gudang toko dan display pada satu outlet pun tetap dapat memerlukan proses transit sesuai aturan cabangnya. Server tetap menentukan izin, tenant, persetujuan, rute, stok, batch/serial, penerimaan dan jurnal.

Editor menerima kebijakan inventori dari konteks POS yang sudah ada. Tidak ada perubahan pengaturan produksi, relasi outlet, API transfer, atau logika jurnal server pada pekerjaan ini. Nomor referensi pemulihan tetap menggunakan bukti permintaan lama; tab tidak ditampilkan pada layar pemulihan respons belum pasti.

## Bukti pengujian

Perjalanan pengguna: memilih jenis perpindahan, memilih asal/tujuan yang sah, berpindah tab tanpa memakai stok/batch lama, membuka Isi Rak, meninjau draf lama yang tidak sesuai, serta memulihkan permintaan tanpa membuat dokumen pengganti.

| Jaminan | Bukti | Status |
|---|---|---|
| Filter profil, pasangan outlet, izin asal/tujuan, lokasi transit/karantina dan lokasi tanpa detail | `test/pos_transfer_modes_test.dart` — 12 tes | PASS |
| Dua tab, pembatalan/konfirmasi pergantian, Isi Rak otomatis, profil tidak sesuai, layar 320 px Indonesia/Inggris, respons barang terlambat | `test/pos_transfer_modes_ui_test.dart` — 5 tes | PASS |
| Aturan persetujuan, rute langsung/transit, stok kirim/terima dan snapshot rute tetap konsisten | Tiga berkas integrasi server di bawah — 53 tes, basis data sementara lokal | PASS |
| Pemeriksaan statis enam target perubahan/tes | `output/transfer-modes-20261126/analyze-final.log` — `No issues found!` | PASS |

Perintah tes fitur: `flutter test --no-pub test/pos_transfer_modes_test.dart test/pos_transfer_modes_ui_test.dart --reporter expanded` menghasilkan **17 tes PASS**.

Regresi final pada kode `fdc4bee`: **95/95 PASS**, sekitar 34 detik, log `output/transfer-modes-20261126/flutter-verified.log`. Rangkaian ini mencakup pemulihan create/receive/report/decision saat respons hilang, batch/serial/konversi, editor/paritas transfer, konteks navigasi POS, stok awal, opname multi rak dan handoff stok-ke-opname. Pengujian memakai `flutter test --no-pub --coverage --coverage-path output/transfer-modes-20261126/coverage-verified.info --reporter expanded` pada:

```text
test/pos_transfer_modes_test.dart
test/pos_transfer_modes_ui_test.dart
test/pos_transfer_editor_test.dart
test/pos_transfer_operation_test.dart
test/pos_transfer_location_number_test.dart
test/pos_transfer_location_number_ui_test.dart
test/pos_transfer_recovery_test.dart
test/pos_transfer_recovery_ui_test.dart
test/pos_inventory_route_context_test.dart
test/pos_transfer_parity_test.dart
test/pos_opname_parity_test.dart
test/pos_opening_stock_page_test.dart
test/pos_opname_stock_handoff_test.dart
```

Cakupan baris pada `coverage-verified.info`: helper penyaringan baru **39/39 (100%)**, editor transfer **542/672 (80,65%)**. Ini cakupan dua berkas tersebut, bukan klaim cakupan seluruh aplikasi.

Perintah server: `node --test --test-concurrency=1 tests/inventory_transfer_three_flows.integration.test.js tests/inventory_transfer_optional_approval.integration.test.js tests/inventory_transfer_dynamic_rules.integration.test.js` menghasilkan **53 PASS, 0 FAIL**, sekitar 24 detik. Log: `presensi_zera_BE/output/transfer-modes-20261126/server.log`. Ada pesan koneksi putus saat penghentian database sementara; seluruh asersi dan proses tes selesai sukses.

Checkpoint TDD pada branch `main`:

- RED `a651ad7`: tab belum ada dan helper filter belum tersedia; GREEN `f0f5d1a`: 13 tes fitur lulus.
- RED `039d22b`: lokasi tanpa detail masih ditawarkan untuk mutasi ke dirinya sendiri; GREEN `177129d`: 16 tes fitur lulus.
- RED `63e1671`: respons lama memasukkan kembali barang setelah tab diganti; GREEN `fdc4bee`: 17 tes fitur lulus.

Tes regresi awal menghasilkan 62 PASS dan satu kegagalan klik pengujian batch di luar viewport setelah penambahan tab. Tes diperbaiki agar menunggu layout selesai dan menggulir tombol ke area terlihat; asersi batch/konversi/payload tidak diubah. Pengulangan berikutnya menghasilkan 66 PASS sebelum tambahan perlindungan respons barang terlambat. Log historis tetap tersedia di `flutter.log` dan `flutter-final.log`.

## Batas verifikasi

Tes antarmuka di sini adalah tes widget Flutter, bukan uji GUI pada APK yang terpasang di HP/emulator. Tidak membuat APK/AAB, mengubah web admin, atau mengubah data produksi. Hasil pengujian ini tidak berarti semua skenario produksi seluruh aplikasi sudah diuji.
