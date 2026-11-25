# Audit alur terkait transaksi POS — 25 November 2026

## Ringkasan dan batas bukti

Lanjutan dari [audit transaksi](POS_TRANSACTION_FOLLOWUP_AUDIT_20261125.md). Cakupan: pesanan → pembayaran/piutang, penerimaan piutang, draft retur → refund → laci kas, penutupan shift, dan pemulihan offline. Enam kelompok celah diperbaiki di source mobile/web. Gate akhir: **1.253 tes Flutter**, **426 tes web**, **55 tes integrasi server**, seluruhnya PASS. Paket terfokus132 tes Flutter sudah termasuk hasil keseluruhan; jangan dijumlahkan sebagai skenario unik.

Pengujian Flutter dijalankan pada runner desktop, termasuk widget UI dan SQLite sementara. Web memakai metode Vue nyata yang diekstrak dari SFC dengan I/O terkontrol, serta tes kontrak/kompilasi yang sudah terdaftar. **Bukan pengujian GUI emulator Android, browser interaktif, atau APK Play Store baru.** Tidak ada build, deploy, perubahan database produksi, reset akun/data perangkat, maupun penghapusan bukti pembayaran yang masih belum pasti. Source server tidak diubah.

## Temuan dan perbaikan

| # | Celah dan dampak | Perbaikan |
|---|---|---|
| 1 | Draft retur baru divalidasi setelah tersimpan. Isian invalid meninggalkan bukti tidak terbaca dan membuat retur berikutnya buntu, walaupun belum dikirim | Mobile dan web memvalidasi sebelum penyimpanan pertama. Bukti lama yang rusak tetap ditahan, bukan diam-diam dihapus. Isian sumber salah, ID sumber kosong/bukan string, dan item kosong diuji |
| 2 | Bukti penerimaan piutang baru belum divalidasi/read-back sebelum dikirim. Angka nol/negatif/pecahan atau invoice berbeda dapat merusak pemulihan | Mobile/web memvalidasi nominal Rupiah dan kecocokan invoice sebelum write, lalu membaca ulang dan mencocokkan request ID. Write yang seolah berhasil tetapi tidak tersimpan ditolak. Bukti lama tetap digunakan apa adanya |
| 3 | Penolakan draft retur yang dibungkus HTTP tidak membebaskan draft yang server sudah tandai ditolak secara permanen | Mobile juga membaca error dari respons HTTP terurai. Hanya marker server `return_draft_write_rejected` yang melepas bukti. Izin ditolak, respons hilang, atau hasil belum pasti tetap menyimpan bukti yang sama |
| 4 | Refund dapat menampilkan hasil kasir lama setelah pergantian akun/PIN; web juga menganggap respons mutation apa pun sukses | Mobile memagari mutation dan query konfirmasi dengan identitas sesi. Web memeriksa identitas sebelum/sepulang request, ID retur, dan status `completed`. Respons tidak cocok dikonfirmasi melalui read retur yang sama, bukan mutation refund kedua |
| 5 | Pelunasan piutang dapat menghapus bukti ketika respons invoice salah atau identitas berganti | Mobile/web memeriksa invoice asal dan identitas sebelum ACK. Mobile juga menolak replay jika operator halaman berubah sebelum submit, termasuk State widget yang dipakai ulang. Lima widget-scenario dan lima runtime-scenario web membuktikan bukti tetap ada pada hasil tidak pasti |
| 6 | Android menahan shift untuk antrean offline, tetapi belum untuk pembayaran online yang masih belum terkonfirmasi | Penutupan shift memeriksa bukti pada endpoint/instansi/terminal yang sama, termasuk PIN kasir lain untuk laci bersama. Bukti shift lain/instansi lain/terminal lain tidak menghalangi. Bukti relevan yang rusak tetap fail-closed. Pemeriksaan diulang setelah await SQLite |

Guard lokal nomor 6 tidak dapat melihat perangkat lain yang offline. Otoritas server dan koordinasi laci bersama tetap diperlukan; ini bukan jaminan global bahwa seluruh perangkat telah sinkron. Web sudah memeriksa outbox sale/pesanan sebelum penutupan dan memperbarui expected cash setelah konfirmasi. Tidak ditambahkan penghapusan antrean atau jalur bypass PIN/permission.

## Alur aman yang dipertahankan

- Pesanan belum dibayar tidak otomatis menjadi piutang Finance. Piutang timbul lewat pembayaran tempo/invoice yang disahkan server; pembayaran ulang mengikuti ID transaksi/pesanan semula.
- Pelunasan piutang mencatat penerimaan/jurnal Finance, bukan penjualan dan pengurangan stok baru. Hasil tidak pasti memakai bukti penerimaan yang sama.
- Simpan draft, pengajuan/persetujuan, dan refund tetap tahap terpisah. Menyimpan/memulihkan draft bukan izin mengeluarkan uang refund.
- Refund tunai mengurangi laci sesuai komponen kas nyata. Retur non-tunai/kredit piutang tidak otomatis menjadi kas keluar; rollback harus mengembalikan seluruh perubahan terkait.
- Hasil jaringan tidak pasti tidak diperlakukan sebagai penolakan permanen. Tidak membuat pembayaran, refund, atau draft pengganti untuk menghilangkan layar pemulihan.

