# Format uang POS mobile

Versi 1.0.7+8 memakai pemisah ribuan Indonesia, contoh `1.000.000`. Nominal yang mendukung pecahan memakai koma, contoh `1.000.000,25`. Backend tetap menerima nilai numerik, bukan teks berformat.

## Form yang diperiksa

- Produk: harga jual dan beli, dialog tambah/edit lama, komposisi, serta detail harga.
- Keranjang: harga satuan dan total item; dialog ubah harga mendukung input berformat.
- Pembayaran: tunai, pembayaran gabungan, deposit reservasi, dan ringkasan pembayaran.
- Pesanan: pembayaran pesanan, rincian item, HPP komponen, dan total.
- Pembelian: harga beli, diskon item nominal/persen, diskon dokumen, biaya tambahan, dan kedua layout form yang tersedia.
- Hutang pembelian: nilai awal sisa hutang/termin, input pembayaran, payload pembayaran, dan riwayat.
- Promo: diskon nominal, maksimum diskon, minimum pembelian, serta perpindahan jenis diskon.
- Shift: modal awal, kas masuk/keluar, dan tutup shift sudah memakai input ribuan.
- Pengaturan: minimum transaksi tunai sudah memakai input ribuan.
- Retur penjualan/pembelian, penerimaan, dan inventory: nominal menggunakan format Indonesia; input kuantitas dipertahankan.
- Dashboard, laporan, stok, dan antrian offline: nilai uang memakai ribuan penuh.
- Struk serta dokumen pembelian: formatter rupiah Indonesia yang sudah ada diperiksa.

Persentase, berat, jumlah barang, kode, nomor telepon, dan durasi tidak diubah menjadi format mata uang.

## Implementasi dan verifikasi

Formatter bersama berada di `lib/core/utils/rupiah_input_formatter.dart`. Input bilangan bulat mempertahankan kontrak form yang sudah ada; `decimalDigits: 2`, `formatRupiahAmount`, dan `parseRupiahAmount` dipakai pada form yang mendukung pecahan. Kursor saat menyunting angka dan backspace pada pemisah ribuan juga ditangani.

15 pengujian lulus: format/parsing, pecahan, edit kursor/backspace, paste, payload pembayaran hutang melalui form sebenarnya, tampilan produk pada lebar 320/360 dp, serta kontrak pembayaran pelanggan. Analisis Dart pada formatter, seluruh halaman POS, dan dashboard: tidak ada masalah.

Log pengujian: `output/pos-money-tests-final.log`. Log analisis: `output/pos-money-analyze-final.log`. APK release dan verifikasi berada di `output/pos-apk-money-format-20261022/`.
