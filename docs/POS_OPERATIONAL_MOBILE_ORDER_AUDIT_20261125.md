# Audit operasional mobile: pembayaran pesanan dan piutang

25 November 2026, Asia/Jakarta. Sumber: permintaan mengaudit alur operasional agar tidak membingungkan atau buntu sebelum transaksi selesai. **Hasil: PASS pada tes terarah di bawah; bukan persetujuan produksi seluruh aplikasi atau pengganti E2E Android/server.**

## Peta state dan jalur yang diperiksa

| Touchpoint | Urutan / state penting | Hasil dan batas bukti |
|---|---|---|
| Bayar keranjang baru | Pilihan metode memakai key bisnis tetap → intake layanan bila perlu → pelanggan wajib → SubmitPayment; respons BLoC menuju halaman hasil | Regresi widget/tarif layanan, tunai/transfer/tempo, split, minimum tunai, loading dan keyboard lulus. BLoC dan shell dikerjakan audit utama, bukan dimodifikasi oleh sub-audit ini |
| Buat pesanan / ambil nanti | `_invoiceFlowOpen` ditahan sebelum await; service/reservasi/pelanggan → konfirmasi → createUnpaidInvoice dengan UUID halaman → sukses/offline-queued baru ClearCart dan pop; gagal tetap membawa keranjang | Trace kode + kontrak pelanggan, tes reservasi tidak bertanya dua kali dan retry. Tidak ada penjualan baru atau penyimpanan order nyata ke server pada sub-audit ini |
| Bayar pesanan yang sudah tersimpan | Customer pending-order terpisah dari customer keranjang yang tidak terkait; reserve busy sebelum await → payPendingOrder → RefreshOrders/runtime dan pop pada sukses; finally membuka kembali UI | Bug customer dan klik ganda diperbaiki; widget nyata membuktikan route selesai dan keranjang lain tetap ada |
| Penjualan tempo | Harus ada customer ID yang tidak kosong dari konteks yang benar; keberhasilan berarti piutang tercatat, bukan uang diterima/lunas | Header/notice ID–EN dan nominal piutang dibenahi; tidak melonggarkan validasi pelanggan |
| Pelunasan piutang | Scope endpoint/tenant/operator/invoice → durable request proof sebelum mutate → frozen input bila respons hilang → acknowledge hanya bila server menerima/menolak pasti | Store diuji ulang. UI ditelusuri untuk nominal rupiah bulat, maksimum outstanding, akun/bank, referensi, canCollect, loading/finally dan generation guard; bukan E2E jurnal/bank/cicilan baru |

Dangerous resets yang diperhatikan: ClearCart menghapus customer, harga/satuan, meja, editingOrder dan preview. Pending-order payment **tidak** mengirim ClearCart sehingga keranjang kasir yang tidak terkait tidak terhapus. Keberhasilan pesanan baru hanya membersihkan keranjang setelah hasil repository sukses. Penentuan customer tempo kini memakai `_hasCustomer` yang sudah memisahkan kedua konteks, bukan null-check alternatif yang berbeda.

## Temuan yang diperbaiki

