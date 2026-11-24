# Tombol PIN lebih kecil tanpa scroll — 25 November 2026

Permintaan terbaru: kecilkan sedikit tombol angka agar panel cukup tanpa scroll. Perubahan hanya presentasi PIN; susunan hapus–0–centang dan footer vertikal dengan label lengkap tetap.

Pada tinggi tersedia di bawah720dp, tombol keypad menjadi48dp dan angka28sp (sebelumnya64dp/32sp pada HP), dengan jarak/padding lebih rapat. Area sentuh tetap minimal48dp. Judul24sp, teks bantuan12sp, nama operator16sp. Layar lebih tinggi tetap memakai ukuran lega sebelumnya. Layar sangat pendek, teks diperbesar atau pesan tambahan masih dapat scroll agar konten tidak terpotong; tidak memakai FittedBox atau mematikan scroll secara paksa.

## Bukti TDD

Journey: kasir membuka PIN pada HP, dapat melihat semua angka, centang dan aksi bawah tanpa menggulir, lalu memasukkan PIN dengan keypad/keyboard yang sama. Tes lama11kasus dipertahankan; acceptance sebelumnya yang mengizinkan scroll HP normal diperbarui sesuai permintaan terbaru.

- RED `d0eb45a`:7PASS/4FAIL; panel lama melebihi viewport185dp pada320×568 dan94dp pada360×640.
- Percobaan pertama:10PASS/1FAIL; tersisa12dp scroll pada320×568 Indonesia. Padding vertikal dirapatkan lagi tanpa mengecilkan target sentuh.
- GREEN akhir: **82PASS**, tujuh suite, exit0,1menit23detik.
- Analyze dua berkas: **No issues found**, exit0.
- Cakupan halaman PIN **481/566baris (85%)**.

| Jaminan | Bukti widget/integration |
|---|---|
| Nol scroll pada viewport320×568,360×640,390×844,768×800 ×ID/EN; angka28/32sp, target≥48dp; footer tetap vertikal dan logout dapat ditekan tanpa ensureVisible | pin_classic_layout_test.dart,8kasus |
| Layar320×320/skala1–1.5 tetap dapat scroll; akun tanpa PIN tetap bisa membuat PIN | pin_classic_layout_test.dart,3kasus |
| Centang/loader, validasi digit, keyboard, lebar/resize, carousel, error create-PIN dan pembatasan akses tetap terlindungi | Enam suite regresi di perintah berikut |

```text
flutter test --no-pub --concurrency=1 --dart-define=PIN_CLASSIC_PHASE=smaller --coverage --coverage-path=output/pin-classic-layout-20261125/smaller-lcov.info test/pin_classic_layout_test.dart test/pin_submit_keypad_test.dart test/pin_viewport_width_test.dart test/pin_lock_responsive_test.dart test/pin_carousel_autoplay_test.dart test/pos_pin_setup_error_test.dart test/pos_subscription_pin_banner_test.dart
flutter analyze --no-pub lib/presentation/pages/common/pin_lock_screen.dart test/pin_classic_layout_test.dart
```

Log: output/pin-classic-layout-20261125/smaller-verification.log. Pratinjau widget memakai font aplikasi: id-smaller.png/en-smaller.png di folder yang sama; Indonesia diperiksa visual dan seluruh footer terlihat. Tidak mengubah API/auth/cache, tidak build/deploy atau menguji GUI Android fisik. Hot restart `R` untuk memperbarui sesi pengembangan.

Evaluasi: akurasi5 (hasil tes/preview), kelengkapan4 (native belum diuji ulang), kejelasan5, tindak lanjut4 (perlu hot restart/build di perangkat), keringkasan5;4,6/5. Tidak ada masalah kritis pada lingkup ini. Perbaikan lanjutan yang relevan: konfirmasi visual di HP pengguna setelah restart; hasil tidak diklaim berlaku tanpa scroll untuk semua skala teks atau semua kondisi error. Preferensi pengguna dipenuhi pada viewport normal yang diuji.
