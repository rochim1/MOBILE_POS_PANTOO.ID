# Login dan daftar Google — perbaikan redirect POS

Tanggal:17November2026. Sumber kebutuhan: pengguna melaporkan pemilih akun Google muncul tetapi sesudah memilih akun tetap berada di halaman login/daftar; diminta mengikuti pengalaman mobile HR.

## Hasil dan batas

**Perbaikan kode dan regresi lokal PASS.** Flutter50/50, backend keamanan login13/13, `flutter analyze --no-pub` exit0: **No issues found**. Ini bukan klaim E2E akun Google nyata di Android. Belum build APK/AAB, instal ulang, menghapus data aplikasi, membuat akun Google/Pantoo produksi atau mengubah OAuth Cloud.

Empat masalah pada alur sesudah identitas diverifikasi berhasil direproduksi dan diperbaiki:

1. Request konfigurasi POS tambahan dapat menahan hasil login meskipun token Pantoo sudah diterima/disimpan. Request ini dibatasi8detik; workspace melanjutkan pemeriksaan dan pemulihannya sendiri bila request lambat. Respons yang datang terlambat tidak mengubah instansi/preference.
2. Listener login menunggu pemeriksaan langganan sebelum mengganti halaman. Navigasi kini tidak menunggu IO itu; `PosSubscriptionBoundary` tetap mengaktifkan verifikasi dan **tetap memblokir akses/penjualan bila status belum terverifikasi atau tidak diizinkan**.
3. Slide login intro melakukan navigasi tersendiri yang dapat mendahului pemeriksaan PIN pusat. Redirect sukses kini hanya dimiliki `App`, dengan PIN tetap fail-closed dan intro ditandai selesai di pusat.
4. Batas luar30detik bersaing dengan transport30detik ditambah penyimpanan sesi/bootstrap. Batas luar Google menjadi45detik, sementara bootstrap tetap dibatasi8detik. Kasus hasil valid pada33detik sekarang diterima, bukan ditampilkan sebagai kegagalan login palsu.

Login dan daftar memakai identitas Google yang sama. Pengguna lama menuju pemeriksaan PIN/onboarding/dashboard yang sesuai; pengguna baru tetap melengkapi nomor telepon dan persetujuan eksplisit, lalu menuju penyiapan profil usaha. Pendaftaran email biasa tidak diubah.

## Jaminan dan pengujian

| TEST-ID | Input dan perilaku yang dibuktikan | Jenis / hasil |
|---|---|---|
| TEST-POS-GOOGLE-RUNTIME-1711 | Backend menerima login, runtime tidak membalas; sesi tetap authenticated. Respons runtime terlambat tidak mengganti instansi. Hasil valid33detik tidak kalah oleh deadline luar | unit/integration, covered scoped |
| TEST-POS-GOOGLE-NAV-1711 | Login maupun Register pada `App` sebenarnya meninggalkan seluruh public stack walau subscription Future masih tertahan; pengguna baru dari kedua route menuju BusinessSetup | integration dengan widget nyata, covered scoped |
| TEST-POS-GOOGLE-PIN-1711 | Intro tidak push route sendiri; navigasi pusat tetap mengunci bila kebijakan PIN aktif, gagal atau timeout; logout saat pengecekan tidak membuka dashboard | integration/unit, covered scoped |
| TEST-POS-GOOGLE-GUARDS-1711 | Runtime UNAUTHORIZED tetap membersihkan sesi; token Google tidak disimpan; identitas baru meminta consent; callback ganda tidak menggandakan login; subscription unknown/read-only tetap menolak write; backend menolak token/email yang tidak valid | unit/integration, covered scoped |
| TEST-POS-GOOGLE-NATIVE-1711 | Memilih akun Google nyata pada APK terbaru sampai tujuan benar, termasuk cancel, akun baru, cold restart dan instalasi Google Play | E2E, **unverified** |

Test code: `test/google_redirect_regression_test.dart`, `test/google_login_test.dart`, `test/pos_google_navigation_test.dart`, serta suite sesi/PIN/subscription di bawah. Google SDK, HTTP, penyimpanan dan waktu disimulasikan pada tes Flutter; widget App/Navigator/Cubit/repository yang diuji adalah kode aplikasi nyata. Tes backend memalsukan verifikasi Google dan akses model, bukan menggunakan kredensial pengguna atau DB produksi. Kelompok-kelompok ini tidak dijumlahkan menjadi jumlah kasus E2E.

### Perintah yang benar-benar dijalankan

Flutter cwd `mobile_POS_Pantoo`:

```powershell
flutter test --no-pub --coverage --coverage-path ../output/google-pos-redirect-20261117/lcov-final.info test/google_redirect_regression_test.dart test/google_login_test.dart test/google_login_progress_test.dart test/pos_google_navigation_test.dart test/auth_session_loading_test.dart test/auth_workspace_session_test.dart test/pos_login_lock_loading_test.dart test/pos_login_captcha_test.dart test/pos_auth_error_classification_test.dart test/pos_subscription_test.dart test/pos_subscription_access_refresh_test.dart --reporter expanded
flutter analyze --no-pub
```