## Matriks bukti

| ID | Jaminan | Bukti aktual | Status |
|---|---|---|---|
| TEST-POS-RELATED-RETURN-2511 | Input draft invalid tidak menulis bukti; proof lama dan idempotent replay tetap terlindungi | `pos_return_draft_request_store_test.dart`, `pos_return_draft_repository_test.dart`, web `return-draft-request-store.test.mjs` | PASS |
| TEST-POS-RELATED-COLLECTION-STORE-2511 | Nominal invalid/invoice asing ditolak sebelum write; bukti yang hilang saat write tidak dikirim | `pos_financial_request_store_test.dart`, web `pos-receivables-recovery.test.mjs` | PASS |
| TEST-POS-RELATED-REFUND-2511 | Sesi berubah saat ACK/lost ACK/read konfirmasi tidak mengklaim sukses atau memulai read dengan akun pengganti; web menolak ACK kosong/asing/status belum selesai | `pos_return_process_recovery_test.dart`, web `pos-refund-process-recovery.test.mjs` | PASS |
| TEST-POS-RELATED-COLLECTION-ACK-2511 | Respons invoice harus cocok; sesi berubah dan operator berganti sebelum submit tidak meng-ACK bukti asal | `pos_receivable_payment_ack_test.dart` (5 widget cases), web `pos-receivable-payment-ack.test.mjs` (5 runtime cases) | PASS |
| TEST-POS-RELATED-SHIFT-2511 | Pembayaran belum pasti dari dua PIN menahan penutupan lokal; konteks asing tidak menghalangi; offline unresolved tetap diblokir | `pos_native_cache_shift_test.dart` (17 cases) | PASS |
| TEST-POS-RELATED-REGRESSION-2511 | Harga jasa/order ACK, izin piutang, antrean offline/revocation dan replay tetap berjalan | Paket 11 suite/132 tes Flutter; seluruh `pos*.test.mjs` + preserve-recovery + return-store:426 tes | PASS |
| TEST-POS-RELATED-FINANCE-2511 | Draft replay, refund kas atomik, pembayaran utang/piutang, laci bersama/per kasir, pemulihan pembayaran order, jurnal/HPP | 6 suite integrasi Mongo sementara/55 tes | PASS |
| TEST-POS-RELATED-DEVICE-2511 | APK terbaru di Android dan browser nyata; pemulihan pembayaran lama pada HP pengguna | Tidak dilakukan pada sesi ini; belum build/deploy | UNVERIFIED |

## Bukti RED → GREEN

Perjalanan diturunkan dari audit ini, tanpa plan eksternal. Checkpoint Git lokal, tidak push/deploy:

- Mobile `58ffc43` RED:21PASS/12FAIL (`related-flows-red.log`) → `a1aee0f` GREEN:33PASS (`related-flows-green.log`). Empat invalid draft, empat invalid collection, tiga refund/session, satu penolakan HTTP.
- Web `1a8aae7a` RED:7PASS/8FAIL (`related-web-red.log`) → `40e57bc5` GREEN:15PASS (`related-web-green.log`).
- Web refund `11caafa3` RED:5PASS/6FAIL → `f82e5c99` GREEN:11PASS. Log `related-refund-web-{red,green}.log`.
- Mobile shift `7ad65dd` RED:9PASS/2FAIL (`related-shift-red-valid.log`) → `4760437` GREEN:11PASS, tercakup `related-receivable-red-valid.log` (tiga kegagalan di file piutang terpisah, bukan shift).
- Mobile piutang `e7f20d4` RED: satu kontrol piutang PASS/tiga kasus piutang FAIL → `533a704` GREEN:15PASS untuk gabungan piutang+shift (`related-receivable-green.log`).
- Pergantian operator sebelum submit: `d702a68` RED:4PASS/1FAIL → `867daaf` GREEN:5PASS (`related-operator-{red,green}.log`). Tambahan positive/isolasi konteks/store dan perapian fixture tercakup gate132PASS.
- Web piutang `115a1198` RED:2PASS/3FAIL → `2dfecf7e` GREEN:5PASS (`related-receivable-web-{red,green}.log`).

Percobaan fixture pertama untuk piutang gagal karena respons tiruan belum menyertakan field tipe cache; itu diperbaiki sebelum RED bisnis dan tidak dihitung sebagai bug aplikasi. Fixture shift sempat perlu melengkapi metode pengganti token provider; hanya `red-valid` dijadikan bukti. Empat peringatan kurung fixture dibereskan; analyzer final bersih.

