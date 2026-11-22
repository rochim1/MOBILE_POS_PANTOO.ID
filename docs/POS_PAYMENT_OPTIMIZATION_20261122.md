# Optimasi pembayaran POS mobile dan server

Tanggal: **22 November 2026**. Status perubahan: **diimplementasikan dan regresi terarah PASS**. Bukan pernyataan sudah dirilis atau sudah diuji di HP produksi.

## Rencana dan realisasi

Journey utama: kasir membuka pembayaran, memilih metode/nominal, menekan Bayar satu kali, dan memperoleh hasil hanya setelah server menyimpan transaksi, stok, jurnal, serta kas shift secara konsisten.

1. Ukur baseline sebelum perubahan — selesai, artefak tersimpan.
2. Mulai pemeriksaan akses yang hampir kedaluwarsa saat halaman pembayaran dibuka — selesai.
3. Gabungkan pembacaan saldo stok awal per keranjang — selesai; pembacaan stok aktual di transaksi tetap dipertahankan.
4. Uji konkurensi, pengulangan respons, kegagalan jurnal, akses, batch/BOM, jasa dan reservasi — selesai untuk suite yang disebut di bawah.
5. Bandingkan sebelum/sesudah dan catat keterbatasan — selesai.

## Peta alur dan perubahan

```text
Buka halaman bayar → siapkan status akses di background
Tekan Bayar → validasi pelanggan/layanan/nominal → guard akses tetap berjalan
→ server: cek izin dan antrean posting → satu snapshot stok awal
→ transaksi MongoDB: baca stok aktual, kurangi stok, simpan transaksi,
  perbarui kas shift, posting jurnal/piutang → commit → halaman berhasil
```

### Mobile

- `PosSubscriptionService.prepareCheckout()` memakai status yang masih segar tanpa request tambahan; bila usia pemeriksaan mencapai 45 detik atau ada kondisi offline/error, pemeriksaan dimulai lebih awal.
- Permintaan persiapan yang bertumpuk tetap digabung. Status tetap terikat identitas/instansi; tidak memperpanjang grant offline atau melewati mutation/offline guard. Ambang pemeriksaan saat mutation yang sudah ada tidak dilonggarkan.
- `PosPaymentPage` memulai persiapan setelah frame pertama, tanpa menunggu sebelum menampilkan form, tanpa mengirim transaksi otomatis. Bayar langsung dan bayar pesanan tersimpan memakai halaman ini.
- Ditemukan celah event Bayar ganda: dua event berdekatan semula memanggil penyimpanan dua kali. Guard `_paymentInFlight` sekarang membatasi satu pembayaran aktif dan dilepas dalam `finally`, termasuk setelah gagal. Keranjang tetap tersedia untuk retry setelah gagal.
- Tidak menampilkan keberhasilan sebelum konfirmasi server dan tidak memindahkan pencatatan keuangan ke pekerjaan background.

### Server

- Pembacaan awal yang sebelumnya berulang untuk harga/batch dan validasi konsumsi digabung melalui `pos_checkout_stock_snapshot.js`.
- Keranjang 10 barang: **20 pembacaan stok awal → 1**. Keranjang 1 barang: **2 → 1**.
- Snapshot hanya hidup selama satu request, difilter menurut instansi, produk, dan lokasi; bukan cache global stok. Batch dan `reserved_qty` tidak dibuang. Semantik komponen BOM lama dipertahankan, termasuk bila flag penjualan langsung komponen berbeda.
- Produk jasa/deposit langsung yang tidak memakai stok tidak menambahkan pembacaan stok.
- Seluruh pembacaan/perubahan saldo aktual dalam `runInventoryTransaction`, alokasi batch, compare-and-set shift, jurnal dan commit tetap ada. Pada benchmark 10 barang, **20 pembacaan stok dalam transaksi tetap 20**.
- Antrean Finance per instansi tidak dihapus atau diubah menjadi posting paralel. Waktu antrean bisa turun karena pekerjaan sebelum commit lebih singkat, bukan karena melepas pagar konsistensi.
- Tidak ada perubahan kontrak GraphQL, field, registrasi middleware, atau aturan permission.

## Metode pengukuran

Pengukuran server menggunakan resolver penjualan sebenarnya, MongoDB **replica set sementara di localhost**, model stok/jurnal/shift sebenarnya, fixture dengan COA valid, dan pembacaan ulang hasil database. Tidak membaca `.env` untuk memilih database dan tidak menjalankan transaksi produksi.

