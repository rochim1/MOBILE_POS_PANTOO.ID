# Audit Printer dan Struk POS

Tanggal audit: 9 September 2026

## Kesimpulan

Pantoo POS menyediakan pencetakan universal melalui dialog cetak sistem pada mobile dan dialog browser pada web. Jalur ini mencakup printer yang dikenali oleh sistem operasi atau layanan print vendor, tetapi tidak berarti seluruh printer thermal dapat dicetak secara langsung.

Pengaturan yang tersimpan di backend adalah **template struk bersama** untuk POS web dan mobile. Pengaturan perangkat printer harus tetap lokal per terminal karena printer, koneksi, dan kemampuan hardware berbeda pada setiap perangkat.

## Perbaikan yang telah diterapkan

- Ukuran kertas diseragamkan menjadi nilai fisik `58` atau `80` mm. Nilai web lama berbasis pixel dimigrasikan secara transparan menjadi 58 mm.
- Mobile dan web membaca/menyimpan `show_segment` dan `show_tipe_pesanan` dari sumber konfigurasi yang sama.
- Logo instansi dimuat ke dokumen PDF mobile tanpa menggagalkan cetak apabila logo tidak dapat diunduh.
- URL logo relatif dinormalisasi ke origin API, dibatasi waktu unduh 5 detik dan ukuran 5 MB, lalu di-cache selama aplikasi berjalan.
- Halaman pengaturan mobile memiliki preview PDF dan tes cetak menggunakan renderer yang sama dengan transaksi.
- Tombol cetak pada halaman sukses membuka layanan cetak sungguhan.
- Opsi `auto_print_receipt` diteruskan ke halaman sukses dan membuka dialog cetak secara otomatis.
- Konten dinamis struk web di-escape sebelum dimasukkan ke jendela cetak dan CSS berbahaya ditolak.
- Jendela cetak web menunggu logo selesai dimuat atau gagal sebelum membuka dialog cetak.
- Label internal jenis pesanan diubah menjadi label yang mudah dibaca pada nota mobile.
- Migrasi data `paper_width` tersedia dalam mode dry-run dan apply.
- Printer sistem dapat dipilih per terminal, disimpan lokal, diuji, dan digunakan untuk direct print saat driver/platform mendukung.
- Jika printer tersimpan hilang atau direct print gagal, pencetakan kembali ke dialog sistem.

## Cakupan printer saat ini

### Didukung melalui sistem operasi

- Printer yang muncul pada Android Print Service.
- AirPrint pada iOS.
- Printer Windows/macOS/Linux yang dikenali sistem pada aplikasi desktop.
- Printer browser pada POS web.
- Simpan/cetak sebagai PDF.

### Belum merupakan direct printing

- ESC/POS Bluetooth Classic atau BLE.
- ESC/POS USB/USB OTG.
- ESC/POS TCP/IP berdasarkan alamat IP dan port.
- Printer internal perangkat seperti Sunmi/PAX melalui SDK vendor.
- Auto-cut, buka cash drawer, buzzer, dan cetak tanpa dialog.

Direct printing harus dibuat sebagai adapter terpisah per transport/vendor. Fallback ke dialog cetak sistem wajib dipertahankan agar transaksi tidak bergantung pada satu jenis perangkat.

## Arsitektur target

### Template bersama di backend

- Logo dan header.
- Kolom invoice, tanggal, kasir, toko, pelanggan, channel, segmen, jenis pesanan, dan promo.
- Footer.
- Ukuran kertas 58/80 mm dan ukuran font.

### Profil printer lokal per terminal

- Jenis koneksi: sistem, Bluetooth, USB, LAN, atau vendor SDK.
- Identitas/alamat printer default.
- Jumlah salinan.
- Auto-cut dan cash drawer bila tersedia.
- Cetak otomatis dan kebijakan fallback.
- Status koneksi serta waktu tes terakhir.

Konfigurasi lokal tidak boleh disimpan sebagai template instansi karena terminal dalam satu toko dapat menggunakan printer berbeda.

## Tahap lanjutan yang direkomendasikan

1. Tambahkan adapter khusus ESC/POS di atas layanan system print yang sudah tersedia.
2. Tambahkan discovery/pairing ESC/POS Bluetooth, USB, dan TCP/IP.
3. Tambahkan test print, status koneksi, timeout, retry satu kali, dan fallback PDF.
4. Tambahkan capability detection untuk cutter dan cash drawer.
5. Tambahkan pengujian golden untuk nota 58/80 mm dan contract test template web/mobile.
6. Catat hasil cetak pada audit lokal tanpa menyimpan data sensitif printer di backend.

## Migrasi ukuran kertas lama

Jalankan pemeriksaan tanpa perubahan data:

```bash
npm run migrate:pos-receipt-width
```

Setelah hasil dry-run diperiksa, terapkan migrasi:

```bash
npm run migrate:pos-receipt-width:apply
```

## Batasan keamanan

`custom_css` hanya berlaku untuk renderer web dan tidak boleh diterapkan ke PDF mobile. CSS perlu disanitasi sebelum dimasukkan ke jendela cetak web. Template tidak boleh berisi kredensial atau data perangkat printer.
