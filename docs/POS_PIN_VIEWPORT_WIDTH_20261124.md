# Panel PIN mengikuti viewport — 24 November 2026

## Permintaan dan penerimaan

Sumber: pengguna meminta lebar panel PIN tidak melebihi viewport. TEST-POS-PIN-VIEWPORT-WIDTH-2411 melindungi batas horizontal panel, indikator PIN, keypad dan tombol hapus pada layar sempit, panel lokal, pembesaran teks serta perubahan ukuran layar.

Hasil yang diharapkan: tidak ada overflow horizontal; panel memakai lebar tersedia dengan batas desain420dp; tombol tetap dapat disentuh; tidak mengecilkan seluruh konten; resize tidak menghapus PIN atau mengganti operator.

## Penyebab dan perbaikan

Panel sebelumnya memiliki batas420dp, tetapi tombol keypad memakai lebar tetap80dp tanpa flex. Tiga tombol membutuhkan240dp di luar padding. Indikator enam digit juga mempunyai lebar tetap162dp. Akibatnya anak panel masih meluber walau kotak panel dibatasi.

- `PosPinAccessViewport` kini memakai lebar eksplisit `min(lebar lokal yang tersedia, 420dp)`, bukan ukuran layar perangkat penuh.
- Tombol angka, ruang kosong dan hapus pada baris terakhir memakai batas fleksibel. Ukuran normal tetap80dp maksimum, namun menyesuaikan kolom ketika layar menyempit.
- Indikator digit ikut dibatasi fleksibel sehingga tidak meluber di viewport paling sempit.
- Scroll tetap vertikal; tidak menutupi kesalahan dengan clipping atau mengecilkan teks. Verifikasi PIN, lockout, selector operator, carousel dan autentikasi tidak diubah.

## Bukti RED → GREEN

`1068160`: `flutter test --no-pub --concurrency=1 test/pin_viewport_width_test.dart` menghasilkan6PASS/7FAIL. Terdapat RenderFlex overflow88px pada keypad dan10px pada indikator pada lebar200dp; kasus panel lokal260dp dalam layar1280dp meluber28px. Ini kegagalan layout nyata, bukan kesalahan kompilasi.

`d572df4`: perbaikan panel/flex; empat suite menghasilkan51PASS. `43733aa`: memperkuat batas tombol hapus, batas420dp dan resize sambil mengisi PIN; run akhir52PASS.

## Perintah akhir

Dari `mobile_POS_Pantoo`:

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/pin-viewport-width-20261124/lcov.info test/pin_viewport_width_test.dart test/pin_lock_responsive_test.dart test/pin_carousel_autoplay_test.dart test/pos_pin_setup_error_test.dart
52 passed; exit0; 29detik; tanpa skip/cancel.
flutter analyze --no-pub lib/presentation/pages/common/pin_lock_screen.dart lib/presentation/pages/common/pos_pin_access_viewport.dart test/pin_viewport_width_test.dart
No issues found!; exit0; 68.1detik.
```

Empat belas tes lebar/resize baru menjalankan widget PIN sebenarnya, memakai fixture kasir/repository lokal yang sudah dipakai suite lama:

- Lebar200/240/280/320/390/1024dp × skala teks1/1.5: panel dan semua tombol angka/hapus di dalam viewport; lebar target sentuh≥48dp.
- Panel260dp di perangkat1280dp: lebar constraint lokal yang dipakai, bukan lebar MediaQuery perangkat.
- Resize390×640→240×400 setelah mengetik12: digit34 lalu Enter tetap mengirim1234 kepada verifikasi operator yang sama. Tidak ada unlock tanpa verifikasi.
- Suite sebelumnya tetap memeriksa keyboard/numpad/delete/Enter, halaman pendek, ID/EN, selector operator, PIN baru, penolakan password, carousel manual/otomatis/reduced motion dan session-expiry.

Cakupan akhir: viewport10/10baris (100%); halaman PIN458/544baris (84.2%). Berkas cakupan berada pada path output di perintah. Ini bukti unit/integration widget, bukan E2E backend atau GUI APK baru. Tidak ada transaksi/database/API produksi yang diubah dan tidak ada build/deploy.

## Batas dan evaluasi

Perubahan belum masuk APK/AAB lama. Pemeriksaan lanjutan setelah build: buka PIN di HP, ubah orientasi atau split-screen, perbesar teks perangkat, lalu pastikan tidak ada konten melewati sisi layar dan PIN yang diketik tidak hilang.

Evaluasi: akurasi5/5 (assertion geometri dan perilaku nyata), kelengkapan4/5 (GUI native terbaru belum diulang), kejelasan5/5 (lebar panel dan lebar anak dipisahkan), keterlaksanaan4/5 (memerlukan build baru pada HP), keringkasan5/5 (dua berkas produksi, tanpa perubahan otorisasi). Rata-rata4.6/5; tidak ada isu kritis dari suite terkait. Self-check: hasil sesuai permintaan dengan batas pengujian dinyatakan; prioritas berikutnya hanya verifikasi native pada build baru.
