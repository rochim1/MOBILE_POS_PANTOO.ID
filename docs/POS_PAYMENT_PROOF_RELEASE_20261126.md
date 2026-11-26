# Perbaikan bukti pembayaran dan rilis POS — 26 November 2026

## Permintaan dan perjalanan pengguna

Memperbaiki temuan audit terbaru, memeriksa ulang flow terkait, kemudian membuat APK dan AAB produksi. Tidak ada plan terpisah; perjalanan berikut diturunkan dari temuan audit:

1. Kasir menyelesaikan penjualan/pembayaran pesanan dengan invoice yang dapat diverifikasi.
2. Respons hilang atau error internal: bukti tetap ada dan dapat dipulihkan dengan ID semula, tanpa transaksi pengganti yang berisiko duplikat.
3. Metode transfer adalah pencatatan manual, bukan pemeriksaan rekening/webhook. Piutang tetap tempo meskipun pemulihan diklik dengan metode lain.
4. Setelah sukses, katalog tetap terlihat dan stok/harga disegarkan di belakang layar (optimasi tugas sebelumnya ikut dalam paket baru).

## Perubahan

- Web: satu helper memeriksa penolakan pasti, identitas transaksi/invoice, status dan metode pembayaran pesanan.
- Error GraphQL internal, campuran, respons kosong/tidak cocok tetap belum pasti. Penolakan replay tidak dijadikan bukti bahwa pengiriman pertama gagal.
- Bukti checkout lama yang ditandai gagal permanen tanpa penolakan terkonfirmasi diubah ke `needs_review`, bukan dihapus. Identitas/payload tidak diubah. Operator asal dan verifikasi PIN tetap diperlukan.
- Mutation penjualan web meminta `client_transaction_id`; acknowledgment harus sesuai request, memiliki ID dan invoice. Pembayaran pesanan harus sesuai ID pesanan dan invoice, serta lunas atau tempo dengan status piutang yang sah.
- Lookup pemulihan pesanan memeriksa persyaratan yang sama; invoice pesanan lain tidak dapat menghapus bukti lokal.
- Mobile: hasil belum pasti tidak diberi judul “Transaksi Ditolak” dan tidak diarahkan ke perubahan pelanggan/otorisasi harga kedaluwarsa sebelum status transaksi diketahui.
- Tidak menambah webhook, mengubah jurnal/stock posting, menghapus antrean pembayaran, atau menulis ke database produksi.

## Bukti TDD

Web RED: `node --test tests/pos-checkout-intent.test.mjs tests/pos-checkout-terminal-state.test.mjs` menghasilkan **39 PASS, 17 FAIL** untuk skenario ketidakpastian dan acknowledgment salah. Log: `output/pos-payment-proof-red-20261126.log` di root workspace. Checkpoint RED `c62a4cea`, GREEN `5abcfd7c`: **56 PASS** pada target yang sama.

Mobile RED: dua tes judul dialog menghasilkan **1 PASS, 1 FAIL**; checkpoint `8bc704b`. Setelah perbaikan, seluruh `pos_payment_mobile_layout_test.dart` **16 PASS**, checkpoint GREEN `fd0116c`. Log di `output/operational-readiness-20261125/payment-status-{red,green}-20261126.log` pada proyek mobile.

Pemeriksaan lanjutan menemukan getter bukti pembayaran dapat melempar `StateError` saat identitas akun hilang. Tes tambahan membuktikan dialog gagal; checkpoint RED `947b5b8`. Perbaikan mempertahankan label belum pasti tanpa menghapus bukti, checkpoint GREEN `7bd56af`.

Run mobile lengkap dengan coverage mencakup 1.345 tes: **1.343 PASS, 2 FAIL**. Dua kegagalan adalah reproduksi kehilangan identitas di atas dan audit label yang timeout 30 detik saat host sibuk. Setelah perbaikan, delapan berkas terkait diulang dengan concurrency 2: **62 PASS, 0 FAIL**, termasuk kedua target tadi dan 17 tes halaman pembayaran. Tidak menaikkan timeout atau menghapus assertion. Ini adalah hasil gabungan full run + rerun target, bukan satu full run final yang seluruhnya hijau. Log: `payment-proof-full-20261126.log` dan `payment-proof-focused-20261126.log` pada `output/operational-readiness-20261125`.

`dart analyze --fatal-infos`: **No issues found!**, exit 0. Log: `payment-proof-analyze-20261126.log` pada folder yang sama. Tidak ada kegagalan tes yang diketahui tersisa setelah rerun.

## Spesifikasi dan hasil yang telah diverifikasi

