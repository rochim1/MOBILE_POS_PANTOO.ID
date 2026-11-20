# Audit pengguna baru: PIN → produk → stok awal → kas/shift → penjualan

Tanggal: 20 November 2026 (Asia/Jakarta).

Pembaruan: temuan audit ini sudah ditindaklanjuti dalam kode. Lihat [implementasi dan hasil pengujian](POS_FIRST_SALE_IMPLEMENTATION_TESTS_20261120.md) untuk status terbaru; isi di bawah merupakan kondisi sebelum perbaikan.

## Kesimpulan

**Alur pengguna baru belum tuntas.** Ada kebuntuan nyata pada pengisian stok pertama dari mobile, serta urutan setelah PIN yang belum mengikuti kebutuhan pengguna baru. Buka kas/shift sudah tersedia; masalah yang terkonfirmasi bukan ketiadaan fitur kas, melainkan shift didahulukan sebelum katalog/stok siap dan tidak dilanjutkan dengan tindakan berikutnya yang jelas.

Audit ini tidak mengubah kode aplikasi, konfigurasi, akun, transaksi, atau database produksi. Yang ditambahkan hanya laporan dan pemeriksaan diagnostik lokal. Tidak dilakukan build APK/AAB ataupun pengujian GUI Android/web pada audit ini. Temuan sumber kode dibedakan dari pembuktian end-to-end yang masih harus dilakukan.

Basis sumber lokal: mobile `fff3ab2`, backend `5696a39c`, Vue `ab731f16`; kondisi lokal pada saat audit, bukan bukti versi yang sedang terpasang di HP/server. Perubahan lain yang sudah ada di workspace tidak disentuh.

## 1. Alur saat ini dan titik buntu

| Tahap/tindakan | Data yang dibaca/ditulis | Perilaku saat ini | Hasil audit |
|---|---|---|---|
| Selesaikan profil usaha | Instansi, penanda setup awal, toko/lokasi | Ada layanan otomatis khusus instansi POS baru; konfigurasi lama dilindungi | Fondasi tersedia; tidak perlu membuat toko/gudang ulang di alur baru |
| Login PIN berhasil | Izin, toko aktif, shift, runtime | Tujuan setelah unlock memeriksa toko/shift/offline, bukan kelengkapan produk/stok | Pengguna baru diarahkan ke shift lebih dulu |
| Buka shift/kas awal | Toko, `opening_cash`, catatan | Form tersedia; callback memuat ulang POS lalu kembali ke indeks kasir | Tidak ada pengecekan katalog/stok sebagai langkah berikutnya |
| Masuk kasir kosong | Daftar produk hasil pemuatan | Pesan “Tidak ada produk ditemukan” | Tidak ada CTA tambah produk di empty-state tersebut |
| Tambah produk | Master inventaris, harga, satuan, aturan stok | Produk baru mengirim `stok: 0`; payload form/repository tidak menambahkan lokasi | Pemisahan master dan pergerakan stok benar, tetapi belum ada handoff ke saldo awal |
| Simpan produk | Refresh katalog POS | `RefreshProducts` dijalankan, form ditutup | Refresh katalog sudah ada; tidak ditemukan tindak lanjut stok awal/kas |
| Panduan → “Isi stok awal” | Readiness runtime, navigasi inventory | Membuka bagian daftar stok, bukan editor saldo awal | Label tindakan menjanjikan proses yang belum terhubung |
| Stok → Koreksi Darurat | Saldo produk di warehouse terpilih | Jika saldo lokasi belum ada, berhenti dengan pesan dan opsi “Buka Stock Opname” | Produk pertama tanpa saldo tidak bisa diinisialisasi melalui jalur ini |
| Lanjut Stock Opname | Snapshot saldo lokasi dari server | Backend membutuhkan saldo lokasi yang sudah ada | Tanpa saldo, opname juga tidak dapat membuat snapshot barang/lokasi tersebut |

Catatan: daftar stok sendiri dapat menampilkan master dengan qty nol. Jadi masalah bukan semata-mata produk hilang dari daftar, melainkan tidak adanya jalur **inisialisasi saldo** yang benar dari tindakan tersebut.

## 2. Temuan terkonfirmasi

### NU-01 — P1: Setelah PIN belum memprioritaskan produk pertama

