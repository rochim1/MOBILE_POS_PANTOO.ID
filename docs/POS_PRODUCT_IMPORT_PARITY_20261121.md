# Import produk mobile dan kesetaraan web

Tanggal: 21 November 2026. Sumber pekerjaan: permintaan memeriksa import yang
sudah ada, menerapkannya ke mobile, meneruskan panduan stok awal, dan menguji
jalur gagal supaya pengguna dapat melanjutkan.

## Audit awal

- Web sudah menyediakan Excel (.xlsx/.xls) dan CSV pada master Inventory.
  Mutation-nya `ImportInventarisUmum`; permission `inventaris_umum.import`.
- Mobile belum mempunyai pilihan import pada Katalog Penjualan.
- Import master memang mengabaikan stok di file; saldo awal adalah dokumen
  terpisah. Itu dipertahankan agar lokasi, stok, dan jurnal tidak dilewati.
- Pengulangan respons hilang belum idempoten: file tanpa kode dapat membuat
  produk kedua. SKU/barcode dan jenis layanan belum dipakai oleh parser lama.
- Preview tanpa penulisan belum ada; harga bukan angka/negatif dapat lolos.

## Implementasi dan kontrak

Kontrak otoritatif tetap GraphQL backend, bukan format API baru terpisah:

```graphql
ImportInventarisUmum(file: Upload!, kategori: KategoriInventaris,
  request_id: String, preview: Boolean = false): ImportInventarisUmumResponse
```

Argumen tambahan opsional menjaga integrasi lama. Respons menambah importedIds,
stockItemIds dan previewRows; field laporan lama tetap dipertahankan. Kontrak
query mobile/Vue diuji terhadap skema aktual serta auth middleware.

Di mobile, Katalog → **Import Excel / CSV** menyediakan template CSV berisi
header, pilih file, preview maksimal 30 baris valid, jumlah siap/gagal/dilewati,
error dan warning per baris, loading, serta konfirmasi import. Template Excel
web tetap dapat digunakan; hapus baris contohnya sebelum mengirim.

Format lama tetap didukung. Kolom tambahan sku, barcode, pos_product_type
(product/service), service_price_mode (fixed/flexible) tersedia pada kedua
template. HPP jasa opsional; service tidak melacak stok. Paket/BOM disiapkan
melalui form, bukan dianggap barang sederhana secara diam-diam. SKU/barcode
harus disimpan sebagai teks di Excel agar nol di depan tidak hilang. CSV raw
dipertahankan ketika dibaca server.

Batas: 5 MB dan 1000 baris per proses. Permission runtime `import_products`
mengikuti permission import yang sudah ada, bukan manage_products. Kasir tanpa
hak import ditolak server; hak import saja tidak memberikan manage_stock.

## Handoff dan pemulihan

- Setelah import terkonfirmasi, katalog di-refresh. Selesai maupun tombol back
  membawa hasil import kembali, sehingga callback panduan tidak hilang.
- Pemilik usaha baru mengambil readiness terbaru dan masuk Stok Awal dengan
  produk persediaan terpilih, lalu kas/shift dan kasir sesuai kebijakan lama.
  Layanan tanpa stok melewati saldo awal. Pengguna lama tidak dipaksa onboarding.
- Import banyak barang tidak mengisi kuantitas otomatis. Barang lain tersedia
  di pemilih stok awal/pencarian; stok tiap barang tetap harus dicatat pada
  lokasi yang benar sebelum dijual bila stok wajib.
- Web menawarkan Isi stok awal setelah import jika memiliki hak manage_stock.
  Aset tetap dan layanan tidak diarahkan ke saldo awal persediaan.
- Web dan Android menghasilkan request ID yang sama dari isi file dan kategori.
  Receipt per tenant dan master baru commit bersama dalam transaksi replica set.
  Retry file identik mengembalikan hasil sebelumnya, bukan membuat master baru.
- File/kategori berbeda dengan request ID yang sama ditolak. Tenant lain tidak
  mendapatkan receipt tenant sebelumnya. Permission diperiksa sebelum replay.
- Mobile menyimpan metadata pending per endpoint/tenant/akun/operator, bukan isi
  file maupun token. Setelah restart, pilih kembali **file asli yang sama** untuk
  konfirmasi. File berbeda tidak dapat menimpa permintaan belum pasti.
- Respons transport/internal/tidak lengkap mempertahankan pending; hanya hasil
  terkonfirmasi atau penolakan definitif yang menyelesaikannya. Tidak ada import
  offline yang dianggap berhasil atau dikirim otomatis di latar belakang.

File identik yang telah sukses diperlakukan sebagai replay. Untuk proses master
baru, gunakan file yang memang berisi data/kode baru. Jika file asli pending
hilang dari perangkat, pemulihan UI ini masih memerlukan salinan file tersebut;
tidak disediakan tombol membuang hasil belum pasti secara paksa.

## Hasil pengujian

**90 tes berbeda lulus: mobile 51, backend 22, web 17.** Tidak ada tes gagal pada
rangkaian akhir. Analisis tujuh file Dart produksi/tes terkait: No issues found.

