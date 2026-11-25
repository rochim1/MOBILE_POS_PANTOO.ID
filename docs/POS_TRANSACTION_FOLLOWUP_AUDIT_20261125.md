# Audit tambahan transaksi POS — 25 November 2026

Lanjutan pemeriksaan retur, piutang, refund dan penutupan shift: [audit alur terkait](POS_RELATED_TRANSACTION_FLOWS_AUDIT_20261125.md). Hasil historis pada laporan ini tidak diganti dengan klaim GUI atau deployment baru.

## Hasil dan batas

Permintaan: periksa bug lain ketika melakukan transaksi, setelah laporan kasir terus menampilkan pemulihan pembayaran. Lima kelompok temuan diperbaiki pada source mobile/web. Gate akhir: **1.227 tes Flutter PASS**, **403 tes POS web PASS**, **34 tes server PASS**. Analisis delapan berkas Dart bersih. Tidak membuat APK/AAB, deploy web/server, menghapus proof atau data HP, mereset akun, melewati PIN/izin, atau menulis database produksi.

Ini bukan klaim transaksi lama pada HP pengguna sudah dipulihkan. Tidak ada request ID maupun respons server HP yang dapat diverifikasi dalam sesi ini; pengguna mengonfirmasi tombol tetap menampilkan pesan yang sama. Perbaikan source perlu build/rilis/pemasangan baru, sedangkan kasus lama tetap harus dipulihkan dengan ID semula. Pengujian GUI Android fisik dan browser nyata setelah patch belum dilakukan.

## Temuan yang diperbaiki

| # | Temuan dan dampak | Perbaikan dan jaminan |
|---|---|---|
| 1 | Pembayaran baru menunggu probe jaringan Android tanpa batas; sebelumnya hanya recovery yang punya timeout | Probe awal juga dibatasi 3 detik. Bila belum ada mutation yang dikirim, hanya intent baru yang dilepas; proof replay tetap utuh. Tidak membuat transaksi offline karena probe belum menjawab |
| 2 | Input baru yang tidak valid dapat terlanjur disimpan lalu gagal dibaca, sehingga percobaan berikutnya terkunci meski tidak ada pembayaran terkirim | Validasi struktur/angka yang sama dipakai sebelum durable write. Empat kasus: items kosong, toko hilang, total negatif, subtotal hilang. Proof lama yang rusak/berbeda tetap fail-closed, tidak dihapus atau ditimpa |
| 3 | Pergantian PIN/operator selama await otorisasi offline dapat melanjutkan antrean dan pengurangan cache stok dengan identitas yang sudah berubah | Snapshot sesi diperiksa setelah otorisasi, saat memuat DB, sebelum insert, sebelum commit SQLite, dan sebelum hasil sukses/ACK lokal. Perubahan dalam transaksi melempar sehingga transaksi SQLite dapat rollback. Tes race pada fase otorisasi membuktikan nol antrean dan stok tetap; injeksi crash pada setiap instruksi SQLite belum diuji |
| 4 | Mobile maupun kasir web menerima objek pembayaran pesanan tanpa memastikan ID dan bukti sale cocok; kasir dapat memperoleh feedback sukses yang belum sah | ID pesanan harus cocok, nomor struk penjualan harus ada, dan status harus lunas atau status piutang yang sesuai metode tempo. Respons kosong/asing/tanpa proof/tunai belum bayar ditolak. Mobile juga menolak respons setelah identitas berubah |
| 5 | Web memakai metode, split dan kembalian dari percobaan ulang, bukan hasil yang sudah commit | Struk dan judul sukses mengikuti tender server, kembalian canonical dan komponen split. Recovery tempo tidak berubah menjadi klaim tunai/lunas. Query pembayaran mengambil field uang/kembalian/split yang sudah tersedia di schema |

Pemeriksaan alur reservasi menunjukkan pembayaran baru memang menyimpan pesanan reservasi terlebih dahulu, lalu membayar order yang sama. Parameter jadwal yang tidak digunakan pada submit sale bukan alasan untuk menambahkan form reservasi kedua. Alur ini tidak diubah.

## Follow-up pemulihan dari pekerjaan sebelumnya

Checkpoint `8b96b07` → `e796d43` memperbaiki penolakan GraphQL yang dibungkus HTTP, membedakan koneksi/server/ACK asing, dan menampilkan referensi pembayaran yang dapat disalin. Sebelas reproduksi gagal → dua suite35PASS, kemudian paket113PASS. Patch itu belum dirilis pada saat laporan HP diterima. Satu peringatan kurung pada fixture yang tersisa sudah dibereskan dan termasuk analisis bersih final pekerjaan ini. Laporan ini melengkapi [audit tombol pemulihan](POS_CHECKOUT_RECOVERY_BUTTON_20261125.md), bukan menghapus hasil/batas historisnya.

