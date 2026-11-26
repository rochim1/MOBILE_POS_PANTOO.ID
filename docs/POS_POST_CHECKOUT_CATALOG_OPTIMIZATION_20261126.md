# Katalog kasir tetap siap setelah transaksi — 26 November 2026

## Hasil dan pendekatan

Pembaruan stok/harga masih diperlukan setelah transaksi, tetapi tidak perlu menghilangkan daftar dan membuat kasir menunggu. Implementasi mobile dan web kini mempertahankan katalog yang sedang terlihat, kemudian memperbarui halaman itu di latar belakang.

Tidak mengubah pembayaran, posting Finance, stok server, otorisasi, atau perlindungan request transaksi. Tidak menebak pengurangan stok di perangkat berdasarkan item struk: paket/BOM, konversi satuan, reservasi, serta transaksi offline dapat mempunyai efek stok berbeda. Katalog diambil kembali dari sumber server/cache yang sudah digunakan aplikasi, dan server tetap memvalidasi stok saat checkout berikutnya.

## Penyebab sebelumnya

### Mobile

1. Tombol selesai pada struk menjalankan `RefreshProducts`.
2. Handler memanggil loader produk umum `getProducts`, yang saat ini mengambil halaman pertama katalog—bukan seluruh koleksi produk tanpa batas.
3. Perubahan daftar `state.products` dianggap perubahan scope oleh panel katalog. Panel menghapus hasil terlihat, kembali ke halaman pertama, lalu meminta halaman katalog lagi.

Ini menyebabkan dua pengambilan halaman katalog berurutan pada jalur tersebut dan tampilan seperti reload saat kembali ke kasir.

### Web

Setelah transaksi selesai, `loadProducts()` tetap menyalakan `loadingProducts`, sehingga daftar digantikan skeleton meski produk toko yang sama sudah tersedia. `newTransaction()` juga menghapus konteks pencarian/kategori.

## Perubahan

### Mobile

- Setelah hasil transaksi dikonfirmasi, `catalogRevision` berubah sehingga panel katalog yang masih terpasang dapat mulai memperbarui saat layar struk masih terbuka.
- Refresh hanya mengambil halaman aktif, dengan pencarian, kategori, dan favorit yang sedang dipakai.
- Daftar, halaman, dan posisi scroll tidak sengaja dihapus ketika master/stok toko yang sama diperbarui. Indikator kecil pencarian yang sudah ada tetap dapat menunjukkan aktivitas jaringan; tidak ada skeleton pengganti daftar tersebut.
- Tombol selesai pada struk hanya mengakui status sukses; tidak memanggil loader produk umum atau memulai permintaan katalog kedua.
- Pemulihan pembayaran yang benar-benar dikonfirmasi juga memicu pembaruan katalog terbatas. Keranjang lain tetap tidak dihapus.
- Sinyal refresh yang tiba dalam frame yang sama digabungkan menjadi satu permintaan.
- Pergantian toko/lokasi/filter tetap mengganti scope. Data toko lama dibersihkan dan respons yang terlambat tidak boleh menimpa toko baru.
- Jika pembaruan latar belakang gagal, daftar yang sudah ada tetap terlihat; kegagalan tidak mengubah penjualan sukses menjadi pembayaran gagal.

### Web

- `loadProducts({ background: true })` mempertahankan daftar toko yang sama tanpa menyalakan skeleton.
- Setelah penjualan sukses, keranjang dan konteks pembayaran dibersihkan, tetapi konteks katalog dipertahankan untuk melanjutkan pelayanan.
- Refresh tetap berupa satu halaman maksimal 30 item, memakai filter aktif; pergantian toko atau muat pertama tetap mempunyai loading normal.
- Versi permintaan tetap melindungi hasil pencarian/toko terbaru dari respons lama.
- Diperbaiki juga loading yang bisa tertinggal ketika request lama belum selesai, lalu toko/lokasi menjadi tidak valid.

## Bukti yang diukur

| Pemeriksaan | Sebelum | Sesudah |
|---|---|---|
| Perubahan katalog mobile pada halaman 2 | Meminta halaman 1, menghapus daftar terlihat | Meminta halaman 2, daftar tetap terlihat selama request ditahan |
| Loader produk umum setelah checkout mobile | Dipanggil setelah tombol selesai | 0 panggilan pada jalur sukses/acknowledgment yang diuji |
| Pembaruan saat kembali dari struk | Menunggu/memicu pengambilan produk umum dan refresh panel | Refresh halaman aktif mulai dari konfirmasi transaksi; acknowledgment tidak menambah request |
| Web, background request sengaja belum diselesaikan | `loadingProducts=true` | `loadingProducts=false`; produk lama toko yang sama tetap terlihat |
| Dua invalidasi mobile dalam frame sama | Tidak ada jaminan penggabungan | Satu permintaan halaman pada tes |

