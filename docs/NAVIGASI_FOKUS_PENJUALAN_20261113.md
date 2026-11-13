# Navigasi fokus penjualan — 13 November 2026

Dashboard tidak lagi menjadi halaman atau menu POS mobile. Halaman awal adalah Kasir/Penjualan; ringkasan angka usaha berada di Laporan. Kandidat Android diperbarui menjadi 1.0.9+10.

- Navbar bawah: Laporan, Katalog, pintasan Kasir di tengah, Transaksi, Lainnya.
- Sidebar layar lebar tidak lagi memuat Dashboard. Alt+1 menuju Kasir; Alt+2 tetap menjadi alias Kasir untuk mempertahankan kebiasaan shortcut sebelumnya.
- Setelah membuka kunci, aplikasi menunggu izin, toko dan katalog penjualan; tidak menunggu atau meminta statistik dashboard.
- Pengguna yang perlu membuka shift diarahkan ke shift; pengguna tanpa izin kasir tetap menuju menu yang diizinkan. Kondisi offline mengikuti snapshot konfigurasi operasional, bukan data dashboard.
- Tombol kembali dari tab utama mengarah ke Kasir, kemudian dapat keluar. Pengguna tanpa izin kasir memakai Menu sebagai halaman utama. Halaman sekunder tetap kembali ke asalnya.
- Indeks internal lama dipertahankan agar tujuan setup, retur, inventori, dan tautan laporan tidak bergeser.
- File dashboard lama tidak dihapus bersama perubahan desain terdahulu; layar itu tidak lagi diimpor atau diekspor sebagai halaman aplikasi. Laporan dan statistiknya tetap tersedia.

Verifikasi: 45 pengujian navigasi, shortcut, kesiapan shift, kasir, toko checkout dan navigasi laporan lulus. Pengujian juga memastikan pembukaan kasir tidak lagi meminta statistik dashboard. Analisis Dart pada seluruh area perubahan bersih.

APK kandidat: `output/pantoo-pos-sales-first/Pantoo-POS-1.0.9+10.apk` relatif terhadap root workspace `zera` (lihat folder `output/pantoo-pos-sales-first`). Kandidat ini belum dipublikasikan. Persyaratan backend laporan yang sudah dicatat pada rilis laporan tetap berlaku; perubahan navigasi ini tidak mengubah kontrak backend.
