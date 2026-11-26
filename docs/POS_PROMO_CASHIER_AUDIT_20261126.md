# Audit penerapan kode promo kasir — 26 November 2026

## Ruang lingkup

Permintaan: periksa penerapan kode promo di Android dan web. Pemeriksaan mencakup input kasir, preview harga, alasan penolakan, pembayaran, dan pencatatan pemakaian promo. Skenario diturunkan dari permintaan ini, tanpa dokumen rencana terpisah.

Kode promo produksi yang bermasalah tidak disebutkan. Karena itu, laporan ini membuktikan perilaku kode dan skenario uji, bukan menyimpulkan konfigurasi promo tertentu pada akun pengguna.

## Temuan dan tindakan

### Mobile

- Dialog lama langsung tertutup setelah Terapkan; hasil validasi tidak terlihat di dialog. Diganti dengan dialog yang tetap menampilkan loading, hasil, alasan penolakan, dan tombol hapus/tutup.
- Kegagalan preview sebelumnya dibuang tanpa penjelasan. Gangguan koneksi kini meminta pengguna menyambungkan internet atau menghapus promo; penolakan server tetap ditampilkan.
- Mengganti atau menghapus kode sebelumnya tidak segera menghapus potongan lama. Preview lama kini dibatalkan saat input diskon berubah; respons yang terlambat tetap ditolak.
- Enter pada field promo panel transaksi sebelumnya tidak menjalankan penerapan. Kini Enter dan tombol Terapkan memakai alur yang sama; kode dinormalisasi dengan trim dan huruf kapital. Jalur F7 dari widget halaman kasir nyata juga diuji sampai Terapkan, alasan validasi, dan Tutup.
- Tidak ada toko yang memenuhi syarat sebelumnya menyebabkan verifikasi berhenti tanpa keterangan. Kini tampil arahan memilih toko kasir.
- Diskon manual pada dialog ringkas dibatasi untuk pengelola, sama dengan panel transaksi. Server tetap memeriksa otorisasi.
- Status loading baru juga diuji terhadap pembatalan keranjang dan penolakan pembayaran agar tidak tertinggal. Pembayaran membatalkan preview latar belakang yang sedang berjalan.
- Pengecekan ulang input yang tidak berubah mempertahankan harga khusus pelanggan yang sudah disepakati. Ini diperbaiki setelah pengujian regresi selama implementasi menemukan harga sempat kembali ke harga dasar.
- Ditambahkan 14 teks Indonesia–Inggris: loading, hasil promo, serta alasan batas pelanggan, periode, channel, tier, kebijakan, minimal pembelian, dan cooldown. Teks server lain yang tidak dikenal tetap ditampilkan apa adanya.

### Web

Tidak ditemukan kegagalan pada metode penerapan dalam skenario yang diuji; tidak ada perubahan kode produksi Vue. Ditambahkan tes perilaku untuk normalisasi kode, pelanggan dalam permintaan preview, hasil validasi, gangguan koneksi, respons lama, dan keranjang kosong. Regresi penyelesaian checkout ikut dijalankan.

### Server dan ketentuan promo

- Promo default dengan batas pemakaian per pelanggan memang memerlukan pelanggan CRM dipilih. Pesan `Pilih pelanggan untuk menggunakan kode promo ini` adalah validasi bisnis, bukan izin mengubah harga manual.
- Kasir biasa dapat memakai promo yang memenuhi syarat tanpa hak mengubah harga manual.
- Preview tidak mengonsumsi kuota promo.
- Promo tidak aktif atau kebijakan `manual_only` memberikan alasan penolakan yang berbeda.
- Pembayaran memakai total setelah potongan; replay transaksi yang sama tidak menggandakan pemakaian promo.
- Kedua dokumen query preview harga cocok dengan skema GraphQL lokal.
- Tidak mengubah aturan promo, hak akses server, data produksi, stok, atau jurnal produksi.

## Bukti pengujian

| Pemeriksaan | Jenis | Hasil |
|---|---|---|
| Promo, dialog ponsel + keyboard, harga jasa, penguncian checkout, pesanan tersimpan, lokalisasi | Unit/widget Flutter, 6 berkas | PASS — 69 tes |
| Penerapan promo web dan penyelesaian checkout | Metode Vue aktual dengan layanan tiruan | PASS — 35 tes |
| Kelayakan promo, preview, pembayaran, dan replay | Integrasi resolver + MongoDB replica set sementara | PASS — 4 tes |
| Query kedua klien, kontrak promo/pesanan/atribusi pelanggan | Kontrak GraphQL | PASS — 6 tes |
| Seluruh suite Flutter setelah perbaikan terakhir | Regresi | PASS — 1.338 tes, 4 menit 17 detik |
| Analisis Dart seluruh proyek | Analisis statis | PASS — No issues found, exit 0 |