Tes final50PASS, exit0; analyze exit0, tanpa issues. Analisis pertama dihentikan saat bertabrakan penggunaan RAM dengan tes; analisis final dijalankan terpisah hingga selesai110,6detik. Tidak ada aplikasi/server pengguna dihentikan.

Backend cwd `presensi_zera_BE`:

```powershell
node --test tests/google_login.security.test.js tests/google_auth_public_fields.test.js tests/login_credentials.security.test.js
```

13PASS,0FAIL,0skip,0cancel, exit0. Source backend tidak diubah.

### Bukti RED → GREEN

Folder `output/google-pos-redirect-20261117/` di root workspace menyimpan:

- `red.log`: intro menghasilkan dua push, sementara hanya satu route awal yang diizinkan sebelum navigasi pusat.
- `red-corrected.log`: reproduksi runtime serta dua route pending subscription gagal pada implementasi lama setelah identifikasi request dan settling async tes dikoreksi. Reproduksi awal yang belum tepat tidak dijadikan bukti tunggal.
- `green-corrected.log`:8/8PASS setelah perbaikan utama.
- `deadline-red.log`: hasil valid33detik salah menjadi ServerFailure dengan deadline lama.
- `regression.log`:49/49PASS sebelum kasus deadline tambahan.
- `regression-final.log`:50/50PASS sesudah seluruh perbaikan.
- `backend-auth.log`, `analyze-final.log`, `lcov-final.info`, `coverage-proof.json`.

Coverage baris executable yang ditambah/diubah terhadap checkpoint `fbbe912`: **11/11(100%)**. Ini metrik changed-line, bukan coverage keseluruhan aplikasi atau E2E native. Sebagai pembatas klaim, seluruh AuthRepository dalam kelompok tes ini120/340baris; fungsi lain di luar login tidak dinyatakan mencapai80%. Tidak ada tes dihapus/dilemahkan atau hasil gagal disembunyikan.

Checkpoint pada branch `main` mobile: `fbbe912` RED awal, `809ddcf` perbaikan reproducer/RED valid, `82f0039` GREEN perbaikan utama, `af6bd97` RED deadline dan tambahan guard, `0cb4033` GREEN final50tes. Perubahan versi `pubspec.yaml` milik pengguna dipertahankan di working tree dan tidak ikut checkpoint. Tidak push/deploy.

## Kesetaraan Google HR dan konfigurasi perangkat

POS dan mobile HR memakai `google_sign_in` resmi: Android menggunakan pemilih akun native; backend `Login(provider:google)` memverifikasi ID token lalu menerbitkan sesi Pantoo. Tidak ditambahkan redirect URI browser/deep link palsu atau jalur melewati verifikasi server.

Query baca-saja `GetGoogleRegistrationClientId` pada `https://graphql.pantoo.id/` menghasilkan HTTP200, client ID terkonfigurasi dan prefix project sesuai HR. Nilai kunci aplikasi dan token tidak dicatat. Backend development `localhost:8080` tidak dapat dihubungi pada pemeriksaan sesi ini; pengujian lokal memerlukan backend aktif/endpoint yang benar. Ini bukan bukti bahwa seluruh pasangan package/SHA Android terdaftar di Cloud.

Jika setelah APK baru masih gagal sebelum server menerima Login, periksa OAuth Android khusus `id.pantoo.pos` dan sertifikat signing build yang dipakai. Sertifikat Google Play dapat berbeda dari APK lokal; jangan menyalin package/SHA HR ke POS. Persyaratan resmi ada pada [konfigurasi Google Sign-In Android](https://pub.dev/packages/google_sign_in_android). iOS/macOS dan Flutter web tidak diuji ulang melalui akun Google nyata dalam sesi ini.

## Penerapan dan pemeriksaan perangkat berikutnya

1. Untuk development lakukan hot restart; untuk HP terpasang, build dan instal APK baru dari source ini. APK lama tidak mendapat perbaikan otomatis.
2. Uji akun Google lama dari Login dan Register: hanya satu navigasi menuju PIN/onboarding/dashboard; Back tidak kembali ke form publik.
3. Uji akun Google baru: nomor telepon dan consent wajib; batal tidak membuat sesi; sesudah berhasil menuju penyiapan usaha, bukan dashboard kosong.
4. Uji koneksi lambat setelah akun dipilih: konfigurasi tambahan tidak menahan Login, tetapi PIN/langganan/izin tetap mencegah akses yang belum sah. Uji logout ketika proses berlangsung.

## Evaluasi

Ringkasan4,0/5: akurasi4 (RED/GREEN dan analyze terbukti, belum akun Google nyata); kelengkapan4 (kedua route, intro, akun baru/lama dan guard diuji, penerapan HP masih diperlukan); kejelasan4 (status lokal dibedakan dari native E2E, detail audit cukup panjang); dapat ditindaklanjuti4 (source/checkpoint/perintah tersedia, perlu APK baru); keringkasan4 (jawaban pengguna ringkas, bukti terpisah). Prioritas berikut adalah TEST-POS-GOOGLE-NATIVE-1711 pada APK baru dan akun uji nyata. Self-check: layak sebagai perbaikan teruji lokal, bukan sertifikasi OAuth/perangkat produksi.
