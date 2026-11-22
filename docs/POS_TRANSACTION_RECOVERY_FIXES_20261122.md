# Perbaikan keamanan transaksi dan pemulihan pembayaran

Tanggal: 22 November 2026 (Asia/Jakarta).

## Ringkasan

Tiga temuan audit diperbaiki: ID transaksi berubah setelah respons hilang, keranjang dapat berubah/terhapus selama pembayaran, dan subtotal struk offline memakai total akhir. Pemeriksaan tambahan juga menemukan tabrakan pembayaran dengan proses simpan/pulihkan pesanan tertunda; kasus itu ikut diperbaiki.

- Regresi mobile: **134 PASS**, tanpa kegagalan atau tes dilewati.
- Regresi server: **127 PASS**, tanpa kegagalan atau tes dilewati.
- Pemeriksaan akhir penyimpanan/pemulihan setelah validasi bukti lokal diperketat: **25 PASS**. Ini sebagian mengulang suite utama, bukan 25 skenario tambahan yang seluruhnya berbeda.
- Seluruh tes menggunakan mock layanan atau database sementara lokal. Tidak ada perubahan database produksi.
- Tidak membuat APK/AAB, tidak deploy, dan tidak melakukan GUI pada emulator/HP nyata dalam tugas ini.

## Perjalanan pengguna dan implementasi

### 1. Respons pembayaran hilang

Sebelumnya setiap panggilan `submitTransaction` membuat UUID baru. Untuk non-tunai, respons terputus menghasilkan kegagalan di layar, tetapi transaksi mungkin sudah committed. Menekan Bayar lagi berpotensi membuat transaksi kedua.

Sekarang:

1. Sebelum mengirim, simpan ID dan kesepakatan pembayaran di perangkat. Jika penyimpanan atau pembacaan ulang gagal, jangan kirim.
2. Simpan satu pembayaran yang belum terkonfirmasi per endpoint, instansi, akun terminal, dan operator PIN.
3. Percobaan ulang yang sama memakai ID dan tanggal asli. Perubahan keranjang/metode/nominal tidak boleh menggantikan bukti lama.
4. Setelah aplikasi dibuka kembali, halaman kasir menyediakan **Pulihkan pembayaran**. Tidak perlu menyusun ulang keranjang untuk mengulang transaksi asal.
5. Respons sukses harus membawa ID yang sama. Hapus bukti hanya setelah konfirmasi cocok atau transaksi tunai sudah masuk antrean lokal secara aman.
6. Penolakan pasti pada pengiriman pertama dapat melepaskan bukti agar kasir memperbaiki input. Respons ambigu, error internal, respons salah ID, atau hak akses ditolak saat replay tidak otomatis dianggap belum pernah tersimpan.

Tidak ada PIN supervisor atau token operator yang disimpan dalam bukti ini. Replay tetap memakai sesi aktif dan pemeriksaan server. Logout tidak menghapus bukti pembayaran yang belum selesai; akun/operator berbeda tidak membacanya.

Server tidak memerlukan jalur posting baru: tetap memakai batas idempotensi dan transaksi MongoDB yang sama. Tes baru membuktikan respons pembayaran yang hilang dapat dipulihkan setelah shift asal ditutup tanpa penambahan stok terjual, kas, atau jurnal kedua.

### 2. Keranjang selama pembayaran

- `paymentInProgress` terpisah dari status pemuatan umum, sehingga refresh belakang layar tidak menghilangkan indikator proses.
- Navigasi kembali dan input pembayaran dikunci selama proses. Tombol Bayar tetap menampilkan spinner.
- Perubahan isi, jumlah, satuan, harga, diskon, pelanggan, konteks penjualan, dan pemulihan keranjang ditolak selama pengiriman.
- Pembayaran tidak dimulai ketika proses simpan/pulihkan pesanan tertunda belum selesai.
- Setelah gagal, kunci proses dilepas dan keranjang tetap ada.
- Pemulihan dari halaman kasir tidak membuang draft berbeda: isi, nominal, pelanggan dan konteks harus cocok, serta state belum berubah, sebelum keranjang asal dikosongkan.

### 3. Struk offline

