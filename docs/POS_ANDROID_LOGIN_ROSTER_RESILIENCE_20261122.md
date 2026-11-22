# Login Android dan pemulihan daftar kasir

Tanggal: 22 November 2026. Status: PASS untuk pengujian otomatis terpilih; uji GUI perangkat Android belum dilakukan pada pekerjaan ini.

## Permintaan dan batas pekerjaan

Mempercepat login serta pemuatan daftar kasir, menangani timeout/cache dengan benar, dan tetap mewajibkan verifikasi PIN. Tidak membangun APK/AAB, mengubah data produksi, atau mengubah aturan stok/jurnal/pembayaran.

## Penyebab yang ditemukan di kode

- Login yang sudah diterima server masih menunggu query runtime POS lengkap, dengan timeout tambahan 8 detik. Timeout juga dapat membuang cache akun yang sebenarnya masih valid.
- Pemulihan sesi membutuhkan runtime lengkap, padahal pemeriksaan identitas pengguna sendiri sudah cukup untuk tahap tersebut.
- Beberapa pemanggil runtime dapat memulai request yang sama bersamaan.
- Daftar kasir yang sudah diterima belum ditampilkan karena masih menunggu pemeriksaan status PIN akun login.
- Timeout pemuatan daftar di UI lebih pendek daripada timeout transport 30 detik. Pemulihan cache bisa datang setelah UI menyatakan gagal.
- Pembatas waktu stream bawaan klien GraphQL tidak menutup sumber setelah timeout. Pembacaan startup perlu penutupan subscription yang eksplisit agar tidak terus mengirim error setelah gagal.

Temuan ini menjelaskan celah penanganan aplikasi; bukan bukti bahwa endpoint atau database tertentu merupakan satu-satunya penyebab lambat pada HP pengguna. Endpoint Android aktual belum tersedia untuk pengukuran terautentikasi langsung.

## Implementasi

1. Login username/password maupun Google mengembalikan hasil setelah server mengesahkan login dan kredensial tersimpan. Query runtime lengkap dikeluarkan dari tahap login; pemeriksaan workspace, langganan, dan PIN tetap dimiliki penjaga akses yang sudah ada.
2. Pemulihan sesi menggunakan `GetCurrentPOSUser`/`GetOneUser`, bukan bootstrap seluruh konfigurasi inventori. Penolakan autentikasi eksplisit tetap mencabut sesi.
3. Pembacaan startup terpilih (`GetPOSPinUsers`, `GetMyPOSLockStatus`, `GetPOSRuntimeConfig`, `GetCurrentPOSUser`) dibatasi 8 detik, menutup stream dengan satu error saat timeout. Ini membatalkan subscription klien, bukan jaminan membatalkan pekerjaan database di server.
4. Permintaan runtime dan daftar kasir yang identik berbagi satu request selama masih berlangsung. Hasil selesai/gagal tidak disimpan sebagai memo izin permanen.
5. Daftar operator ditampilkan segera setelah siap, sebelum pemeriksaan opsional PIN akun login. Jika akun sendiri sudah ada dan memiliki PIN, request status tambahan dilewati. Daftar dari cache PIN juga tidak menunggu request status online.
6. Cache runtime dipisahkan berdasarkan endpoint, instansi, akun terminal, dan operator PIN. Request berjalan juga terikat pada sesi/client aktif; respons terlambat dari sesi lama tidak boleh diterima oleh sesi baru.
7. Hanya kegagalan transport/offline yang boleh memakai cache daftar kasir terverifikasi. Respons server yang menolak akses, kesalahan skema, atau respons daftar tidak valid tidak diubah menjadi keberhasilan offline.
8. Penolakan autentikasi/otorisasi daftar kasir dicatat dan bukti PIN lokal dibatalkan. Setelah itu, mematikan internet tidak membuka kembali akses; diperlukan verifikasi online yang sah.
9. Pembuatan PIN akun sendiri hanya ditawarkan setelah status eksplisit `has_pin: false`. Status kosong/tidak lengkap meminta pemeriksaan ulang, bukan dianggap belum punya PIN.
10. Verifikasi PIN menolak identitas respons yang berbeda dan hasil terlambat setelah reset, perubahan akun/instansi, atau perubahan pilihan kasir.

## Jaminan yang dipertahankan

