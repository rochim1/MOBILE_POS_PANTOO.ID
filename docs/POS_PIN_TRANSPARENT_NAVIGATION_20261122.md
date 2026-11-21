# Navigasi gambar PIN transparan — 22 November 2026

Journey: pengguna mengganti gambar di sisi kiri layar PIN tanpa latar bulat berwarna pada tombol navigasi, sementara PIN tetap dapat diisi.

- Tombol sebelumnya/berikutnya kini memakai latar transparan, bukan `filledTonal`.
- Panah berwarna `#344054` pada slide terang dan putih pada slide gelap agar tetap terbaca.
- Area sentuh minimal 44×44, tooltip, navigasi melingkar, swipe, dan indikator gambar dipertahankan. Tidak mengubah autentikasi atau akses langganan.

## Bukti

- RED `0cbcd05`: tes navigasi gagal karena tombol lama tidak memiliki style transparan eksplisit.
- GREEN `97a1b7e`: tes yang sama lulus untuk slide terang/gelap, tombol sebelumnya/berikutnya, swipe, ukuran sentuh, posisi panel PIN, dan input keyboard `123456`.
- `flutter test test/pin_lock_responsive_test.dart test/pos_subscription_pin_banner_test.dart --no-pub --concurrency=1 --coverage --coverage-path=../output/pos-pin-transparent-navigation-coverage-20261122.info --reporter expanded`: **17 PASS**.
- Seluruh style dan callback navigasi yang diubah dieksekusi oleh tes. Preview widget hasil render diperiksa secara visual: `../output/pos-pin-transparent-navigation-20261122.png`; lingkaran ungu tidak lagi terlihat.
- Cakupan seluruh file layar PIN: **397/483 baris (82,2%)**.
- Analisis terarah: `dart analyze lib/presentation/pages/common/pin_lock_screen.dart test/pin_lock_responsive_test.dart` — **No issues found**.

Tidak menjalankan GUI HP fisik atau membangun ulang APK/AAB. Preview berasal dari renderer widget Flutter, bukan screenshot perangkat produksi.