Jalur benar-benar offline dan jalur koneksi putus saat pengiriman sekarang memakai pembuat hasil offline yang sama. Subtotal berasal dari nilai barang sebelum diskon/pajak, bukan total akhir.

Contoh yang diuji: subtotal 100, diskon 10, pajak 5, total 95, uang diterima 100, kembalian 5. Antrean menyimpan satu transaksi; tidak memodifikasi jurnal server secara offline.

## Jaminan yang diuji

| Perilaku | Bukti | Hasil |
|---|---|---|
| ID tetap setelah respons hilang dan repository dibuat ulang | `test/pos_checkout_recovery_test.dart` | PASS |
| Pemulihan tanpa keranjang; tidak ada pembayaran baru pengganti | File yang sama | PASS |
| Nominal berbeda tidak mengganti pembayaran belum terkonfirmasi | File yang sama | PASS |
| Penolakan pertama BAD_REQUEST/FORBIDDEN/SUBSCRIPTION_REQUIRED dapat diperbaiki | File yang sama | PASS |
| Respons salah ID/kosong/error internal atau replay terlarang mempertahankan bukti | File yang sama | PASS |
| Respons tenant sebelumnya tidak menghapus/menampilkan pembayaran pada tenant baru | File yang sama | PASS |
| Dua jalur offline menjaga subtotal, total dan kembalian | File yang sama | PASS |
| Gagal simpan/hapus, bukti rusak/tidak lengkap, isolasi scope dan sanitasi kredensial | `test/pos_checkout_request_store_test.dart` | PASS |
| Keranjang terkunci; hold/restore tidak bertabrakan dengan pembayaran | `test/pos_checkout_cart_lock_test.dart` | PASS |
| Klik Bayar cepat tidak membuat dua panggilan; kegagalan dapat diulang | `test/pos_payment_single_flight_test.dart` | PASS |
| Back terkunci dan spinner tetap ada walaupun status umum berubah | `test/pos_payment_mobile_layout_test.dart` | PASS |
| Panel pemulihan, tombol/spinner, gagal offline dapat dicoba kembali, shortcut normal tetap berfungsi | `test/pos_keyboard_navigation_test.dart` | PASS |
| Replay setelah shift tutup: transaksi, stok, kas dan jurnal hanya sekali | Backend `tests/pos_checkout_optimization.integration.test.js` | PASS |
| Stok terakhir diperebutkan dua kasir; kegagalan jurnal membatalkan stok/kas/transaksi | File backend yang sama | PASS |
| Refund dan pelunasan menjaga alokasi, saldo, laci dan jurnal | Backend `tests/customer-settlement.integration.test.js`, `tests/pos_return_cash_drawer.integration.test.js` | PASS |
| Harga fleksibel, offline multikasir, izin PIN, GraphQL/auth middleware | Suite regresi di bawah | PASS |

## Bukti pengujian

Artifact berada di `D:/my node app/zera/output/`:

- `pos-checkout-bugfix-red-20261122.log`: 9 kegagalan bisnis awal, bukan kesalahan fixture.
- `pos-checkout-draft-race-red-20261122.log`: pembayaran dapat mulai sebelum hold/restore selesai. Kesalahan cleanup tes juga dicatat dan diperbaiki sebelum GREEN.
- `pos-checkout-bugfix-mobile-final-20261122.log`: `03:14 +134: All tests passed!`.
- `pos-checkout-bugfix-server-20261122.log`: `tests 127`, `pass 127`, `fail 0`, `skipped 0`.
- `pos-checkout-bugfix-store-final-20261122.log`: `00:08 +25: All tests passed!` setelah validasi bukti tidak lengkap diperbaiki.
- `pos-checkout-bugfix-coverage-final-20261122.info`: cakupan regresi mobile utama.
- `pos-checkout-bugfix-store-final-20261122.info`: cakupan store versi akhir.

Cakupan baris: store pemulihan baru **58/58 (100%)**, panel pemulihan **15/15 (100%)**. Ini bukan klaim seluruh repository/BLoC lama memiliki cakupan 100%.