- Memuat daftar kasir atau memulihkan identitas login tidak membuka kunci POS.
- PIN salah tetap ditolak. Cache tidak pernah menjadi alasan untuk melewati input/verifikasi PIN.
- Perangkat pertama tanpa PIN yang pernah diverifikasi online tidak bisa memperoleh akses offline dari daftar nama saja.
- Masa berlaku bukti PIN lokal tetap 7 hari. Batas percobaan dan penguncian sementara yang sudah ada tidak dilonggarkan.
- Mutation pembayaran dan mutation verifikasi PIN tidak dimasukkan ke deadline khusus pembacaan startup. Pengamanan transaksi, stok, jurnal, dan antrean offline tidak dihapus.
- Data transaksi offline tidak dihapus oleh perbaikan ini.

### Catatan migrasi cache

Runtime izin memakai kunci `pos_runtime_config_v2` yang memiliki identitas lengkap. Cache izin lama yang tidak memiliki pemisahan tersebut tidak otomatis dipercaya sebagai izin akun/operator baru. Diperlukan satu pemuatan runtime online yang berhasil untuk mengisi cache baru. Bukti PIN terenkripsi yang masih berlaku tetap memakai penyimpanan yang sudah ada; ini bukan reset data aplikasi.

## Perbandingan terkontrol

Angka berikut berasal dari perilaku kode dan pengujian terkontrol, bukan benchmark waktu login pada HP/produksi.

| Bagian | Sebelum | Sesudah |
| --- | --- | --- |
| Login diterima server | Masih menunggu runtime lengkap hingga 8 detik | Tidak ada request runtime tambahan dalam metode login |
| Pemulihan sesi | Runtime POS lengkap | Query identitas pengguna sendiri |
| Dua pembaca runtime bersamaan | Bisa mengirim dua request | Satu request per identitas/sesi; pemanggilan setelah selesai tetap membaca ulang |
| Daftar kasir sudah siap | Tertahan status PIN opsional | Langsung ditampilkan, POS tetap terkunci |
| API startup tidak merespons | Transport hingga 30 detik, UI daftar dapat gagal lebih awal | Deadline baca 8 detik, lalu cache terverifikasi atau pesan retry |
| Penolakan akses lalu perangkat offline | Berisiko menggunakan bukti lama | Denial tercatat; cache tidak membuka kembali akses |

## Hasil pengujian

### A. Login, sesi, daftar kasir, PIN, dan langganan — PASS

103 tes lulus, 0 gagal. Termasuk 19 skenario baru ketahanan login/roster serta 3 tes helper pembacaan startup.

Skenario penting: login tanpa bootstrap ganda; restore memakai identitas ringan; daftar siap saat status opsional masih menunggu; status PIN tidak lengkap; perangkat pertama tanpa cache; timeout dengan cache sah; PIN salah/benar; bukti kedaluwarsa; penolakan FORBIDDEN/UNAUTHORIZED lalu offline; perubahan instansi/endpoint saat respons berjalan; respons PIN pengguna berbeda; reset saat verifikasi berjalan; isolasi dan pelepasan single-flight; deadline menutup subscription; mutation tidak ikut dibatasi; regresi Google/CAPTCHA/workspace/langganan/tampilan PIN.

Perintah dari direktori proyek mobile:

```powershell
flutter test test/pos_login_roster_resilience_test.dart test/pos_bootstrap_read_test.dart test/pos_login_lock_loading_test.dart test/google_login_test.dart test/auth_workspace_session_test.dart test/pos_auth_error_classification_test.dart test/pos_pin_setup_error_test.dart test/pos_login_captcha_test.dart test/auth_session_loading_test.dart test/auth_subscription_preparation_test.dart test/pos_subscription_test.dart test/pos_subscription_pin_banner_test.dart test/pin_lock_responsive_test.dart test/google_redirect_regression_test.dart test/google_login_progress_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-login-roster-coverage-final-20261122.info' --reporter expanded
```

Bukti: `D:/my node app/zera/output/pos-login-roster-regression-final-20261122.log`.

### B. Regresi tambahan transaksi/offline — PASS

80 tes lulus, 0 gagal. Ada pengulangan skenario dengan suite A; jumlah kedua suite tidak dijumlahkan sebagai tes unik. Suite ini dijalankan sebelum koreksi terakhir status PIN kosong; suite A kemudian diulang dan mencakup koreksi tersebut.

```powershell
flutter test test/pos_login_roster_resilience_test.dart test/pos_bootstrap_read_test.dart test/pos_offline_safety_test.dart test/pos_offline_revocation_sync_test.dart test/pos_checkout_recovery_test.dart test/pos_checkout_cart_lock_test.dart test/pos_payment_single_flight_test.dart --no-pub --concurrency=1 --reporter expanded
```

Bukti: `D:/my node app/zera/output/pos-login-roster-offline-checkout-20261122.log`.