Baseline source: `cbb92cc2`. Kode optimasi: `bd02b0aa`, perbaikan kompatibilitas leaf BOM `8ea77b80`; run akhir menggunakan HEAD `32a8cbf0` yang juga memuat koreksi fixture. Harness berpasangan dicatat dalam `858d42d5`.

Run terpisah awal menunjukkan variasi beban komputer yang besar (contoh baseline 10 barang 624,15 ms dan run sesudah awal 562,66 ms, lalu run sesudah berikutnya 235,71 ms). **Selisih run terpisah tersebut tidak dianggap seluruhnya disebabkan optimasi.** Oleh karena itu pembanding utama di bawah memakai kode lama dan baru secara bergantian AB/BA dalam **proses, tenant uji, dan replica set yang sama**, tanpa menimpa source/worktree.

- Dua warm-up per implementasi; 12 transaksi terukur per implementasi per skenario.
- Tiga pembayaran bersamaan berarti tiga request pada antrean instansi yang sama, bukan tiga HP fisik.
- Run normal tanpa delay tambahan; run sensitivitas menambahkan jeda **simulasi 10 ms** hanya pada pembacaan stok awal. Ini bukan pengukuran latensi jaringan produksi.
- Dengan n=12, p95 dan p99 sama-sama sampel maksimum; tidak cukup untuk menyimpulkan p99 produksi.

### Server: pembanding berpasangan, milidetik

| Kondisi | Barang / request bersamaan | p50 sebelum | p50 sesudah | p95 sebelum | p95 sesudah |
| --- | --- | ---: | ---: | ---: | ---: |
| Lokal, tanpa delay tambahan | 1 / 1 | 74,70 | 74,09 | 86,12 | 88,92 |
| Lokal, tanpa delay tambahan | 10 / 1 | 210,49 | 195,97 | 266,00 | 222,81 |
| Lokal, tanpa delay tambahan | 10 / 3 | 407,52 | 403,52 | 654,67 | 610,50 |
| Simulasi 10 ms per pembacaan awal | 1 / 1 | 113,97 | 93,27 | 143,33 | 112,61 |
| Simulasi 10 ms per pembacaan awal | 10 / 1 | 522,60 | 231,85 | 554,13 | 256,85 |
| Simulasi 10 ms per pembacaan awal | 10 / 3 | 1005,86 | 462,96 | 1613,31 | 757,91 |

Untuk 10 barang satu request: median turun sekitar **6,9%** pada database lokal cepat dan **55,6%** pada run delay terkontrol. Untuk 1 barang lokal, median nyaris sama dan p95 sedikit lebih buruk; jangan menjanjikan semua transaksi akan jauh lebih cepat.

| Kondisi (10 barang) | Request bersamaan | Antrean p95 sebelum → sesudah (ms) | Throughput sebelum → sesudah (transaksi/detik) |
| --- | ---: | ---: | ---: |
| Lokal | 1 | 0 → 0 | 4,64 → 4,95 |
| Lokal | 3 | 429 → 403 | 4,78 → 5,07 |
| Delay terkontrol 10 ms | 1 | 0 → 0 | 1,91 → 4,26 |
| Delay terkontrol 10 ms | 3 | 1070 → 497 | 1,93 → 4,28 |

Raw JSON juga menyimpan p50/p95/p99 waktu pekerjaan di dalam giliran posting, waktu antrean, jumlah pembacaan, dan throughput. Tidak ada klaim cache-hit server: optimasi ini adalah penggabungan pembacaan dalam satu request, bukan cache lintas transaksi.

### Mobile: bagian pemeriksaan akses saat tombol Bayar ditekan

Menggunakan service langganan sebenarnya, secure storage/clock simulasi, dan respons `fetch` dengan jeda terkontrol 120 ms, 12 sampel. Persiapan sesudah dijalankan sebelum stopwatch tombol dimulai untuk mewakili waktu kasir memilih metode/nominal.

| Metrik | Sebelum | Sesudah |
| --- | ---: | ---: |
| p50 guard pada saat Bayar (ms) | 123,711 | 0,239 |
| p95/p99 guard (ms) | 157,130 | 6,842 |
| Total fetch pada 12 sampel, termasuk aktivasi dan persiapan | 24 | 24 |

