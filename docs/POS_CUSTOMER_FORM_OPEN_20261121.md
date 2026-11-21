# Form pelanggan kasir/pembayaran — 21 November 2026

## Penyebab

`showPosQuickCustomerDialog` menunggu `getRuntimeConfig()` sebelum membuka route. Request konfigurasi memakai network-only dengan batas waktu 30 detik. Kasir dan pembayaran sudah menyimpan konfigurasi di `PosBloc`, tetapi tidak menggunakannya saat membuka form.

## Perbaikan

- Kasir (panel produk dan panel informasi) serta pembayaran meneruskan snapshot konfigurasi aktif. Membuka form tidak lagi membuat request konfigurasi tambahan.
- Bila konfigurasi belum tersedia, route langsung terbuka dengan indikator pemuatan, Batal, dan Coba lagi bila gagal. Tidak menganggap konfigurasi gagal sebagai konfigurasi harga yang valid.
- Level harga tetap mengikuti default dan opsi yang sudah dimuat. Pilihan form tidak diinisialisasi ulang setiap kali builder dipanggil.
- Controller dilepas ketika widget route benar-benar dihapus, bukan ketika hasil route diterima sebelum animasi penutupan selesai. Tes sempat mereproduksi error controller disposed saat simpan; perbaikan menutup jalur tersebut.
- Tidak mengubah API penyimpanan, kewajiban nomor telepon, otorisasi server, atau proses pembayaran.

## Bukti pengujian

Journey: kasir membuka form tanpa menunggu server, mengisi nama lalu menyimpan pelanggan dengan level harga default yang benar. Jika belum ada konfigurasi, pengguna dapat membatalkan atau mencoba lagi.

- RED checkpoint `be1453f`: tes baru tidak dapat memakai snapshot konfigurasi karena parameter belum tersedia.
- GREEN: `flutter test test/pos_quick_customer_open_test.dart test/pos_customer_form_validation_test.dart test/pos_customer_payment_contract_test.dart --no-pub --concurrency=1 --coverage --coverage-path=../output/pos-google-access-20261120/customer-open-coverage.info --reporter expanded` — 12 tes lulus.
- Tes widget: HP langsung tampil tanpa request konfigurasi; nama dan default grosir tersimpan satu kali; tablet langsung tampil; membatalkan request lambat aman; gagal lalu retry berhasil tanpa level harga tebakan.
- Tes regresi: validasi nama/telepon/email dan kontrak pelanggan hingga submit pembayaran/pesanan.
- Cakupan komponen form: 211/227 baris (93%). Analisis kode seluruh empat file produksi terkait dan tes: bersih.

## Batas verifikasi

Pengujian widget otomatis memakai repository palsu; bukan pengukuran waktu di HP fisik atau uji server produksi. Tidak menjalankan build APK. Salin snapshot tidak menghilangkan kebutuhan koneksi ketika menyimpan pelanggan ke server.
