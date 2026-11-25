# Area aman navigasi sistem HP — 25 November 2026

## Kebutuhan pengguna

Tombol POS tidak boleh berada di belakang navigasi sistem HP, termasuk perangkat tiga tombol/gestur dan navigasi sisi kanan ketika landscape. Seluruh halaman, route baru, panel PIN dan modal harus mewarisi perlindungan yang sama; area yang sudah memakai SafeArea tidak boleh mendapat jarak ganda.

## Temuan dan perbaikan

Audit sumber mencakup 34 berkas halaman pemilik Scaffold, 51 pemanggilan modal bottom sheet dalam 27 berkas, serta empat lokasi footer/navigation/FAB dalam halaman. Pemindaian meliputi `lib/presentation/pages`, widget bersama, `App`, navigator PIN/lock dan subscription, serta konfigurasi Android. Angka adalah inventaris struktur sumber, bukan jumlah layar yang diklik secara manual.

Perlindungan sebelumnya bersifat lokal: sebagian footer memakai SafeArea, sementara route dan bottom sheet lain tidak. Reproducer memakai App nyata, viewport390×844 dengan navigasi48dp: batas bawah Navigator masih844, seharusnya≤796. Karena Navigator adalah pemilik semua route/modal, perbaikan diletakkan di atasnya, bukan menambahkan padding tetap pada puluhan halaman.

`PosSystemSafeArea` baru dipasang pada builder `MaterialApp`, membungkus seluruh pohon navigasi, pembatas langganan dan inactivity/PIN overlay. Berlaku untuk jalur HP dan tablet/layar lebar. SafeArea melindungi bawah/kiri/kanan dari inset perangkat; top tetap mengikuti pengaturan AppBar/halaman lama. Latar area sistem mengikuti tema aplikasi.

SafeArea mengonsumsi padding pada MediaQuery anak sehingga SafeArea/BottomAppBar yang sudah ada tidak menambah jarak dua kali. ViewInsets keyboard tidak dihapus atau diubah; Scaffold tetap dapat menyesuaikan keyboard. Tidak mengubah kebijakan modal form yang sengaja mempertahankan tinggi saat keyboard tampil. Tidak ada perubahan handler pembayaran, stok, query, hak akses, PIN atau autentikasi.

Seluruh route dalam App—kasir, pembayaran, stok/pembelian, retur, piutang, laporan, pelanggan, pengaturan, profil, login/setup dan sebagainya—mewarisi area aman ini. Popup/dialog, modal bottom sheet tanpa SafeArea lokal dan navigator PIN/subscription juga berada di dalam batas yang dilindungi. Bukan klaim E2E setiap tombol atau semua merek HP.

## Bukti pengujian

Perjalanan uji: pengguna dapat menekan tombol bawah tanpa bersentuhan dengan navigasi sistem; membuka route/sheet/dialog tetap aman; mengganti mode navigasi tidak membuang route; keyboard dan SafeArea lokal tidak menghasilkan inset ganda; PIN tetap perlu diverifikasi.

| Jaminan | Bukti otomatis | Hasil |
|---|---|---|
| App nyata menempatkan Navigator di atas navigasi48dp | `test/widget_test.dart` | RED:844>796 → GREEN≤796 |
| Tombol halaman dan FAB aman pada inset0/16/24/48/80dp | `test/pos_system_safe_area_test.dart` | PASS |
| Route, dialog dan bottom sheet tanpa SafeArea lokal tetap aman | Berkas yang sama | PASS |
| SafeArea lama tidak menambah padding ganda; keyboard300dp tetap ditangani Scaffold | Berkas yang sama | PASS |
| Navigasi sisi kanan48dp pada844×390 | Berkas yang sama | PASS |
| Pergantian inset48→80→0 mempertahankan route aktif | Berkas yang sama | PASS |
| Navbar bawah asli dan tombol kasir tetap di atas navigasi, tanpa menutupi CTA halaman | `test/pos_mobile_bottom_bar_layout_test.dart` | PASS pada320/360/768dp dan teks1,5× |
| PIN nyata tetap terjangkau pada390×640 dan320×568 dengan navigasi48dp | `test/pin_viewport_width_test.dart` | PASS; menekan0 tidak melewati verifikasi |
| Modal keyboard stabil, pemulihan pembayaran dan filter Transaksi tidak mengalami regresi pada paket terarah | Suite pada perintah di bawah | PASS |

