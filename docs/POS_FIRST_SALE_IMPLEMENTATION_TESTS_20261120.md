# Implementasi dan pengujian alur penjualan pertama POS

Tanggal: 20 November 2026, Asia/Jakarta.

Sumber pekerjaan: [audit pengguna baru](POS_NEW_USER_FIRST_SALE_FLOW_AUDIT_20261120.md), temuan NU-01 sampai NU-04. User meminta penerapan mobile + web, menjaga pengguna lama, dan pengujian sampai lulus.

## Ringkasan hasil

**Temuan audit sudah ditangani dalam kode mobile, Vue dan backend. Total 187 tes otomatis lulus: mobile 82, web 50, backend 55; tanpa tes gagal atau dilewati pada rangkaian akhir.** Analisis seluruh halaman POS mobile dan kode baru: `No issues found`.

Ini bukan klaim semua fitur POS sudah siap produksi. Yang dibuktikan adalah cakupan alur ini dan regresi terkait. Tidak dilakukan reset akun, perubahan transaksi produksi, deploy server, build APK/AAB, ataupun sesi GUI Android/emulator/Chrome berlogin pada pekerjaan ini. Pengujian tampilan mobile memakai Flutter widget tests dengan interaksi pada ukuran HP; pengujian backend memakai replica set lokal sementara.

## 1. Alur yang sekarang diterapkan

```text
PIN sah → periksa kesiapan dan identitas pemilik
  ├─ Usaha POS baru, belum ada produk → Katalog / Tambah produk pertama
  │    ├─ Barang stok → Stok Awal dengan barang dan lokasi toko terpilih
  │    ├─ Jasa tanpa stok → lewati Stok Awal
  │    └─ BOM/paket → stok dicatat pada komponen, bukan induknya
  ├─ Produk dan stok sudah tersedia → gunakan shift aktif / buka kas
  └─ Pengguna lama/operator lain/offline → pertahankan jalur sebelumnya
Simpan Stok Awal → periksa kesiapan terbaru → Buka Kas bila wajib → Kasir
```

Kas awal nol diperbolehkan sesuai kebijakan server. Shift aktif dipakai ulang; alur baru tidak membuat shift, stok, atau jurnal hanya karena halaman dibuka. Pengisian persediaan tidak memerlukan PO fiktif dan tidak otomatis membuat utang supplier/kas keluar.

## 2. Pemetaan temuan ke perbaikan

| Temuan | Perbaikan | Pembuktian |
|---|---|---|
| NU-01: PIN mendahulukan shift meskipun produk kosong | Policy mobile dan web membaca readiness terverifikasi, hanya untuk pemilik usaha POS baru yang memenuhi syarat | Tes routing baru, regresi routing lama, metode unlock Vue, perjalanan tujuh profil backend |
| NU-01 tambahan: katalog sebelum shift memang belum dimuat | Pemilik baru dengan izin kelola produk dapat memuat katalog sebelum membuka kas; guard checkout tidak diubah | Tes BLoC reproduksi `reads=0` → `reads=1`, serta regresi kasir terbatas tanpa shift |
| NU-02: belum ada jalur saldo awal mobile | Repository dan halaman Stok Awal memanggil `SubmitInventoryOpeningBalance` yang sudah ada | Tes repository dengan GraphQL client, widget simpan/retry, kontrak schema/middleware, posting/jurnal database lokal |
| NU-03: tanpa balance diarahkan ke opname | Mobile tanpa balance diarahkan ke Stok Awal bagi yang berhak; operator lain mendapat penjelasan. Panduan tidak lagi menawarkan opname untuk inisialisasi | Regresi stok/opname dan inspeksi jalur baru; editor opening diuji interaktif |
| NU-03: panduan web menuju daftar stok | Panduan web menuju formulir stok awal. Tersedia tombol Stok Awal di Stok Toko dan Stok Inventory sesuai izin | Tes kompilasi template dan policy; route memakai permission yang sama dengan API |
| NU-04: tidak ada tindakan berikutnya | Setelah simpan produk pertama mobile/web, lanjut stok atau kas. Kasir kosong memiliki CTA kelola produk | Callback mobile, metode Vue, tes routing dan kompilasi template |
| Konteks web membingungkan | Route `/pos/produk/tambah` dan `/pos/stok-awal` memakai komponen Inventory yang sama tanpa memindahkan konteks aplikasi/sidebar ke Inventory | Tes route policy tetap namespace POS; route dilindungi izin `create`/`manage_stock` |

