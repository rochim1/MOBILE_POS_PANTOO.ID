# Bahasa pada setup profil usaha — 18 November 2026

## Permintaan dan penyebab

Pemilih bahasa sebelumnya tersedia di login/daftar, tetapi belum dipasang pada pembuatan profil usaha dan konfigurasi awal POS. Komponen yang berada di dalam formulir scroll juga tidak menjamin akses tetap terlihat.

Journeys: pengguna dapat mengganti bahasa selama setup, tetap dapat menjangkaunya sesudah scroll/keyboard/loading/error, dan tidak kehilangan isian atau sesi.

## Implementasi

- `PosSetupScaffold` menjadi kerangka bersama untuk `BusinessSetupPage`, `PosOnboardingPage`, dan layar loading `PosOnboardingGate`.
- `PosSetupLanguageBar` menampilkan `LanguagePicker` yang sudah ada pada header tetap, di luar scroll/form/loading. Tidak menduplikasi penyimpanan atau logika bahasa.
- Header memakai SafeArea, permukaan terpisah dengan kontras jelas, dan area sentuh minimal 48 piksel logis.
- Pilihan tetap Bahasa Indonesia, English, atau mengikuti perangkat. Perubahan menggunakan `AppLanguageController` dan penyimpanan preferensi yang sama dengan login/daftar/pengaturan.
- Pilihan nama usaha, telepon, profil, logo, PIN, konfigurasi, dan navigasi tidak diubah. Perubahan bahasa tidak mengirim ulang pembuatan usaha.
- Ruang lingkup “selalu tampil” adalah layar setup: formulir profil, persiapan/gate, konfigurasi awal, penyimpanan, dan pesan gagal. Ini bukan overlay bahasa baru pada seluruh dashboard atau di atas semua dialog sistem.

## Verifikasi aktual

| Jaminan | Bukti | Hasil |
|---|---|---|
| Header tetap bisa diketuk sesudah scroll dan keyboard | Widget test 320×568 skala 1,5; 390×844 skala 1; 844×390 skala 1,3 | PASS |
| Bahasa berubah langsung tanpa kehilangan nama, telepon atau profil | Mengisi form dan memilih Jasa, berganti EN lalu ID; nilai controller/form diperiksa | PASS |
| Token dan shift tidak berubah akibat pergantian bahasa | Preferensi sesi/shift diperiksa setelah memilih bahasa | PASS |
| Bahasa tetap bisa dipilih saat membuat usaha dan sesudah kegagalan | Transport pembuatan usaha ditahan dengan Completer, lalu mengembalikan kegagalan; hanya satu permintaan | PASS |
| Gate dan konfigurasi tetap memiliki header saat loading/error | Widget kedua layar diuji dalam keadaan menunggu dan gagal memuat | PASS |
| Logo, pemilihan profil, setup dan lokalisasi tidak regresi | 9 target regresi, **67 PASS**, exit 0 | PASS |
| Analisis 4 file berubah | **No issues found**, exit 0 | PASS |

