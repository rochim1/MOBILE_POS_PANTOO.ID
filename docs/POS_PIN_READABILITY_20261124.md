# Keterbacaan halaman PIN HP — 24 November 2026

## Permintaan dan kriteria

Screenshot pengguna menunjukkan teks sangat kecil pada halaman Cashier Access. Judul, operator, petunjuk dan tombol harus terbaca pada HP tanpa memperkecil seluruh panel; semua aksi tetap terjangkau pada layar pendek dan skala teks besar. PIN, lockout, input keyboard dan aturan akses tidak boleh dilewati.

## Penyebab dan perubahan

Panel lama420×810 dipasang dalam FittedBox. Pengukuran pada320×568 menunjukkan skala horizontal68,15%: teks13menjadi sekitar8,9pixel logis. Menambah font saja tidak menyelesaikan akar masalah.

- Hilangkan FittedBox dan tinggi tetap; viewport baru memakai scroll natural dengan lebar maksimum420 dan perataan tengah jika ruang cukup.
- Judul26, nama operator16, petunjuk/keterangan14, tombol masuk16 dan aksi sekunder14. Gaya tombol tetap mengikuti font tema aplikasi.
- Keypad32, target HP80×64; tombol utama dan aksi sekunder minimal48tinggi. Padding horizontal disesuaikan agar keypad tetap muat di320.
- Akun login yang belum punya PIN langsung melihat tombol Buat PIN, tanpa keypad yang belum dapat digunakan. Challenge password/PIN tidak diubah.
- PIN existing, validasi, lockout, keyboard, carousel, langganan/offline guard dan data akun tetap memakai jalur sebelumnya.

## Bukti dan reproduksi

TEST-POS-PIN-READABLE-2411, unit/integration, critical path/regression protection:12kombinasi320×568/360×640/768×800 ×ID/EN ×skala teks1/1,5. Assert transform render100→100 (tanpa scaling), font nama≥16, tombol submit≥48, logout terjangkau lewat scroll; satu digit tidak memverifikasi/membuka akses dan tombol masuk masih disabled. Widget PIN asli, cubit/repository fake terisolasi; bukan autentikasi server/perangkat fisik.

TEST-POS-PIN-CREATE-VISIBLE-2411, integration/regression protection:akun tanpa PIN tidak menampilkan keypad, CTA terlihat, modal create/eye-toggle/password salah tetap dapat digunakan. Ketiga regresi create-PIN yang semula gagal akibat tap di luar viewport kembali PASS setelah CTA diprioritaskan, bukan dengan melemahkan assertion.

RED6ee5e63/d36cabf:12kasus gagal; pengukuran aktual68,148/100. GREEN3bbac41:12kasus PASS. RED09d76de untuk keypad akun tanpa PIN→GREENfbde988. Refactor tema/previewf4b98f3. Final **50/50tes PASS**,28detik; analyze tiga berkas **No issues found**,4,4detik. Cakupan viewport9/9baris; halaman PIN453/539baris (84,04%) pada kelompok ini, bukan coverage seluruh aplikasi/semua branch.

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/pin-readability-20261124/lcov-final.info test/pin_lock_responsive_test.dart test/pin_carousel_autoplay_test.dart test/pos_subscription_pin_banner_test.dart test/pos_login_lock_loading_test.dart test/pos_cashier_entry_size_test.dart test/pos_mobile_bottom_bar_layout_test.dart
flutter analyze --no-pub lib/presentation/pages/common/pin_lock_screen.dart lib/presentation/pages/common/pos_pin_access_viewport.dart test/pin_lock_responsive_test.dart
```

Log: `output/pin-readability-20261124/{red-measured,no-pin-red,green,regression-final,analyze-final}.log`, `lcov-final.info`. Render widget asli dengan font Roboto dan data sintetis: [ID atas](../output/pin-readability-20261124/id-top.png), [ID bawah](../output/pin-readability-20261124/id-bottom.png), [EN atas](../output/pin-readability-20261124/en-top.png), [EN bawah](../output/pin-readability-20261124/en-bottom.png); diperiksa secara visual. Font blok pada preview percobaan awal berasal dari fallback Ahem test; preview final memakai font yang dimuat dan tema tombol dipertahankan.

Tidak ada build ulang, install, deploy atau perubahan versi/data produksi. APK/AAB yang sudah dibuat sebelumnya belum memuat perbaikan font ini maupun navigasi bawah setelah build tersebut. Native pada perangkat pengguna masih perlu dicek saat build baru diminta. Pengujian utuh seluruh POS tidak dijalankan ulang untuk perubahan tampilan terisolasi ini.

Review: akurasi5 (render/log/transform nyata), kelengkapan4 (native belum dipasang), kejelasan5, kegunaan4 (perlu build baru untuk pengguna APK), keringkasan4 (rincian disimpan di sini). Rata-rata4,4/5. Tidak ada tes dihapus/di-skip, password/PIN dicatat, guard dilonggarkan, atau perubahan pengguna lain diikutkan.