**Ini bukan waktu pembayaran keseluruhan.** Request pemeriksaan tidak dihilangkan; waktu tunggunya dipindahkan lebih awal. Bila kasir langsung menekan Bayar sebelum persiapan selesai, atau status kembali stale, guard tetap boleh menunggu pemeriksaan.

## Pengujian dan jaminan

Hasil akhir: **131 tes server + 62 tes mobile = 193 PASS**, tidak ada tes dilewati dalam kedua suite akhir. Benchmark mobile terpisah juga PASS sebelum dan sesudah.

| Jaminan yang diuji | Bukti utama | Hasil |
| --- | --- | --- |
| Sepuluh barang memakai satu pembacaan awal, tetap membaca stok aktual dan menghasilkan jurnal berimbang | `pos_checkout_optimization.integration.test.js` | PASS |
| Tiga request dengan client transaction ID sama mengembalikan satu transaksi; stok/kas/jurnal hanya berubah sekali | integration test yang sama | PASS |
| Dua akun kasir berebut satu unit: hanya satu penjualan berhasil | integration test yang sama | PASS |
| Jurnal gagal: stok, transaksi, dan kas shift rollback; request yang sama bisa diulang setelah penyebab gagal diperbaiki | integration test yang sama | PASS |
| Saldo berubah setelah snapshot awal: pemeriksaan aktual tetap menolak penjualan | integration test yang sama | PASS |
| Stok instansi/lokasi lain tidak mengesahkan penjualan | integration test dan `pos_checkout_stock_snapshot.test.js` | PASS |
| Batch dengan nomor sama tetap dibedakan menurut ID, expiry dan reservasinya | `inventory_batch_consumers.integration.test.js` | PASS |
| BOM, nilai HPP, branch jurnal, retur, dan jurnal tidak berimbang tetap ditangani benar | `finance_pos_inventory_sync.test.js` | PASS |
| Role dicabut saat request menunggu antrean: posting ditolak | `role_read_scope.integration.test.js` | PASS |
| Jasa fleksibel, pesanan, piutang, reservasi dan profil simple/centralized/advanced tetap mengikuti aturan yang ada | suite fleksibel, order workspace, reservation, selling policy | PASS |
| Form pembayaran dapat dipakai saat persiapan belum selesai; persiapan sekali per pembukaan; tidak auto-submit | `pos_payment_mobile_layout_test.dart` | PASS |
| Guard tetap menolak read-only dan status dari identitas lain; refresh bersamaan digabung | `pos_checkout_preparation_test.dart` dan `pos_subscription_test.dart` | PASS |
| Dua event Bayar berdekatan menghasilkan satu pengiriman; gagal tidak mengunci retry | `pos_payment_single_flight_test.dart` | PASS |
| Tunai, QRIS, split, nominal kurang, layanan langsung/reservasi dan harga jasa yang diedit tetap benar | suite pembayaran/mobile/jasa | PASS |

Regresi awal server sempat **121 PASS / 10 FAIL** karena dua fixture lama tidak membuat COA sebelum posting. Fixture diperbaiki dengan `ensureDefaultCoa` dan akun komponen khusus yang benar-benar dipakai tes. **Validasi akun Finance produksi tidak dinonaktifkan.** Run akhir yang sama menjadi 131/131 PASS.

Beberapa run MongoDB sementara menulis `ECONNRESET` ketika proses replica set dimatikan setelah assertion selesai; exit code run akhir 0 dan seluruh readback/assertion lulus. Warning deprecation dependency tidak dianggap hasil tes gagal.

### Cakupan dan analisis

- Helper stok baru: **100% line/branch/function coverage**.
- Service akses mobile: **182/227 baris (80,2%)** pada suite terarah.
- Seluruh baris executable baru pada persiapan/guard pembayaran dijalankan tes. File besar yang turut dipakai tidak diklaim teruji seluruhnya: payment page 930/1400, POS bloc 230/727 pada suite ini.
- `dart analyze` untuk tiga file produksi yang diubah dan tes terkait: **No issues found**.
- `node --check` resolver, helper, dan benchmark: PASS; `git diff --check`: PASS.

### Bukti TDD

