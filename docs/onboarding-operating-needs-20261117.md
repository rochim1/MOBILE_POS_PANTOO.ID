# Setup POS tanpa langkah Operating Needs

Tanggal: 17 November 2026. Permintaan: ringkas onboarding mobile dengan tidak menampilkan kebutuhan operasional.

## Hasil

- Wizard dipersingkat dari empat menjadi tiga halaman: Profil Usaha → Default Transaksi → Validasi Inventory.
- Langkah kebutuhan operasional dan kontrol switch-nya dihapus dari wizard, bukan sekadar disembunyikan dari tombol lanjut. Swipe juga tidak dapat membukanya.
- Fitur mengikuti preset katalog ketika profil dipilih. Pengaturan tersimpan tetap dipertahankan saat profil tidak diganti; Custom mempertahankan konfigurasi sebelumnya.
- Tracking stok wajib untuk inventory centralized, advanced, dan custom dengan kebijakan terkait tetap diaktifkan sebelum validasi/simpan. Inventory simple tidak dipaksa.
- Pemeriksaan kesehatan inventory, izin kelola, pajak, dan kontrak penyimpanan tetap berlaku.
- Kustomisasi tetap tersedia di Pengaturan POS → Transaksi & Penjualan → Fitur operasional. Tidak ada pengubahan kode halaman pengaturan pada tugas ini.
- Label langkah, indikator, tombol akhir dan terjemahan Indonesia/Inggris disesuaikan. Logo usaha tetap tersedia.
- Tidak mengubah backend, data produksi, versi aplikasi, atau pubspec.yaml milik pengguna. Tidak build APK.

## Bukti TDD

Journeys diturunkan dari permintaan pengguna, tanpa dokumen plan terpisah.

1. RED `e45bd91`: test wizard tiga langkah dieksekusi pada implementasi empat langkah; 1 PASS, 14 FAIL. Kegagalan meliputi adanya Kebutuhan operasional dan tidak ditemukannya tombol Simpan setelah dua kali Lanjut.
2. Perbaikan minimal menghapus slide, menyelaraskan indeks/jumlah langkah, dan menormalkan tracking wajib ketika konfigurasi dimuat.
3. RED bahasa `c59a657`: test widget locale Inggris gagal karena `Step 1 of 3 · Business Profile` belum diterjemahkan. Fixture Custom juga diperbaiki menggunakan label yang memang terlihat (`Kustom`).
4. GREEN `40e8669`: 46 tes PASS, termasuk semua reproducer, setelah implementasi dan sinkronisasi sumber/hasil terjemahan.

## Pengujian yang dijalankan

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/operating-needs-20261117-lcov.info test/pos_onboarding_profile_test.dart test/pos_setup_readiness_test.dart test/business_setup_page_test.dart test/pos_business_logo_flow_test.dart test/setup_operational_labels_test.dart test/pos_localization_test.dart test/pos_translation_rescan_test.dart --reporter expanded
```

Hasil: `01:17 +46: All tests passed!`, exit 0.

| Jaminan | Target | Hasil |
|---|---|---|
| Tiga langkah dan payload preset untuk retail, restoran, laundry, bengkel, salon, jasa, custom | pos_onboarding_profile_test.dart | PASS |
| Profil baru dari backend tetap dapat dipilih/disimpan tanpa mengubah katalog bawaan | pos_onboarding_profile_test.dart | PASS |
| Fitur tersimpan, pajak dan auto-print tidak hilang; metadata GraphQL tidak dikirim sebagai fitur | pos_onboarding_profile_test.dart | PASS |
| Tracking wajib aman pada centralized/advanced/custom; simple tetap opsional | pos_onboarding_profile_test.dart | PASS |
| Ketiga judul langkah, petunjuk pengaturan dan tombol akhir diterjemahkan dalam locale Inggris | pos_onboarding_profile_test.dart | PASS |
| Prasyarat operasional dan migrasi flag setup tetap berlaku | pos_setup_readiness_test.dart | PASS |
| Label setup, pemilihan/penggantian/penghapusan logo dan pemulihan gagal upload tidak regresi | business_setup_page_test.dart, pos_business_logo_flow_test.dart, setup_operational_labels_test.dart | PASS |
| Pergantian bahasa, validator dan terjemahan label bersama tetap berlaku | pos_localization_test.dart, pos_translation_rescan_test.dart | PASS |

Pemeriksaan kode:

```powershell
flutter analyze --no-pub lib/presentation/pages/pos/pos_onboarding_page.dart lib/l10n/pos_translation_lookup.dart lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_id.dart lib/l10n/generated/app_localizations_en.dart test/pos_onboarding_profile_test.dart
git diff --check
```

Hasil analyze: `No issues found!`, exit 0. Pemeriksaan whitespace juga bersih.

Coverage LCOV: onboarding page 375/460 executable lines (81,5%); executable lines yang ditambahkan pada halaman itu 6/6 (100%). Angka bukan coverage seluruh aplikasi. Test penyimpanan wizard menangkap payload lewat fake repository dan respons gagal yang disengaja; bukan bukti transaksi database produksi atau E2E Android native. Tidak dilakukan deploy, build, maupun uji emulator pada tugas ini.

## Evaluasi hasil

Accuracy 4/5: bukti widget/payload dan analyze tersedia; belum bukti native Android. Completeness 4/5: permintaan dan profil terjangkau, tetapi navigasi Pengaturan yang tidak berubah diverifikasi dari sumber, bukan skenario baru mengedit switch. Clarity 4/5: jalur pengaturan dijelaskan; nama mengikuti bahasa aplikasi. Actionability 4/5: kode siap dipakai setelah aplikasi dimuat ulang/dibuild, APK belum dibuat. Conciseness 4/5: perubahan logic kecil, hasil terjemahan ikut berubah karena generator. Rata-rata 4,0/5; tidak ada isu kritis. Tindak lanjut bernilai tertinggi: smoke test onboarding tiga langkah di perangkat setelah build berikutnya. Hasil layak diserahkan dengan batasan tersebut, tanpa klaim semua flow produksi telah diuji.
