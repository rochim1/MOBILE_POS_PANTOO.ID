# Perbaikan tombol kasir dan navigasi bawah — 24 November 2026

## Sumber dan kriteria

Permintaan pengguna disertai dua screenshot: ikon tengah terlalu besar dan area abu-abu menutupi konten/tulisan menu. Perbaikan harus menjaga tombol kasir kecil tetapi tetap mudah ditekan; tidak ada bagian tombol atau parent-nya yang melayang di atas baris terakhir/tombol pembayaran; laporan, katalog, transaksi dan lainnya tetap dapat digunakan. Guard PIN, hak akses, keyboard dan perpindahan kasir tidak boleh dilewati.

## Perubahan

- Tombol menjadi `FloatingActionButton.small`: ikon20, visual40 dan target sentuh padded48 pada HP maupun tablet. Sebelumnya HP memakai tombol56/ikon28.
- `PosMobileBottomBar` menempatkan tombol di slot tengah56 di dalam bar60, bukan `centerDocked` di atas isi halaman. Background putih, elevation0, tint/shadow transparan dan tanpa notch.
- Shell tidak lagi menambahkan `PosCashierDockBody`/ruang kosong abu-abu32 di atas navigasi. Wrapper lama tidak dihapus agar tes kompatibilitas tetap tersedia, tetapi bukan lagi jalur shell aktif.
- Callback kasir tetap melalui `_openCashierWorkspace`; izin `use_cashier` dan sembunyikan tombol saat keyboard terbuka tetap dijaga. Navigasi empat menu, PIN dan shift tidak diubah.
- Perubahan pengguna lain pada header/profil/loader tetap dipertahankan dan tidak dimasukkan ke checkpoint perbaikan ini.

## Bukti dan test point

| TEST-ID | Level / tujuan | Bukti | Status |
|---|---|---|---|
| TEST-POS-BOTTOM-COMPACT-2411 | unit / regression protection | `test/pos_cashier_entry_size_test.dart`,320/360/768, ikon20, ukuran≤48 dan callback sekali | covered scoped |
| TEST-POS-BOTTOM-INLINE-2411 | integration / critical path, regression protection | `test/pos_mobile_bottom_bar_layout_test.dart`, ukuran320/360/768, skala teks1,5 dan safe area24; tombol hadir/tidak hadir, seluruh aksi dalam bar, baris/tombol Bayar tidak tertutup, menu bisa ditekan; wiring shell nyata dicek | covered scoped |

Boundary: widget/render/gesture Flutter asli, bukan screenshot mockup; scaffold tes menggunakan aksi pengganti dan tidak memanggil server. Bukan E2E Android/perangkat fisik atau regresi bisnis seluruh aplikasi.

RED: dua ukuran HP gagal pada batas tombol≤48; komponen inline belum ada sehingga target tes baru gagal compile sesuai fitur yang belum diterapkan. Checkpoint `b77503a`. GREEN:16tes terkait awal PASS; checkpoint minimal `17fcd23`. Regresi final **25/25PASS**,27detik, exit0. Pemeriksaan enam berkas terkait: **No issues found**,179,9detik, exit0. Cakupan bar baru13/13 dan tombol5/5 executable lines (100% pada dua komponen ini), bukan coverage seluruh aplikasi.

Perintah dari root mobile:

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/bottom-navigation-20261124/lcov-final.info test/pos_cashier_entry_size_test.dart test/pos_mobile_bottom_bar_layout_test.dart test/pos_cashier_dock_overlap_test.dart test/pos_cashier_entry_hero_test.dart test/pos_cashier_setup_entry_test.dart test/pos_keyboard_navigation_test.dart test/pos_mobile_navigation_policy_test.dart
flutter analyze --no-pub lib/presentation/pages/pos/pos_shell_page.dart lib/presentation/pages/pos/widgets/pos_mobile_bottom_bar.dart lib/presentation/pages/pos/widgets/pos_cashier_entry_button.dart test/pos_mobile_bottom_bar_layout_test.dart test/pos_cashier_entry_size_test.dart test/pos_cashier_dock_overlap_test.dart
```

Log: `output/bottom-navigation-20261124/{red,green,regression-final,analyze}.log`; coverage `lcov-final.info`. Percobaan regresi pertama menyebut berkas back-navigation lama yang tidak ada dan gagal pada loader, bukan bug produk. Perintah final memakai suite policy yang benar dan lulus; log percobaan tetap disimpan, tidak ada tes produk dihapus/di-skip.

Tidak ada build ulang APK/AAB, pemasangan native, deploy, perubahan versi atau data akun/transaksi. **APK/AAB1.0.21+22 yang dibuat sebelum patch ini belum memuat perbaikan tersebut.** Verifikasi visual native pada build berikutnya tetap perlu, terutama perangkat/ukuran yang ada pada screenshot pengguna.

Review: akurasi5 (hasil/log dan batas terverifikasi), kelengkapan4 (belum native pada perangkat pengguna), kejelasan5 (root cause/perubahan/bukti dipisah), kegunaan4 (perlu build berikutnya untuk pengguna APK), keringkasan4 (rincian teknis disimpan di laporan). Rata-rata4,4/5; langkah berikutnya yang relevan adalah memasang build baru saat diminta, bukan menganggap APK lama otomatis berubah.
