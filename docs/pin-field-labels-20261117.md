# Label modal pembuatan PIN — 17 November 2026

Permintaan: setiap field modal pembuatan PIN harus memiliki label yang terlihat, termasuk setelah nilainya diisi. Tema global memakai `FloatingLabelBehavior.never`, sehingga label yang sudah ada menghilang saat mengetik.

Perbaikan hanya pada tiga field di `_CreatePinDialog`: **Password akun**, **PIN baru**, **Ulangi PIN**, masing-masing memakai `FloatingLabelBehavior.always`. Terjemahan Indonesia/Inggris yang sudah ada tetap digunakan. Tema global, masking password/PIN, validasi, panjang PIN dan alur autentikasi tidak diubah.

Reproduksi: assertion label permanen gagal (`actual:null`, `expected:always`), tersimpan di `output/pin-field-labels-20261117/red.log`. Setelah perbaikan, `flutter test --no-pub --coverage test/pin_lock_responsive_test.dart --reporter expanded` lulus **8/8**, exit0; `green.log` dan `lcov.info` tersimpan pada folder yang sama. Mencakup dialog, input digit/filter, keyboard, overlay, dan layout ponsel/tablet. Checkpoint RED `1227aaf`, GREEN `982c6d6`.

LCOV mengukur ketiga konstruksi field beserta dekorasinya sebagai terlewati. Tiga baris atribut enum konstan sendiri tidak diinstrumentasi; karena itu jangan mengartikan pesan checkpoint sebagai metrik tiga baris executable atau coverage keseluruhan file. Assertion widget memeriksa ketiga atribut secara langsung.

Pemeriksaan `dart analyze lib/presentation/pages/common/pin_lock_screen.dart test/pin_lock_responsive_test.dart`: **No issues found**, exit0. `git diff --check` juga exit0.

Belum build/instal APK dan tidak mengubah data server. Perubahan versi pengguna di pubspec dipertahankan. Bukan acceptance perangkat fisik baru; hot restart/APK baru diperlukan untuk melihat perubahan pada aplikasi yang sudah berjalan.
