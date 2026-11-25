# Nota transaksi 58 mm — 26 November 2026

## Hasil

Perbaikan source mobile untuk nota pelanggan: ID shift/database dan ID permintaan pembayaran tidak lagi dicetak pada PDF, teks termal, maupun teks WhatsApp. ID tetap ada pada model/query transaksi untuk rekonsiliasi dan pemulihan. Nomor nota, kasir, toko, produk, nominal dan rincian pembayaran dipertahankan. Tidak ada perubahan mutasi penjualan, stok, jurnal atau API server.

Font 58 mm dibatasi7–9pt; template lama12–18pt dinormalkan menjadi9pt, template tanpa ukuran memakai8pt. Judul lebih besar2pt. Pengaturan font dan pratinjau menggunakan kebijakan yang sama; skala pratinjau mengikuti lebar kertas. Pilihan80mm tetap tersedia dengan ukuran eksplisit8–18pt, default tanpa ukuran10pt. Margin4mm tidak dipersempit untuk memaksakan isi.

PDF kini memakai tinggi roll sesuai isi, bukan tinggi perkiraan tetap. Reproduksi awal menunjukkan contoh nota terpotong setelah subtotal; sesudah perbaikan total, diterima, kembalian dan footer lengkap. Kolom harga diberi ruang fleksibel; qty bulat tidak lagi memakai `.0`, pecahan tetap dipertahankan. Teks ESC/POS memakai kolom32karakter untuk58mm dan48untuk80mm, memisahkan baris jika kedua nominal tidak cukup pada satu baris.

Widget test juga menemukan overflow59px pada dropdown mode cetak dan29px pada judul kartu pengaturan di HP390px. Dropdown dibuat expanded dan judul dapat membungkus. Peralihan80→58mm tidak meninggalkan nilai font di luar pilihan.

## Bukti pengujian

| Jaminan | Bukti | Hasil |
|---|---|---|
| Tidak mencetak ID teknis; invoice dan jumlah uang tetap ada | `pos_receipt_layout_test.dart`, `receipt_share_contract_test.dart`, PyMuPDF atas PDF nyata | PASS |
| Ukuran default/tersimpan12/18 tidak membuat58mm membesar | Pembacaan operasi font pada stream PDF aktual, bukan hanya konstanta | PASS |
| Tinggi sesuai isi dan total tidak hilang | PDF pendek dan12produk bernama panjang dengan nominal besar | PASS |
| Diskon, promo, pajak, pelanggan, channel, segmen, catatan dan qty pecahan utuh | Kasus opsional thermal/PDF | PASS |
| Nominal termal tidak terpotong paksa pada32karakter | Kasus harga123.456.789 | PASS |
| Pengaturan/pratinjau HP dan80→58mm tidak overflow | `pos_receipt_printer_density_test.dart`, widget Android tiruan390×844 | PASS |
| Berbagi WhatsApp, terjemahan, preview PDF, dokumen pembelian, pembayaran mobile tetap berfungsi | Paket delapan suite | PASS43tes, exit0 |

Perintah final di repo mobile:

```text
flutter test --no-pub --coverage --coverage-path=output/operational-readiness-20261125/receipt-58-lcov-final-20261126.info test/pos_receipt_layout_test.dart test/pos_receipt_printer_density_test.dart test/receipt_share_contract_test.dart test/pos_short_labels_test.dart test/pos_translation_rescan_test.dart test/pos_pdf_preview_bytes_test.dart test/pos_purchase_thermal_document_test.dart test/pos_payment_mobile_layout_test.dart --reporter expanded
```

`receipt-58-regression-20261126.log`: **00:18 +43: All tests passed!**. `dart analyze --fatal-infos` pada3source dan4tes: **No issues found**, exit0 (`receipt-58-analyze-final-20261126.log`). Tidak menjalankan seluruh suite aplikasi, GUI emulator/browser nyata, atau printer fisik pada tugas ini.

