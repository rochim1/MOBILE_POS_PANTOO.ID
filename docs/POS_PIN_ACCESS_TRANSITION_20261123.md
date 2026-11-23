# Transisi PIN dan penguncian kasir

Tanggal: 23 November 2026. Skenario berasal dari laporan/screenshot pengguna, tanpa dokumen rencana terpisah.

## Penyebab

Status langganan terikat endpoint, instansi, akun login, dan identitas kasir. Ketika dikunci, token operator dibersihkan; setelah PIN benar, identitas operator diperbarui. Perubahan identitas ini memicu pemeriksaan akses baru. Halaman verifikasi sebelumnya langsung menampilkan pesan akses belum pasti dan tombol pemulihan, sekalipun pemeriksaan masih berjalan. Overlay itu juga bisa menutupi layar PIN saat status scope baru belum terverifikasi.

## Perbaikan

- Saat status akses belum terverifikasi dan kasir terkunci, layar PIN dari `InactivityWrapper` tetap tampil. Hanya overlay status **unknown** yang tidak menutupinya; pembatasan langganan yang sudah diketahui tetap diberlakukan.
- Setelah PIN benar, bila akses masih diperiksa, hanya tampil persiapan akses dengan spinner. Pesan koneksi, Coba lagi, Tutup shift, antrean offline dan Keluar akun tidak muncul prematur.
- Jika pemeriksaan benar-benar gagal/timeout, pilihan pemulihan kembali tersedia. Menekan Coba lagi mengembalikan tampilan ke loading, lalu mengikuti keputusan server.
- Tidak menambah jeda buatan. Batas pemeriksaan jaringan yang sudah ada tetap 12 detik; kegagalan tidak menghasilkan spinner tanpa batas.
- Tidak mengubah verifikasi PIN, token operator, kunci cache, masa berlaku offline, otorisasi mutasi, maupun kebijakan server. Penjualan tetap ditolak saat akses belum terverifikasi atau dibatasi.

## Bukti TDD

| Skenario | Jaminan |
| --- | --- |
| Setelah PIN, jaringan belum memberikan jawaban | Spinner tanpa pesan gagal/tombol pemulihan; kasir di belakangnya belum dapat diklik. Setelah jawaban full, halaman kasir dapat digunakan. |
| Dikunci lalu scope berubah dan koneksi gagal | Layar PIN tetap terlihat; mutasi penjualan dan penulisan offline ditolak; verifikasi PIN tetap boleh dilakukan. |
| Timeout lalu Coba lagi | Pemulihan tersedia setelah timeout; saat mencoba lagi kembali ke spinner. Jika server menyatakan billing-only, kasir tetap tidak dapat digunakan. |
| Offline, read-only, kedaluwarsa | Pemeriksaan berkala dan pembatasan lama tetap berlaku; menyembunyikan informasi pada PIN tidak memperpanjang akses offline. |

RED: tiga skenario baru gagal karena tampilan lama, empat regresi lama lulus. Log `output/pin-access-transition-red.log`, checkpoint `fadc6a4`.

GREEN: tujuh tes transisi lulus. Log `output/pin-access-transition-green.log`, checkpoint `a29e8bf`. Skenario loading juga diuji ulang pada HP 320 × 568 dp.

Satu ekspektasi regresi lama mengharuskan tombol Retry nonaktif tetap terlihat saat memuat; diperbarui agar mengharuskan spinner tanpa tombol/pesan pemulihan, sesuai permintaan baru. Assertion penolakan akses dan keputusan langganan tidak dihapus.

## Regresi akhir

**68 PASS**, 53 detik. Mencakup login, daftar kasir, penolakan PIN, pergantian identitas, status langganan, cache offline dan trusted clock, masa berlaku akses, pemulihan draft/struk, fokus keyboard, serta layout PIN HP/tablet.

Analisis pada ketiga berkas yang diubah: **PASS — No issues found**, 22 detik.

Cakupan `_SubscriptionVerification`, area tampilan loading/pemulihan yang diubah: **35/35 baris (100%)**. Cakupan keseluruhan berkas boundary **136/203 (67,0%)**, karena jalur alat pemulihan shift/antrean lain tidak seluruhnya dieksekusi; service akses yang tidak diubah tercakup **172/227 (75,8%)**. Tidak mengklaim cakupan seluruh aplikasi 80% atau pengujian seluruh GUI perangkat.

```powershell
flutter test --no-pub --concurrency=1 --timeout=2m --coverage --coverage-path=output/pin-access-transition-lcov.info test/pos_subscription_pin_banner_test.dart test/pos_subscription_test.dart test/pos_subscription_access_refresh_test.dart test/pos_login_lock_loading_test.dart test/pos_login_roster_resilience_test.dart test/auth_subscription_preparation_test.dart test/pin_lock_responsive_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/widgets/pos_subscription_boundary.dart test/pos_subscription_pin_banner_test.dart test/pos_subscription_test.dart
```

Bukti akhir: `output/pin-access-transition-verified.log`, `output/pin-access-transition-analyze.log`, `output/pin-access-transition-lcov.info`.

Batas bukti: tes widget/unit dan analisis kode, bukan uji GUI APK Android terpasang. APK tidak dibangun ulang. Web admin Vue, backend, dan database tidak diubah. Perubahan pengguna yang sudah ada di worktree dipertahankan.

## Evaluasi hasil

| Aspek | Nilai / 5 | Bukti atau batasan |
| --- | --- | --- |
| Akurasi | 5 | Penyebab ditelusuri sampai scope identitas dan service; hasil sesuai log yang dirujuk. |
| Kelengkapan | 4 | Transisi normal dan gagal diuji; belum dicoba manual pada APK perangkat. |
| Kejelasan | 5 | Loading dibedakan dari kegagalan, tanpa menyembunyikan keputusan pembatasan server. |
| Dapat digunakan | 4 | Kode dan regresi tersedia; APK lama belum memuat perubahan. |
| Keringkasan | 4 | Laporan menyimpan rincian pembuktian yang tidak perlu diulang dalam jawaban pengguna. |

Rata-rata 4,4/5. Tindak lanjut paling berguna: cek visual transisi pada APK berikutnya. Tidak ada masalah kritis pada evaluasi ini; batas pengujian disampaikan agar pengguna tidak menganggap APK sudah diperbarui.