- Pemicu: pemilik baru memiliki toko/lokasi otomatis dan PIN, tetapi belum punya produk/shift.
- Trace: unlock → `_finishUnlockLoading` → `mobilePosUnlockDestination` → indeks `11` (shift) → buka shift → indeks `1` (kasir).
- Aktual: `operational_readiness.next_step = product` tidak digunakan oleh kebijakan unlock. Bahkan ketika shift sudah ada dan produk belum ada, hasilnya tetap kasir.
- Dampak: pengguna diminta kas awal lebih dulu, lalu berakhir di katalog kosong tanpa diarahkan menambahkan barang/layanan.
- Seharusnya: bagi pemilik/pengelola dengan katalog benar-benar kosong, setelah PIN tampilkan katalog dengan tindakan **Tambah produk pertama**. Pengguna yang sudah siap tetap langsung ke kasir/shift sesuai kebijakan. Jangan mengembalikan wizard setup wajib untuk semua pengguna.
- Bukti: `lib/presentation/pages/pos/utils/pos_mobile_navigation_policy.dart:17`; `pos_shell_page.dart:415` dan `:637`; `pos_bloc.dart:365`.
- Penting: sebelum shift dibuka, `state.products` sengaja dapat kosong karena katalog belum dimuat. Perbaikan tidak boleh menyimpulkan “belum punya produk” hanya dari `state.products.isEmpty`; gunakan readiness server/jumlah katalog yang sudah terverifikasi.

### NU-02 — P1: Mobile belum menyediakan jalur saldo awal yang setara web

- Pemicu: buat produk stok dari katalog mobile, kemudian ingin memasukkan barang yang sudah dimiliki sebelum memakai aplikasi.
- Trace: `_CatalogProductForm` → `CreateProduct` → `PosProductManagementRepository.createProduct` → `AddInventarisUmum` → Stok → koreksi → saldo lokasi kosong.
- Aktual: form mengirim qty nol tanpa `lokasi_cabang_id`; repository juga sengaja tidak mengambil lokasi dari shift/toko. Backend hanya membuat balance lokasi saat input lokasi dikirim. Karena itu produk yang dibuat melalui form ini belum memiliki balance lokasi.
- Koreksi mobile mensyaratkan balance; opname backend juga mengambil snapshot dari balance yang sudah ada. Jalur mobile tidak ditemukan memanggil `SubmitInventoryOpeningBalance`.
- Dampak: pemilik tidak bisa menyelesaikan stok pertama melalui panduan/koreksi tersebut. PO/penerimaan memang dapat membentuk saldo, tetapi tidak boleh dipaksakan untuk stok lama yang bukan pembelian baru; transfer juga membutuhkan stok asal.
- Seharusnya: sediakan tindakan **Isi stok awal** yang memanggil layanan saldo awal yang sudah tersedia, dengan barang/toko/lokasi terpilih. Jangan melemahkan validasi koreksi/opname dan jangan menambahkan qty langsung ke master inventaris.
- Bukti mobile: `pos_product_page.dart:1783`–`:1830`; `domain/repositories/pos_product_management_repository.dart:411`; `pos_stock_page.dart:1345`–`:1380`.
- Bukti backend: `graphql/inventaris_umum/inventaris_umum.resolvers.js:2876` (balance dibuat jika lokasi ada); `graphql/inventory_opname/inventory_opname.resolvers.js:235`–`:267` (snapshot mensyaratkan balance).
- Pembanding web: `/inventory/saldo-awal`, `front_end_template/src/pages/inventaris_umum/saldoAwal.vue:281` dan `:617`. Resolver aktif meneruskan ke `inventory_opening_balance.service.js`, bukan implementasi legacy.

### NU-03 — P2: Bantuan stok mengarahkan ke opname yang tidak menyelesaikan kasus tanpa saldo

- Trace A: panduan → “Isi stok awal” → inventory section `stock` → koreksi saldo kosong → “Buka Stock Opname”.
- Trace B: detail stok tanpa saldo → teks “Tambahkan melalui penerimaan, mutasi, atau Stock Opname”.
- Aktual: opname tidak bisa menginisialisasi barang/lokasi yang tidak masuk snapshot balance. Bila warehouse memiliki balance barang lain, opname mungkin terbuka, tetapi barang tanpa balance tersebut tetap tidak menjadi item snapshot yang dapat dihitung.
- Seharusnya: bedakan **stok awal**, **barang datang/penerimaan**, **pindah stok/transfer**, dan **selisih/opname**. Pada kasus tanpa balance, CTA utama harus saldo awal/penerimaan sesuai konteks, bukan opname.
- Bukti: `pos_setup_guide_page.dart:347`–`:373`; `pos_shell_page.dart:897`–`:902`; `pos_stock_page.dart:1117`, `:1370`, `:1413`; resolver opname `:235`.
- Gap navigasi web terkait: dashboard juga memetakan langkah `stock` ke `/pos/stok`, bukan langsung `/inventory/saldo-awal` (`src/pages/pos/dashboard.vue:598`). Web sudah punya formulir saldo awal tersendiri, tetapi jalur panduannya perlu disambungkan. Ini pemeriksaan navigasi sumber, bukan hasil GUI web.

