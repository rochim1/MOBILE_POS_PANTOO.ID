# Konfigurasi POS timeout dan cache lintas platform

Tanggal: 22 November 2026. Permintaan: menelusuri timeout 8 detik dan error `Platform._operatingSystem`, lalu memeriksa Chrome serta Android. Skenario diturunkan langsung dari laporan pengguna, tanpa file rencana terpisah.

## Penyebab dan perbaikan

1. **Server runtime mengulang pembacaan role.** Dalam fixture non-admin, satu `GetPOSRuntimeConfig` membaca role 92 kali untuk pemeriksaan izin yang berbeda. Resolver kini memakai scope pembacaan izin yang sudah ada, hanya selama satu pemanggilan. Hasil tidak dibagi antar permintaan, akun, atau instansi. Permintaan berikutnya tetap membaca pencabutan izin terbaru.
2. **Flutter Chrome mencoba database native.** `getStores` menyimpan cache tanpa memeriksa dukungan platform. Jalur cache pelanggan memiliki pola serupa. Pembacaan/penyimpanan cache toko dan pelanggan kini melewati SQLite pada platform tanpa dukungan database offline.
3. **Batas database belum defensif.** Getter database kini menolak akses SQLite pada platform yang tidak mendukungnya sebelum menyentuh `Platform.isAndroid/isIOS`. Jalur SQLCipher Android/iOS tidak diganti dan skema database tidak diubah.
4. **Tutup shift Chrome ikut memerlukan SQLite.** Pemeriksaan antrean lokal kini hanya dijalankan pada platform yang memang memiliki antrean SQLite. Android/native tetap menolak tutup shift dengan transaksi `pending`, `syncing`, `needs_review`, atau `rejected` yang belum diselesaikan. Server tetap menjadi otoritas terakhir bagi kedua platform.

PIN, langganan, batas waktu startup 8 detik, aturan hak akses, dan pengamanan stok/jurnal tidak dilonggarkan. Timeout tetap mungkin terjadi jika koneksi atau server lain bermasalah; optimasi role bukan bukti bahwa semua penyebab timeout di perangkat pengguna telah hilang.

## Pengukuran terkontrol

Pada fixture MongoDB sementara, query role berkurang **92 → 1** per konfigurasi. Waktu fungsi runtime pada satu run lokal: **463,5 ms → 66,2 ms**. Ini pengamatan satu fixture, bukan benchmark statistik, waktu startup total, atau pengukuran pada HP/database produksi.

API development `http://localhost:8080/graphql` juga diperiksa dengan query publik `{ __typename }`: HTTP 200, sekitar 2.144 ms pada pemeriksaan terakhir. Ini membuktikan koneksi dasar dari komputer, bukan performa konfigurasi terautentikasi atau keterjangkauan endpoint dari HP. Alamat endpoint aktual perangkat pengguna belum diberikan.

## Hasil pengujian

| Kelompok | Hasil | Yang dibuktikan |
| --- | --- | --- |
| Flutter Chrome, `pos_web_native_cache_test.dart` | **4 PASS** | Batas SQLite menolak akses native; daftar toko online tidak memicu peringatan cache; tutup shift mencapai server; penolakan izin server tetap ditolak. |
| Native/VM, enam file terpilih | **47 PASS** | Cache toko menyimpan cabang dan mode shift; empat status antrean menghalangi penutupan; penyelesaian/antrean shift lain ditangani benar; antrean tak terbaca gagal tertutup; respons kosong tidak dianggap sukses; regresi PIN, cache offline, dan stok. |
| Server, lima file terpilih | **51 PASS** | Role dibaca sekali per runtime; pencabutan izin terbaca pada request berikutnya; isolasi akun/instansi; regresi PIN, profil pesanan dan kontrak GraphQL. |
| Analisis Dart, empat file terkait | **No issues found!** | Tidak ada issue analisis pada file yang diubah. |

Tidak ada tes yang dilewati dalam ketiga eksekusi di atas. Jumlah tersebut bukan klaim seluruh suite aplikasi sudah dijalankan.

### Perintah validasi

```powershell
flutter test test/pos_web_native_cache_test.dart --platform chrome --no-pub --reporter expanded --verbose
flutter test test/pos_native_cache_shift_test.dart test/pos_login_roster_resilience_test.dart test/pos_bootstrap_read_test.dart test/pos_store_cache_test.dart test/pos_offline_read_store_test.dart test/pos_offline_safety_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-platform-cache-native-coverage-20261122.info' --reporter expanded
dart analyze lib/data/datasources/local/pos_local_database.dart lib/domain/repositories/pos_repository.dart test/pos_web_native_cache_test.dart test/pos_native_cache_shift_test.dart
node --test --test-concurrency=1 tests/pos_runtime_read_scope.integration.test.js tests/role_read_scope.integration.test.js tests/pos_lock.security.test.js tests/pos_order_workspace.integration.test.js tests/pos_graphql.contract.test.js
```