1. **P1 — Customer piutang salah konteks.** Submit tempo dahulu hanya memeriksa `_paymentCustomer ?? state.selectedCustomer`: pending order dengan customer sah justru ditolak ketika customer keranjang kosong; pending order tanpa customer malah boleh memakai keberadaan customer keranjang yang tidak terkait; ID customer kosong/spasi juga lolos. Kini memakai `_hasCustomer(state)`, lalu mengirim customer pending yang benar. Ini bukan bypass pemeriksaan server.
2. **P1 — Race klik pembayaran pesanan.** `_payingPendingInvoice` dahulu baru disetel setelah await pemeriksaan customer. Dua callback yang dipanggil cepat menghasilkan dua panggilan repository. Busy kini ditahan sebelum await pertama dan dilepas melalui finally. Tes membuktikan satu panggilan, back terkunci selama request, lalu dapat mencoba lagi sesudah penolakan. Tidak mengklaim ditemukan duplikasi jurnal; server mempunyai penjagaan sendiri.
3. **P1 — Tempo seolah-olah sudah dibayar.** Halaman hasil umum selalu berjudul pembayaran berhasil dan baris Credit/Receivables menampilkan Rp0; toast pending order selalu mengatakan berhasil dibayar. Kini judul/notice menjelaskan piutang belum lunas, baris piutang menunjukkan total tagihan, dan pending-credit toast menunjukkan lokasi pelunasan. Label Indonesia/Inggris diuji pada widget nyata.
4. **P1 — Pemulihan harus percaya tender server.** Toast memakai `metode_pembayaran` dari respons sebagai sumber kebenaran, bukan selalu metode form retry. Seleksi query PayPOSOrder ditambah field yang sudah ada di schema POSOrder. Tes request-transfer/respons-tempo dan kebalikannya lulus. Tidak mengubah argumen mutation atau enum transport layar pelanggan.

## Bukti RED → GREEN

- `291d832` RED: 1PASS/4FAIL, customer-linked ditolak, customer keranjang salah konteks/ID kosong diterima, dua panggilan PayPOSOrder. Fixture compile dan selector awal dibenahi sebelum checkpoint runtime ini.
- `5322327` GREEN:6 widget PASS; customer guards, single flight, retry, route keluar dan cart preservation.
- `1e5a17e` RED:16PASS/5FAIL; dua toast piutang ID/EN, dua header/notice ID/EN dan nominal credit0 vs1000. Ekspektasi lama Rp0 di tes hasil pembayaran diperbarui sesuai kebutuhan bisnis, bukan dihapus/di-skip.
- `4d73587` GREEN: run terarah8suite **67/67PASS**, exit0,1menit22detik; run akhir dua suite hasil/pending **23/23PASS**, exit0,11detik, termasuk dua skenario tender terkomit tambahan. Angka tersebut tumpang-tindih, **jangan dijumlahkan sebagai90tes unik**.
- Run tambahan store finansial + key metode pembayaran: **4/4PASS**, exit0. Analyzer5berkas terkait: **No issues found**,13,8detik. Analisis awal2berkas juga bersih147,4detik.

Perintah yang benar-benar dijalankan:

```text
flutter test --no-pub --concurrency=1 test/pos_pending_payment_flow_test.dart
flutter test --no-pub --concurrency=1 test/pos_pending_payment_flow_test.dart test/pos_success_print_nonblocking_test.dart
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/operational-readiness-20261125/payment-order-credit-lcov.info test/pos_pending_payment_flow_test.dart test/pos_success_print_nonblocking_test.dart test/pos_payment_mobile_layout_test.dart test/pos_customer_payment_contract_test.dart test/pos_service_fulfillment_test.dart test/pos_checkout_recovery_test.dart test/pos_payment_single_flight_test.dart test/pos_order_pending_customer_test.dart
flutter test --no-pub --concurrency=1 test/pos_financial_request_store_test.dart test/pos_payment_locale_contract_test.dart
flutter analyze --no-pub lib/presentation/pages/pos/pos_payment_page.dart lib/presentation/pages/pos/pos_success_page.dart lib/data/graphql/pos_queries.dart test/pos_pending_payment_flow_test.dart test/pos_success_print_nonblocking_test.dart
```

Coverage run67: method `_payPendingInvoice` baris959–1027 **38/44 (86,4%)**, build hasil pembayaran baris46–277 **78/83 (94%)**. Seluruh `pos_payment_page.dart` **914/1277 (71,6%)**, sehingga tidak diklaim80% seluruh file/aplikasi. Cakupan tersisa termasuk dialog/printing/exception paths lain. Berkas lcov tetap berada di output lokal, bukan perubahan pada coverage pengguna.

