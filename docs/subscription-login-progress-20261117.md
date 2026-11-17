# Login: pemeriksaan langganan tanpa halaman perantara

Tanggal: 17 November 2026. Lingkup: aplikasi Flutter POS mobile, tanpa perubahan backend, Finance, database, versi aplikasi, atau build APK/AAB.

## Permintaan dan kriteria penerimaan

Sumber: permintaan pengguna pada chat ini, “ketika login halaman check subscription status tidak perlu ditampilkan … tombol untuk login menampilkan keterangan, baru jika expired subscriptionnya menampilkan halaman itu”.

- Kredensial diterima → tombol menunjukkan proses pemeriksaan, form tetap terpasang.
- Status aktif terverifikasi → navigasi pusat tetap melewati kebijakan PIN/onboarding.
- Gagal koneksi atau belum diketahui → tidak dianggap expired; tampilkan kesalahan dan coba lagi di form, tanpa mengirim ulang password/proof Google. Pengguna juga dapat mengganti akun.
- Pembatasan langganan terkonfirmasi → halaman pemulihan/billing tetap muncul sesuai kebijakan server. Read-only dan grace mempertahankan perilaku sebelumnya.
- Pemulihan sesi tersimpan → splash berlogo sampai verifikasi selesai, bukan kilatan form/billing.
- Offline hanya memakai grant tersimpan yang masih sah menurut batas server dan trusted clock. Tidak mengendurkan guard transaksi.

## Implementasi

`AuthCubit` memiliki tahap `checkingSubscription` sebelum authenticated, callback produksi `preparePosLoginSession`, deadline20detik dan retry sesi yang sudah diterima. Akun baru tanpa workspace tidak ditahan oleh pemeriksaan tenant yang belum ada. Revision guard melindungi logout dari respons terlambat.

Form login menampilkan spinner serta “Memeriksa langganan…”. Tombol Google dan jalur daftar juga mengenali tahap pemeriksaan/retry; pendaftaran email tidak dapat menimpa kelanjutan sesi yang masih menunggu. Pemilihan akun/consent Google sebelum identitas diterima tetap tidak diinterupsi.

Boundary langganan tetap memblokir write saat status belum diketahui, tetapi tidak menyebutnya sebagai expired atau menampilkan halaman billing. Kondisi unknown saat perubahan akses di sesi yang sudah terbuka memakai panel netral dengan retry, logout dan jalur pemulihan shift/antrean. Struk yang telah diterima tetap dilindungi oleh pengecualian yang ada.

## Bukti pengujian

Checkpoint RED `bb48046`: tes widget `pending verification is not a subscription billing page` berhasil mereproduksi bug pada kode lama: mengharapkan0 `PosSubscriptionPage`, aktual1; exit1 karena assertion perilaku, bukan kompilasi.

GREEN: rangkaian13file, **71/71PASS, exit0**, `output/subscription-login-20261117/regression.log`. Pemeriksaan kode pada semua source/test terkait: **No issues found, exit0**, `output/subscription-login-20261117/analyze.log`.

Coverage: `output/subscription-login-20261117/lcov.info`, **155/174 (89,1%) baris executable yang ditambahkan/diubah** pada sembilan file source dalam diff terhadap checkpoint RED. Hanya baris yang memiliki record DA dihitung; bukan coverage seluruh aplikasi atau bukti E2E Android.

### Required test points

