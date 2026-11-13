# Carousel panel kiri halaman PIN — 14 November 2026

Koreksi kebutuhan: carousel hanya pada panel promosi sebelah kiri. Kolom operator dan keypad PIN di kanan selalu tampil dan tetap dapat digunakan. Halaman PIN bukan lagi slide tersendiri dan tidak memiliki halaman iklan pendahuluan.

- Slide pertama: gambar EDC BNI dari lampiran pengguna, ditampilkan utuh menggunakan fit contain.
- Slide kedua: panel gambar/branding Pantoo yang sudah ada sebelumnya.
- Navigasi: geser pada panel kiri, panah sebelumnya/berikutnya, serta dua indikator yang dapat ditekan. Navigasi berputar antara dua slide.
- Panel promosi mengikuti aturan responsif semula (lebar minimal 1000). Ponsel sempit langsung menampilkan PIN seperti sebelumnya.
- Pergantian gambar tidak menghapus angka PIN, mengubah posisi panel PIN, memindahkan operator, atau mengubah aturan verifikasi. Fokus dan dukungan keyboard PIN dikembalikan ke perilaku semula.

Sepuluh tes PIN dan login/penguncian lulus, termasuk perpindahan carousel saat PIN sudah terisi sebagian, penyelesaian PIN melalui keyboard, swipe, posisi kolom kanan, ponsel pendek, fokus keyboard, pemilihan operator dan pembuatan PIN. Pratinjau renderer Flutter 1200×800 tersimpan di output/pantoo-pin-left-carousel.png.

Versi APK pembaruan: 1.0.13+14. Versi 1.0.12+13 menggunakan penafsiran seluruh halaman sebagai slide dan telah digantikan untuk kebutuhan ini.
