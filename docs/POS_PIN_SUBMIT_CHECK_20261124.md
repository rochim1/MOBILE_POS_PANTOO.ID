# Masuk kasir melalui centang di sebelah nol — 24 November 2026

## Permintaan dan hasil

Pengguna meminta tombol “Sign In as Cashier” diganti tombol centang di samping0. Baris terakhir keypad kini hapus–0–centang. Tombol masuk lebar tidak ditampilkan lagi untuk operator yang sudah punya PIN. Akun login tanpa PIN tetap menampilkan tombol pembuatan PIN, bukan centang yang tidak bisa digunakan.

TEST-POS-PIN-SUBMIT-CHECK-2411: tombol centang di kanan0 pada baris yang sama, target sentuh≥48dp, tooltip Indonesia/Inggris, nonaktif sebelum4digit/selama proses/lockout, spinner selama verifikasi dan satu permintaan untuk klik ganda. Enter serta otomatis verifikasi6digit tetap memakai alur sebelumnya. Key panduan dipertahankan satu kali saja pada cabang centang atau pembuatan PIN.

Perubahan hanya presentasi `pin_lock_screen.dart`; tidak mengubah verifikasi, hak akses, sesi, cache PIN atau endpoint server.

## Bukti pengujian

- `2ee10ec` RED: suite baru terkompilasi;8kasus posisi/icon gagal karena tombol masih lebar,3kasus perilaku lama PASS.
- `acb8046` GREEN: tombol centang/posisi hapus diperbarui;51tes pada tiga suite PASS.
- Run akhir menambahkan perpindahan create-PIN↔keypad untuk membuktikan key panduan tidak ganda.12kasus baru ditambah regresi lebar/resize, PIN, keyboard, carousel, password dan subscription menghasilkan71PASS, tanpa skip/cancel; exit0,45detik.

Perintah dari `mobile_POS_Pantoo`:

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/pin-submit-check-20261124/lcov.info test/pin_submit_keypad_test.dart test/pin_viewport_width_test.dart test/pin_lock_responsive_test.dart test/pin_carousel_autoplay_test.dart test/pos_pin_setup_error_test.dart test/pos_subscription_pin_banner_test.dart
flutter analyze --no-pub lib/presentation/pages/common/pin_lock_screen.dart test/pin_submit_keypad_test.dart
```

Analyze: No issues found!, exit0,7.1detik. Halaman PIN467/552baris tercakup (84.6%). Delapan kasus geometri baru memakai lebar200/320/390/768dp × ID/EN; regresi lebar tetap mencakup textscale1.5, constraint lokal dan resize. Tes pending verifikasi membuktikan spinner, tombol angka/hapus/submit nonaktif dan Enter tidak mengirim permintaan tambahan. Gagal verifikasi mengosongkan PIN dan menonaktifkan centang kembali. Akun tanpa PIN masih bisa membuka dialog pembuatan PIN.

Ini unit/integration widget nyata dengan fixture `AppLockCubit`/repository lokal, bukan autentikasi backend atau GUI Android. Tidak ada data produksi, build APK/AAB atau deploy. Pratinjau widget dengan font aplikasi diperiksa pada `output/pin-readability-20261124/en-top.png`; baris hapus–0–centang tampak, tanpa tombol masuk lebar. Pratinjau tersebut diperbarui oleh suite responsive yang sudah ada.

## Evaluasi dan batas

Akurasi5/5: posisi, disabled state dan satu verifikasi dibuktikan. Kelengkapan4/5: GUI native pada APK terbaru belum diulang. Kejelasan5/5: satu tindakan utama dengan tooltip dan bentuk centang. Keterlaksanaan4/5: perlu hot restart pada sesi pengembangan atau build baru untuk APK. Keringkasan5/5: satu berkas produksi berubah, tanpa alur autentikasi baru. Rata-rata4.6/5; tidak ada isu kritis pada suite terkait. Self-check: sesuai permintaan dan batas pengujian dinyatakan. Prioritas berikutnya hanya pemeriksaan native pada build baru; bukan klaim seluruh POS siap produksi.
