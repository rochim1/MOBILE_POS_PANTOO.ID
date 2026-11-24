# Panel PIN ringkas tanpa scroll pada HP umum — 24 November 2026

## Permintaan dan kriteria

Pengguna meminta panel PIN tidak perlu di-scroll, dengan angka sedikit lebih kecil. TEST-POS-PIN-COMPACT-HEIGHT-2411: semua aksi terlihat pada viewport umum dengan ukuran teks normal; tombol tetap minimal48dp; layar sangat pendek/teks besar mempunyai scroll pengaman, bukan konten terpotong atau seluruh panel diperkecil.

## Perubahan

- Tinggi aman di bawah720dp memakai mode ringkas: angka32→28sp, baris keypad64/80→48dp, judul26→24sp dan jarak vertikal lebih rapat. Nama operator tetap16sp dan petunjuk utama14sp; catatan sekunder12sp. Ukuran teks tetap mengikuti pengaturan perangkat.
- Tinggi tombol selector operator minimal48dp. Keypad, hapus dan centang tetap minimal48×48dp pada matriks viewport yang diuji. PIN/keyboard, verifikasi4–6digit, proses/klik ganda dan hak akses tidak berubah.
- Untuk panel ringkas berlebar≥280dp, layar pelanggan dan logout dibuat sejajar. Label pelanggan dipendekkan menggunakan terjemahan yang sudah ada; tooltip tetap menjelaskan aksi menghubungkan layar. Pada panel sangat sempit atau layar lapang, susunan vertikal sebelumnya tetap tersedia.
- Layout ringkas memakai constraint tinggi lokal setelah SafeArea, bukan mengubah skala seluruh widget. Viewport tetap membatasi lebar dan menyediakan scroll vertikal hanya jika konten benar-benar lebih panjang.

## Bukti RED → GREEN

`1285e6a`:11tes baru terkompilasi,7PASS/4FAIL karena scroll pada320×568 dan360×640. Kebutuhan scroll sebelum perubahan:185dp (ID/EN320×568),113dp (ID360×640),94dp (EN360×640). Ini layout asli dengan font Roboto dan SafeArea24dp atas/bawah.

`a299323`: implementasi ringkas menghasilkan37PASS pada suite tinggi, centang dan batas lebar. Run akhir82PASS pada tujuh suite, tanpa skip/cancel; exit0,72detik.

Perintah dari `mobile_POS_Pantoo`:

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/pin-compact-height-20261124/lcov.info test/pin_compact_height_test.dart test/pin_submit_keypad_test.dart test/pin_viewport_width_test.dart test/pin_lock_responsive_test.dart test/pin_carousel_autoplay_test.dart test/pos_pin_setup_error_test.dart test/pos_subscription_pin_banner_test.dart
flutter analyze --no-pub lib/presentation/pages/common/pin_lock_screen.dart test/pin_compact_height_test.dart
```

Analyze: No issues found!, exit0,11.6detik. Cakupan halaman PIN489/574baris (85.2%), bukan cakupan seluruh POS.

Tes baru membuktikan `maxScrollExtent≤0.1` dan logout bisa disentuh tanpa scrolling pada320×568,360×640,390×844,768×800 × bahasa ID/EN, seluruhnya dengan SafeArea24dp atas/bawah. Angka tetap≥28sp, tombol≥48dp, dan tidak memakai FittedBox. Pada320×320 dengan skala teks1/1.5, scroll tetap tersedia dan logout dapat dicapai tanpa overflow. Akun baru tanpa PIN tetap dapat mengakses tombol Buat PIN pada HP320×568.

Suite regresi mencakup batas horizontal200–1024dp, split-screen/resize tanpa kehilangan PIN, angka/Enter/Backspace, loader/submit tunggal, create-PIN↔keypad tanpa key ganda, carousel, penolakan password, batas langganan dan cache offline. Widget berjalan nyata; repository/cubit autentikasi menggunakan fixture. Ini bukan uji login backend atau GUI Android terbaru.

Pratinjau sebelum/sesudah dibuat dengan `--dart-define=PIN_COMPACT_PHASE=before/after` pada suite terkait dan diperiksa: `output/pin-compact-height-20261124/{id,en}-{before,after}.png`. Kedua pratinjau sesudah memperlihatkan centang, catatan, layar pelanggan dan logout di viewport320×568 tanpa scroll. Tidak ada gambar lampiran pengguna yang diedit.

## Batas dan evaluasi

Tidak ada build APK/AAB, deploy atau perubahan data produksi. Layout baru terlihat setelah hot restart pada sesi pengembangan; APK lama belum berubah. Tidak dijanjikan nol scroll pada semua ukuran/font: layar sangat pendek, font aksesibilitas besar atau pesan tambahan tetap boleh scroll agar kontrol tidak tersembunyi.

Evaluasi: akurasi5/5 (batas scroll/geometri diperiksa), kelengkapan4/5 (GUI native terbaru belum diulang), kejelasan5/5 (mode ringkas dan fallback dipisahkan), keterlaksanaan4/5 (perlu restart/build pada perangkat), keringkasan5/5 (satu berkas produksi, tanpa alur autentikasi baru). Rata-rata4.6/5; tidak ada isu kritis di suite terkait. Self-check: sesuai permintaan pada HP umum dan batas dinyatakan. Langkah berikutnya hanya pemeriksaan native pada build baru.
