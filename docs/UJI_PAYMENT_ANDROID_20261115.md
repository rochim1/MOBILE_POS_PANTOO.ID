# Uji pembayaran Android â€” 15 November 2026

## Lingkungan

Emulator Pantoo_POS_UI_QA_20261102, aplikasi QA release, layar 1080 Ã— 2400 pada density 480 (360 Ã— 800 logical pixels). Backend GraphQL asli menggunakan Mongo replica set sementara di loopback. Akun, toko, barang, dan seluruh transaksi merupakan data uji baru. Aplikasi dan data produksi tidak diubah.

## Temuan dan perbaikan

Pada rilis awal yang diuji (1.0.14+15), login, PIN, kasir, serta transaksi tunai/QRIS/pisah bayar berhasil. Halaman sukses memakai uang_diterima untuk semua metode sehingga QRIS dan pisah bayar menampilkan Rp0 meskipun nilai transaksi benar di server.

Halaman sukses kini menampilkan total transaksi untuk metode non-tunai dan pisah bayar. Tunai tetap menampilkan uang yang diterima; nilai kembalian dan data server tidak diubah. Versi perbaikan: 1.0.15+16.

## Pengujian otomatis

38 pengujian pembayaran lulus, mencakup tata letak ponsel, keyboard, teks besar, nominal kurang/cukup, metode non-tunai, pisah bayar, harga manual, snapshot invoice, dan tampilan nominal pada halaman sukses. Analisis halaman sukses dan pengujiannya tidak menemukan masalah.

## Bukti awal di emulator

- Login melalui form dan verifikasi PIN, lalu masuk kasir dan memuat katalog.
- Tunai: total 1000, diterima 2000, kembalian 1000. Nominal 500 memblokir proses pembayaran.
- QRIS: total 1000, transaksi tersimpan di server.
- Pisah bayar: tunai 400 + QRIS 600, total 1000, tersimpan beserta alokasinya.
- Sesudah selesai, aplikasi kembali ke kasir, keranjang kosong, dan stok diperbarui.
- Input uang dan form pisah bayar dapat digunakan dengan keyboard terbuka.

Pencatatan QRIS merupakan konfirmasi manual pada lingkungan uji; tidak ada pengujian gateway atau transfer uang sungguhan.

Sesi QA lama sempat ditolak sebelum login baru karena database uji dibuat ulang. Aplikasi mengarah kembali ke login. Penolakan ini dibedakan dari alur kasir setelah login valid.

Hasil pengulangan versi perbaikan, data transaksi, dan log tersedia pada output/pantoo-payment-android-20261115.

## Hasil akhir versi 1.0.15+16

QRIS (invoice 0004), pisah bayar (0005), dan tunai (0006) telah diulang di emulator dan berhasil. Tampilan nominal non-tunai sudah benar. Pemeriksaan teks 130% juga berhasil; footer pembayaran tetap dapat digunakan. Riwayat menampilkan enam invoice berstatus lunas.

Total enam penjualan uji bernilai 6000, stok 50 menjadi 44, enam jurnal penjualan berstatus posted dan debit/kredit masing-masing 1000. Tidak ada duplikasi ID transaksi. 96 respons server setelah login valid: HTTP 200, tanpa GraphQL error. Log Flutter/AndroidRuntime tidak mencatat error. Terdapat pesan deprecation ashmem dari platform Android, tanpa kegagalan aplikasi.

APK produksi 1.0.15+16 berhasil dibangun, tanda tangan v2 valid, registrant plugin/shared_preferences tersedia di DEX, dan integration_test tidak dibundel. Pengujian transaksi dilakukan pada flavor QA release dari kode yang sama; produksi tidak menerima transaksi uji.

Ukuran layar dan teks emulator dikembalikan ke pengaturan semula, tanpa menghapus data aplikasi. Emulator dan server fixture dihentikan setelah bukti disimpan.