## Perjalanan dan bukti TDD

Tidak ada plan baru dari pengguna; perjalanan diturunkan dari keluhan dan audit: kasir dapat pulih dari preflight macet tanpa transaksi pengganti, data tidak valid tidak merusak pembayaran berikutnya, perubahan identitas tidak mengotorisasi write lama, dan pembayaran pesanan hanya dinyatakan selesai sesuai bukti canonical.

| TEST-ID | Reproduksi / bukti | Hasil dan jenis |
|---|---|---|
| TEST-POS-TX-PREFLIGHT-2511 | Native connectivity Future tidak selesai; paling lambat5detik caller sudah selesai, nol HTTP/antrean, tidak ada fence baru | PASS unit/integration, MethodChannel terkontrol |
| TEST-POS-TX-VALIDATE-2511 | Empat input invalid ditolak sebelum preference ditulis; percobaan valid berikutnya tetap bisa begin | PASS unit, durable-store boundary |
| TEST-POS-TX-OFFLINE-ACTOR-2511 | Kasir berganti di callback otorisasi offline; hasil Left, queue0, stok10, proof kasir asal tetap ada | PASS repository + SQLite temporer |
| TEST-POS-TX-ORDER-ACK-2511 | Lima respons invalid/identitas berubah dan tiga kontrol tunai/piutang/partial piutang | PASS8kasus integrasi mobile; retry tunai tidak mengganti tender tempo yang sudah commit |
| TEST-POS-TX-WEB-ACK-2511 | ID asing, tanpa struk dan tunai belum bayar tidak meng-ACK intent/tidak sukses; kontrol tempo/tunai/split memakai data server | PASS6kasus runtime metode Vue nyata dengan I/O terkontrol |
| TEST-POS-TX-REGRESSION-2511 | Tap ganda, cart freeze, satuan/harga jasa, pending order/customer, split, PIN offline revocation, subscription, ID/EN | PASS paket136 dan seluruh Flutter1227; angka bertumpang tindih, tidak dijumlahkan |
| TEST-POS-TX-SERVER-2511 | Concurrent replay/last-unit contention, lost ACK setelah shift tutup, rollback jurnal, harga jasa/tempo, pemulihan tunai/split/piutang dan jurnal seimbang | PASS34kasus pada DB Mongo temporer lokal; bukan DB produksi |
| TEST-POS-TX-DEVICE-2511 | APK terbaru + pembayaran/recovery nyata pada HP dan kasir web browser | **unverified**; belum build/deploy dan bukan hasil GUI nyata |

Mobile RED valid `transaction-extra-red2.log`:39PASS/6FAIL, bukan kegagalan compiler. Perbaikan fixture tipe nullable pada percobaan pertama dicatat sebagai setup, tidak dianggap bukti bug. RED checkpoint **6c82e53** → GREEN **a1142c9**, dua suite45PASS (`transaction-extra-green.log`).

Mobile order ACK RED valid `order-payment-ack-red2.log`:3PASS/5FAIL; percobaan awal memakai opsi cache yang tidak tersedia bukan RED bisnis. Checkpoint **5bc127a** → GREEN **aada79f**,8PASS; final sesudah perapian kurung8PASS (`order-payment-ack-final.log`).

Web branch aktif `production`: RED **26718159**,24PASS/4FAIL (`web-order-ack-red.log`) → GREEN **70add70c**,28PASS (`web-order-ack-green.log`). Dua kontrol canonical cash/split tambahan tercakup runner403PASS final. Tidak push atau deploy branch. Mobile branch `main`; dirty work lain/versi aplikasi pengguna dipertahankan dan tidak dimasukkan checkpoint.

## Perintah dan keluaran aktual

Mobile cwd `mobile_POS_Pantoo`:

```text
flutter test --no-pub --concurrency=2 --timeout 2m
```

`transaction-extra-all-tests.log`: **04:34 +1227: All tests passed!**, exit0. Full suite dimulai setelah perbaikan produksi terakhir; perapian dua kurung fixture berikutnya diverifikasi ulang dengan delapan tes order ACK dan analyzer final.