| Jaminan | Target aktual | Jenis | Hasil |
|---|---|---|---|
| Error internal/campuran dan penolakan replay tidak membuka checkout pengganti | `pos-checkout-intent.test.mjs`, `pos-checkout-terminal-state.test.mjs` | Fungsi aplikasi aktual + transport tiruan | PASS |
| ID/invoice tidak lengkap atau milik request lain tidak menghapus bukti | Dua berkas di atas + `pos-checkout-proof.test.mjs` | Unit/integrasi komponen | PASS |
| Pemulihan lama tetap tersedia; kredensial tidak disimpan dalam payload | `pos-checkout-intent.test.mjs`, `pos-outbox-revocation.test.mjs` | Penyimpanan terisolasi | PASS |
| Operator lain tidak mengirim antrean kasir asal; offline tidak mengirim request | `pos-outbox-revocation.test.mjs`, `pos-checkout-intent.test.mjs` | Integrasi komponen | PASS |
| Jasa langsung/reservasi, harga fleksibel, pesanan, tempo, promo dan katalog tetap berfungsi | Semua `tests/pos*.mjs` | Regresi web | **454 PASS, 0 FAIL** |
| Transfer manual tersimpan tanpa webhook; recovery tidak menambah jurnal/transaksi/kas | `pos_order_payment_recovery.integration.test.js` | Resolver aktual + MongoDB replica set lokal sementara | PASS |
| Request sama bersamaan hanya sekali, stok terakhir tidak terjual dua kali, jurnal gagal menggulung balik stok/kas | `pos_checkout_optimization.integration.test.js` | Integrasi server + DB lokal sementara | PASS |
| Dokumen GraphQL web sesuai skema server termasuk identitas ACK | `pos_promo_order.contract.test.js` | Kontrak | PASS |
| Ketiga berkas server di atas | `node --test --test-concurrency=1 ...` | Integrasi/kontrak | **20 PASS, 0 FAIL** |

Log regresi web final: `output/pos-payment-proof-all-web-final-20261126.log`; server: `output/pos-payment-proof-server-green-20261126.log`, keduanya di root workspace.

## Cakupan dan batas

Helper baru `checkout-proof.mjs`: **100% baris/cabang/fungsi** dari Node precise coverage. Perubahan executable pada metode Vue: **3/3 baris** terukur; outbox **17/17 baris** pada pengukuran final. Range fungsi V8 dicocokkan dengan nama dan panjang sumber AST, bukan hanya nama, untuk menghindari hit palsu. Data mentah: `output/pos-payment-proof-v8-final-20261126` pada workspace. Ini bukan klaim 100% seluruh aplikasi.

Mobile: **6/6 baris executable yang ditambah/diubah = 100%**, dari LCOV `payment-proof-focused-20261126.info`, diff produksi terhadap `13480ca`. Komentar dan markup non-executable tidak dihitung; perubahan startup milik pekerjaan lain tidak masuk perhitungan ini.

Pengujian ini terisolasi, bukan GUI HP fisik/Play Store atau deploy web/server. Penyebab penolakan transfer pertama pada perangkat pengguna belum bisa dipastikan tanpa error awal lengkap; tidak boleh menghapus bukti belum pasti untuk membuat layar kasir hilang. Tidak ada transaksi pengganti atau penghapusan data aplikasi dalam tugas ini.

## Paket produksi

Versi sumber dinaikkan dari **1.0.24+25** ke **1.0.25+26** (checkpoint `9dfc166`). APK dan AAB produksi selesai, masing-masing 131.412.000 dan 109.743.483 byte; lokasi `D:/my node app/zera/output/pos-release-1.0.25+26-20261126`. Identitas kedua manifest: `id.pantoo.pos`, versionName `1.0.25`, versionCode `26`, minSdk 24, targetSdk 36.

`flutter clean` selesai exit 0, termasuk penghapusan `build` dan `.dart_tool`; `flutter pub get` exit 0. Tidak mengubah dependency constraint/lockfile atau endpoint untuk melewati build. Build produksi berjalan setelah semua tes di atas selesai.

APK `scripts/build-pos-apk.ps1 -Flavor production` exit 0 (Gradle 418,1 detik). AAB `flutter build appbundle --release --flavor production --target lib/main_production.dart --no-pub` exit 0 (32,6 detik). APK apksigner v2 PASS; AAB bundletool 1.18.3 validate dan jarsigner verify exit 0. Manifest dan sertifikat kedua paket sesuai; hash kode native sama pada ketiga ABI. Rincian checksum, sertifikat, dan warning sertifikat upload ada pada README folder rilis. Log build/validasi berada pada `output/operational-readiness-20261125/release-1.0.25-*-20261126.log`.

Tidak upload Play Store, deploy web/server, memasang APK baru, atau menghapus data perangkat dalam tugas ini. Perbaikan web perlu dipublikasikan lewat deployment web; APK/AAB tidak mengubah web yang sedang berjalan.

## Evaluasi penyerahan

| Aspek | Nilai | Bukti dan batas |
|---|---:|---|
| Akurasi | 4/5 | Hasil tes dan pemeriksaan paket nyata dicatat; GUI HP dengan paket baru belum dijalankan |
| Kelengkapan | 4/5 | Tiga temuan audit web, feedback mobile dan kedua paket selesai; akar penolakan awal perangkat pengguna belum diketahui tanpa error lengkap |
| Kejelasan | 4/5 | Penolakan pasti dibedakan dari hasil belum pasti; detail teknis dipusatkan di laporan |
| Dapat digunakan | 5/5 | Paket produksi bertanda tangan, versi baru, checksum dan lokasi tersedia |
| Keringkasan | 4/5 | Jawaban penyerahan singkat; pembaruan selama tes/build cukup banyak karena durasinya |

Rata-rata 4,2/5; tidak ada isu kritis tersisa pada pekerjaan yang diuji. Perbaikan lanjutan paling bernilai: smoke-test GUI pada perangkat target dan pemeriksaan error awal transfer bila muncul lagi. Self-check: hasil memenuhi permintaan perbaikan temuan dan pembuatan APK/AAB, bukan jaminan bahwa seluruh skenario produksi sudah diuji pada perangkat fisik.