### NU-04 — P2: Tidak ada handoff tindakan berikutnya dari katalog kosong/produk tersimpan

- Aktual: kasir kosong hanya menampilkan pesan; setelah tambah produk, listener memberi toast dan refresh katalog lalu form ditutup. Pengguna harus menemukan sendiri menu inventory dan shift.
- Dampak: pengguna jasa pun dapat merasa buntu setelah membuat layanan, meskipun jasa sebenarnya tidak memerlukan stok awal.
- Seharusnya: empty-state kontekstual dan tindak lanjut ringkas setelah simpan: barang stok → **Isi stok awal** / **Nanti**; jasa → **Mulai berjualan**; kasir belum shift → **Buka kas**; shift sudah aktif → kasir, tanpa membuka shift kedua.
- Bukti: `widgets/pos_product_panel.dart:202`–`:212`; `pos_product_page.dart:135`–`:143`, `:1828`–`:1830`; `pos_bloc.dart:95`–`:139`; `pos_shell_page.dart:637`–`:661`.
- Klarifikasi: refresh katalog setelah simpan sudah tersedia, jadi tidak dicatat sebagai bug “produk pasti tidak diperbarui”. `RefreshProducts` hanya memperbarui katalog; runtime/readiness perlu diperbarui bila dipakai menentukan langkah berikutnya. `_continueSetup` saat panduan dilanjutkan sudah menjalankan `LoadPosData`.

## 3. Kas kasir: apa yang sudah tersedia

- Halaman shift memiliki pilihan toko, **Kas Awal (Rp)** dan **Catatan Buka Shift**; submit mengirim `OpenShiftEvent`. Nilai awal variabel kas adalah `0`.
- Toko awal dipilih dari toko shift aktif bila cocok, selain itu toko aktif pertama. Ini bukan bukti semua variasi multi-toko sudah diuji GUI.
- Kasir tetap memblokir penjualan tanpa shift apabila kebijakan mewajibkan shift. Perlindungan ini harus dipertahankan.
- **Kas awal laci berbeda dari saldo awal persediaan.** Kas awal bukan harga beli/HPP barang dan tidak boleh otomatis dianggap pendapatan penjualan.
- Tidak ditemukan bukti pada audit ini bahwa API kas awal selalu gagal. Keluhan “buntu” pada kas perlu dibuktikan lagi lewat GUI setelah rute pengguna baru dibenahi; jangan menyamakan masalah navigasi dengan gagal simpan kas.
- Referensi: `widgets/pos_active_shift_tab.dart:84`, `:544`–`:650`; `pos_page.dart:376`–`:382`; `widgets/shift_management_panel.dart:31`–`:82`.

## 4. Fondasi backend yang harus digunakan, bukan diduplikasi

1. Toko/lokasi otomatis: `graphql/pos_kasir/pos_initial_setup.service.js:22` menggunakan transaksi, penanda instansi POS baru, kepemilikan, serta perlindungan konfigurasi lama. Alur perbaikan cukup memakai hasilnya, bukan membuat toko/lokasi lagi setiap login.
2. Readiness: `pos_kasir.resolvers.js:244`–`:278` sudah menyusun urutan lokasi → toko → produk → konfigurasi → stok → PIN → shift. Mobile menerima field ini, tetapi kebijakan unlock belum memakainya untuk produk/stok.
3. Saldo awal: `inventory_opening_balance.service.js:177` memeriksa izin `inventaris_umum/manage_stock`, akses warehouse, periode Finance, qty/HPP, batch/serial/FIFO, identitas permintaan dan transaksi database. Request sama yang sudah posted dikembalikan berhasil tanpa menambah saldo kedua. Ini hasil inspeksi, bukan pengujian transaksi/jurnal aktual pada audit ini.
4. Layanan saldo awal menolak stok/nilai yang sudah ada atau opening kedua. Tindakan pasca-inisialisasi harus menjadi penerimaan atau koreksi/opname yang sesuai, bukan terus menawarkan opening balance.
5. `has_initial_stock` adalah indikator adanya stok pada cakupan produk/lokasi yang diperiksa, **bukan jaminan setiap SKU, setiap toko, atau kasir saat ini siap**. `has_open_shift` runtime juga menghitung shift pada cakupan toko, bukan menggantikan verifikasi active shift operator. Routing dan guard transaksi harus tetap memakai konteks toko/operator yang benar.