## 3. Perlindungan pengguna lama dan hak akses

Backend mengirim `initial_setup.first_sale_pending` hanya bila semua ini benar:

- Instansi memang POS baru yang ditandai eligible, versi 1, setup otomatis berstatus ready.
- Pengguna runtime adalah pemilik instansi.
- Belum ada transaksi POS, dokumen pesanan POS, atau shift yang telah ditutup.

Instansi lama tanpa penanda tidak disimpulkan sebagai pengguna baru hanya karena katalog kosong. Pemilik dengan riwayat operasional dan operator selain pemilik tidak dipaksa mengulang persiapan. Konfigurasi toko/lokasi/profil lama tidak ditulis ulang oleh perubahan ini.

Routing juga memeriksa izin dan status offline. `initialize_stock` mengikuti izin backend `inventaris_umum/manage_stock`; server tetap memeriksa warehouse, periode, dan aturan barang. Nilai `has_open_shift` runtime bukan pengganti verifikasi shift operator. Guard transaksi tanpa shift serta kontrol batch/FIFO/serial tidak dilemahkan.

Pada mobile, keputusan setelah simpan mengambil runtime terbaru langsung. Ini mencegah event refresh katalog yang selesai lebih dulu dianggap sebagai hasil pemeriksaan kesiapan terbaru.

## 4. Perilaku Stok Awal dan pemulihan

- Barang/lokasi toko dibawa dari konteks; pengguna dapat memeriksa lokasi dan memilih gedung/ruangan/rak opsional.
- Jumlah dan biaya mengikuti satuan terpilih. Contoh diuji: biaya dasar Rp3.000, 1 box=12 pcs, 2 box menghasilkan 24 pcs dengan HPP dasar Rp3.000; bukan Rp3.000 per box.
- Form memiliki label dan proses simpan terlihat pada tombol. Double submit selama proses tidak membuat dua permintaan posting.
- FIFO meminta tanggal perolehan. Batch/expiry dan serial tersedia sesuai aturan item; backend tetap menjadi validator akhir.
- Master produk tetap dimulai dari stok nol. Saldo awal membuat dokumen/pergerakan/balance, bukan menimpa angka master secara langsung.
- Request ID dan payload saldo awal disimpan sebelum dikirim. Respons hilang mempertahankan permintaan yang sama setelah halaman/app dibuka ulang. Akun/instansi/operator lain tidak mengambil draft tersebut.
- Hanya respons sukses terkonfirmasi yang menyelesaikan permintaan. Penolakan server yang definitif mengizinkan koreksi form; kegagalan transport/hasil belum pasti tidak dianggap penolakan.
- Draft web yang belum pasti tidak dapat diedit sampai hasilnya diperiksa. Retry memakai input tersimpan, bukan input baru.
- Posting saldo awal kedua untuk barang yang sudah diinisialisasi tetap ditolak server. Tambahan barang berikutnya memakai Penerimaan; selisih saldo yang sudah tercatat memakai koreksi/opname sesuai aturan.

## 5. Rincian pengujian akhir