| TEST-ID | Status / level / purpose | Input dan bukti perilaku | Lokasi |
|---|---|---|---|
| TEST-POS-SUBLOGIN-PROGRESS-1711 | covered scoped; integration; regression protection, critical path | Password/Google diterima, fetch ditahan: LoginPage tetap ada, tombol menyebut pemeriksaan, belum ada onboarding/billing; gagal lalu klik retry tidak mengulang kredensial. Google dari Register juga retry tanpa SDK ulang; sesi tersimpan memakai splash. | `test/google_redirect_regression_test.dart`, `test/google_login_progress_test.dart` |
| TEST-POS-SUBLOGIN-DECISION-1711 | covered scoped; unit, integration; rule protection | Active/read-only/billing-only/blocked dibedakan dari unknown; unknown gagal tertutup, expired baru menampilkan billing setelah respons, panel netral bisa retry hingga status billing terkonfirmasi. | `test/pos_subscription_test.dart` |
| TEST-POS-SUBLOGIN-GUARDS-1711 | covered scoped; unit, integration; specialized protection | Hung20detik → retry; logout menang atas respons terlambat; submit ganda tidak memulai login ulang; cache offline valid tetap digunakan dan deadline/tenant/operator/trusted-clock tetap diuji; PIN, CAPTCHA, struk dan akses pulih tidak diregresikan. | `test/auth_subscription_preparation_test.dart`, suite auth/subscription/PIN terkait di bawah |
| TEST-POS-SUBLOGIN-NATIVE-1711 | unverified; E2E; critical path | Login password/Google nyata pada APK terbaru, jaringan lambat/offline, status tenant aktif/expired, Back dan pergantian akun. | Belum dijalankan pada Android untuk perubahan ini; perlu hot restart/source terbaru atau APK baru. |

Boundary pengujian: App/Navigator, Cubit, form dan service langganan nyata dalam runner Flutter; kredensial, SDK Google/HTTP, secure storage/trusted clock dan repositori eksternal menggunakan fake/fixture. Tidak ada login Google native atau API produksi yang dinyatakan PASS. Tidak ada tes dihapus; dua nama tes lama diperjelas karena fixture-nya memang tidak memiliki required subscription scope, bukan izin melewati pemeriksaan tenant nyata.

### Perintah yang dijalankan

Dari `mobile_POS_Pantoo`, memakai Flutter SDK lokal:

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/subscription-login-20261117/lcov.info test/auth_subscription_preparation_test.dart test/auth_session_loading_test.dart test/auth_workspace_session_test.dart test/google_login_test.dart test/google_redirect_regression_test.dart test/google_login_progress_test.dart test/pos_subscription_test.dart test/pos_subscription_access_refresh_test.dart test/pos_google_navigation_test.dart test/pos_login_lock_loading_test.dart test/pos_login_captcha_test.dart test/pos_auth_error_classification_test.dart test/pos_pin_setup_error_test.dart --reporter expanded
dart analyze lib/app.dart lib/injections.dart lib/core/subscription/pos_subscription_service.dart lib/presentation/bloc/auth lib/presentation/widgets/login lib/presentation/widgets/pos_subscription_boundary.dart lib/presentation/pages/login/register_page.dart test/auth_subscription_preparation_test.dart test/google_redirect_regression_test.dart test/google_login_progress_test.dart test/pos_subscription_test.dart
```

Lint awal menemukan3 kebutuhan kurung kurawal, sudah diperbaiki dan rerun bersih. Dua assertion UI awal memerlukan pump frame tambahan, dan tes expired memakai bounded pump karena onboarding sengaja ditahan oleh fixture; assertion keamanan/perilaku tidak dilemahkan.

## Tinjauan hasil

Accuracy5/5: klaim dibatasi hasil71tes, analyze dan coverage terukur. Completeness4/5: jalur form, Google, daftar, restore dan offline diuji otomatis, tetapi Android native terbaru belum diuji. Clarity4/5: keputusan akses dirinci; laporan teknis ini lebih panjang daripada ringkasan pengguna. Actionability4/5: source siap diuji dengan hot restart, belum ada paket rilis baru. Conciseness4/5: ringkasan pengguna singkat; rincian bukti disimpan di sini. Rata-rata4,2/5; tidak ada isu kritis dari pemeriksaan ini.

Peningkatan berikut: jalankan acceptance native pada aplikasi terbaru untuk tenant aktif/expired dan jaringan terputus. Pengguna dapat menyetujui hasil source ini tanpa menganggapnya sebagai klaim APK produksi sudah diperbarui.
