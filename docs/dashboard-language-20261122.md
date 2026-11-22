# Pilihan bahasa dari dashboard — 22 November 2026

## Hasil dan cara mengakses

- Mobile: dari dashboard buka **Lainnya → Pengaturan → Bahasa**. Ini baris pilihan langsung di kelompok Pengaturan, bukan harus masuk ke konfigurasi toko terlebih dahulu.
- Di halaman **Pengaturan POS**, pilihan Bahasa kini tampil paling atas, sebelum kategori, termasuk ketika data pengaturan sedang dimuat atau gagal karena koneksi.
- Pilihan: **Bahasa Indonesia**, **English**, atau **Ikuti perangkat**. Seluruh baris dapat diketuk; bahasa aktif ditampilkan dengan nama lengkap. Pilihan langsung disimpan pada perangkat, tidak membutuhkan tombol Simpan pengaturan toko.
- Web sudah menyediakan pilihan lewat **menu akun di navbar → Preferensi tampilan → Bahasa** (`front_end_template/src/components/navbar.vue` / `LanguageSwitcher.vue`). Tidak ada perubahan Vue/backend dalam tugas ini.

Sebelumnya bahasa mobile tersembunyi di Kasir & Keamanan. Barisnya juga berada dalam `IgnorePointer` untuk pengguna tanpa `manage_settings`, sehingga preferensi perangkat ikut terkunci bersama konfigurasi toko.

## Perubahan dan batas akses

Komponen `LanguagePicker` yang sudah ada dipakai ulang dengan tampilan baris pengaturan. Mode ringkas di login/setup tetap dipertahankan. Pengaturan bahasa dipindahkan keluar dari pemuatan API dan pembatasan edit konfigurasi operasional.

Kelompok Pengaturan pada Lainnya tetap menampilkan Bahasa untuk kasir tanpa izin admin; tujuan Pengaturan POS/Struk tetap mengikuti permission masing-masing. Tidak menambah izin server, melewati PIN, mengganti tenant, menyimpan konfigurasi toko, atau mengubah transaksi. Preferensi menggunakan kunci penyimpanan lama `pos_app_locale`.

## Verifikasi

| Jaminan | Hasil |
| --- | --- |
| Kasir tanpa `view_settings`/`manage_settings` dapat mengganti ID ↔ EN dari Lainnya tanpa navigasi/logout | PASS |
| Bahasa tersedia saat API pengaturan masih loading dan setelah pesan kegagalan koneksi ditutup | PASS |
| Mode lihat saja tetap dapat mengganti bahasa tanpa menyimpan konfigurasi toko | PASS |
| Baris terlihat pada 320×568, 844×390, dan 1024×768 | PASS |
| Token, shift, keranjang, dan isian pengaturan yang belum disimpan tetap terjaga | PASS |
| Pilihan tersimpan dan dapat dimuat controller baru; mengikuti perangkat menghapus override | PASS |
| Regresi menu, bahasa login/setup, pesan dinamis, dan validator | **24 tes PASS** |
| Analisis 4 file yang berubah | **No issues found** |

Perintah aktual dari folder `mobile_POS_Pantoo`:

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/dashboard-language-lcov.info test/pos_dashboard_language_test.dart test/pos_more_menu_visibility_test.dart test/pos_localization_test.dart test/pos_setup_language_test.dart --reporter expanded
flutter analyze --no-pub lib/l10n/language_picker.dart lib/presentation/pages/pos/pos_settings_page.dart lib/presentation/pages/pos/pos_more_menu_page.dart test/pos_dashboard_language_test.dart
```

RED `944afc5`: lima tes berhasil dijalankan dan gagal karena pemilih bahasa tidak ada di lokasi yang diminta. GREEN `fa3cbba`: lima tes tersebut lolos. Regresi tambahan menjaga draf pengaturan tanpa memicu submit; hasil akhir 24 PASS. Penyesuaian tes menutup toast koneksi sementara sebelum mengetuk header dan memilih field berdasarkan label agar label/hint tidak dihitung ganda; peringatan hit-test tidak disembunyikan.

Cakupan `language_picker.dart`: **24/27 baris (88,9%)**, bukan cakupan seluruh aplikasi. Bukti lokal: [RED](../output/dashboard-language-red.log), [GREEN](../output/dashboard-language-green.log), [regresi](../output/dashboard-language-regression.log), [analisis](../output/dashboard-language-analyze.log).

Tidak ada build APK/AAB, pemasangan Android, atau uji GUI perangkat untuk perubahan bahasa ini. Hasil di atas merupakan tes widget/interaksi dan pemeriksaan kode; APK yang sudah terpasang sebelumnya belum berisi perubahan ini.

## Evaluasi

Akurasi 5/5 (24 PASS dan analyze terverifikasi); kelengkapan 4/5 (belum verifikasi APK); kejelasan 5/5 (lokasi menu dan izin dijelaskan); dapat ditindaklanjuti 4/5 (kode siap, APK perlu diperbarui untuk perangkat); keringkasan 5/5 (bukti dipisahkan dari jawaban). Rata-rata 4,6/5. Tindak lanjut: cek visual pada Android setelah build berikutnya. Pengguna mendapat langkah menu yang jelas dengan batas pemasangan tersebut, tanpa klaim perangkat sudah diperbarui.
