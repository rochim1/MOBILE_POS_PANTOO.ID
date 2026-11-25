# Navigasi kembali POS mobile — 26 November 2026

Pembaruan berikutnya: [konfirmasi keluar aplikasi](POS_APP_EXIT_CONFIRMATION_20261126.md) menambahkan dialog pada root setelah riwayat habis. Tidak keluar otomatis; hanya pilihan Keluar aplikasi yang dikonfirmasi menutup activity Android. Jaminan riwayat/guard di bawah tetap berlaku.

## Permintaan dan penyebab

Pengguna meminta tombol kembali menuju halaman sebelumnya, bukan menutup aplikasi. Perpindahan menu POS sebelumnya hanya mengganti indeks halaman; tidak ada riwayat kunjungan. Guard shell mengizinkan sistem menutup halaman utama kasir, dan tidak melindungi root pada layout lebar.

## Perilaku baru

- Perpindahan menu melalui navbar bawah, menu Lainnya, sidebar, shortcut dan navigasi setup dicatat pada satu riwayat shell. Pemilihan menu yang sedang aktif tidak menambah entri.
- Tombol kembali navbar dan Android menggunakan riwayat yang sama, termasuk saat kembali ke kasir setelah membuka menu lain. Contoh: Kasir → Lainnya → Pelanggan → Kasir; Back menuju Pelanggan → Lainnya → Kasir.
- Ketika riwayat habis, tetap berada di halaman utama yang diizinkan (Kasir atau Lainnya). Back tidak menutup aplikasi atau membawa pengguna ke halaman sebelum login.
- Guard berlaku pada lebar HP dan tablet. Tombol panah pada layout mobile juga tersedia saat halaman utama memiliki riwayat.
- Dialog, detail, editor, dan route pembayaran yang dipush tetap memakai Navigator: route teratas ditangani terlebih dahulu. Guard pembayaran yang sedang berjalan tidak dilewati.
- Back saat keyboard tampil hanya melepas fokus. Back pada panduan setup menutup panduan terlebih dahulu.
- Saat terkunci, mempersiapkan akses, pembayaran sedang berlangsung, atau pemulihan pembayaran sedang berjalan, Back tidak memindahkan halaman. Pemulihan memberi sinyal busy sampai blok finally selesai.
- Riwayat dibersihkan saat lock/akses operator berganti dan selesai mempersiapkan workspace. Saat kembali, halaman yang hak aksesnya telah dicabut dilewati.
- Riwayat memori dibatasi 100 entri. Tidak disimpan melintasi restart/login, tidak memulihkan sesi autentikasi dan tidak mengubah bukti transaksi.

## Bukti TDD

Journey diturunkan dari permintaan pengguna tanpa dokumen rencana tambahan.

1. `b95a7a6`: compile-time RED untuk controller riwayat dan guard yang belum ada. Tes baru memanggil kontrak yang diperlukan, belum mengklaim reproduksi perangkat.
2. `3d91ef1`: GREEN awal, 7 tes. Urutan menu, root tidak keluar, dialog/detail dan busy route lulus pada 390×844 dan 1100×800.
3. `51e2248`: RED perlindungan pemulihan pembayaran; parameter callback busy belum tersedia pada PosPage.
4. `6b38d00`: GREEN akhir, **61 PASS** pada 10 suite, termasuk widget shell POS asli dengan layanan tiruan. Riwayat lock/permission/keyboard dan callback pemulihan diverifikasi.

Pemisahan staging pada shell mempertahankan satu import `pos_startup_loading` milik perubahan yang telah ada. Posisi import/reset dari checkpoint awal dirapikan pada checkpoint akhir; tidak ada perubahan pengguna yang dibuang atau ikut dikomit.

## Jaminan pengujian