```text
flutter test --no-pub --concurrency=2 --timeout 2m --coverage --coverage-path=output/operational-readiness-20261125/transaction-extra-final3-lcov.info test/pos_checkout_request_store_test.dart test/pos_checkout_recovery_test.dart test/pos_checkout_recovery_flow_test.dart test/pos_order_payment_ack_test.dart test/pos_payment_single_flight_test.dart test/pos_checkout_cart_lock_test.dart test/pos_pending_payment_flow_test.dart test/pos_payment_mobile_layout_test.dart test/pos_flexible_service_test.dart test/pos_cart_units_test.dart test/pos_offline_revocation_sync_test.dart test/pos_checkout_preparation_test.dart test/pos_localization_test.dart
```

`transaction-extra-final3.log`: **00:45 +136: All tests passed!**, exit0. Runner terdahulu memakai nama suite layanan yang tidak ada dan gagal load1target; itu diperbaiki, bukan diklaim PASS. Hasil128pada paket sebelum order ACK termasuk136, bukan tambahan128tes unik.

```text
dart analyze --fatal-infos lib/core/network/pos_checkout_request_store.dart lib/domain/repositories/pos_repository.dart lib/presentation/pages/pos/pos_page.dart lib/presentation/pages/pos/widgets/pos_checkout_recovery_panel.dart test/pos_checkout_request_store_test.dart test/pos_checkout_recovery_test.dart test/pos_checkout_recovery_flow_test.dart test/pos_order_payment_ack_test.dart
```

`transaction-extra-analyze-clean.log`: **No issues found!**, exit0. Coverage executable changed-line pada dua source mobile terhadap `e796d43`: store20/20, repository23/24, gabungan **43/44 (97,7%)**; seluruh class checkout store62/62. Satu baris tak tercakup adalah guard cabang stok nonaktif. Bukan coverage seluruh repository/aplikasi. Metrik baris Vue tidak diinstrumentasi; pengujiannya runtime metode yang diekstrak dari AST SFC, ditambah compile/contract pada suite web, bukan GUI browser.

Web cwd `front_end_template`: `node --test` seluruh `tests/pos*.test.mjs` dan `tests/preserve-pos-recovery.test.mjs` → **403PASS/0FAIL/0skip**, exit0, `transaction-extra-web-final.log`,5,2detik. Tidak menjalankan build web.

Backend cwd `presensi_zera_BE`:

```text
node --test --test-concurrency=1 tests/pos_checkout_optimization.integration.test.js tests/pos_order_payment_recovery.integration.test.js tests/pos_flexible_service_pricing.integration.test.js tests/finance_pos_inventory_sync.test.js
```

`transaction-extra-server.log`: **34PASS/0FAIL/0skip**, exit0,32,8detik. Tiga suite memakai MongoMemoryReplSet dan suite jurnal memakai MongoMemoryServer lokal; model/query/transaction/journal asli diuji. Log mencatat warning deprecation dan koneksi Mongo ECONNRESET; asal warning tersebut tidak didiagnosis lebih lanjut, dan tidak ada tes gagal. Source backend tidak diubah.

## Penerapan dan pemeriksaan berikutnya

1. Build APK/AAB dari source ini dan pasang/publikasikan; paket1.0.23+24 yang sudah terpasang tidak menerima patch lokal otomatis. Instal sebagai update, jangan clear data/uninstall.
2. Di kasir HP, pulihkan ID yang sama. Jika gagal, salin referensi pembayaran dan alasan spesifik dari panel. Periksa hasil canonical server dengan akses admin; jangan membuat sale pengganti untuk menghilangkan fence.
3. Rilis perubahan web lalu ulangi GUI order restoran, tempo dan recovery tender berbeda; pastikan nomor invoice/metode/kembalian sesuai transaksi asli.
4. Validasi Android fisik, pergantian operator di fase SQLite yang berbeda dan crash proses/penyimpanan tetap menjadi pengujian perangkat lanjutan; gate kode bukan sertifikasi seluruh profil/hardware produksi.

## Evaluasi

Rata-rata4,0/5: akurasi4 (RED/GREEN dan hasil runner ada; transaksi HP lama belum diverifikasi), kelengkapan4 (lima kelompok risiko mobile/web dan34integrasi server; GUI perangkat/crash matrix belum), kejelasan4 (bukti lokal dibedakan dari deployment), dapat ditindaklanjuti4 (source/komit/perintah tersedia; butuh build dan uji HP), keringkasan4 (jawaban pengguna ringkas, detail di file). Prioritas: rilis/pasang tanpa hapus data, kemudian recovery transaksi lama dan GUI tender canonical. Self-check: layak sebagai audit dan perbaikan teruji kode, bukan klaim semua bug atau pembayaran HP sudah selesai.