## Perintah verifikasi

Semua log di `output/operational-readiness-20261125/` pada repo mobile.

Mobile:

```text
flutter test --no-pub --concurrency=2 --timeout 2m --reporter expanded
```

`related-flows-all-tests.log`: **06:09 +1253: All tests passed!**, exit0. Dimulai setelah perubahan source mobile terakhir dan perapian empat kurung fixture.

```text
flutter test --no-pub --concurrency=2 --coverage --coverage-path=output/operational-readiness-20261125/related-flows-lcov.info test/pos_return_draft_request_store_test.dart test/pos_financial_request_store_test.dart test/pos_return_process_recovery_test.dart test/pos_return_draft_repository_test.dart test/pos_receivable_payment_ack_test.dart test/pos_native_cache_shift_test.dart test/pos_trade_repository_test.dart test/pos_trade_workspace_test.dart test/pos_checkout_recovery_test.dart test/pos_order_payment_ack_test.dart test/pos_offline_revocation_sync_test.dart --reporter expanded
```

`related-flows-final.log`: **132PASS, exit0**,29detik. Coverage changed executable lines terhadap baseline `3528c17`: **82/85 (96,47%)**. Per source: financial store17/17, return store12/12, repository35/38, piutang page18/18. Tiga baris belum terkena adalah fallback exception/decision refund; ini bukan coverage seluruh aplikasi dan bukan cakupan GUI perangkat.

`dart analyze --fatal-infos` pada empat source dan enam berkas tes: **No issues found**, exit0 (`related-analyze-final.log`).

Web: `node --test` untuk seluruh `tests/pos*.test.mjs`, `tests/preserve-pos-recovery.test.mjs`, dan `tests/return-draft-request-store.test.mjs`: **426PASS/0FAIL/0skip, exit0** (`related-web-final2.log`),9detik. Parser/compileScript/compileTemplate Vue juga berhasil untuk `retur.vue` dan `piutang.vue`, exit0. Tidak menjalankan build.

Server:

```text
node --test --test-concurrency=1 tests/pos_return_draft.integration.test.js tests/pos_return_cash_drawer.integration.test.js tests/pos_trade.integration.test.js tests/pos_shift_operator_scope.integration.test.js tests/pos_order_payment_recovery.integration.test.js tests/finance_pos_inventory_sync.test.js
```

`related-server-final.log`: **55PASS/0FAIL/0skip, exit0**,47detik. Lima suite memakai `MongoMemoryReplSet`, jurnal memakai `MongoMemoryServer`; tidak terhubung DB produksi. Percobaan sebelumnya gagal55 saat setup karena `connect EACCES 127.0.0.1` (`related-server.log`), bukan dianggap PASS atau dilewati. Setelah izin eksekusi jaringan lokal sesuai, perintah sama lulus. Warning deprecation dan Mongo ECONNRESET tetap terlihat di log akhir, tidak membuat tes gagal; tidak diklaim telah didiagnosis tuntas.

## Yang belum dibuktikan dan penerapan

1. Build/rilis lalu install sebagai **update tanpa clear data/uninstall** agar proof HP tetap ada. Source lokal tidak memperbarui APK Play Store otomatis.
2. Ulangi GUI Android dan browser nyata: cicilan/lunas, retur penuh/parsial, pergantian PIN saat request, refund pada laci bersama, dan penutupan setelah recovery.
3. Pulihkan kasus HP yang terus menampilkan pemeriksaan pembayaran memakai referensi asli. Laporan ini tidak membuktikan pembayaran HP tersebut sudah terselesaikan.
4. Crash OS/disk failure fisik, dua HP offline bersamaan, dan seluruh matriks profil/perangkat bukan tercakup hanya karena gate kode lulus.

## Evaluasi hasil

Akurasi4/5: RED/GREEN dan log gate tersedia, tetapi APK/GUI nyata belum diverifikasi. Kelengkapan4/5: enam celah terkait tertutup beserta integrasi keuangan; pengujian dua perangkat/crash fisik masih perlu. Kejelasan4/5: source, runner dan deployment dibedakan; rincian teknis dipisah dari ringkasan. Dapat ditindaklanjuti4/5: commit/perintah/batas tersedia, tetapi masih perlu rilis dan uji perangkat. Keringkasan4/5: ringkasan pengguna singkat, bukti rinci di sini. Rata-rata4,0/5. Prioritas lanjutan: pasang update tanpa hapus data dan lakukan GUI/recovery kasus asli; kemudian dua perangkat offline. Self-check: layak sebagai audit/perbaikan teruji kode, bukan klaim seluruh POS siap produksi tanpa syarat.