Pemeriksaan statis terarah sempat menghasilkan informasi gaya penulisan pada tes; informasi tersebut diperbaiki. Percobaan analisis akhir kemudian berhenti tanpa hasil. Proses analisis milik tugas ini dihentikan setelah diverifikasi, tanpa menghentikan server/emulator. Karena itu **analisis statis akhir belum terkonfirmasi**, bukan dinyatakan PASS atau klaim seluruh proyek bebas warning. Seluruh target tes di atas tetap berhasil dikompilasi dan dieksekusi. Artifact percobaan ada di `pos-checkout-bugfix-analyze-20261122.log`.

Perintah utama mobile, dari `mobile_POS_Pantoo`:

```powershell
flutter test test/pos_checkout_request_store_test.dart test/pos_checkout_recovery_test.dart test/pos_checkout_cart_lock_test.dart test/pos_payment_single_flight_test.dart test/pos_payment_mobile_layout_test.dart test/pos_keyboard_navigation_test.dart test/pos_checkout_preparation_test.dart test/pos_subscription_test.dart test/pos_service_fulfillment_test.dart test/pos_flexible_service_test.dart test/pos_offline_revocation_sync_test.dart test/pos_return_process_recovery_test.dart test/pos_customer_payment_contract_test.dart test/pos_payment_custom_cash_contract_test.dart test/pos_bloc_no_shift_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-checkout-bugfix-coverage-final-20261122.info' --reporter expanded
flutter test test/pos_checkout_request_store_test.dart test/pos_checkout_recovery_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-checkout-bugfix-store-final-20261122.info' --reporter expanded
```

Perintah server, dari `presensi_zera_BE`:

```powershell
node --test --test-concurrency=1 tests/pos_checkout_optimization.integration.test.js tests/pos_return_cash_drawer.integration.test.js tests/customer-settlement.integration.test.js tests/pos_flexible_service_pricing.integration.test.js tests/pos_offline_multicashier.contract.test.js tests/pos_inventory_hardening.security.test.js tests/pos_graphql.contract.test.js tests/pos_shift_operator_scope.integration.test.js
```

Pada lingkungan Windows ini, TEMP/TMP diarahkan ke direktori uji D yang sudah ada agar tidak membebani C. Beberapa suite MongoDB sementara menulis ECONNRESET saat shutdown; hasil akhir tetap exit 0 dan seluruh assertion lulus. Ini bukan uji gangguan produksi.

## Jejak RED → GREEN

- Mobile `71c8574`: reproduksi 9 kegagalan awal.
- Mobile `e79acff`: reproduksi indikator proses yang hilang setelah perubahan status umum.
- Mobile `133412c`: reproduksi tabrakan hold/restore.
- Mobile `d64bf52`: pengujian bukti persisten, termasuk reproduksi bukti receipt tidak lengkap.
- Mobile `b144ad6`: implementasi GREEN, 134 regresi utama dan 25 pemeriksaan akhir store/recovery lulus.
- Backend `9b53f908`: tambahan bukti replay setelah shift ditutup, 127 regresi transaksi lulus.

Perubahan pemuatan dashboard yang sedang dikerjakan di worktree yang sama serta file versi/coverage lama dipertahankan dan tidak dimasukkan ke commit perbaikan ini.

## Batas aman dan tindak lanjut

- Tidak membuktikan GUI Android fisik, pemadaman proses OS saat disk flush, printer fisik, atau gateway pembayaran eksternal. Restart dalam tes berarti repository dibuat ulang dari bukti persisten yang sama.
- Bukti yang rusak tidak boleh dibuang otomatis. Jika hak kasir dicabut atau hasil server masih ambigu, pulihkan akses/koneksi atau minta administrator memeriksa transaksi asal; jangan membuat transaksi pengganti dengan ID baru.
- Tidak ada tombol bebas untuk menghapus bukti pembayaran ambigu, karena itu akan membuka kembali risiko transaksi ganda.
- APK/AAB yang sudah dibangun sebelumnya belum memuat perbaikan ini. Perlu build baru sebelum dicoba pada perangkat pengguna.
- Server tetap memerlukan replica set dan indeks unik transaksi yang telah tersedia; tidak ada migrasi/skema GraphQL baru dalam perubahan ini.
