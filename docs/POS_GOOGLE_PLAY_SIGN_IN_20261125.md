# Login Google dari Google Play — 25 November 2026

## Hasil saat ini

Keluhan: pemilih akun muncul, tetapi sesudah dipilih tetap di Login/Daftar, dan kegagalan tidak terlihat. Perbaikan kode lokal dan paket regresi autentikasi **55 PASS**, exit 0. Pemeriksaan browser admin menemukan ketidaksesuaian sertifikat. Setelah pengguna menyetujui penambahan ketiganya, **tiga client Android Play berhasil dibuat melalui browser admin dan diverifikasi pada daftar Cloud**. Client APK lokal/development dan HR tetap ada; IAM, key Play Signing, akun dan database tidak diubah. Login akun Google nyata dari Play Store masih belum dinyatakan PASS.

Tidak dibuat APK/AAB baru pada pekerjaan ini. Rilis Play yang terlihat adalah **24 (1.0.23)**; patch pesan gagal ini belum masuk rilis tersebut.

## Bukti konfigurasi, dibaca langsung

Proyek Google Cloud `pantoo-511802` / `941313151223`, package produksi `id.pantoo.pos`. Browser profil admin Pantoo berhasil mengakses proyek; browser akun lain sebelumnya tidak mempunyai akses. Tidak meminta akses IAM baru.

Daftar Cloud awal berisi lima client: POS Android Production, POS Android Development, HR Android Production, HR Android Development, dan Web/backend. Detail **Pantoo POS Android Production** mempunyai SHA-1 `7E:26:7D:AA:76:A9:A5:5A:40:5E:93:F9:EB:1A:A0:A9:11:CB:9B:71`, sama dengan sertifikat APK/upload lokal, bukan sertifikat distribusi Google Play. Daftar final berisi delapan client setelah tiga penambahan berikut.

Play Console → Protected with Play → Play Store protection → Manage Play app signing → Copy all SHA-1 fingerprints menghasilkan:

| Sertifikat Play, urutan salinan | SHA-1 |
|---|---|
| 1 | `4A:CC:76:CB:06:9A:6C:BE:9A:F5:8F:EF:BA:97:56:A0:D4:D3:C5:4A` |
| 2 | `76:7E:AF:0A:5E:F0:46:5C:9D:D0:26:8B:63:43:91:24:8D:A8:2D:34` |
| 3 | `90:01:72:F1:6A:2E:B1:B6:4A:12:A8:85:68:0B:D3:EB:FE:E2:A7:74` |

Play menampilkan signing quantum-ready dan kunci sebelumnya. Pemetaan individual fingerprint ke kunci klasik/PQC/lama belum dibaca; jangan mengarang pemetaan atau mengganti key signing. Ketiga nilai tidak cocok dengan client POS produksi awal. Ketiganya kini mempunyai client Android tersendiri untuk package `id.pantoo.pos`; client lokal/development dan HR dipertahankan.

### Penambahan Cloud yang benar-benar dilakukan

Persetujuan: pengguna menjawab “boleh” atas penambahan ketiga sertifikat, lalu meminta “tolong tambahkan gunakan computer use”. Form masing-masing diisi Android / `id.pantoo.pos` / SHA-1 sesuai tabel. Checkbox agent tetap tidak dipilih. Tiga hasil **OAuth client created** terbaca, kemudian seluruh client baru terlihat di daftar akhir bersama lima client lama. Tidak mengunduh JSON, membuat secret tambahan, mengubah consent/scopes, meminta ownership/IAM atau mengganti signing key.

| Nama client baru | Prefix SHA-1 | Client ID |
|---|---|---|
| Pantoo POS Google Play 4ACC | `4A:CC` | `941313151223-f95k9dhc7kl9gihvc8tgijr3jq89t8jf.apps.googleusercontent.com` |
| Pantoo POS Google Play 767E | `76:7E` | `941313151223-f9ij5lcs2b9pi393sgbam6p9ame1c6di.apps.googleusercontent.com` |
| Pantoo POS Google Play 9001 | `90:01` | `941313151223-i4rsu3g4rpkbjiof22hdsiafgdc0or8u.apps.googleusercontent.com` |