| Kelompok | Lulus | Gagal | Dilewati | Yang dibuktikan |
|---|---:|---:|---:|---|
| Flutter unit/BLoC/widget | 82 | 0 | 0 | Routing baru/lama, katalog pra-shift, form 390×844, box/pcs, tombol/spinner, pemulihan draft, izin, regresi shift/kas/opname/navbar |
| Vue/JavaScript komponen & kontrak UI | 50 | 0 | 0 | Metode unlock, urutan refresh, redirect sebelum prompt kas, retry hasil belum pasti, isolasi operator, template tujuh halaman, regresi opening/opname/shift/panduan opsional |
| Backend unit, kontrak, integration | 55 | 0 | 0 | PIN nyata dan perjalanan tujuh profil, posting/jurnal stok awal, retry tanpa duplikat, setup lama tetap utuh, FIFO/serial/reversal, schema + auth middleware |
| Analisis Dart | bersih | 0 isu | — | Seluruh halaman POS, BLoC POS, repository baru dan lima berkas tes baru |

### Perjalanan backend tujuh profil

Ketujuh profil berikut lulus pada database lokal sementara: **retail, jasa, restoran, laundry, bengkel, salon, custom**.

Setiap skenario membuat tenant uji tersendiri, menjalankan setup toko/lokasi, membuat dan memverifikasi PIN, menambahkan produk melalui resolver nyata, mengisi stok awal untuk barang atau melewatinya untuk jasa, membuka kas nol, mengulang buka kas untuk memastikan shift tidak ganda, lalu menyelesaikan penjualan tunai pertama. Profil yang mewajibkan pelanggan diberi pelanggan sah; layanan langsung tidak dikirimi jadwal. Setelah penjualan, penanda first-sale tidak aktif lagi. Stok barang turun 24→23; jasa tidak menciptakan stok. Jurnal yang posted seimbang.

Ini **integration test melalui resolver**, bukan GUI penuh per profil. Tidak berarti seluruh operasi inventori/dapur/reservasi telah diuji ulang pada pekerjaan ini.

### Cakupan kode baru mobile

Hasil cakupan rangkaian Flutter akhir:

| Berkas | Baris tercakup | Persentase |
|---|---:|---:|
| `pos_opening_stock_repository.dart` | 49/52 | 94,2% |
| `pos_opening_stock_page.dart` | 230/275 | 83,6% |
| `pos_mobile_navigation_policy.dart` | 28/29 | 96,6% |
| Gabungan ketiganya | 307/356 | 86,2% |

Angka ini bukan coverage keseluruhan aplikasi. Error infrastruktur/perangkat dan semua cabang data belum tercakup GUI.

## 6. Perintah verifikasi yang dijalankan

Dari `mobile_POS_Pantoo`:

```powershell
flutter test test/pos_opening_stock_repository_test.dart test/pos_opening_stock_page_test.dart test/pos_opening_stock_draft_test.dart test/pos_bloc_first_sale_catalog_test.dart test/pos_first_sale_flow_test.dart test/pos_mobile_navigation_policy_test.dart test/pos_setup_readiness_test.dart test/pos_bloc_no_shift_test.dart test/pos_stock_location_contract_test.dart test/pos_opname_stock_handoff_test.dart test/pos_catalog_form_initialization_test.dart test/pos_initial_setup_copy_test.dart test/pos_optional_setup_test.dart test/pos_cashier_shift_sync_test.dart test/pos_shift_cash_test.dart test/pos_navbar_context_actions_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-new-user-audit-20261120/coverage.info' --reporter expanded
dart analyze lib/presentation/pages/pos lib/presentation/bloc/pos/pos_bloc.dart lib/domain/repositories/pos_opening_stock_repository.dart test/pos_first_sale_flow_test.dart test/pos_opening_stock_draft_test.dart test/pos_opening_stock_repository_test.dart test/pos_opening_stock_page_test.dart test/pos_bloc_first_sale_catalog_test.dart
```

Dari `front_end_template`:

```powershell
node --test tests/pos-first-sale-components.test.mjs tests/pos-first-sale-flow.test.mjs tests/pos-opening-stock-request.test.mjs tests/pos-kasir-shift-sync.test.mjs tests/pos-optional-setup.test.mjs tests/opening-balance-form.test.mjs tests/opening-balance-error.test.mjs tests/inventory-opname-mobile-contract.test.mjs tests/inventory-opname-post.test.mjs
```