| Kelompok | Pembuktian |
|---|---|
| Mobile unit/repository | Kontrak template, ID stabil, multipart beridentitas operator, guard perubahan operator, pending sebelum jaringan, double submit, reopen/retry, file salah, respons tidak lengkap |
| Mobile widget 360×800 | Pilih → preview → import parsial → hasil → handoff ID stok; loading/back; koneksi putus dan retry; perbaikan preview gagal; hak akses/offline; back sesudah sukses tetap membawa hasil |
| Regresi mobile | Stok awal, box/pcs, HPP nol, batch/FIFO/serial, retry saldo awal, panduan spotlight, katalog sebelum shift dan guard checkout |
| Backend replica set lokal | Preview tanpa penulisan, replay respons hilang, ID/file conflict, tenant terpisah, harga invalid, kode otomatis banyak baris, concurrent receipt, service/HPP opsional, barcode nol di depan, aset, kasir terbatas dan role non-admin import-only |
| Perjalanan backend | PIN nyata → preview/import → readiness produk → saldo awal → kas nol → penjualan pertama; saldo akhir 12→11, jurnal seimbang; tujuh profil lama tetap lulus |
| Web | Hash sama dengan format Android, template Vue terkompilasi, guard stok awal dan route product_id; regresi first-sale dan retry saldo awal |

Cakupan dua file baru mobile: repository **76/87 (87,4%)**, halaman **113/128
(88,3%)**, gabungan **189/215 (87,9%)**. Ini bukan coverage keseluruhan aplikasi.

## Bukti RED → GREEN

- Backend `904c3fd0` → `17bb8116`: preview menulis data dan retry membuat master
  ganda; setelah kontrak/receipt diterapkan lima tes lulus.
- Backend `59c05837` → `abe5a103`: kode auto banyak baris dan harga nonangka;
  tujuh tes lulus.
- Backend `fb0629fd` → `748e0f85`: service dan identifier hilang; sepuluh tes lulus.
- Backend `b55ab893` → `6cbacb35`: aset salah mendapat handoff stok; 21 tes lulus.
  Tes non-admin ditambahkan dengan tenant/role eksplisit; rangkaian terakhir 22.
- Mobile `57895b5` → `2dca22c`: fitur/template/result belum tersedia; tiga tes lulus.
- Mobile `8202baa` → `e442518`: respons kosong sempat membuang pending; sembilan
  tes lulus. Integrasi layar dan panduan pada `0312bbf` lulus 51 tes.

Perubahan web sudah tercakup pada HEAD `0a755bb7` oleh commit workspace lain
selama pekerjaan ini; tidak dilakukan rewrite atau perubahan commit tersebut.

Log dan coverage terpisah berada di
`D:/my node app/zera/output/pos-google-access-20261120/import-*`.
`import-mobile-final.log`: +51; `import-backend-suite.log`: pass 22;
`import-web.log`: pass 17; `import-analyze.log`: No issues found.

Perintah utama:

```powershell
# mobile_POS_Pantoo
flutter test test/pos_product_import_test.dart test/pos_product_import_repository_test.dart test/pos_product_import_page_test.dart test/pos_opening_stock_page_test.dart test/pos_opening_stock_repository_test.dart test/pos_opening_stock_draft_test.dart test/pos_first_sale_flow_test.dart test/pos_first_sale_guide_test.dart test/pos_catalog_form_initialization_test.dart test/pos_bloc_first_sale_catalog_test.dart test/pos_bloc_no_shift_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-google-access-20261120/import-coverage.info' --reporter expanded
# presensi_zera_BE
node --test --test-concurrency=1 tests/pos-product-import.integration.test.js tests/pos-product-import.contract.test.js tests/pos-first-sale-runtime.test.js tests/pos-first-sale-journey.integration.test.js
# front_end_template
node --test tests/pos-product-import.test.mjs tests/pos-first-sale-components.test.mjs tests/pos-first-sale-flow.test.mjs tests/pos-opening-stock-request.test.mjs
```

Run awal fixture non-admin belum memiliki tenant sehingga ditolak permission
ceiling; fixture dilengkapi tanpa melonggarkan policy. Log MongoMemoryReplSet
kadang mencetak ECONNRESET ketika shutdown walaupun seluruh assertion lulus dan
exit code 0; ini tidak disebut sebagai error aplikasi produksi.

## Penerapan dan batas verifikasi

1. Deploy/restart **backend terlebih dahulu** agar argumen preview/request_id,
   field respons dan import_products tersedia. Receipt memakai koleksi baru
   inventory_import_receipts dan indeks _id; tidak memerlukan reset data lama.
2. Deploy web dan bangun APK baru. APK terpasang sebelumnya belum memiliki fitur
   ini. Pekerjaan ini tidak build APK/AAB atau mengubah database produksi.
3. Tes mobile adalah widget/repository tests; uji pemilih file Android asli,
   penyimpanan template oleh DocumentsUI dan GUI Chrome/HP terpasang masih perlu
   smoke test sesudah pemasangan. Tidak ada klaim GUI Android native sudah PASS.
4. Import lama dari integrasi yang tidak mengirim request_id tetap kompatibel,
   tetapi perlindungan receipt hanya berlaku jika request_id disertakan.
