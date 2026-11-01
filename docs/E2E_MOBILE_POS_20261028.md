# Uji end-to-end Pantoo POS mobile — 28 Oktober 2026

## Lingkungan dan batas uji

- Flutter development dijalankan di Chrome pada `http://localhost:53127`, viewport ponsel 375 × 812 CSS pixel. API: `http://localhost:8080/graphql`.
- Port diverifikasi pada host: `53127` dipakai proses Flutter/Dart (HTTP 200) dan `8080` dipakai `node server.js` (query GraphQL baca-saja mengembalikan `Query`). Log Flutter mengonfirmasi endpoint `http://localhost:8080/graphql`.
- Sesi akun `rochim`, toko `Toko Bandung [Dummy]`. Pengguna mengizinkan pembuatan data uji pada instansi tersebut walaupun database backend jarak jauh.
- Hanya alur profil/toko yang tersedia pada sesi ini yang diuji. Printer Bluetooth fisik, mode Android asli, profil resto/laundry, dan beberapa kasir offline bersamaan **belum** diuji.

## Hasil yang terbukti

| Alur | Hasil | Bukti |
| --- | --- | --- |
| Mulai aplikasi dan masuk PIN | Lulus | Sesi masuk ke kasir dan katalog produk tampil. |
| Cari produk | Lulus | Pencarian `Biskuit` menyisakan produk yang cocok. |
| Tambah ke keranjang | Lulus | Tab berubah menjadi `Keranjang (1)`; total Rp 12.500. |
| Bayar tunai uang pas | Lulus | Invoice `PANTOO-20261028-0003`, total Rp 12.500, kembalian Rp 0. |
| Uang diterima kurang | Lulus | Tagihan Rp 5.500 dan uang diterima Rp 5.000 menampilkan sisa Rp 500; tombol `Proses Bayar` nonaktif, tidak ada transaksi baru atau layar merah. Kembali ke keranjang mempertahankan item. |
| Setelah transaksi | Lulus | Keranjang kosong; invoice muncul di riwayat berstatus `Lunas`; stok Biskuit Cokelat [Dummy] turun dari 477 ke 476. |
| Dashboard | Lulus terbatas | Periode 7/30 hari dapat diganti; ringkasan dan transaksi terakhir tampil. |
| Pesanan aktif | Lulus terbatas | Halaman terbuka dan menampilkan keadaan kosong untuk filter saat ini. Perpindahan status tidak dapat diuji karena tidak ada pesanan aktif. |
| Antrean offline | Lulus terbatas | Halaman terbuka dan menampilkan antrean kosong; sinkronisasi transaksi offline belum diuji. |
| Katalog dan stok inventori | Lulus terbatas | Data produk dan ringkasan stok tampil. |
| Ringkasan shift aktif/riwayat | Lulus | Kas awal Rp 30.000, kas seharusnya Rp 48.000, 3 transaksi; angka expected di riwayat juga Rp 48.000. |
| Retur penjualan (pra-simpan) | Lulus terbatas | Invoice `PANTOO-20261028-0003` ditemukan, item dan opsi alasan/refund muncul, tombol draft baru aktif setelah item dipilih. Draft tidak disimpan, jadi refund/restock belum diuji. |
| Pengaturan profil retail | Lulus terbatas | Toko dummy memakai `Retail / Toko`; meja, dapur, delivery, order layanan, reservasi, teknisi, kendaraan, dan wajib pelanggan nonaktif; tracking stok aktif; pembayaran default Tunai dan pemenuhan Bawa Pulang. |
| Pembelian Langsung | Gagal pada proses backend yang berjalan | Tab ini memanggil query gabungan `GetDirectPurchasePolicy`, `GetDirectPurchases`, dan `GetDirectPurchaseOptions`, lalu menampilkan 403 “Anda belum terautentikasi”. Operasi tersebut belum terdaftar di auth middleware. Kode dan tes sudah diperbaiki, tetapi server yang sedang berjalan perlu memuat versi backend baru untuk uji ulang. |
| Purchase Order (pra-simpan) | Lulus terbatas | Daftar PO memuat status draft/disetujui/penerimaan; “Tambah” membuka form. Menekan Lanjut tanpa supplier memberi pesan validasi dan tidak membuat dokumen. Pengajuan, persetujuan, penerimaan, dan pembayaran belum diuji pada putaran ini. |