## 5. Alur yang direkomendasikan

```text
Profil usaha selesai → toko/lokasi otomatis → PIN
  ├─ Pemilik/pengelola, katalog benar-benar kosong → Tambah produk pertama
  │    ├─ Barang stok → Isi stok awal (atau Nanti bila stok belum ada)
  │    ├─ Jasa / non-stock → lewati stok awal
  │    └─ BOM/bundle → stok dicatat pada komponen yang benar
  └─ Katalog sudah ada → lanjutkan kebutuhan toko/operator, bukan ulang onboarding
Siap mulai jual → gunakan shift aktif / buka kas jika diwajibkan → kasir
```

Panduan lengkap tetap opsional. Yang berubah adalah arahan satu langkah yang relevan, bukan wizard panjang atau pemaksaan semua SKU harus punya stok. Pemilik boleh membuat produk sebelum membuka shift. Kasir terbatas yang tidak berhak mengubah produk/stok mendapat penjelasan dan instruksi menghubungi pengelola, bukan tombol mati atau eskalasi hak akses otomatis.

Form stok awal profil sederhana cukup menonjolkan barang, jumlah, satuan, lokasi otomatis dan biaya per satuan barang bila relevan. Detail rak, batch, tanggal perolehan FIFO dan serial ditampilkan hanya bila aturan item memerlukannya. HPP barang persediaan mengikuti aturan valuasi server; layanan tanpa stok tidak dimintai HPP/stok awal. Jangan membuat PO fiktif, utang supplier atau kas keluar hanya untuk memasukkan stok yang sudah dimiliki.

## 6. Rencana perbaikan berurutan

| Prioritas | Pekerjaan | Batas aman / kriteria selesai |
|---|---|---|
| P1 | Satukan keputusan setelah PIN dengan readiness baru yang terverifikasi dan izin operator | Katalog kosong untuk pemilik → CTA produk pertama; data belum dimuat bukan dianggap kosong; pengguna lama tidak dilempar ulang ke setup |
| P1 | Tambahkan repository, query dan editor saldo awal di mobile, memakai API yang sudah ada | Membentuk balance nol→positif tanpa PO, identitas retry persisten, tanpa duplikat stok/jurnal; izin sesuai backend |
| P1 | Sambungkan hasil tambah produk ke tindakan berikutnya | Barang stok → saldo awal/penerimaan; jasa → kasir/shift; simpan berhasil tetapi respons hilang tidak membuat master kedua |
| P2 | Perbaiki CTA panduan, detail stok, dan empty-state mobile + tautan panduan web | Tanpa balance tidak diarahkan ke opname; konteks barang/lokasi dibawa otomatis |
| P2 | Perjelas “Buka kas” dan refresh setelah stok/shift tersimpan | Gunakan shift aktif, dukung kas nol sesuai kebijakan, hindari buka dua shift dan refresh readiness sebelum menentukan tujuan |
| P2 | Uji regresi profil/izin/offline dan GUI instansi baru | Tidak mengubah konfigurasi lama; tidak membuat data duplikat pada login kedua/perangkat kedua |

## 7. Pengujian yang benar-benar dijalankan

### Regresi Flutter: 27 PASS, 0 gagal

Perintah (dari folder mobile):

```powershell
flutter test test/pos_mobile_navigation_policy_test.dart test/pos_setup_readiness_test.dart test/pos_bloc_no_shift_test.dart test/pos_stock_location_contract_test.dart test/pos_opname_stock_handoff_test.dart --no-pub --concurrency=1 --reporter expanded
```

Cakupan: kebijakan navigasi, perhitungan readiness, pemuatan tanpa shift, kontrak query/halaman stok, widget handoff opname pada saldo/rak yang **sudah ada**, serta larangan bypass pelacakan batch. Sebagian tes merupakan pemeriksaan sumber/kontrak; bukan semuanya interaksi GUI. Tidak membuktikan saldo awal mobile sudah bekerja.