- Mobile `4ef59bf`: baseline dan reproducer API persiapan yang belum tersedia (RED); `354a1d6`: persiapan GREEN.
- Server `8d1a8842`: reproducer 20 pembacaan awal, target 1 (RED); `bd02b0aa`: enam integration test GREEN.
- Server `834e8206` → `8ea77b80`: reproducer/perbaikan kompatibilitas leaf BOM lama.
- Mobile `8e454f2` → `6334154`: reproducer dua pengiriman akibat event ganda → pengaman pembayaran dan retry GREEN.
- `4a2a81c`: regresi mobile 62 PASS; `32a8cbf0`: fixture COA diselaraskan dengan aturan Finance yang berlaku.

## Perintah verifikasi yang dijalankan

```text
node scripts/measure-pos-checkout.cjs before
POS_MEASURE_DB_DELAY_MS=10 node scripts/measure-pos-checkout.cjs before
node scripts/measure-pos-checkout.cjs after
POS_MEASURE_DB_DELAY_MS=10 node scripts/measure-pos-checkout.cjs after
node scripts/measure-pos-checkout-paired.cjs
POS_MEASURE_DB_DELAY_MS=10 node scripts/measure-pos-checkout-paired.cjs
node --test --experimental-test-coverage --test-coverage-include=**/pos_checkout_stock_snapshot.js tests/pos_checkout_stock_snapshot.test.js
```

Notasi variabel lingkungan di atas diringkas untuk keterbacaan; eksekusi Windows menggunakan `$env:POS_MEASURE_DB_DELAY_MS`. Kedua benchmark hanya membuka replica set sementara localhost.

Suite server akhir dijalankan `node --test --test-concurrency=1` terhadap:

```text
tests/pos_checkout_stock_snapshot.test.js
tests/pos_checkout_optimization.integration.test.js
tests/pos_flexible_service_pricing.integration.test.js
tests/pos_order_workspace.integration.test.js
tests/pos_order_selling_location.integration.test.js
tests/inventory_batch_consumers.integration.test.js
tests/pos_selling_policy.test.js
tests/finance_pos_inventory_sync.test.js
tests/role_read_scope.integration.test.js
tests/finance_posting_admission.test.js
tests/pos_offline_multicashier.contract.test.js
tests/pos_inventory_hardening.security.test.js
tests/pos_graphql.contract.test.js
tests/pos_reservation_lifecycle.integration.test.js
```

Suite mobile akhir dijalankan `flutter test --no-pub --concurrency=1 --coverage --coverage-path=../output/pos-checkout-mobile-coverage-20261122.info --reporter expanded` terhadap:

```text
test/pos_checkout_preparation_test.dart
test/pos_payment_single_flight_test.dart
test/pos_payment_mobile_layout_test.dart
test/pos_subscription_test.dart
test/pos_service_fulfillment_test.dart
test/pos_flexible_service_test.dart
test/pos_customer_payment_contract_test.dart
test/pos_payment_custom_cash_contract_test.dart
```

## Artefak

- [A/B server lokal](../../output/pos-checkout-optimization-20261122/server-paired-delay0.json)
- [A/B server dengan delay 10 ms](../../output/pos-checkout-optimization-20261122/server-paired-delay10.json)
- [Log regresi server akhir](../../output/pos-checkout-server-regression-final-20261122.log)
- [Log regresi mobile akhir](../../output/pos-checkout-mobile-regression-final-20261122.log)
- [Pengukuran mobile sebelum](../../output/pos-checkout-mobile-before-20261122.log) dan [sesudah](../../output/pos-checkout-mobile-after-20261122.log)
- [Analisis mobile akhir](../../output/pos-checkout-mobile-analyze-final-20261122.log)
- [Coverage helper stok](../../output/pos-checkout-stock-coverage-20261122.log)

## Batas verifikasi dan penerapan

Tidak memakai database produksi, melakukan deploy produksi, membuat APK/AAB baru, atau menguji payment gateway/bank sungguhan. Angka server adalah resolver + database lokal, bukan HTTP/network/renderer Android produksi. Tes widget memakai repository palsu untuk alur tampilan; integration test server memakai penyimpanan dan transaksi MongoDB sebenarnya. Pengujian GUI Android online/offline dan jaringan dua perangkat setelah instalasi belum dilakukan pada perubahan ini.

Target acceptance produksi: **NOT PERFORMED**. Untuk memakai perubahan di HP, deploy backend dan build/install versi aplikasi terbaru, lalu ukur payment nyata per metode/profil. Jangan menjanjikan angka benchmark lokal sebagai SLA produksi. Artefak APK/AAB 21 November belum memuat perubahan ini.