Angka ini adalah bukti jumlah request dan perilaku UI pada layanan tiruan, **bukan pengukuran milidetik di HP/jaringan produksi**. Tidak mengklaim waktu posting pembayaran atau jurnal menjadi lebih cepat.

## Validasi

| Pengujian | Hasil |
|---|---|
| Mobile terfokus: katalog, pembayaran, struk nonblocking, recovery, lock keranjang, keyboard, harga jasa | PASS — 50 tes |
| Web: katalog background + paging dan regresi checkout/promo/pesanan/offline/piutang/refund/shift | PASS — 203 tes |
| Seluruh suite Flutter | PASS — 1.342 tes, 6 menit 49 detik, exit 0 |
| Analisis Dart seluruh proyek | PASS — No issues found, exit 0 |

Perintah utama:

```text
flutter test --no-pub test/pos_cashier_catalog_refresh_test.dart test/pos_catalog_pagination_test.dart test/pos_checkout_recovery_flow_test.dart test/pos_success_print_nonblocking_test.dart test/pos_keyboard_navigation_test.dart test/pos_checkout_cart_lock_test.dart test/pos_flexible_service_test.dart --coverage --coverage-path=output/operational-readiness-20261125/catalog-background-focused-20261126.info --reporter expanded
flutter test --no-pub --concurrency=2 --reporter expanded
dart analyze --fatal-infos
node --test tests/pos-catalog-background-refresh.test.mjs tests/pos-catalog-pagination.test.mjs tests/pos-checkout-terminal-state.test.mjs
```

Run web 203 tes mencakup tiga berkas di atas serta 17 berkas POS terkait; daftar subtest terdapat di log `output/pos-catalog-background-web-regression-20261126.log` pada root workspace. Tes awal tiga berkas berjumlah 40; setelah dua kasus konteks invalid dan satu kasus kegagalan background ditambah, jumlahnya 43.

### RED/GREEN dan cakupan

- Mobile: tes widget terlebih dahulu membuktikan refresh halaman 2 justru meminta halaman 1. Checkpoint RED `6fd2643`, GREEN `f8496ce` dengan empat tes saat itu. Penambahan tes selanjutnya membuktikan sukses, penolakan, acknowledgment, coalescing, kegagalan jaringan, dan respons toko lama.
- Web: 2 PASS/2 FAIL sebelum optimasi (`42a040bb`), lalu 40 PASS (`feada33e`). Kasus konteks invalid berikutnya 5 PASS/2 FAIL (`52ea578d`), lalu 43 PASS (`09556d62`). Pengujian checkout aktual diperluas pada `7331ad4e`.
- Mobile: **22/24 = 91,67%** baris executable yang ditambah/diubah pada berkas produksi, terhadap checkpoint `6fd2643`. Perubahan startup yang sudah ada sebelum tugas dikecualikan.
- Web: **11/11 = 100%** baris yang ditambah/diubah dalam tiga metode katalog/checkout, terhadap checkpoint `42a040bb`. Diukur dari V8 precise coverage pada fungsi aktual hasil ekstraksi Vue; range fungsi dicocokkan dengan panjang sumber AST agar tidak menghitung fungsi lain bernama sama.

Log mobile berada di `mobile_POS_Pantoo/output/operational-readiness-20261125/catalog-background-*-20261126.log`; LCOV terfokus pada `catalog-background-focused-20261126.info`. Log web pada `output/pos-catalog-background-web-*-20261126.log` di root workspace; data V8 pada `output/pos-catalog-background-v8-20261126`.

## Batas dan masalah terpisah

Tidak build APK/AAB, deploy, mengubah database produksi, atau menguji GUI perangkat/peramban aktif pada tugas ini. APK yang sudah terpasang belum otomatis memuat perubahan. Ini juga bukan penambahan streaming stok realtime antarkasir; validasi server tetap diperlukan pada setiap checkout.

Tiga temuan guard pemulihan pembayaran web dari laporan `front_end_template/docs/POS_WEB_PAYMENT_FLOW_AUDIT_20261126.md` adalah pekerjaan terpisah dan **belum diperbaiki oleh optimasi katalog ini**. Karena itu, hasil ini bukan klaim seluruh alur pembayaran web sudah siap produksi.

## Evaluasi hasil

Akurasi 4/5: request dan state diuji dengan angka aktual, belum benchmark HP. Kelengkapan 4/5: kedua klien dan kondisi gagal diperiksa; GUI produksi belum dijalankan. Kejelasan 4/5: pembaruan stok dibedakan dari reload penghambat; rincian teknis disimpan di sini. Kemudahan tindakan 4/5: implementasi dan tes tersedia, paket aplikasi belum dibuat. Keringkasan 4/5: jawaban pengguna dapat singkat, bukti lebih panjang di laporan. Rata-rata 4,0/5. Tindak lanjut terbesar adalah verifikasi GUI dan latency di perangkat target setelah build baru; tidak menyamakan hasil host test dengan jaminan performa seluruh perangkat.