Log: `D:/my node app/zera/output/pos-new-user-audit-20261120/regression.log`.

### Kontrak backend: 3 PASS, 0 gagal

```powershell
node --test tests/inventory_opening_balance_identity.test.js tests/pos_initial_setup.contract.test.js
```

Cakupan: identitas/hash request saldo awal stabil, serta dokumen setup/runtime mobile dan Vue sesuai skema penuh dan terdaftar pada auth middleware. Bukan tes posting saldo/jurnal/Finance. Muncul peringatan deprecation `punycode`, bukan kegagalan tes.

Log: `D:/my node app/zera/output/pos-new-user-audit-20261120/backend-contract.log`.

### Diagnostik routing: 6 perilaku saat ini terkonfirmasi

Script: `D:/my node app/zera/output/pos-new-user-audit-20261120/navigation_probe.dart`.

| Input | Tujuan aktual | Arti |
|---|---|---|
| Pemilik, toko ada, produk belum ada, shift belum ada, next_step=product | 11 = shift | Menunjukkan NU-01, bukan PASS alur yang diharapkan |
| Pemilik, produk belum ada, shift aktif | 1 = kasir | Tidak mengarahkan tambah produk |
| Produk ada, stok awal belum ada, shift aktif, next_step=stock | 1 = kasir | Tidak mengarahkan stok awal |
| Offline tanpa shift | 4 = Lainnya | Fallback tersedia; bukan tes bootstrap offline |
| Toko belum ada dan punya izin toko | 10 = toko | Jalur konfigurasi toko tersedia |
| Tidak punya izin membaca shift | 4 = Lainnya | Tidak dipaksa ke halaman shift yang tidak berhak diakses |

## 8. Belum diuji / belum PASS sebagai perjalanan pengguna

Seluruh baris di bawah **belum dijalankan end-to-end pada audit ini**. Tidak boleh diubah menjadi PASS hanya karena 30 tes regresi/kontrak di atas lulus.

| Skenario penerimaan | Hasil yang wajib dibuktikan |
|---|---|
| Android, pemilik instansi POS benar-benar baru | PIN → produk pertama → stok awal → buka kas → penjualan pertama tanpa mencari menu tersembunyi |
| Web, instansi baru yang sama | Arahan dan stok/jurnal sama dengan mobile; tautan saldo awal tepat |
| Jasa tanpa stok | PIN → tambah layanan → kas/shift bila wajib → bayar; tidak diminta stok awal/HPP layanan/jadwal layanan langsung |
| Barang biasa, belum ada balance | Opening membentuk saldo lokasi, stok master/lokasi/katalog konsisten |
| Batch/expiry, FIFO, serial, BOM/bundle | Detail wajib sesuai jenis, stok komponen benar, tidak bypass pelacakan |
| Satuan box/pcs dan beberapa rak | Konversi qty/HPP, pilihan lokasi serta nilai persediaan benar |
| Kas awal 0 dan positif | Nilai tersimpan benar; shift aktif dipakai ulang; tidak salah pendapatan/kas |
| Kasir terbatas tanpa izin produk/manage_stock | Pesan tindakan pengelola jelas; API tetap menolak tindakan tanpa izin |
| Respons create/opening/shift hilang dan retry/double tap | Pulih dengan identitas yang sama, tidak membuat master, saldo, jurnal atau shift kedua |
| Offline pada pengguna benar-benar baru | Jelaskan perlu online untuk persiapan awal, jangan menganggap tenant/produk/toko tidak ada karena fetch gagal |
| Pengguna lama/offline dengan data tersimpan | Tidak dipaksa setup ulang, tidak reset toko/profil/shift; cache terikat instansi/operator |
| Dua perangkat/peralihan toko | Readiness dan saldo sesuai toko, tidak memakai shift kasir lain secara keliru |
| Finance setelah opening dan penjualan pertama | Nilai persediaan, lawan ekuitas saldo awal, HPP penjualan dan dimensi cabang sesuai; tidak membuat utang pembelian fiktif |

Status penutup: **audit selesai; perbaikan aplikasi dan pembuktian GUI perjalanan pengguna baru masih diperlukan.** Prioritas pertama NU-02 (saldo awal) dan NU-01 (arah setelah PIN). Jalur kas/shift tidak boleh dihapus sebagai jalan pintas untuk menutupi masalah ini.