[Daftar OAuth proyek](https://console.cloud.google.com/auth/clients?project=pantoo-511802) dibiarkan terbuka sebagai hasil. Cloud menampilkan waktu propagasi 5 menit sampai beberapa jam. Penambahan server-side ini tidak memerlukan perubahan serverClientId atau build baru untuk mendaftarkan cert; patch UI/progres lokal tetap memerlukan rilis aplikasi tersendiri.

Query publik baca-saja `GetGoogleRegistrationClientId` di `https://graphql.pantoo.id/` berhasil dan cocok dengan bundled Web client `941313151223-pbdntkrdmhhqc88vafpte9svfdqv6kf8.apps.googleusercontent.com`. Karena itu mengganti backend client ID atau memakai Android client sebagai serverClientId bukan perbaikan yang tepat saat ini.

Ini menjelaskan mengapa APK lokal dapat bekerja sementara versi Play gagal. SDK Android juga mendokumentasikan bahwa sebagian kesalahan konfigurasi setelah memilih akun dilaporkan sebagai `canceled`, sehingga sebelumnya ditelan tanpa pesan. Referensi: [SDK resmi Google Sign-In Android](https://pub.dev/packages/google_sign_in_android), [pengelolaan app signing Google Play](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en).

## Perbaikan aplikasi

- Pembatalan/tahap Google yang tidak selesai sekarang mempunyai pesan persisten, warna kontras, ikon kesalahan dan pengumuman aksesibilitas; tidak lagi diabaikan. Pesan tidak menuduh pengguna membatalkan jika sebenarnya konfigurasi bermasalah.
- Kesalahan konfigurasi SDK mendapat pesan khusus dan alternatif login email/password. Batas waktu pemilih akun mendapat pesan timeout dan tombol dapat dicoba lagi.
- Pesan dan progres tersedia dalam Indonesia/Inggris. Detail exception privat, token dan password tidak ditampilkan atau dicatat. Diagnostik inisialisasi hanya mencatat jenis exception.
- Inisialisasi SDK dipakai satu kali lintas widget Login/Daftar; client ID server tetap divalidasi, perubahan project mengharuskan restart.
- ID token kosong/whitespace ditolak. Backend Pantoo tetap harus menerima dan memverifikasi bukti Google sebelum navigasi; PIN, langganan dan scope akses tidak dilewati.
- Redirect tetap dimiliki App. Akun lama menuju gate workspace/PIN; akun baru melengkapi telepon dan persetujuan eksplisit lalu menuju setup usaha. Tidak menambahkan redirect/deep link palsu.

## Skenario dan hasil

| TEST-ID | Jaminan | Hasil / jenis |
|---|---|---|
| TEST-POS-GOOGLE-PLAY-CERT-2511 | Sertifikat POS Cloud dibandingkan dengan seluruh SHA-1 app signing Play | mismatch terkonfirmasi, inspeksi GUI baca-saja |
| TEST-POS-GOOGLE-PLAY-CONFIG-2511 | Tiga pasangan Android/package/SHA-1 dibuat setelah persetujuan, setiap hasil sukses dan daftar delapan client dikonfirmasi | PASS konfigurasi GUI, bukan login akun nyata |
| TEST-POS-GOOGLE-CANCEL-2511 | Tombol Google Login dan Daftar benar-benar ditekan; respons canceled SDK menampilkan error dan retry, tanpa login backend | PASS, widget/integrasi terkontrol |
| TEST-POS-GOOGLE-SDK-NAV-2511 | Tombol → SDK native → AuthCubit → App: akun lama meninggalkan public stack; akun baru telepon/consent → BusinessSetup; SDK tidak diinisialisasi ulang | PASS, widget/integrasi terkontrol |
| TEST-POS-GOOGLE-ERROR-2511 | Konfigurasi client/provider, interrupted ID/EN, proof kosong, backend menolak, picker macet 90 detik | PASS, widget/integrasi terkontrol |
| TEST-POS-GOOGLE-GUARD-2511 | Pemeriksaan langganan/timeout/retry, login password, CAPTCHA, PIN dan penolakan sesi tetap aman | PASS, regresi terarah |
| TEST-POS-GOOGLE-PLAY-ACCOUNT-2511 | Akun Google nyata pada instalasi Play, Login dan Daftar, cold restart, tujuan benar | **unverified**, konfigurasi selesai; perlu propagasi dan pengujian perangkat |

Tidak menghapus/skip tes, memperlemah assertion bisnis atau mengubah akun/DB agar tes lulus. SDK, repository/network dan penyimpanan tes dikontrol; ini bukan hasil login Google nyata. Tambahan finder consent dibatasi ke bottom sheet agar tidak salah menekan checkbox halaman Daftar di belakangnya.

## Bukti RED → GREEN dan perintah

Perjalanan diturunkan dari keluhan sesi ini, bukan dari dokumen rencana baru. Runtime RED valid: `google-native-red2.log`, tombol Google native ditekan dan cancellation tidak menghasilkan panel kesalahan pada implementasi lama. Checkpoint RED **95a214f**. Percobaan awal dengan locale/fake-zone yang salah tidak dihitung sebagai bukti bisnis; fixture dikoreksi. GREEN utama **07f635b** dan dependency fixture **389896c**, pada branch `main`; perubahan versi milik pengguna tidak diikutkan.

Cwd `mobile_POS_Pantoo`:

```powershell
flutter test --no-pub --concurrency=2 --timeout 2m --coverage --coverage-path=output/operational-readiness-20261125/google-native-final-lcov.info test/google_redirect_regression_test.dart test/google_login_test.dart test/google_login_progress_test.dart test/pos_google_navigation_test.dart test/auth_session_loading_test.dart test/auth_subscription_preparation_test.dart test/pos_login_captcha_test.dart test/registration_flow_contract_test.dart test/pos_pin_setup_error_test.dart
```

Hasil `google-native-final.log`: **00:53 +55: All tests passed!**, exit 0. Suite redirect mempunyai 20 kasus, termasuk 10 jalur SDK baru; suite lain saling melengkapi, bukan 55 akun/perangkat nyata. Cakupan yang dicatat runner: GoogleAccountButton **139/170 (81,8%)** baris executable; GoogleIdentityService **4/5 (80%)** pada record terinstrumentasi. Bukan coverage seluruh autentikasi/aplikasi. Cabang stream browser web tidak diuji native; pengujian akun Play tetap gap eksplisit.

Analisis tiga berkas (GoogleIdentityService, GoogleAccountButton dan tes redirect) melalui `dart analyze`: **No issues found!**, exit 0, `google-native-analyze.log`. Satu peringatan kurung pada fixture tes dirapikan; tidak ada perilaku produksi berubah setelah GREEN.

Runner penuh `flutter test --no-pub --concurrency=2 --timeout 2m`: **05:32 +1201: All tests passed!**, exit 0, `google-all-tests.log`. Ini regresi seluruh suite Flutter pada working tree saat diuji, bukan 1.201 sesi GUI/akun Google nyata. Hasil 55 terarah tercakup runner penuh, tidak dijumlahkan.

## Langkah penutupan

1. **Selesai:** tiga konfigurasi Android Play ditambahkan setelah izin pengguna; client ID dicatat, nilai form dan hasil sukses diverifikasi; client APK lokal serta HR tidak diubah/dihapus.
2. Tunggu propagasi yang dinyatakan Cloud (5 menit sampai beberapa jam), lalu uji ulang dari aplikasi yang benar-benar diunduh Play Store. Tidak perlu mengganti key signing.
3. Login dan Daftar akun lama harus menuju PIN/workspace, akun baru harus meminta consent/telepon lalu setup. Batal atau gagal tidak boleh membuka workspace.
4. Rilis aplikasi berikutnya harus menyertakan patch pesan/progres ini. Tidak menjanjikan patch lokal sudah diterima pengguna Play tanpa publikasi.

## Evaluasi hasil

Ringkasan 4,0/5: akurasi 4 (tes lokal dan tiga hasil konfigurasi sukses terbukti; belum akun Play nyata), kelengkapan 4 (Login/Daftar/error/guard dan penambahan OAuth selesai; uji perangkat setelah propagasi belum), kejelasan 4 (konfigurasi Cloud dibedakan dari patch UI/rilis), dapat ditindaklanjuti 4 (ketiga client ID dan langkah uji tersedia; pengguna perlu mencoba akun dari Play), keringkasan 4 (detail audit terpisah dari jawaban pengguna). Prioritas: uji akun nyata sesudah propagasi. Self-check: penambahan yang diminta selesai dan terverifikasi, bukan klaim E2E Google Play sudah lulus.
