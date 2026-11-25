# Konfirmasi keluar aplikasi Android — 26 November 2026

## Perubahan

Permintaan pengguna: ketika ingin keluar dari aplikasi, tampilkan konfirmasi. Melengkapi `POS_BACK_NAVIGATION_FIX_20261126.md`: bukan kembali menutup aplikasi secara otomatis.

- Back di halaman selain root tetap mengikuti riwayat, atau menutup dialog/detail teratas.
- Pada halaman utama Kasir/Lainnya yang diizinkan, setelah riwayat habis dan keyboard/panduan tertutup, Back membuka dialog **Keluar dari aplikasi?**.
- **Batal** atau Back dari dialog hanya menutup dialog. Ketuk latar tidak menyetujui keluar.
- **Keluar aplikasi** menutup activity Android melalui SystemNavigator.pop. Tidak logout, tidak menutup shift, tidak menghapus transaksi/antrean/bukti pemulihan.
- Dialog memberi peringatan bahwa perubahan belum disimpan bisa hilang. Tidak menjanjikan pemulihan keranjang/form yang belum disimpan.
- Pencegah dialog ganda dan pemilihan berulang disertakan. PIN, busy payment/recovery, riwayat dan halaman saat ini diperiksa ulang setelah konfirmasi; jika berubah, penutupan dibatalkan.
- Android saja: tidak menutup tab web atau memaksa aplikasi iOS keluar.
- Galat platform ditampilkan sebagai pesan yang bisa ditindaklanjuti; guard dibuka kembali untuk percobaan berikutnya.

## Bahasa

Empat key (`exitAppTitle`, `exitAppMessage`, `exitAppConfirm`, `exitAppFailed`) ditambahkan hanya ke sumber `app_id.arb` dan target `app_en.arb`, mengikuti struktur proyek. `flutter gen-l10n` memperbarui tiga berkas generated. Label Batal memakai terjemahan yang sudah ada. Kedua JSON ARB diparse dan keempat key diverifikasi pada kedua bahasa; dialog ID/EN diuji. Tidak mengubah terjemahan lain atau menambahkan mesin lokalisasi.

## Bukti TDD dan validasi

Journey berasal dari permintaan pengguna, tanpa rencana eksternal.

- RED `7396293`: helper belum tersedia (compile-time RED) dan shell asli gagal assertion dialog yang belum tampil (runtime RED). Log `app-exit-red-20261126.log`.
- GREEN awal `8e13aa4`: empat widget tests lulus: dialog ID/EN, tidak exit pada iOS, shell root nyata.
- Final **65 PASS** pada 11 suite, **17 detik**, exit 0. Mencakup konfirmasi/cancel/system-back/latar, dialog ganda, perubahan guard selama dialog, native exit gagal, menu/permission/PIN, recovery/cart lock, halaman sukses, Google navigation dan first-sale.
- Pengujian shell asli membuktikan SystemNavigator.pop tidak dipanggil saat batal dan tepat satu kali setelah konfirmasi; kanal platform ditiru sehingga tidak benar-benar menutup host tes.
- Analisis tujuh berkas: **No issues found**, exit 0.
- Changed executable terhadap `7396293`: **44/45 = 97,78%**, termasuk generated. Satu getter pesan gagal English belum dieksekusi (jalur galat diuji dalam ID). Bukan cakupan seluruh aplikasi.

Perintah dari root mobile:

```powershell
flutter gen-l10n
flutter test --no-pub --coverage --coverage-path=output/operational-readiness-20261125/app-exit-lcov-final-20261126.info test/pos_app_exit_confirmation_test.dart test/pos_back_navigation_test.dart test/pos_shell_back_navigation_test.dart test/pos_mobile_navigation_policy_test.dart test/pos_keyboard_navigation_test.dart test/pos_more_menu_visibility_test.dart test/pos_checkout_recovery_flow_test.dart test/pos_checkout_cart_lock_test.dart test/pos_success_print_nonblocking_test.dart test/pos_google_navigation_test.dart test/pos_first_sale_flow_test.dart --reporter expanded
dart analyze --fatal-infos lib/presentation/pages/pos/pos_shell_page.dart lib/presentation/pages/pos/widgets/pos_app_exit_confirmation.dart test/pos_app_exit_confirmation_test.dart test/pos_shell_back_navigation_test.dart lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_id.dart lib/l10n/generated/app_localizations_en.dart
```

Log final: `output/operational-readiness-20261125/app-exit-final-20261126.log`, `app-exit-analyze-final-20261126.log`, dan `app-exit-lcov-final-20261126.info`.

## Batas dan evaluasi

Belum build APK/AAB, deploy atau pengujian pada perangkat/emulator. Root login/PIN di luar navigasi shell tidak diubah. Tidak menulis database atau mengubah Vue/server. Satu import shell dari pekerjaan sebelumnya tetap dibiarkan unstaged.

Evaluasi 4,0/5: akurasi 4 (65 tes/analyzer bersih, platform ditiru), kelengkapan 4 (alur root/batal/konfirmasi/guard/bahasa/galat tercakup, native-device belum), kejelasan 4 (keluar app dibedakan dari logout dan tutup shift), keterpakaian 4 (siap build berikutnya, belum paket), keringkasan 4 (rincian bukti dipisah dari jawaban). Tindak lanjut: uji Back dan konfirmasi pada HP setelah build baru. Pengguna dapat menilai tanpa menganggap APK terpasang telah berubah.
