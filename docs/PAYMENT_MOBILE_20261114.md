# Pembayaran mobile — 14 November 2026

Rilis Android: 1.0.14+15.

## Perubahan

- Layar pembayaran ponsel memakai satu area gulir, total tagihan yang jelas, dan tombol bayar tetap di bawah.
- Metode pembayaran memiliki area sentuh lebih lapang. Input uang, nominal cepat, pelanggan, catatan, dan ringkasan pesanan tetap tersedia.
- Form pisah bayar ditata vertikal di layar sempit. Form uang dan catatan tetap dapat digunakan saat keyboard terbuka.
- Peralihan dari pisah bayar ke metode tunggal membersihkan alokasi lama. Kontrol form baru dibersihkan setelah dialog benar-benar ditutup untuk mencegah error saat animasi penutupan.
- Ringkasan menggunakan harga yang sudah diedit dan snapshot invoice tertunda. Tata letak dua panel pada desktop tetap tersedia.

## Verifikasi

- 27 pengujian terkait pembayaran lulus: layar 320/360 piksel, landscape, teks diperbesar, keyboard, tunai kurang/cukup, nominal minimum, QRIS, pisah bayar, penghapusan baris, catatan, harga manual, dan invoice tertunda.
- Payload metode dan nominal diperiksa dengan bloc uji, tanpa memposting transaksi ke server.
- Analisis Dart untuk halaman dan pengujian pembayaran: tidak ada masalah.
- Pratinjau berasal dari widget Flutter dengan tema aplikasi.
- Belum dilakukan pengujian pembayaran langsung pada perangkat fisik untuk perubahan ini.

APK produksi dibuat terpisah dari aplikasi QA; tidak ada deployment server atau transaksi produksi.

Build APK produksi berhasil. Identitas paket id.pantoo.pos, versionCode 15/versionName 1.0.14, tanda tangan v2 valid. Registrasi plugin dan shared_preferences tersedia di DEX; plugin integration_test tidak disertakan. Bukti: output/pantoo-pos-mobile-payment-1.0.14/verification.json.
