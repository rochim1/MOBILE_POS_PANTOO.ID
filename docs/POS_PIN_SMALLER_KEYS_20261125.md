# Tombol PIN lebih kecil tanpa scroll — 25 November 2026

## Penyesuaian terbaru: jarak antarbaris lebih lega

Journey dari masukan pengguna: jarak atas–bawah antar tombol masih terlalu rapat. Gap antarbaris keypad dinaikkan **4→12dp** pada layar pendek (10→12dp pada layar lega), tanpa mengecilkan tombol56dp/angka30sp. Di tinggi tersedia<560dp, pengantar generik tidak ditampilkan bagi operator yang sudah memiliki PIN; petunjuk PIN, pemilih operator dan semua aksi tetap. Padding panel layar lega dikurangi2dp per sisi vertikal agar tablet tidak mendapat scroll4dp setelah gap diperbesar.

RED `7d60949`:3PASS/8FAIL karena gap4/10dp belum mencapai12dp. Percobaan pertama80PASS/2FAIL: HP sudah muat, tablet768×800 masih scroll4dp; diperbaiki melalui padding, bukan pelonggaran tes. GREEN `832188d`: **82PASS**, exit0,1menit10detik. Analyze akhir **No issues found**,6,8detik. Coverage halaman PIN **480/565baris (85%)**.

| Jaminan | Bukti |
|---|---|
| Jarak tiga pasangan baris 1–4/4–7/7–0 minimal12dp, tombol≥56dp, angka30/32sp dan nol scroll normal |8kasus layout ID/EN pada320×568,360×640,390×844,768×800|
| Layar pendek/font besar tetap bisa scroll; akun tanpa PIN tetap bisa membuat PIN |3kasus layout lain, seluruh11kasus dipertahankan|
| Keyboard, centang, loader, lockout, resize dan pembatasan akses tetap |Enam suite regresi; total82PASS|

Perintah tujuh suite pada blok di bagian riwayat dijalankan dengan `--dart-define=PIN_CLASSIC_PHASE=spaced` dan `--coverage-path=output/pin-classic-layout-20261125/spaced-final-lcov.info`. Log `spaced-final-verification.log`; preview widget `id-spaced.png`/`en-spaced.png` di folder yang sama. Preview Indonesia diperiksa: keypad lebih renggang, footer lengkap, tidak terpotong. Tidak build/deploy, mengubah otorisasi/server atau menguji GUI Android fisik. Hot restart `R` untuk melihat perubahan.

Evaluasi: akurasi5 (tes/preview/analyzer), kelengkapan4 (kenyamanan di HP pengguna belum dikonfirmasi), kejelasan5, tindak lanjut4 (perlu hot restart), keringkasan5;4,6/5, tanpa masalah kritis pada lingkup ini. Bukti memastikan dimensi dan perilaku, bukan menjamin preferensi visual pengguna; tindak lanjut relevan adalah meninjau di HP sebenarnya.

## Penyesuaian sebelumnya: tombol lebih tinggi dan nyaman

Masukan pengguna berikutnya: tombol terlalu kecil dan pendek. Pada layar pendek, tinggi keypad dinaikkan **48→56dp**, angka **28→30sp**; layar lega tetap memakai ukuran sebelumnya. Journey tetap sama: semua tombol dan aksi bawah terlihat tanpa scroll pada HP normal. Keterangan umum pengelolaan PIN disembunyikan hanya pada layar pendek untuk operator yang sudah memiliki PIN; panduan akun tanpa PIN, pesan error, lockout, verifikasi dan semua aksi tetap tersedia. Footer tetap vertikal.

RED `28dffbf`:7PASS/4FAIL karena tinggi48dp belum memenuhi56dp. GREEN akhir: **82PASS**, exit0,1menit19detik;11kasus layout tetap, tanpa skip/deletion. Analyze dua berkas **No issues found** (6,9detik). Coverage PIN **482/567baris (85%)**. Delapan viewport×bahasa normal tetap tanpa scroll dan target angka≥56dp; layar sangat pendek/skala besar tetap dapat scroll. Keyboard/centang/loader dan guard akses dilindungi enam suite regresi yang sama.

Perintah akhir sama dengan blok di bawah, dengan `--dart-define=PIN_CLASSIC_PHASE=comfortable` dan `--coverage-path=output/pin-classic-layout-20261125/comfortable-lcov.info`. Log `comfortable-verification.log`; preview `id-comfortable.png`/`en-comfortable.png` dalam folder yang sama. Preview Indonesia diperiksa: seluruh panel terlihat dengan angka lebih besar. Tidak build/deploy atau menguji GUI Android fisik.

Evaluasi hasil terbaru: akurasi5 (tes, analyzer, preview), kelengkapan4 (konfirmasi visual HP pengguna belum dilakukan), kejelasan5, tindak lanjut4 (perlu hot restart `R`), keringkasan5; total4,6/5, tanpa masalah kritis pada lingkup perubahan. Layak diserahkan; kenyamanan akhir tetap perlu umpan balik pengguna pada HP sebenarnya.

## Riwayat penyesuaian sebelumnya

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
