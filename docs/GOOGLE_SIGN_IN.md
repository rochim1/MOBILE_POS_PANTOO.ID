# Login dan daftar Google — Pantoo POS

Halaman Masuk dan Daftar memakai komponen Google bersama. Web memakai tombol Google Identity Services resmi; Android memakai pemilih akun SDK. Windows dan Linux tetap memakai login email karena SDK Google Flutter tidak mendukung kedua platform tersebut.

## Alur akun

- Client ID Web diambil dari query publik `GetGoogleRegistrationClientId` pada backend yang aktif.
- ID token Google hanya dipegang selama proses login dan dikirim ke mutation `Login`, provider `google`. Backend memverifikasi signature, audience dan email terverifikasi.
- Akun baru menerima challenge `GOOGLE_REGISTRATION_DETAILS_REQUIRED`; nomor telepon 8–15 digit dan checkbox persetujuan eksplisit diperlukan. Membatalkan formulir tidak membuat akun.
- Pendaftaran membawa `primary_product: pos`, `registration_source: mobile_pos`, dan `access_via: mobile_pos`.
- Sesi Pantoo dan refresh token mengikuti penyimpanan aman serta bootstrap POS yang sama dengan login email. Akun tanpa instansi melanjutkan ke setup usaha/trial. Hak akses toko tetap ditentukan backend.
- Respons login tidak masuk cache GraphQL. Inspector HTTP tidak digunakan agar token Google, password, dan refresh token tidak tersimpan pada log debug.

## Google Cloud

Gunakan project `pantoo-511802` / `941313151223`, client Web backend `941313151223-pbdntkrdmhhqc88vafpte9svfdqv6kf8.apps.googleusercontent.com` yang sudah berstatus In production pada konfigurasi HR.

Android POS memerlukan OAuth Android tersendiri; client package HR tidak berlaku untuk POS:

| Build | Package | SHA-1 |
| --- | --- | --- |
| Production, sertifikat APK lokal yang diperiksa | `id.pantoo.pos` | `7E:26:7D:AA:76:A9:A5:5A:40:5E:93:F9:EB:1A:A0:A9:11:CB:9B:71` |
| Development debug lokal | `id.pantoo.pos.dev` | `A3:1E:84:F8:72:9C:B4:EF:3D:E1:3B:71:5E:AE:87:CD:8B:24:0D:E7` |

Kedua client Android POS berhasil dibuat dan diverifikasi di daftar Google Cloud pada 25 Oktober 2026:

| Client | Client ID |
| --- | --- |
| Pantoo POS Android Production | `941313151223-ibad2oieraeksbiijm0nuomjqejbv146.apps.googleusercontent.com` |
| Pantoo POS Android Development | `941313151223-ifugpgd0n5sf3sog6ns1g95jdp912n3h.apps.googleusercontent.com` |

Package dan SHA-1 mengikuti tabel di atas. Untuk distribusi Play Store, cocokkan juga SHA-1 App Signing di Play Console. Client Android tidak dipakai sebagai serverClientId; aplikasi tetap mengambil client Web dari backend.

Pada uji endpoint production terakhir, backend masih mengembalikan client Web lama dari project 657305849206. Atur GOOGLE_CLIENT_ID server ke client Web project 941313151223 yang tercantum di atas, lalu reload environment proses sebelum uji login nyata. Backend production dideploy manual oleh pemilik.

Web development menggunakan `http://localhost:7357`, origin yang sudah diizinkan pada client Web. Jalankan konfigurasi VS Code **Pantoo POS Dev Web Google (7357)** atau:

```sh
flutter run -d chrome --target lib/main_development.dart --web-hostname localhost --web-port 7357
```

Tutup preview HR pada port yang sama terlebih dahulu. Jangan memakai port acak atau `127.0.0.1`, karena berbeda origin. Backend development dipilih melalui pengaturan endpoint POS yang sudah ada, kemudian restart aplikasi.

iOS/macOS memerlukan client OAuth dan konfigurasi platform tersendiri sebelum login diuji di platform tersebut.

## Validasi

```sh
flutter test test/google_login_test.dart test/pos_login_captcha_test.dart test/auth_session_loading_test.dart
```

Sepuluh pengujian lulus: atribusi POS/persetujuan, token Google tidak disimpan, challenge akun baru tanpa sesi, callback ganda, formulir persetujuan, serta regresi sesi email/CAPTCHA. Registrasi OAuth Android selesai. Uji login dengan akun Google nyata masih menunggu penyelarasan client ID backend dan backend development yang dapat dijangkau.

Pemeriksaan analyzer pada file autentikasi dan pengujian: **No issues found**. Build web `lib/main_development.dart` berhasil. APK baru belum dibuat pada perubahan ini.

SDK: https://pub.dev/packages/google_sign_in dan https://pub.dev/packages/google_sign_in_web.