Perintah Node dijalankan dari proyek backend, lainnya dari proyek mobile. Semua database tes dibuat sementara; tidak menghapus database aplikasi atau data produksi. Native test memakai direktori SQLite baru di folder TEMP tugas, bukan database aplikasi terpasang.

### Kendala runner Chrome dan cara uji dijalankan

Runner Flutter Windows lokal salah melayani beberapa aset engine sehingga mendapat 404. Beberapa percobaan awal gagal sebelum tes berjalan; itu **bukan** bukti RED aplikasi. Beberapa fixture awal juga kekurangan `__typename`; fixture tersebut dilengkapi sebelum membuktikan kegagalan cache toko.

Untuk run Chrome yang lulus, `CHROME_EXECUTABLE` di shell tes diarahkan sementara ke `D:/my node app/zera/output/PosFlutterTestChromeRelay.exe`. Launcher QA itu meneruskan output Chrome dan menyiapkan intersepsi aset sebelum halaman tes pertama dimuat: file CanvasKit dibaca dari SDK lokal; manifest font kosong hanya dipakai untuk tes repository non-visual. SDK, browser pengguna, kode aplikasi, dan endpoint tidak diubah oleh launcher ini. Sumber pendukung: `output/PosFlutterTestChrome.cs` dan `output/pos-flutter-test-chrome-assets.cjs` di root workspace. Pengaturan environment hanya berlaku pada proses tes tersebut.

## Bukti RED → GREEN dan log

- Backend RED: 1 gagal/1 lulus; assertion `92 !== 1`. Commit `3bf8b46c`; GREEN `b32cd089`, 51 tes server lulus.
- Mobile RED awal: akses database browser dan dua skenario tutup shift gagal pada jalur native; commit `3f2fdaa`. Tes toko saat itu juga menemukan fixture tidak lengkap dan belum dihitung sebagai reproduksi bug cache yang valid.
- Mobile RED cache toko yang valid: assertion `Expected: empty` menemukan peringatan cache setelah respons GraphQL lengkap. Commit fixture `71a2164`.
- Mobile GREEN: `ecf7e6a`, 4 tes Chrome serta regresi native lulus. Tambahan kondisi antrean tak terbaca dan respons kosong diuji lagi hingga 47 PASS.

Log di `D:/my node app/zera/output/`:

- `pos-runtime-read-scope-red-20261122.log`
- `pos-runtime-read-scope-green-20261122.log`
- `pos-web-store-cache-red-final2-20261122.log`
- `pos-web-native-cache-green-final-20261122.log`
- `pos-platform-cache-native-green-20261122.log`
- `pos-platform-cache-analyze-20261122.log`
- Coverage native: `pos-platform-cache-native-coverage-20261122.info`; metode `closeShift` tercakup **18/19 baris (94,7%)**. Laporan ini tidak mengklaim coverage seluruh file/proyek 80%; banyak metode registrasi, migrasi, dan transaksi lain berada di luar suite terpilih. Guard browser dibuktikan oleh run Chrome terpisah, bukan dihitung sebagai hit coverage VM.

## Batas hasil dan penerapan

- `adb devices -l` kosong; belum ada pengujian GUI langsung pada HP/emulator Android. Hasil native/VM membuktikan logika database dan penjaga offline, bukan integrasi plugin SQLCipher pada perangkat.
- Tidak membuat APK/AAB baru atau mereset akun/data. Aplikasi Android yang sudah terpasang belum otomatis memuat perubahan kode ini.
- Sesi Flutter yang sedang berjalan perlu hot restart untuk memuat perubahan. Backend perlu memuat ulang resolver; bila memakai nodemon, perubahan berkas dapat memicu reload otomatis.
- Untuk HP Android dengan endpoint development localhost, pastikan jalur koneksi ke komputer memang tersedia, misalnya pengaturan endpoint perangkat yang benar atau pemetaan USB. Respons localhost di komputer bukan bukti HP dapat mengaksesnya.

## Evaluasi penyerahan

Ringkasan: perbaikan dan tes lintas platform yang dapat dijalankan sudah PASS; verifikasi GUI Android dan latensi request akun pengguna masih terbuka. Evaluasi 4,0/5: akurasi 5 (klaim sesuai log), kelengkapan 3 (belum perangkat Android aktual), kejelasan 4 (detail teknis dipisahkan), dapat ditindaklanjuti 4 (kode dan perintah tersedia, build perangkat belum dibuat), keringkasan 4 (bukti rinci disimpan dalam laporan).

Prioritas berikutnya: jalankan build terbaru pada Android yang terhubung; ukur `GetPOSRuntimeConfig` terautentikasi pada endpoint pengguna. Kedua hal itu tidak dapat digantikan dengan menambah tes simulasi. Pemeriksaan kewajaran: hasil ini cukup untuk menyatakan kode/regresi terpilih lulus, tetapi belum cukup untuk menyatakan seluruh masalah di HP telah terbukti selesai.