Dari `presensi_zera_BE`:

```powershell
node --test --test-concurrency=1 tests/pos-first-sale-runtime.test.js tests/pos-first-sale-journey.integration.test.js tests/pos-opening-stock-contract.test.js tests/pos_initial_setup.contract.test.js tests/pos_initial_setup.integration.test.js tests/inventory_opening_balance_identity.test.js tests/inventory_opening_tracked.integration.test.js
```

Log akhir tersimpan di `D:/my node app/zera/output/pos-new-user-audit-20261120/`:

- `mobile-final.log`: `+82: All tests passed!`
- `web-final.log`: `tests 50`, `pass 50`, `fail 0`.
- `backend-final.log`: `tests 55`, `pass 55`, `fail 0`.
- `analyze-final.log`: `No issues found!`.
- `coverage.info`: data cakupan Flutter.

Peringatan deprecation `punycode` dari dependensi backend bukan kegagalan pengujian. Beberapa run awal gagal karena fixture tes belum lengkap (misalnya pelanggan jasa dan respons mock GraphQL); fixture dibetulkan tanpa melonggarkan aturan aplikasi. Angka pada tabel adalah hasil run akhir, bukan menggabungkan percobaan yang gagal.

## 7. Bukti RED → GREEN

| Reproduksi | RED nyata | GREEN |
|---|---|---|
| Tujuan setelah PIN | Pemilik tanpa produk diharapkan indeks 2, aktual 11 | Policy baru + pengecualian lama/offline lulus |
| Katalog sebelum kas | Fetch katalog diharapkan 1, aktual 0 | Hanya pemilik baru berizin yang dapat memuat katalog sebelum kas |
| Pemulihan stok awal | Store draft dan policy belum tersedia | Payload/ID bertahan setelah reopen, coalescing double submit, respons hilang/retry lulus |
| Konteks web | Route stok awal masih `/inventory/...`, diharapkan `/pos/...` | Route POS memakai komponen sama dan izin yang tepat |

Checkpoint pada branch aktif selama pekerjaan:

- Mobile RED: `e4b2f07`, `3ccbf3b`, `187b4ad`; GREEN: `4ec63e4`. Perapian lanjutan diverifikasi ulang dengan 82 tes dan analisis bersih.
- Backend RED: `7f6e7740`; GREEN: `9c40360f`.
- Web RED: `64843fe8`, `1796ddbd`; GREEN: `b54b9fb5`, `4eff7c82`.

Tes baru, bukti log, dan laporan ini perlu dipertahankan jika commit digabung/squash.

## 8. Penerapan dan batas verifikasi

1. **Deploy/restart backend terlebih dahulu**, karena mobile dan Vue sekarang meminta `first_sale_pending`, identitas toko/lokasi setup, serta permission `initialize_stock` pada skema runtime. Tidak dibutuhkan migrasi data toko/lokasi atau reset akun.
2. Deploy Vue dan build mobile yang memuat perubahan ini. APK lama di HP tidak otomatis berubah; pekerjaan ini belum membuat APK/AAB baru.
3. Smoke test GUI di Android nyata/emulator dan Chrome berlogin masih perlu dijalankan sesudah pemasangan/deploy: akun baru, akun lama, identitas operator berbeda, buka ulang aplikasi, dan putus koneksi nyata.
4. Printer, pembayaran gateway eksternal, keseluruhan offline multikasir, dan seluruh operasi Finance tidak diuji ulang di sini. Tidak ada klaim PASS tambahan untuk bagian tersebut.

**Status: implementasi selesai dan rangkaian otomatis terkait PASS. Verifikasi GUI perangkat/deployment dicatat terpisah, bukan dianggap sudah dilakukan.**
