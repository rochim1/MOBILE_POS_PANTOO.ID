# Koreksi tinggi kotak satuan yang terlihat

23 November 2026. Skenario diturunkan dari screenshot lanjutan pengguna, tanpa rencana terpisah.

## Penyebab dan perbaikan

Perbaikan sebelumnya menyamakan ukuran pembungkus, tetapi `InputDecorator` tidak otomatis memperbesar area border ketika `expands` masih false. Dalam reproduksi, pembungkus keduanya 48 dp, sedangkan kotak jumlah yang terlihat 48 dp dan satuan 40 dp. Karena itu tes lama lulus meskipun screenshot pengguna masih berbeda.

Kini kedua dekorator menggunakan `expands: true` dan isi diposisikan di tengah. Dropdown mewarisi font/tinggi baris tema yang sama dengan jumlah. Tidak mengubah lebar berdasarkan fungsi kontrol, aturan jumlah, konversi satuan, harga atau transaksi.

## Bukti

- Tes mengukur kotak yang benar-benar digambar melalui `InputDecorator.containerOf`, bukan hanya `tester.getRect` pada widget pembungkus.
- Tinggi dan sisi atas/bawah border diuji pada lebar 320, 360, 600 dp serta skala teks 1,5. Posisi dan tinggi isi jumlah/ikon juga diperiksa agar tetap berada dalam kotaknya.
- Tombol tambah/kurang dan pemilihan satuan tetap mengirim event. Tampilan hasil render lengkap diperiksa langsung; angka, ikon dan unit terlihat dengan kedua kotak sejajar.
- RED: empat tes layout gagal, satu tes aksi lulus. Bukti `output/cart-visible-border-red.log`, checkpoint `32c39e8`.
- GREEN: lima tes lulus. Bukti `output/cart-visible-border-green.log`, checkpoint `62b2afc`. Penguatan pemeriksaan isi dan capture halaman lengkap juga lulus (`output/cart-visible-border-final.log`).
- Hasil render terbaru: `output/cart-visible-border-after.png`. Capture menyertakan seluruh Scaffold/Material agar isi kontrol ikut tergambar; menangkap hanya lapisan dalam dapat melewatkan gambar yang dilukis oleh Material leluhurnya.

## Regresi akhir

**23 PASS**, 37 detik, termasuk keranjang, dialog jumlah/harga, tarif layanan fleksibel dan audit label. Log: `output/cart-visible-border-verified.log`. Cakupan panel keranjang **144/155 baris (92,9%)**, bukan cakupan seluruh aplikasi. Analisis kedua berkas yang diubah: **No issues found**, 1,6 detik (`output/cart-visible-border-analyze.log`).

```powershell
flutter test --no-pub --concurrency=1 --timeout=2m --dart-define=CART_BORDER_PREVIEW=after --coverage --coverage-path=output/cart-visible-border-lcov.info test/pos_cart_control_alignment_test.dart test/pos_cart_dialog_lifecycle_test.dart test/pos_flexible_service_test.dart test/pos_field_labels_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/pages/pos/widgets/pos_cart_panel.dart test/pos_cart_control_alignment_test.dart
```

Batas bukti: render dan tes widget, bukan GUI APK pada perangkat. APK tidak dibangun ulang. Perubahan lain yang sudah ada di worktree dipertahankan.

## Evaluasi hasil

Akurasi 5/5: mengukur border aktual dan memeriksa render. Kelengkapan 4/5: layar sempit dan teks besar diuji, belum GUI perangkat. Kejelasan 5/5: membedakan ukuran pembungkus dengan border. Dapat digunakan 4/5: kode dan tes tersedia, APK lama belum diperbarui. Keringkasan 4/5: rincian pembuktian disimpan di laporan ini. Rata-rata 4,4/5; tidak ada isu kritis. Peningkatan berikutnya: konfirmasi visual pada APK berikutnya. Batas pengujian ini perlu disampaikan supaya hasil tidak disalahartikan sebagai APK baru.