## Temuan

1. **Selesai — crash dialog nominal tunai.** Error pertama yang relevan ternyata `A TextEditingController was used after being disposed` pada field `pos_payment_page.dart`; `_dependents.isEmpty` adalah error susulan. Field kini menyimpan nilai tanpa controller sementara. Callback WebSocket halaman pesanan juga dilindungi saat `dispose`. Uji ulang urutan Pesanan Aktif → kasir → nominal kurang tidak lagi menghasilkan layar merah.
2. **Selesai — ringkasan shift tidak konsisten.** Query shift aktif kini mengambil total transaksi dan nilai kas; untuk shift terbuka, expected dihitung dari kas awal + pergerakan kas. Form tutup shift dan riwayat memakai perhitungan yang sama. Angka tampil cocok pada uji ulang.
3. **Selesai — kontrak tes pembelian tertinggal.** Tes disesuaikan ke query paginasi `GetPurchaseAdvancePage` yang memang digunakan halaman dan tersedia di backend. Seluruh 235 tes lulus.
4. **Rendah — Google Sign-In di origin lokal.** Konsol mencatat `The given origin is not allowed for the given client ID` pada `localhost:53127`; login PIN tetap bekerja. Perlu origin development yang terdaftar bila Google login hendak diuji di Chrome lokal.
5. **UX — riwayat transaksi pertama tampil sebagai tabel pada lebar ponsel**, sehingga kolom kanan keluar dari viewport. Tombol `Tampilkan sebagai kartu` bekerja dan hasilnya lebih terbaca; pertimbangkan kartu sebagai default untuk ponsel.
6. **Selesai di kode — operasi Pembelian Langsung tidak didaftarkan ke auth middleware.** Seluruh query/mutasi modul telah didaftarkan dan tes kontrak memastikan operasi tetap privat. Uji runtime ulang masih menunggu backend yang berjalan memuat perubahan.
7. **Kesenjangan produk — ritel perorangan belum punya jalur “satu orang” yang benar-benar ringkas.** Profil `Retail / Toko` sudah merupakan preset sederhana untuk penjualan: pelanggan tidak wajib, meja/dapur nonaktif, tunai dan bawa pulang default. Namun PIN dan shift wajib secara default (keduanya bisa diubah di Pengaturan POS), setup tetap bertahap, dan menu operasional lanjutan tetap terlihat. Khusus `Pembelian Langsung`, backend mensyaratkan pemohon, penyetuju, dan pembayar berbeda serta MongoDB replica set. Jangan menjanjikan pembelian langsung satu-orang lewat alur itu; tentukan jalur pengadaan sederhana tersendiri atau arahkan ke PO/penerimaan yang sesuai kebijakan.

## Belum dapat dinyatakan lulus

- Split payment, invoice/tempo, retur, pemesanan meja/dapur, pembelian/PO, printer/struk fisik, offline→online sync, dan profil bisnis lain belum diuji end-to-end.
- Uji retur di atas hanya sampai sebelum penyimpanan draft; tidak membuktikan refund maupun perubahan stok.
- Uji visual tiga breakpoint serta audit aksesibilitas lengkap belum dilakukan. Hasil ini bukan sertifikasi siap produksi.

## Verifikasi statis

- `flutter analyze --no-pub`: tidak ada masalah pada putaran sebelumnya. Setelah perubahan default kartu riwayat, percobaan ulang analisis tertahan tanpa hasil selama proses Flutter development aktif; verifikasi analisis terbaru belum dapat dinyatakan lulus.
- `flutter test --no-pub`: 235 lulus, 0 gagal.
- Backend: `node --check middlewares/authMiddleware.js` lulus; 22 tes kontrak POS dan autentikasi Pembelian Langsung lulus.

