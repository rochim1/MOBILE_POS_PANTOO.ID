# Kesejajaran jumlah dan satuan keranjang

Tanggal: 23 November 2026. Skenario diturunkan dari screenshot pengguna: kontrol satuan harus sejajar, sama tinggi, dan ukuran teksnya seimbang dengan jumlah.

## Perbaikan

- Sebelumnya kontrol jumlah 36 dp, sedangkan satuan 48 dp. Label satuan juga menggunakan ukuran teks yang lebih kecil.
- Kedua kontrol sekarang setinggi 48 dp, menggunakan dekorasi, border, padding, dan posisi label yang sama; label jumlah tetap terlihat.
- Isi jumlah dan satuan sama-sama 14 sp. Padding horizontal berlebih pada satuan dihapus.
- Tiga bagian kontrol jumlah menggunakan lebar fleksibel agar tombol tidak meluber ketika berada dalam field berlabel.
- Tidak mengubah aturan jumlah, konversi satuan, harga, stok, maupun transaksi.

## Bukti TDD

| Jaminan | Tes | Hasil |
| --- | --- | --- |
| Tinggi dan sisi atas/bawah kedua kontrol sejajar pada 320, 360, dan 600 dp | `test/pos_cart_control_alignment_test.dart` | PASS |
| Ukuran teks sama, label terlihat, tanpa overflow saat skala teks 1,5 di layar 320 dp | Berkas yang sama | PASS |
| Tombol tambah/kurang dan pilihan satuan masih mengirim event yang sesuai | Berkas yang sama | PASS |

RED: empat tes layout gagal dengan `Actual: 36.0`, `Expected: 48.0`; satu tes aksi lulus. Log: `output/cart-control-alignment-red.log`; checkpoint `c19a524`.

GREEN: kelima tes lulus. Log: `output/cart-control-alignment-green.log`; checkpoint `2848f74`. Sebelum GREEN, tes juga menemukan overflow internal tombol; pembagian lebar fleksibel menyelesaikannya.

## Regresi akhir

Regresi akhir: **23 PASS** dalam 68 detik (`output/cart-control-alignment-verified.log`). Mencakup tampilan, aksi keranjang, dialog edit jumlah/harga saat keyboard ditutup, tarif layanan fleksibel, dan pemindaian label seluruh aplikasi. Cakupan panel keranjang: **141/152 baris (92,8%)**, tercatat di `output/cart-control-alignment-lcov.info`.

Satu percobaan awal melewati batas waktu 30 detik pada pemindaian seluruh label aplikasi; tes tidak dilewati, melainkan dijalankan ulang dengan batas dua menit. Pemeriksaan selanjutnya menemukan label melalui helper tidak dikenali pemindai; pemanggilan helper diperjelas menggunakan argumen `labelText` eksplisit. Aturan pemindai tidak dilonggarkan. Kedua kendala terselesaikan pada hasil 23 PASS di atas.

Analisis kode akhir pada widget dan tes yang diubah: **PASS — No issues found**, 107,3 detik. Bukti: `output/cart-control-alignment-analyze.log`.

```powershell
flutter test --no-pub --concurrency=1 --timeout=2m --coverage --coverage-path=output/cart-control-alignment-lcov.info test/pos_cart_control_alignment_test.dart test/pos_cart_dialog_lifecycle_test.dart test/pos_flexible_service_test.dart test/pos_field_labels_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/pages/pos/widgets/pos_cart_panel.dart test/pos_cart_control_alignment_test.dart
```

Batas bukti: pengujian widget, bukan GUI perangkat Android. APK tidak dibangun ulang dalam pekerjaan ini. Perubahan lain yang sudah ada di worktree dipertahankan.
