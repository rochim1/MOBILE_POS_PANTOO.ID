# Jarak form Utang & Piutang mobile — 26 November 2026

## Perubahan

Permintaan: form pada halaman utang/piutang tidak berdempetan. Pengukuran awal menemukan jarak antar-input0px.

- Form tambah tagihan manual dan saldo awal utang/piutang memakai jarak vertikal16px antarelemen. Spacer lama yang akan menumpuk dihapus.
- Form pembayaran utang dan penerimaan piutang juga memakai16px. Nama pihak dan penjelasan dikelompokkan dengan jarak4px.
- Tombol tanggal yang membungkus ke baris berikutnya diberi jarak antarbaris8px.
- Form pelunasan invoice POS lama diberi16px antar-field dan sebelum aksi, termasuk jarak setelah peringatan bukti belum terkonfirmasi.
- Padding tepi20px dan penanganan keyboard/scroll modal dipertahankan. Tidak mengubah label/terjemahan, validasi, nominal, permission, payload, idempotensi atau posting Finance.

## Bukti

RED `933433b`: **0PASS/9FAIL**, runtime gap0px dibanding minimum12px (`trade-form-spacing-red-20261126.log`). Enam konteks utama kemudian diperiksa: tambah tagihan, saldo awal dan pembayaran untuk kedua jenis tagihan. Lima kasus pelunasan invoice juga memeriksa jarak tanpa mengurangi pemeriksaan ACK/sesi yang sudah ada.

GREEN `2c18684`: **27PASS, exit0** (`trade-form-spacing-regression-20261126.log`), empat suite:

```text
flutter test --no-pub --coverage --coverage-path=output/operational-readiness-20261125/trade-form-spacing-lcov-final-20261126.info test/pos_trade_form_spacing_test.dart test/pos_receivable_payment_ack_test.dart test/pos_trade_workspace_test.dart test/pos_trade_repository_test.dart --reporter expanded
```

Jaminan: minimum12px pada rect input nyata (implementasi16px), modal390×844 dapat dibuka tanpa overflow, form dapat digulir ke aksi, konfirmasi tetap diwajibkan, mapping akun/nominal tidak berubah, respons hilang mempertahankan bukti, respons invoice asing/pergantian sesi tidak meng-ACK pembayaran, serta hak akses tetap berlaku. Tes tidak memakai database produksi.

Percobaan GREEN pertama perlu menyesuaikan alat uji untuk menggulir ListView ke tombol yang sekarang berada di bawah layar; bukan menghapus pemeriksaan submit. Tidak ada pengurangan assertion nominal/permission/recovery. Font Roboto dimuat hanya pada harness agar screenshot dapat dibaca, bukan perubahan font/warna aplikasi produksi.

`dart analyze --fatal-infos` pada dua source dan dua tes: **No issues found**, exit0 (`trade-form-spacing-analyze-final-20261126.log`). Cakupan changed executable terhadap `933433b`: halaman trade7/7, invoice lama1/1, gabungan**8/8 (100%)**. Bukan coverage keseluruhan aplikasi. Screenshot widget berada pada `output/trade-form-spacing-20261126/after/`; layout tambah utang dan penerimaan piutang dilihat langsung.

## Batas dan evaluasi

Belum build APK/AAB atau uji GUI emulator/HP fisik; paket yang dibuat sebelum perubahan ini belum memuat patch. Tidak mengubah web Vue/backend. Tes27terfokus bukan pengujian ulang semua profil/aplikasi.

Evaluasi4,0/5: akurasi4 (pengukuran runtime dan27tes, bukan perangkat nyata); kelengkapan4 (tiga jenis form termasuk saldo awal/legacy, matriks perangkat belum penuh); kejelasan4 (perubahan spacing saja dan batas dipisahkan); dapat ditindaklanjuti4 (source/commit/perintah tersedia, perlu update paket); keringkasan4 (jawaban ringkas, bukti di sini). Prioritas berikutnya: build/update bila dibutuhkan lalu cek perangkat yang digunakan. Self-check: memenuhi perapian form tanpa mengklaim rilis atau E2E fisik.
