# Audit perubahan terkait POS — 26 November 2026

## Ruang lingkup

Meninjau ulang rangkaian perubahan form utang/piutang, nota 58/80 mm dan logo profil usaha, navigasi Back/keluar aplikasi, serta kaitannya dengan pembayaran, bukti pemulihan, pergantian kasir, hak akses, pelunasan dan refund. Bukan sertifikasi seluruh integrasi produksi berdasarkan riwayat percakapan.

## Temuan yang diperbaiki

| # | Bug | Perbaikan dan bukti |
|---|---|---|
| 1 | Konfirmasi keluar milik operator lama dapat menutup sesi operator baru setelah pergantian operator selesai | Bekukan instansi/akun/operator dan token PIN saat dialog dibuka; periksa lagi sebelum exit. Diuji melalui shell asli, pergantian operator, batal dan konfirmasi baru. |
| 2 | Query nota lama dapat mengembalikan `show_logo=true` sesudah penyimpanan `false` dikonfirmasi | Revisi template dan salinan template tersimpan mempertahankan keputusan penyimpanan terbaru ketika query lama selesai. |
| 3 | Respons lama dari kunjungan sesi A dapat menimpa cache setelah A→B→A | Revisi sesi membedakan kunjungan, bukan hanya kesamaan string scope. Respons kunjungan terdahulu ditolak. |
| 4 | Cetak cepat yang mengantre dapat berpindah ke printer lain; disconnect juga memakai pilihan baru | Alamat dibekukan per job, diperiksa sebelum pengiriman dan setelah persiapan logo. Job lama dibatalkan bila pilihan berubah; disconnect hanya target awal. |
| 5 | Cetak PDF dapat mengikuti printer baru selama proses raster/discovery | Target Bluetooth/driver dibekukan dan diperiksa ulang sebelum penyerahan data. Tes Bluetooth serta driver normal/berubah lulus. Tidak berpindah printer atau retry otomatis. |
| 6 | PNG dengan header benar tetapi data piksel rusak lolos validasi awal, lalu menggagalkan PDF nota yang sudah dibayar | Decode kecil setelah pemeriksaan ukuran/dimensi, sebelum logo masuk renderer PDF. Gagal decode membuang logo saja; teks, invoice dan total tetap dirender. Codec/image dibersihkan. |
| 7 | Pelunasan utang/piutang dapat menghapus bukti lokal walau ACK merujuk ID/jenis dokumen berbeda | Validasi ID tidak kosong, jenis, dan target pembayaran pada repository serta sebelum UI menghapus bukti. Respons tidak cocok tetap unconfirmed; retry memakai bukti/ID permintaan yang sama. |

Tidak mengubah jumlah transaksi, stok, jurnal server, PIN, mapping akun, atau mengirim ulang mutasi finansial secara otomatis. Form spacing dan label dari perbaikan sebelumnya tetap diuji.

## TDD

Journey berasal dari permintaan audit pengguna. Checkpoint pada branch aktif:

- `fb2190d` RED: 12 PASS / 4 FAIL untuk respons nota/template, sesi, printer antre, dan exit antaroperator.
- `1fb4100` GREEN: 16 PASS. Fixture antrean cetak diperbaiki agar Completer dibuat dalam zona runAsync yang sama; ini menghindari timeout buatan pada harness, bukan menaikkan timeout produksi.
- `68d34fe` RED: 15 PASS / 2 FAIL, PNG IDAT rusak dan PDF mengirim ke target yang berubah.
- `8dccae5` GREEN: 17 PASS untuk renderer dan target PDF.
- `1911d90` RED: 5 FAIL, ID salah/kosong atau jenis salah diterima sebagai ACK; UI menghapus bukti.
- `fc98b4e` GREEN: 32 PASS untuk repository/UI utang-piutang, spacing dan ACK piutang lama.

Fixture sukses repository kini membawa `kind`/`document_id` yang memang wajib pada kontrak produksi, bukan input kosong. Assertion nominal, request ID, tujuan kas/bank dan bukti tidak dihapus atau dilemahkan.

## Hasil akhir