### Perintah

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/setup-language-lcov.info test/pos_setup_language_test.dart test/business_setup_page_test.dart test/pos_onboarding_profile_test.dart test/pos_business_logo_flow_test.dart test/pos_setup_readiness_test.dart test/registration_flow_contract_test.dart test/setup_operational_labels_test.dart test/pos_localization_test.dart test/pos_translation_rescan_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/widgets/pos_setup_scaffold.dart lib/presentation/pages/login/business_setup_page.dart lib/presentation/pages/pos/pos_onboarding_page.dart test/pos_setup_language_test.dart
```

### TDD dan coverage

- RED `31ec8ec`: 7 skenario UI gagal karena tidak ada `LanguagePicker` pada layar setup.
- GREEN `04a17d4`: komponen bersama ditambahkan; 7 skenario UI PASS. Setelah formatting, seluruh 67 tes regresi PASS.
- Coverage LCOV: komponen baru **17/17 (100%)**, halaman profil usaha **120/129 (93,0%)**, onboarding/gate **232/269 (86,2%)**. Gabungan ketiga file **369/415 (88,9%)**; bukan persentase seluruh aplikasi.
- Kesalahan penyiapan animasi popup di tes diperbaiki dengan menunggu frame awal dan transisinya, bukan menyembunyikan peringatan tap.

## Batas dan evaluasi

Ini pengujian widget/komponen dan repository palsu, bukan uji GUI pada APK perangkat. Tidak ada build APK/AAB, perubahan backend/database, atau reset akun tambahan dalam pekerjaan ini. Login/daftar tetap memakai pemilih bahasa yang sudah ada; kerangka baru dapat dipakai ulang oleh halaman setup berikutnya.

Evaluasi: akurasi 5/5 (output 67 PASS dan analyze bersih); kelengkapan 4/5 (belum diverifikasi lewat APK); kejelasan 5/5 (ruang lingkup header dan batas pengujian eksplisit); kesiapan ditindaklanjuti 4/5 (kode/tes tersedia, pemasangan perangkat belum dilakukan); keringkasan 4/5 (rincian pengujian sengaja dipisahkan dari ringkasan pengguna). Rata-rata 4,4/5; tidak ada aspek ≤2. Peningkatan berikutnya adalah pengecekan visual header pada Android saat keyboard nyata terbuka. Pengguna dapat menerima hasil ini dengan batas pengujian tersebut dijelaskan, tanpa klaim telah diuji pada perangkat.

## Perbaikan lanjutan: scroll dari latar hijau

Keluhan berikutnya: scroll hanya bekerja dari card, bukan latar hijau di sekitarnya. Reproduksi menemukan `Center` di luar scrollable membuat viewport mengikuti lebar card pada tablet/layar lebar.

`PosSetupScrollBody` kini mengisi viewport sebelum membatasi lebar card menjadi 480. Area hijau di kiri/kanan card ikut menerima drag dan mouse wheel. Card pendek tetap di tengah tanpa scroll yang tidak perlu; card panjang tetap dapat digulir. Komponen dipakai pada pembuatan usaha dan konfigurasi profil POS. Header bahasa tetap terpisah dan tidak ikut bergulir.

| Skenario | Hasil |
|---|---|
| Drag dari latar hijau kiri dan kanan pada 390×600, 1024×600, 1440×600 | PASS |
| Mouse wheel pada latar hijau layar lebar | PASS |
| Scroll dengan keyboard terbuka, tanpa kehilangan isian | PASS |
| Konten pendek tetap di tengah dan tidak memiliki scroll berlebih | PASS |
| Regresi scroll, bahasa, setup, logo, profil dan lokalisasi | **73 PASS**, exit 0 |
| Analisis 4 file yang berubah | **No issues found**, exit 0 |

RED `5b52475`: 2 PASS/3 FAIL pada 5 tes reproduksi (drag tablet/desktop dan wheel gagal). GREEN `481fcaa`: 5 tes tersebut PASS. Setelah penambahan tes konten pendek dan formatting, seluruh 73 tes regresi PASS. Coverage `pos_setup_scaffold.dart`, termasuk komponen scroll baru: **28/28 baris executable (100%)** dalam `output/setup-scroll-lcov.info`.

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/setup-scroll-lcov.info test/pos_setup_scroll_test.dart test/pos_setup_language_test.dart test/business_setup_page_test.dart test/pos_onboarding_profile_test.dart test/pos_business_logo_flow_test.dart test/pos_setup_readiness_test.dart test/registration_flow_contract_test.dart test/setup_operational_labels_test.dart test/pos_localization_test.dart test/pos_translation_rescan_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/widgets/pos_setup_scaffold.dart lib/presentation/pages/login/business_setup_page.dart lib/presentation/pages/pos/pos_onboarding_page.dart test/pos_setup_scroll_test.dart
```

Tetap berupa tes widget/gesture, bukan uji GUI perangkat atau build APK baru. Evaluasi lanjutan 4,4/5: akurasi 5 (73 PASS dan analyze terverifikasi), kelengkapan 4 (belum diuji pada APK), kejelasan 5 (penyebab dan batas viewport eksplisit), kesiapan 4 (kode selesai, pemasangan perangkat terpisah), keringkasan 4 (detail disimpan di catatan ini). Tidak ada aspek kritis ≤2; tindak lanjut opsional adalah verifikasi gesture pada perangkat Android nyata. Hasil layak diserahkan dengan batas pengujian tersebut dinyatakan.