| Skenario | Bukti | Hasil |
|---|---|---|
| Back mengikuti urutan sebenarnya, termasuk tab utama dan kembali ke kasir | `pos_back_navigation_test.dart` | PASS |
| Klik halaman sama tidak menumpuk; history reset dan batas 100 | Tes controller | PASS |
| HP dan tablet tidak mengirim SystemNavigator.pop setelah riwayat habis | Tes platform channel + handlePopRoute | PASS |
| Dialog/detail dipop sebelum shell berpindah | Widget Navigator asli dalam harness | PASS |
| Busy payment route tidak bisa dipop | Guard PopScope di route teratas | PASS |
| Shell POS asli: Kasir → Lainnya → Pelanggan → Kasir lalu Back | `pos_shell_back_navigation_test.dart` | PASS |
| Arrow navbar dan Back Android menggunakan alur sama | Shell POS asli | PASS |
| Payment/recovery busy menahan Back, lalu dilepas setelah selesai | Shell dan `pos_keyboard_navigation_test.dart` | PASS |
| Keyboard, izin pelanggan dicabut, dan lock tidak membuka halaman lama | Shell POS asli dengan state terkontrol | PASS |
| Menu/izin, checkout recovery, cart lock, Google/PIN navigation, first-sale, sukses pembayaran | Delapan suite regresi tambahan | PASS |

Perintah dari root proyek mobile:

```powershell
flutter test --no-pub --coverage --coverage-path=output/operational-readiness-20261125/back-navigation-lcov-final-20261126.info test/pos_back_navigation_test.dart test/pos_shell_back_navigation_test.dart test/pos_mobile_navigation_policy_test.dart test/pos_keyboard_navigation_test.dart test/pos_more_menu_visibility_test.dart test/pos_checkout_recovery_flow_test.dart test/pos_checkout_cart_lock_test.dart test/pos_success_print_nonblocking_test.dart test/pos_google_navigation_test.dart test/pos_first_sale_flow_test.dart --reporter expanded
dart analyze --fatal-infos lib/presentation/pages/pos/pos_shell_page.dart lib/presentation/pages/pos/pos_page.dart lib/presentation/pages/pos/utils/pos_navigation_history.dart lib/presentation/pages/pos/widgets/pos_back_navigation.dart test/pos_back_navigation_test.dart test/pos_shell_back_navigation_test.dart test/pos_keyboard_navigation_test.dart
```

Hasil: **61 PASS, 20 detik, exit 0**; analyzer **No issues found, exit 0**. Cakupan executable yang berubah terhadap `b95a7a6`: **52/53 = 98,11%**, bukan cakupan seluruh aplikasi.

Log pada `output/operational-readiness-20261125/`:

- `back-navigation-final-20261126.log`
- `back-navigation-analyze-final-20261126.log`
- `back-navigation-lcov-final-20261126.info`

## Batas dan tindak lanjut

- Widget test menggunakan shell/widget Navigator/PopScope asli dengan repository dan platform tiruan. Belum uji gesture perangkat Android fisik atau emulator, belum build APK/AAB dan belum deploy.
- Riwayat ini mencatat tujuan menu shell, bukan setiap pergantian filter/tab di dalam satu halaman. Route detail/modal tetap memakai stack Navigator yang sudah ada.
- Helper lama `mobilePosBackDestination` masih tersedia untuk kompatibilitas tes lama, tetapi **tidak lagi digunakan shell** untuk mengizinkan keluar aplikasi.
- Tidak mengubah frontend Vue, server, database, nilai transaksi, draft, PIN, atau otorisasi backend.

## Evaluasi hasil

Nilai 4,0/5: akurasi 4 (61 tes dan analyzer bersih, perangkat belum diuji); kelengkapan 4 (urutan/menu/root/busy/lock/izin tercakup, bukan semua tab internal); kejelasan 4 (batas widget dan perangkat dijelaskan); keterpakaian 4 (kode siap masuk build berikutnya, paket belum dibuat); keringkasan 4 (rincian bukti dipisahkan dari ringkasan pengguna). Tindak lanjut paling bernilai: uji gesture Back pada Android terbaru setelah memasang build baru. Pengguna dapat menilai hasil tanpa menganggap aplikasi yang sudah terpasang otomatis diperbarui.