- Paket fokus 25 suite: **172 PASS**, 80 detik, exit 0. Mencakup nota/printer, profil/logo, Back/exit, menu/izin, checkout/cart lock, request store, first-sale, bahasa, utang/piutang/ACK dan retur/refund recovery.
- Changed executable terhadap `fb2190d`: **58/61 = 95,08%**. Bukan cakupan aplikasi keseluruhan. Tiga baris yang tidak tercakup berada pada fallback/cabang defensif receipt scope/target.
- Seluruh suite: **1309 PASS**, **4 menit 24 detik**, exit 0. Perintah dijalankan ulang dari awal setelah seluruh perbaikan produksi selesai, tanpa mengedit produksi selama run final. Berkas tes driver juga termasuk pada run ini.
- Analisis seluruh proyek: **No issues found**, exit 0 (`dart analyze --fatal-infos`). Dua koreksi awal lint pada tes printer diselesaikan; tidak ada suppression baru.

Percobaan full pertama menghasilkan 1302 PASS / 5 FAIL: kelima kegagalan adalah reproducer ACK yang baru ditambahkan ketika kernel full pertama masih memuat kode sebelum perbaikan pelunasan. Karena ada perubahan kode selama audit, full test diulang dari awal setelah semua perbaikan produksi selesai. Hasil awal ini tidak dilaporkan sebagai PASS final.

## Perintah dan log

Perintah dari root `mobile_POS_Pantoo`:

```powershell
flutter test --no-pub --concurrency=2 --reporter expanded
dart analyze --fatal-infos
```

Pengujian fokus menggunakan opsi `--coverage --coverage-path=output/operational-readiness-20261125/related-followup-lcov-final-20261126.info` dengan berkas:

```text
pos_receipt_logo_test.dart, pos_receipt_printer_target_test.dart,
pos_receipt_layout_test.dart, pos_receipt_printer_density_test.dart,
pos_business_profile_repository_test.dart, receipt_share_contract_test.dart,
pos_short_labels_test.dart, pos_app_exit_confirmation_test.dart,
pos_back_navigation_test.dart, pos_shell_back_navigation_test.dart,
pos_mobile_navigation_policy_test.dart, pos_keyboard_navigation_test.dart,
pos_more_menu_visibility_test.dart, pos_checkout_recovery_flow_test.dart,
pos_checkout_cart_lock_test.dart, pos_checkout_request_store_test.dart,
pos_success_print_nonblocking_test.dart, pos_google_navigation_test.dart,
pos_first_sale_flow_test.dart, pos_trade_repository_test.dart,
pos_trade_workspace_test.dart, pos_trade_form_spacing_test.dart,
pos_receivable_payment_ack_test.dart, pos_return_refund_ui_test.dart,
pos_return_process_recovery_test.dart
```

Log dalam `output/operational-readiness-20261125/`:

- `related-followup-full-final-20261126.log`
- `related-followup-focused-final-20261126.log`
- `related-followup-analyze-clean-20261126.log`
- `related-followup-lcov-final-20261126.info`
- RED/GREEN detail: `related-followup-red-*`, `related-followup-green-final-*`, `related-receipt-red-*`, `related-receipt-green-*`, `related-trade-ack-red-*`, `related-trade-ack-green-*`.

## Batas verifikasi

- Pengujian otomatis unit/widget termasuk shell/Navigator/dialog asli; HTTP, printer dan keputusan server dimodelkan dengan fixture, bukan transaksi produksi.
- Tidak build/deploy APK/AAB, mencetak fisik, menguji perangkat/emulator GUI, atau menjalankan integrasi Google Play/Google OAuth nyata. Perlu uji perangkat setelah paket diperbarui.
- Tidak mengubah Vue, backend, konfigurasi Cloud atau database produksi. Tidak menghapus cache/pending proof/data akun sebagai jalan pintas.
- Pengaturan/berkas pengguna yang sudah berubah sebelum audit dipertahankan. Import startup loading pada shell tetap unstaged.

## Evaluasi hasil

Nilai 4,0/5: akurasi 4 (1309 tes full, 172 fokus dan analyzer bersih, bukan bukti perangkat); kelengkapan 4 (tujuh bug lintas perubahan diperbaiki, integrasi nyata belum diuji); kejelasan 4 (hasil fokus dibedakan dari full dan simulasi); keterpakaian 4 (kode tersedia untuk build selanjutnya, paket belum dibuat); keringkasan 4 (bukti rinci terpisah dari ringkasan). Tindak lanjut bernilai tertinggi: uji Back/exit, pelunasan kehilangan respons, dan hasil printer 58/80 mm pada versi terpasang terbaru. Pengguna semestinya dapat menilai hasil tanpa menganggap perubahan sudah terdistribusi di Play Store.