Perintah yang dijalankan:

```text
flutter test --no-pub test/pos_promo_apply_test.dart test/pos_flexible_service_test.dart test/pos_checkout_cart_lock_test.dart test/pos_keyboard_navigation_test.dart test/pos_held_order_safety_test.dart test/pos_localization_test.dart --coverage --coverage-path=output/operational-readiness-20261125/promo-focused-final-20261126.info --reporter expanded
flutter test --no-pub --concurrency=2 --reporter expanded
dart analyze --fatal-infos
node --test tests/pos-promo-apply.test.mjs tests/pos-checkout-terminal-state.test.mjs
node --test tests/pos_promo_cashier.integration.test.js tests/pos_promo_order.contract.test.js
node --test tests/pos_promo_order.contract.test.js
```

Perintah Flutter dijalankan dari `mobile_POS_Pantoo`; dua perintah Node terakhir dari `presensi_zera_BE`; tes Vue dari `front_end_template`. Pemeriksaan kontrak terakhir menambahkan validasi dokumen pricing untuk kedua klien.

### Cakupan dan jejak TDD

- Reproducer pertama: 2 PASS, 6 FAIL karena normalisasi, potongan lama, pesan kegagalan, toko tidak tersedia, dan Enter. Setelah perbaikan: 8 PASS.
- Pembatalan keranjang: 8 PASS, 1 FAIL; setelah perbaikan: 9 PASS.
- Penolakan pembayaran ketika preview berjalan: 14 PASS, 1 FAIL; setelah perbaikan: 15 PASS.
- Run menyeluruh sebelum perbaikan terakhir: 1.324 PASS, 14 FAIL. Ke-14 kegagalan sengaja mereproduksi 13 alasan promo yang belum diterjemahkan dan harga pelanggan yang ter-reset; semuanya termasuk pengujian terfokus yang kemudian PASS.
- Cakupan baris executable yang ditambah/diubah pada enam berkas produksi kasir: **119/134 = 88,81%**, dibanding checkpoint `555be8c`. Perubahan startup yang sudah ada sebelum tugas tidak dihitung. Berkas lokalisasi generated tidak termasuk metrik ini; 13 pemetaan pesan diuji secara eksplisit.
- Checkpoint mobile: `555be8c` → `25cb0e4`; `add2ad1` → `f11752f`; `c4a537b` → `e1c76b9`; `b272b26` → `31b2442`. Checkpoint RED/GREEN tetap tersedia di branch `main`.
- Tes server disimpan pada `eaace595` dan kontrak pada `43526273`; tes web pada `60ad2921`.

Log mobile/web berada di `output/operational-readiness-20261125/promo-*-20261126.log`; cakupan terfokus di `promo-focused-final-20261126.info`. Log server berada di `presensi_zera_BE/output/promo-cashier-20261126.log` dan `promo-contract-20261126.log`. Ada warning koneksi dari pengelola database sementara saat teardown integrasi; seluruh assertion integrasi akhirnya PASS dengan exit 0. Percobaan awal salah memakai nama field hasil transaksi (`grand_total` alih-alih `total`), lalu diperbaiki pada tes dan diulang.

## Batas verifikasi

Tidak melakukan build APK/AAB, deploy, pengujian GUI emulator/peramban terhubung, ataupun mencoba kode promo aktual di perangkat pengguna. Tes mobile berupa widget/logic pada host Windows, tes web berupa eksekusi metode Vue, dan tes pembayaran server memakai database sementara yang terisolasi. Hasil ini tidak membuktikan aplikasi Play Store yang terpasang sudah memuat perubahan.

## Evaluasi hasil

Skor 4/5 untuk akurasi: bukti tes dan batas verifikasi dicatat, tetapi kode promo pengguna belum dapat direproduksi secara spesifik. Kelengkapan 4/5: kedua klien dan pembayaran diperiksa, belum GUI/perangkat aktual. Kejelasan 4/5: sebab teknis dipisahkan dari syarat promo; detail bukti memang cukup panjang. Kemudahan tindakan 4/5: perbaikan dan tes tersedia, APK belum dibuat. Keringkasan 4/5: jawaban pengguna dapat singkat, rincian disimpan di laporan. Rata-rata 4,0/5. Perbaikan lanjutan terbesar adalah uji GUI dengan kode promo yang benar-benar dilaporkan; hasil tidak boleh disebut sudah terverifikasi pada HP pengguna.
