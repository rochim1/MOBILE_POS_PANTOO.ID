# Audit ulang stok awal POS mobile

Tanggal: 20 November 2026. Sumber: permintaan memastikan stok awal/saldo awal
tidak buntu. Cakupan: halaman stok awal, repository/draft, handoff stok toko,
persiapan penjualan pertama, dan kontrak posting backend.

## Hasil audit dan perbaikan

| Jalur | Temuan | Perbaikan dan pembuktian |
|---|---|---|
| Buka ulang posting yang responsnya hilang | Pemuatan master barang/lokasi bisa gagal sehingga `_item` kosong dan tombol konfirmasi terkunci | Draft dipulihkan tanpa bergantung pada lookup. Tombol replay memakai payload/ID tersimpan, tetap tunduk pada izin dan pemeriksaan server. Widget test retry dengan master offline lulus |
| Selesai posting, pemeriksaan kesiapan/navigasi gagal | Halaman sukses hanya menawarkan barang lain, tidak bisa mencoba lanjut lagi | Tombol Lanjutkan mengulang callback tanpa memposting stok lagi; error terlihat. Widget test membuktikan dua callback tetapi hanya satu posting |
| Server mengembalikan error internal/hasil belum pasti | Semua error GraphQL dianggap penolakan definitif dan menghapus request ID | Hanya kode penolakan yang diketahui sebelum posting boleh membuka editing. Error internal/transport/hasil false mempertahankan permintaan identik |
| Penolakan validasi tanggal/batch | Kode nyata server adalah `BAD_REQUEST`; harus dibedakan dari hasil belum pasti | Penolakan definitif ini membuka koreksi input. Regression test menutup celah penguncian draft |
| Halaman ditutup saat lookup berjalan | Lookup susulan berpotensi memulai pemilihan barang setelah widget dibuang | Pemeriksaan `mounted` ditambahkan setelah await lookup |

Tidak ada perubahan permission server, pembuatan stok otomatis, penghapusan
data produksi, atau migrasi konfigurasi pengguna lama.

## Jalur yang diperiksa

- Produk pertama → stok awal pada lokasi toko → pemeriksaan readiness → shift/kas
  bila diwajibkan → kasir. Jasa tanpa stok tetap melewati stok awal.
- Stok Toko tanpa saldo → stok awal dengan barang/lokasi dibawa → kembali ke
  daftar stok dan refresh setelah selesai.
- Satuan box/pcs: 2 box × 12 = 24 pcs; harga Rp36.000/box → HPP Rp3.000/pcs.
- Jumlah nol ditolak dan dapat diperbaiki; HPP nol diperbolehkan.
- Form FIFO, tanggal perolehan, batch, expiry dan serial membawa nilai ke payload.
- Double submit memakai satu proses; draft tahan reopen dan terpisah per
  endpoint/instansi/akun/operator; payload pending tidak boleh ditimpa.
- Muat awal gagal memiliki tombol muat ulang; setelah koneksi pulih bisa simpan
  tanpa keluar dari POS.
- Pengguna terbatas tidak mendapat tombol posting. Pengguna lama/offline tidak
  dipaksa mengulang onboarding stok.

Stok awal **belum dianggap berhasil secara offline**. Draft dapat dipertahankan,
tetapi posting harus dikonfirmasi server setelah koneksi pulih. Tidak dibuat PO
fiktif, utang supplier, atau kas keluar untuk stok yang sudah dimiliki sebelumnya.

## Bukti pengujian

Flutter menjalankan widget/repository tests, bukan GUI aplikasi Android terpasang.
Rangkaian akhir mobile: **89 tes lulus, 0 gagal**. Termasuk 15 tes fokus
repository/draft/form stok awal serta regresi persiapan, shift, stok dan navigasi.
Backend menjalankan integration tests pada MongoDB replica set lokal sementara,
bukan database produksi. Backend **21 tes lulus**, meliputi tujuh profil POS,
posting/jurnal, FIFO/serial, rollback, reversal, isolasi tenant dan kecocokan
GraphQL/auth middleware. Analisis Dart file yang diubah: **No issues found**.

Cakupan kode dua file stok awal pada run akhir: **317/354 baris (89,5%)**:
repository 52/55 dan halaman 265/299. Baris executable yang ditambahkan pada
audit ini tercakup **39/40 (97,5%)**. Ini bukan coverage keseluruhan aplikasi.

Checkpoint RED → GREEN pada branch mobile aktif:

- `02b7a71` → `bcd83d2`: tiga reproduksi awal gagal, kemudian sepuluh tes lulus.
- `14c7998` → `3afa3f1`: reproduksi kode validasi server gagal, kemudian lima
  belas tes fokus lulus; termasuk tiga skenario form tambahan.

Perintah verifikasi mobile:

```powershell
flutter test test/pos_opening_stock_repository_test.dart test/pos_opening_stock_page_test.dart test/pos_opening_stock_draft_test.dart test/pos_bloc_first_sale_catalog_test.dart test/pos_first_sale_flow_test.dart test/pos_mobile_navigation_policy_test.dart test/pos_setup_readiness_test.dart test/pos_bloc_no_shift_test.dart test/pos_stock_location_contract_test.dart test/pos_opname_stock_handoff_test.dart test/pos_catalog_form_initialization_test.dart test/pos_initial_setup_copy_test.dart test/pos_optional_setup_test.dart test/pos_cashier_shift_sync_test.dart test/pos_shift_cash_test.dart test/pos_navbar_context_actions_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-google-access-20261120/opening-audit-coverage.info' --reporter expanded
```

Perintah backend:

```powershell
node --test --test-concurrency=1 tests/pos-first-sale-runtime.test.js tests/pos-first-sale-journey.integration.test.js tests/pos-opening-stock-contract.test.js tests/inventory_opening_balance_identity.test.js tests/inventory_opening_tracked.integration.test.js
```

Log berada di `D:/my node app/zera/output/pos-google-access-20261120/`:
`opening-audit-red.log`, `opening-audit-green.log`, `opening-validation-red.log`,
`opening-validation-green.log`, `opening-audit-final.log`, `opening-backend.log`,
`opening-analyze.log`, dan `opening-audit-coverage.info`.

## Batas verifikasi dan penerapan

- APK belum dibangun ulang pada pekerjaan ini; APK lama tidak otomatis berubah.
- Belum ada smoke test GUI emulator/HP yang dipasang dengan kode terbaru.
- Backend readiness/permission dari implementasi sebelumnya tetap perlu tersedia
  di server tujuan. Audit ini tidak melakukan deploy atau restart layanan.
- Skenario tanpa barang/lokasi tetap memerlukan penambahan master atau bantuan
  pengelola; izin tidak dilewati dan stok tidak diposting tanpa lokasi sah.