Boundary: widget/layout Flutter dan App nyata; sumber identitas/layanan mengikuti fake/fixture masing-masing suite. Semua uji di atas bukan interaksi perangkat fisik. Tidak ada penulisan data produksi.

RED `c01ee43`: test App nyata gagal pada geometri viewport, komponen baru belum tersedia. Log `system-safe-area-red.log`. GREEN `d29aca0`: implementasi minimal dan pengujian terkait sudah lulus. Log `system-safe-area-green.log`:13PASS. Paket regresi delapan suite `system-safe-area-regression.log`:61PASS/exit0,27detik. Paket core setelah tambahan uji PIN `system-safe-area-core-final.log`:37PASS/exit0,4detik. Angka paket bertumpang tindih, bukan penjumlahan tes unik.

Cakupan komponen baru `pos_system_safe_area.dart`:5/5baris executable(100%) dalam `system-safe-area-lcov.info`; bukan coverage keseluruhan aplikasi. Analisis enam berkas final: lihat `system-safe-area-analyze-final.log`. Semua log berada di `output/operational-readiness-20261125/`.

Perintah terarah:

```powershell
flutter test --no-pub --concurrency=2 --timeout 30s --coverage --coverage-path=output/operational-readiness-20261125/system-safe-area-lcov.info test/pos_system_safe_area_test.dart test/widget_test.dart test/pos_mobile_bottom_bar_layout_test.dart test/pos_keyboard_stable_sheet_test.dart test/pos_keyboard_stable_dialog_test.dart test/pin_viewport_width_test.dart test/pos_checkout_recovery_flow_test.dart test/pos_transaction_filter_collapse_test.dart
```

Suite lengkap `flutter test --no-pub --concurrency=2 --timeout 2m`: **1.191/1.191 PASS**, exit0,3m23s; bukti `system-safe-area-all-tests.log`. Analisis enam berkas final **No issues found**, exit0.

## Rilis dan batas

TEST-POS-SYSTEM-INSET-{APP,OVERLAY,PIN,NAV,KEYBOARD}-2511 terlindungi oleh pengujian unit/integration/widget di atas. TEST-POS-SYSTEM-INSET-DEVICE-2511 belum diverifikasi: belum ada build/pasang APK atau pengujian fisik pada merek perangkat pengguna di pekerjaan ini. Perubahan source baru tersedia setelah hot restart development atau APK rilis berikutnya. Tidak menghapus data, menghentikan aplikasi pengguna, mengubah konfigurasi navigasi HP, maupun membangun APK/AAB.

Verifikasi perangkat berikutnya: uji navigasi tiga tombol dan gestur, portrait/landscape, keyboard, tombol Bayar/Simpan di kasir, PO, retur, sheet pelanggan, pengaturan cetak dan panel PIN; pastikan tombol dapat ditekan dan tidak berada di bawah area sistem.

## Evaluasi penyerahan

Keakuratan4/5: geometri dan App nyata diuji, perangkat OEM belum diuji—tindak lanjut APK pada HP terdampak. Kelengkapan4/5: perlindungan root mencakup seluruh route dan overlay, audit bukan klik seluruh tombol—tindak lanjut pemeriksaan fisik di atas. Kejelasan4/5: bukti sumber/widget/perangkat dibedakan, screenshot fisik akan memperjelas hasil. Keterpakaian4/5: source dapat diuji dengan hot restart, APK lama masih perlu rilis berikutnya. Keringkasan4/5: satu perbaikan bersama menggantikan patch per halaman; rincian disimpan di laporan, jawaban pengguna singkat. Rata-rata4,0/5; tidak ada isu kritis/skor≤3 tersembunyi. Self-check: pengguna dapat membedakan perlindungan yang diterapkan dan verifikasi perangkat yang belum dilakukan. Peningkatan utama: validasi pada APK di HP terdampak setelah build diminta.