| Jaminan / jenis | Bukti eksekusi |
|---|---|
| Customer pesanan sah diterima untuk tempo; customer tidak terkait dan ID kosong tetap ditolak |3 widget regresi +1 jalur credit baru sah, pos_pending_payment_flow_test.dart|
| Klik ganda tidak membuat dua request; penolakan dapat dicoba ulang; sukses keluar dan tidak menghapus cart lain |2 widget regresi di suite yang sama|
| Informasi piutang tidak menyiratkan pelunasan; nominal tagihan, ID/EN dan tender respons benar |4 widget ID/EN,2 tender recovery, tes nominal seluruh10metode di dua suite hasil/pending|
| Pemulihan lost ACK mempertahankan transaksi/request dan isolasi tenant; penolakan pasti vs ambigu dibedakan |13 integration/local-repository cases di pos_checkout_recovery_test.dart|
| Tampilan kecil, landscape, text scale, keyboard, custom cash, split, pending items dan loading tetap bekerja |14 widget pos_payment_mobile_layout_test.dart|
| Layanan langsung tidak memaksa jadwal, reservasi bertanya satu kali, tarif tetap |10 widget/unit pos_service_fulfillment_test.dart|
| Bukti pelunasan tidak diganti saat retry/restart/korup; scope terpisah |3 unit pos_financial_request_store_test.dart|

## Batas aman dan yang masih perlu verifikasi

- Tidak memakai browser/Android emulator atau melakukan build/pemasangan APK/AAB pada sub-audit ini. Tidak membuat transaksi produksi, reset akun, mengubah hak akses, cache pengguna atau data server. Repository pembayaran pada widget memakai fake; GraphQL recovery memakai link terkontrol dan SQLite sementara dari tes yang sudah ada.
- Query baru dikonfirmasi terhadap field schema lokal POSOrder.metode_pembayaran. Audit server paralel melaporkan51kontrak, termasuk semua dokumen static pos_queries.dart, PASS. Hasil backend/jurnal bukan berasal dari sub-audit widget ini.
- Belum membuktikan ulang melalui GUI Android terbaru: dua akun kasir berbeda, piutang cicilan→lunas transfer bank, perubahan hak akses saat offline, crash perangkat saat pembayaran pending atau seluruh variasi profil. Tes otomatis bukan pengganti bukti tersebut.
- Customer-display transport tetap memakai status `payment_success` sebagaimana kontrak lama; halaman/toast kasir membedakan tempo, namun tampilan pelanggan fisik/downstream perlu ditinjau agar istilah sukses tidak disalahartikan sebagai lunas. Tidak ada klaim printer/layar pelanggan fisik lulus.
- Halaman piutang mempunyai request proof yang tahan respons hilang dan guard canCollect di UI, tetapi hasil jurnal, saldo bank, permission server dan semua race lintas perangkat perlu dicocokkan dengan laporan server/E2E utama. Tidak mengubah cara bank/Finance memposting.
- Perubahan pengguna pada bloc/shell/startup, versi, terjemahan, katalog dan coverage tidak dimasukkan ke commit sub-audit. Terjemahan3getter disediakan audit utama; tidak membuat katalog paralel.

## Evaluasi mandiri

Akurasi5 (RED/GREEN, source diff, angka coverage aktual); kelengkapan4 (GUI Android/server dan hardware belum diverifikasi dalam sub-audit ini); kejelasan5 (pemisahan pesanan, penjualan tempo dan pelunasan); tindak lanjut4 (memerlukan E2E perangkat/jurnal untuk keputusan produksi); keringkasan4 (detail bukti panjang agar audit dapat diteruskan). Total4,4/5. Tidak ada klaim seluruh POS bebas bug. Hasil siap digabung sebagai perbaikan terbatas; prioritas berikutnya ialah pembuktian GUI dua akun dan rekonsiliasi Finance pada build terbaru.