Coverage executable changed-line terhadap baseline `f519a6f`: builder87/87, halaman printer102/120, total **189/207 (91,30%)**, bukan coverage seluruh aplikasi. Dua baris dihapus pada teks WhatsApp tidak menambah executable line; jalur WhatsApp diuji melalui widget share yang sudah ada. Cabang logo/network dan beberapa aksi perangkat printer belum terkena paket ini.

## RED → GREEN

- `f95be5a`:6FAIL/2PASS pada `receipt-58-red-final-20261126.log`: ID teknis, tiga kasus font, qty bulat, tinggi tetap. Tidak menyamakan kegagalan fixture dengan bug aplikasi.
- `4530aa3`: reproduksi runtime dua overflow pengaturan (`receipt-58-density-valid-20261126.log`) dan nominal termal9PASS/1FAIL (`receipt-thermal-columns-red-20261126.log`). Fixture sempat perlu membaca item dari DropdownButton anak dan mengembalikan override platform sebelum invariant runner; kegagalan setup tersebut tidak dianggap temuan produksi.
- `7fb41fe`: perbaikan inti,25PASS (`receipt-58-final-clean-20261126.log`).
- `9c64cea`: cakupan cabang tambahan dan dua guard kurung,43PASS dan analyzer bersih. Perubahan pengguna sebelumnya, termasuk versi1.0.24+25 dan koreksi assertion tempo, dipertahankan; hanya hunk test nota yang masuk checkpoint, bukan perubahan tempo milik pengguna.

## Pemeriksaan visual dan PDF

File di `output/pdf/receipt-20261126-after/`: `receipt-58.pdf`, `receipt-80.pdf`, `receipt-58-long.pdf`, beserta PNG. Dirender dengan Poppler dan dilihat langsung. PyMuPDF memastikan seluruh span teks berada di dalam halaman, footer/total/kembalian ada, dan kedua ID teknis tidak ada. Hasil:58×100,13mm;80×121,04mm;58×275,96mm, masing-masing satu halaman, nol span keluar halaman. PDF sebelum perbaikan disimpan terpisah di `receipt-20261126-before`.

`pdftotext` bawaan Git gagal karena DLL relocation; pemeriksaan teks diganti PyMuPDF yang tersedia, bukan dilewati. Poppler memberi peringatan alias font Symbol/ArialUnicode dan Dart PDF memberi peringatan dukungan Unicode font standar; contoh ID/EN yang diuji ter-render tanpa kotak/teks hilang. Ini tidak membuktikan seluruh aksara atau printer nyata.

## Penerapan dan batas

Belum membuat APK/AAB baru atau mengunggah Play Store. Paket1.0.24+25 yang sudah dibuat sebelumnya belum berisi perubahan nota ini. Diperlukan build/update berikutnya untuk dipakai di HP; jangan clear data/uninstall. Uji cetak fisik58mm tetap diperlukan untuk memeriksa karakteristik printer, koneksi dan hasil kertas. PDF/share memakai builder yang sama pada sukses pembayaran, riwayat transaksi dan contoh cetak; invoice/dokumen A4 tidak diubah.

## Evaluasi

Akurasi4/5 (RED/GREEN,43tes, analisis dan3PDF diperiksa; printer fisik belum). Kelengkapan4/5 (PDF/termal/WhatsApp/pratinjau dan nominal besar; belum paket Android baru). Kejelasan4/5 (bukti source dibedakan dari APK terpasang). Dapat ditindaklanjuti4/5 (source/commit/contoh tersedia; perlu build lalu cetak nyata). Keringkasan4/5 (detail di laporan, ringkasan pengguna singkat). Rata-rata4,0/5. Prioritas lanjutan: build/update tanpa hapus data, lalu cek cetak fisik58mm dan aksara nama pelanggan yang dipakai. Self-check: hasil sesuai perbaikan nota, bukan klaim sudah diverifikasi pada printer pengguna.