### C. Kontrak dan hak akses server — PASS

66 tes lulus, 0 gagal, 0 dilewati. Database sementara untuk tes; tidak mengubah database produksi. Log memuat pesan ECONNRESET dari proses Mongo sementara, tetapi seluruh tes selesai dan ringkasan runner menyatakan pass 66/fail 0.

```powershell
node --test --test-concurrency=1 tests/pos_graphql.contract.test.js tests/role_read_scope.integration.test.js tests/pos_inventory_hardening.security.test.js
```

Bukti: `D:/my node app/zera/output/pos-login-roster-server-regression-20261122.log`.

### D. Analisis kode — PASS

`dart analyze` terhadap 11 file produksi/tes terkait: **No issues found!** `git diff --check` pada file perubahan juga bersih.

Bukti: `D:/my node app/zera/output/pos-login-roster-analyze-final-20261122.log`.

Coverage baris dari suite A: helper startup 21/22 (95,5%); penyimpanan PIN 102/123 (82,9%); lock cubit 138/193 (71,5%); keseluruhan AuthRepository 120/312 (38,5%, termasuk banyak operasi registrasi/profil di luar suite ini). Angka ini bukan klaim coverage seluruh aplikasi atau semua cabang izin.

## Jejak RED → GREEN

- `4324f9e`: reproduksi enam kegagalan bootstrap/daftar kasir.
- `99d23e8`: spesifikasi deadline dan single-flight.
- `2d5a23a`: reproduksi restore berat dan PIN terlambat setelah reset.
- `b712acf`: reproduksi status PIN tidak lengkap.
- `f290cc9`: implementasi perbaikan dan regresi lulus.

Log RED berada di folder output workspace: `pos-login-roster-red-20261122.log`, `pos-bootstrap-read-red-20261122.log`, `pos-login-restore-pin-race-red-20261122.log`, dan `pos-login-incomplete-pin-status-red-20261122.log`.

## Yang belum dibuktikan di perangkat

- Tidak ada Android/emulator terhubung pada pemeriksaan akhir `adb devices -l`; karena itu tidak ada klaim GUI Android sudah pass.
- Belum mengukur latensi login pada HP pengguna, koneksi seluler, dan endpoint aktual terautentikasi.
- Belum membangun/memasang APK baru. Aplikasi yang sudah terpasang belum memuat perubahan ini.
- Tidak menjalankan seluruh tes proyek atau menyatakan seluruh profil bisnis siap produksi berdasarkan suite terpilih ini.

Langkah uji perangkat berikutnya: pasang build yang memuat perbaikan; uji login online → daftar kasir → PIN benar/salah; ulangi dengan API terputus dan cache sah; uji perangkat tanpa cache; pulihkan internet; pastikan pembatasan akses dan langganan tetap berlaku. Endpoint development di HP harus benar-benar dapat mencapai server; cache bukan pengganti koneksi untuk login pertama.

## Evaluasi penyerahan

Ringkasan: implementasi dan tes otomatis selesai; pembuktian pada Android aktual masih terbuka. Nilai evaluasi 4,0/5, bukan sertifikasi kesiapan produksi.

| Aspek | Nilai | Bukti dan batasan |
| --- | --- | --- |
| Akurasi | 5/5 | Hasil runner 103/80/66 dilaporkan terpisah, analisis bersih, tidak mengklaim benchmark HP atau GUI yang belum dijalankan. |
| Kelengkapan | 3/5 | Timeout, cache, PIN, penolakan akses dan respons terlambat diuji; uji ulang di Android yang diminta belum dapat dibuktikan karena daftar perangkat kosong. |
| Kejelasan | 4/5 | Laporan memisahkan implementasi, hasil, migrasi cache, dan batasan; istilah stream/deadline pada bagian teknis masih ditujukan untuk pengembang. |
| Dapat ditindaklanjuti | 4/5 | Kode, checkpoint dan perintah reproduksi tersedia; perlu memasang build baru sebelum hasil terlihat di HP. |
| Keringkasan | 4/5 | Ringkasan singkat tersedia di awal; detail perintah dan pengamanan sengaja disimpan di laporan audit, bukan jawaban percakapan. |

Prioritas perbaikan berikutnya: uji langsung build terbaru pada Android yang terhubung dan ukur login terautentikasi di endpoint aktual. Kesenjangan ini tidak bisa diselesaikan dengan menambah tes simulasi saja. Pemeriksaan kewajaran: pengguna bisa menilai perbaikan otomatis sebagai selesai, tetapi berhak menunggu bukti perangkat sebelum menyebut masalah HP sepenuhnya tuntas.
