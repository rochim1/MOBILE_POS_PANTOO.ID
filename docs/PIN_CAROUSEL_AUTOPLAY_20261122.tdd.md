# Carousel otomatis halaman PIN — 22 November 2026

Permintaan: carousel pada halaman PIN bergeser otomatis. Skenario disusun langsung dari permintaan, tanpa file rencana terpisah.

## Perilaku

- Slide bergeser setiap 5 detik, transisi 300 ms, lalu kembali ke awal setelah slide terakhir.
- Tombol panah, indikator, dan swipe manual tetap berfungsi. Interaksi manual mengulang jeda 5 detik; auto-slide tidak melawan drag yang masih berlangsung.
- Timer berhenti saat aplikasi tidak aktif, widget dilepas, animasi dinonaktifkan, navigasi aksesibilitas aktif, atau ticker subtree dinonaktifkan. Route lain yang menutupi halaman tidak dipaksa berpindah slide.
- Input dan verifikasi PIN tidak diubah. Slide hanya memperbarui panel carousel.

## Bukti RED → GREEN

RED valid: 3 gagal / 1 lulus, karena slide tidak berpindah otomatis. Setup awal sempat diperbaiki agar font dan pemanggilan lifecycle sesuai API Flutter; kegagalan setup itu tidak dihitung sebagai bukti fitur.

GREEN akhir: **18 lulus, 0 gagal** (5 tes autoplay baru + 13 regresi halaman PIN). `dart analyze` dua file terkait: **No issues found!**

```powershell
flutter test test/pin_carousel_autoplay_test.dart test/pin_lock_responsive_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pin-carousel-autoplay-coverage-20261122.info' --reporter expanded
dart analyze lib/presentation/pages/common/pin_lock_screen.dart test/pin_carousel_autoplay_test.dart
```

| Jaminan | Bukti widget test | Hasil |
| --- | --- | --- |
| Bergeser otomatis, berulang, dan angka PIN yang sudah diketik tetap tersimpan | `carousel advances every five seconds, loops, and preserves PIN input` | PASS |
| Tombol manual mengulang jeda otomatis | `manual navigation restarts the five second autoplay interval` | PASS |
| Berhenti di latar belakang, lanjut saat aktif, timer bersih setelah widget dilepas | `autoplay pauses in background and resumes without disposing PIN` | PASS |
| Tidak melawan pengguna yang sedang drag | `autoplay waits while a user is dragging and restarts after release` | PASS |
| Pengaturan kurangi animasi mematikan autoplay, navigasi manual tetap bisa | `reduced motion disables autoplay but keeps manual navigation` | PASS |

Coverage kelas carousel: **79/81 baris (97,5%)**, bukan coverage keseluruhan halaman/aplikasi. Cabang route tertutup dan controller belum terpasang belum diuji terpisah.

Log berada di `D:/my node app/zera/output/`: `pin-carousel-autoplay-red-20261122.log`, `pin-carousel-autoplay-green-20261122.log`, `pin-carousel-autoplay-analyze-20261122.log`.

Checkpoint: RED `6acee14`, GREEN `3e186ac`, pembaruan API Flutter usang dengan tes ulang tetap lulus `d83b3a8`.

## Batas verifikasi dan evaluasi

Belum build APK atau uji GUI Android langsung; hasil di atas berasal dari widget test. Tidak mengubah data server ataupun pengamanan autentikasi.

Evaluasi penyerahan: akurasi 5/5 (klaim sesuai log); kelengkapan 4/5 (cabang route tertutup belum diuji khusus); kejelasan 4/5 (detail teknis disimpan di laporan); dapat ditindaklanjuti 4/5 (kode siap, aplikasi terpasang memerlukan build baru); keringkasan 4/5 (perintah dan bukti dipisahkan dari jawaban singkat). Rata-rata 4,2/5. Perbaikan lanjutan utama: verifikasi visual pada perangkat/build terbaru. Pengguna dapat menerima perubahan kode ini sebagai selesai tanpa menganggap APK terpasang sudah diperbarui.
