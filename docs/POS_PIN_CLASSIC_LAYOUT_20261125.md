# Panel PIN kembali lega — 25 November 2026

> Permintaan lanjutan pada hari yang sama mengecilkan tombol agar HP normal tidak perlu scroll, dengan footer tetap vertikal. Lihat [hasil terkini](POS_PIN_SMALLER_KEYS_20261125.md). Bukti di bawah merekam tahap restorasi sebelum penyesuaian ukuran tersebut.

## Permintaan dan batas perubahan

Permintaan: “tolong rapikan pin seperti di awal”. Interpretasi yang disampaikan kepada pengguna: kembalikan susunan sebelum pemadatan terakhir, bukan membatalkan seluruh perbaikan PIN sebelumnya.

`pin_lock_screen.dart` kembali sama dengan versi `acb8046`: angka 32sp, tinggi keypad 64dp pada HP/80dp pada tablet, jarak lebih lega, serta aksi layar pelanggan dan logout vertikal dengan label lengkap. Tombol centang di sebelah 0, input keyboard, batas lebar viewport, fallback scroll, loader, validasi PIN, lockout dan perlindungan akses tetap dipertahankan. Tidak ada perubahan backend atau data akun.

## Kriteria dan bukti

TEST-POS-PIN-CLASSIC-LAYOUT-2511 — covered scoped; unit/integration; purpose critical path/regression protection. Delapan kombinasi viewport 320×568, 360×640, 390×844, 768×800 × Indonesia/Inggris melindungi angka 32sp, tombol minimal 64dp tinggi/48dp lebar, footer vertikal dan dapat dijangkau tanpa overflow. Dua kasus layar pendek dengan skala teks 1/1.5 dan satu kasus akun tanpa PIN melengkapi 11 kasus tata letak.

`pin_compact_height_test.dart` dipindahkan menjadi `pin_classic_layout_test.dart`; seluruh 11 kasus dipertahankan. Kriteria lama “tanpa scroll pada HP kecil” diganti sesuai preferensi terbaru pengguna untuk susunan lega. Scroll vertikal diperbolehkan jika tinggi layar tidak cukup; tidak mengecilkan keseluruhan panel dengan FittedBox. Tidak ada tes dilewati atau dihapus.

- RED `a128def`: 7 PASS/4 FAIL; empat layout HP kecil masih menghasilkan angka 28sp, bukan 32sp.
- GREEN: tujuh suite, **82 PASS**, exit 0, 58 detik pada run akhir.
- Analyze dua berkas: **No issues found**, exit 0.
- Cakupan halaman PIN: **467/552 baris (84,6%)**.
- `git diff acb8046 --exit-code -- lib/presentation/pages/common/pin_lock_screen.dart`: exit 0, restorasi presentasi sesuai versi acuan.

Perintah dari direktori aplikasi:

```text
flutter test --no-pub --concurrency=1 --dart-define=PIN_CLASSIC_PHASE=restored --coverage --coverage-path=output/pin-classic-layout-20261125/lcov.info test/pin_classic_layout_test.dart test/pin_submit_keypad_test.dart test/pin_viewport_width_test.dart test/pin_lock_responsive_test.dart test/pin_carousel_autoplay_test.dart test/pos_pin_setup_error_test.dart test/pos_subscription_pin_banner_test.dart
flutter analyze --no-pub lib/presentation/pages/common/pin_lock_screen.dart test/pin_classic_layout_test.dart
```

Log dan preview widget dengan font aplikasi: `output/pin-classic-layout-20261125/verification.log`, `analyze.log`, `id-restored.png`, `en-restored.png`, `lcov.info`. Pengujian mencakup centang, keyboard, resize, carousel, error pembuatan PIN dan batas subscription menggunakan fixture aplikasi. Ini bukan klaim E2E autentikasi server atau GUI Android fisik. Tidak melakukan build APK/AAB, pemasangan atau deployment; gunakan hot restart `R` pada sesi pengembangan untuk melihat susunan terbaru.

## Evaluasi hasil

Akurasi 5/5 (tes dan hasil restorasi terverifikasi), kelengkapan 4/5 (native GUI belum diuji ulang), kejelasan 5/5, kemudahan tindak lanjut 4/5 (perlu hot restart/build untuk perangkat), keringkasan 5/5; total 4,6/5. Tidak ada masalah kritis pada lingkup perubahan. Hasil siap ditinjau, bukan klaim seluruh aplikasi siap produksi.
