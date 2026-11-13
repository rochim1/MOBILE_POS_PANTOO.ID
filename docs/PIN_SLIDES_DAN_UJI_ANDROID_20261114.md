# Slide halaman PIN dan uji alur Android — 14 November 2026

**Koreksi kebutuhan:** desain dua halaman pada versi 1.0.12+13 digantikan oleh carousel panel kiri saja di versi 1.0.13+14. Lihat PIN_PANEL_KIRI_CAROUSEL_20261114.md. Catatan di bawah adalah hasil historis versi sebelumnya.

Halaman PIN kini memiliki dua slide. Slide pertama menampilkan gambar EDC BNI yang dilampirkan pengguna, secara utuh dengan fit contain. Slide kedua memuat pilihan operator dan keypad PIN yang sudah ada. Pengguna dapat menggeser layar atau menekan Lanjut ke PIN; tombol Info BNI kembali ke slide gambar. Tidak ada penggantian gambar atau pemuatan iklan dari jaringan.

Input PIN hanya aktif pada slide kedua. Perpindahan slide mengosongkan input yang belum selesai, tanpa mengubah operator terpilih, penghitung percobaan, atau aturan verifikasi PIN. Geser dan tombol kembali dinonaktifkan selama verifikasi sedang berjalan. Gambar disimpan sebagai assets/images/pin_bni_edc_promo.jpg.

## Verifikasi

- Analisis Dart pada perubahan PIN dan pengujiannya: No issues found.
- Sepuluh tes PIN dan proses login/penguncian lulus. Meliputi gambar di slide pertama, input keyboard yang tidak boleh membuka PIN tersembunyi, tombol lanjut, swipe, pembersihan input parsial, layar pendek 320×568, layar lebar, keyboard angka/numpad/Backspace/Enter, fokus, modal pemilihan operator, dan pembuatan PIN akun login.
- Uji native memakai APK mode release QA 1.0.12+13 di emulator Android dengan server GraphQL dan Mongo replica set staging sekali pakai. Login dilakukan melalui form Android dengan akun uji, kemudian verifikasi melalui enam tombol keypad yang terlihat. Tidak ada injeksi token untuk melewati login atau PIN.
- Login → slide gambar BNI → slide PIN → verifikasi PIN → Kasir/katalog berjalan. Dua produk tampil, termasuk stok 50 dan harga dari staging.
- Lainnya → Utang & Piutang: daftar piutang dan utang pemasok, masing-masing satu dokumen Rp100.000, serta detail kedua tagihan berhasil dibuka.
- Form tagihan manual dan form pembayaran pemasok berhasil dibuka dan dibatalkan. Kembali ke Kasir juga berhasil. Pengujian ini tidak mengirim transaksi penjualan, tagihan baru, atau pembayaran melalui UI.
- Seluruh 38 respons server sejak login berhasil memiliki status 200 dan tanpa error GraphQL. Log proses Android tidak memuat unhandled exception, class/plugin/channel error, RenderFlex overflow, atau fatal exception.

Bukti tersimpan di output/pantoo-pos-pin-slides-1.0.12: android-flow-verification.json, server-responses.jsonl, android-errors.log, dan tangkapan layar login, gambar BNI, PIN, Kasir, daftar/detail utang-piutang, serta kedua form.

## APK

Kandidat normal adalah Pantoo-POS-1.0.12+13.apk dengan package id.pantoo.pos. Tanda tangan APK v2 terverifikasi; kelas registrant plugin Android ada dalam DEX, plugin integration_test tidak disertakan, dan gambar asli BNI cocok byte demi byte dengan aset dalam APK. Cold launch APK normal berhasil sampai layar login tanpa error plugin/channel. SHA-256: 132fb45be693ec665f11b8bfcb2f65d01fd894266e57def5b80f779d915a0b89. Berkas Pantoo-POS-QA-release-smoke.apk hanya untuk pengujian staging, memiliki package id.pantoo.pos.qa dan sertifikat uji.

Backend produksi tetap memerlukan versi yang menyediakan operasi Utang & Piutang. Tidak ada deployment produksi atau pengujian menggunakan transaksi/akun produksi dalam pekerjaan ini. Data aplikasi yang sudah ada tidak dihapus.

Aplikasi QA reguler dipasang kembali menggunakan pembaruan tanpa menghapus data aplikasi. Server dan proxy staging sekali pakai dihentikan setelah pengujian.
