# Perbaikan inventori dan transfer Pantoo POS Android

Tanggal: 26 November 2026, Asia/Jakarta.

Sumber pekerjaan: [audit inventori dan transfer Android](ANDROID_INVENTORY_TRANSFER_AUDIT_20261126.md). User journey berasal dari temuan audit dan permintaan pengguna: permintaan tetap aman ketika respons hilang, form ditutup/dibuka ulang, operator berubah, atau data lokasi/pencarian melebihi batas awal.

## Perubahan

| Temuan | Implementasi | Validasi |
|---|---|---|
| INV-A01 — draft transfer ganda setelah reopen | Simpan document/payload/ID sebelum request; saat reopen tampilkan pemulihan, bukan form kosong | Widget halaman asli + repository asli dengan transport tiruan; ID dan payload retry identik, hanya satu efek server tiruan |
| INV-A02 — penerimaan sebagian terulang | Intent per dokumen tetap tersimpan setelah timeout/restart; pemulihan mengulang ID yang sama, bukan menghitung ulang ID dari revisi terbaru | Penerimaan fisik satu kali tetap dihitung satu kali setelah reopen dan replay |
| INV-A03 — kembali saat menyimpan | `PopScope` melindungi editor dan operasi transfer ketika request aktif | Event kembali Android pada tes widget tidak menutup form yang sedang menyimpan |
| INV-A04 — pilihan biaya yang ditolak server | Opsi landed cost dihilangkan untuk pilihan baru; nilai legacy yang belum didukung ditampilkan sebagai opsi nonaktif dan pengguna dapat memilih beban langsung | Menu biaya tidak menawarkan penambahan ke nilai persediaan |
| Batas 200 lokasi/rak | Ambil halaman lanjutan warehouse dan saldo lokasi, bukan memotong halaman pertama | 201 warehouse dan 201 saldo lokasi seluruhnya termuat |
| Respons pencarian lama menimpa terbaru | Nomor generasi request; perubahan teks langsung membatalkan relevansi respons lama | Respons “slow” yang datang setelah “fast” tidak mengganti PO-FAST |
| Tiga tes koreksi stok gagal | Seed COA bawaan pada fixture seperti onboarding nyata, tanpa melonggarkan validasi Finance | Seluruh 5 tes manual-stock atomic PASS; seluruh 132 regresi server PASS |

## Alur pemulihan baru

1. Sebelum mengirim, Android menyimpan bukti intent ke penyimpanan perangkat dan memeriksa hasil penulisannya.
2. Bukti dibatasi per endpoint, instansi, akun login, operator, dan dokumen. Pembuatan transfer baru memiliki slot tersendiri.
3. Request memakai ID yang sama sampai hasil terkonfirmasi. Klik ganda dengan payload sama, termasuk dari dua instance repository, memakai satu request aktif.
4. Respons terputus/timeout, hasil kosong, respons parsial dengan error, atau respons yang menunjuk dokumen lain tidak menghapus bukti.
5. Form dibuka kembali: tampilkan “Periksa transfer sebelumnya”, termasuk referensi dan ringkasan data asli. Pemeriksaan ini tidak bergantung pada keberhasilan memuat ulang daftar barang/warehouse.
6. Tombol pemeriksaan mengirim mutation asli dengan ID dan payload asli. Deduplikasi server yang sudah ada mengembalikan dokumen/penerimaan yang sama.
7. Bukti dihapus hanya setelah respons sukses yang cocok dan penghapusan lokal berhasil. Penghapusan lokal gagal: tetap periksa ID lama, jangan membuat pengganti.
8. Daftar dokumen menyediakan aksi pemeriksaan pada dokumen dengan bukti pending, termasuk ketika statusnya sudah selesai. Aksi lain pada dokumen itu tidak boleh mengganti intent yang belum selesai.
9. Penolakan pasti pada pengiriman pertama dapat membuka form untuk diperbaiki. Penolakan ketika memulihkan request lama tidak dianggap bukti bahwa percobaan pertama belum pernah berhasil.

Penyimpanan ini juga melindungi laporan selisih, keputusan reviewer, dan aksi status transfer yang memiliki protokol idempotensi server. Data autentikasi tidak disimpan di intent; pengiriman memakai sesi serta pemeriksaan izin yang berlaku saat ini.

Tidak ada izin transfer offline baru, tidak ada queue yang otomatis memindahkan stok tanpa server, tidak ada perubahan shift/toko secara diam-diam, dan tidak mengunci seluruh kasir penjualan. Ketika koneksi belum tersedia, bukti tetap ada sampai dapat diperiksa.

## Bukti pengujian

### RED yang benar-benar dijalankan

- API pemulihan belum tersedia: `pos_transfer_recovery_test.dart` gagal kompilasi karena `execute`, `pendingIntent`, dan `recoverPending` belum ada.
- Pagination: setelah setup respons tiruan diperbaiki, tes benar-benar mengeksekusi repository dan gagal `Expected 201, Actual 200`.
- Navigasi: event kembali menutup editor ketika request belum selesai.
- Pencarian: tes widget gagal menemukan PO-FAST setelah respons PO-SLOW yang lebih lama datang.
- Isolasi aksi: tes batal menemukan bahwa aksi berbeda sempat menjalankan ulang operasi pending; kini harus meminta pemeriksaan eksplisit.
- Respons parsial: tes gagal karena bukti menjadi null; kini `ErrorPolicy.all` mempertahankan data beserta error sehingga tidak salah dianggap sebagai penolakan tanpa hasil.
- Server: `manual_stock_atomic.test.js` semula 2 PASS/3 FAIL karena COA tidak disiapkan. Seed diperbaiki, tanpa mengubah kode posting atau menghilangkan assertion rollback/dimensi.

Checkpoint mobile RED: `aa66980`, `24e8f31`, `e4a6e95`, `7f5be50`, `c0edf9d`. Checkpoint GREEN implementasi mobile: `8acc28f` pada branch `main`. Server: `b5a4da87` memperbarui fixture COA setelah bukti kegagalan dan pengujian 5/5 PASS.

### Hasil terbaru

- Regresi inventori/transfer/opname/stok awal terarah: **69/69 PASS**, log `output/inventory-fix-20261126/mobile-targeted-final.log`.
- Widget tambahan terbaru: **8/8 PASS**, log `output/inventory-fix-20261126/ui-expanded.log`. Termasuk create/receive/report/decide dengan respons hilang lalu reopen, pilihan batch, konversi box, navigasi, biaya, dan tampilan English 320 px.
- Server: **132/132 PASS**, log `presensi_zera_BE/output/inventory-fix-20261126/server.log`. Database replica set sementara lokal, bukan produksi.
- Analisis statis final 11 target kode/tes yang diubah, dengan `--fatal-infos`: **No issues found**, log `output/inventory-fix-20261126/analyze-final-clean.log`.
- Regresi Flutter menyeluruh final: **1.388 PASS dan 1 timeout lingkungan** (1.389 skenario), durasi 5 menit 59 detik. Log `output/inventory-fix-20261126/mobile-full-final.log` tetap merekam exit code gagal, bukan ditulis ulang sebagai satu full-run PASS.
- Satu skenario timeout tersebut adalah pemindai label yang membuat proses analisis Dart tambahan; batas default 30 detik terlewati saat empat worker aktif. File itu diulang tersendiri tanpa mengubah assertion atau kode aplikasi, `--concurrency=1 --timeout 2m`: **3/3 PASS**, durasi 35 detik, log `output/inventory-fix-20261126/field-labels-rerun.log`.
- Dengan rerun tersebut, **seluruh 1.389 skenario yang dijalankan telah memiliki hasil PASS dan tidak ada kegagalan yang belum ditindaklanjuti**. Ini hasil gabungan run penuh dan rerun, bukan klaim bahwa raw full-run terakhir memiliki exit code 0. Perbedaan jumlah dari run awal mencakup tes lain yang bertambah di workspace bersama; perubahan di luar inventori/transfer tidak ikut diambil ke commit ini.

### Cakupan perubahan

LCOV terarah dan widget tambahan digabung dengan hit maksimum per file/baris, bukan menjumlahkan ulang baris yang diuji dua kali. Baseline sebelum perubahan: `aa66980^`.

- Penyimpanan intent baru: **61/63 baris (96,83%)**.
- Perubahan repository transfer: **52/59 baris (88,14%)** pada diff Git biasa.
- Halaman pemulihan baru: **42/45 baris (93,33%)**.
- Seluruh perubahan berdasarkan diff Git biasa, termasuk kode lama yang terformat/terbungkus ulang: **538/682 baris (78,89%)**.
- Untuk membedakan perubahan logika dari pergeseran/format ulang kode lama, perbandingan urutan token menggunakan jalur edit Myers menghasilkan **248/281 baris yang mengandung token tambahan (88,26%)**. Ini metrik tambahan; angka diff biasa tetap dilaporkan di atas agar batas cakupannya terlihat.

Script pengukuran dan hasil per berkas: `output/inventory-fix-20261126/coverage-review.cjs`, `coverage-summary.json`. Sumber: `targeted.info` dan `ui-expanded.info`. Coverage bukan bukti GUI perangkat; beberapa cabang error/navigasi dan entry pemeriksaan pada daftar dokumen tetap memerlukan pengujian perangkat lanjutan.

Regresi menyeluruh pertama dimulai sebelum dua guard final (respons parsial dan ID dokumen salah) selesai. Runner itu memakai kernel versi awal untuk repository tersebut dan berakhir 1.382 PASS/2 FAIL. Tes terarah dengan kode final sudah PASS. Seluruh suite kemudian dijalankan ulang dari kode perbaikan final yang dibekukan, tanpa coverage, dan lognya dipisahkan di `mobile-full-final.log`. Satu timeout lingkungan pada run kedua diselesaikan dengan rerun terpisah sebagaimana dicatat di atas.

Perintah validasi Flutter yang dijalankan:

```text
flutter test --no-pub --concurrency=2 --coverage
  --coverage-path output/inventory-fix-20261126/targeted.info
  test/pos_transfer_recovery_test.dart test/pos_transfer_recovery_ui_test.dart
  test/pos_transfer_editor_test.dart test/pos_transfer_operation_test.dart
  test/pos_transfer_parity_test.dart test/pos_inventory_route_context_test.dart
  test/pos_stock_location_contract_test.dart test/pos_stock_pagination_test.dart
  test/pos_opname_stock_handoff_test.dart test/pos_opname_parity_test.dart
  test/pos_opening_stock_repository_test.dart test/pos_opening_stock_page_test.dart

flutter test --no-pub --concurrency=2 --coverage
  --coverage-path output/inventory-fix-20261126/full.info --reporter expanded

flutter test --no-pub --concurrency=4 --reporter expanded

flutter test --no-pub --concurrency=1 --timeout 2m
  test/pos_field_labels_test.dart --reporter expanded

flutter test --no-pub --coverage
  --coverage-path output/inventory-fix-20261126/ui-expanded.info
  test/pos_transfer_recovery_ui_test.dart --reporter expanded
```

Daftar server 132 skenario sama dengan dua kelompok regresi pada audit awal: transfer P0, receiving audit, receipt resolution, profile contract, routing filters, dynamic rules, three flows, optional approval, payment, stock allocation, batch plan, opname multirack, dan manual stock atomic. Ketiga kegagalan awal kini telah hilang, termasuk pengujian dimensi cabang/proyek.

### Jaminan yang diuji

| Jaminan | Bukti utama | Jenis |
|---|---|---|
| Tidak mengirim ketika penulisan bukti gagal atau tidak terbaca kembali | `pos_transfer_recovery_test.dart` | Repository/penyimpanan |
| Request dan payload sama setelah repository serta form dibuat ulang | `pos_transfer_recovery_test.dart`, `pos_transfer_recovery_ui_test.dart` | Repository + widget |
| Klik ganda tidak membuat request aktif kedua | `pos_transfer_recovery_test.dart` | Konkurensi klien |
| Respons parsial atau dokumen salah tidak menghapus bukti | `pos_transfer_recovery_test.dart` | Kontrak respons |
| Akun/operator lain tidak membaca intent milik akun asal | `pos_transfer_recovery_test.dart` | Isolasi identitas |
| Akun berubah saat simpan: request belum dikirim | `pos_transfer_recovery_test.dart` | Perubahan identitas |
| Gagal menghapus bukti setelah sukses: retry tetap menggunakan ID lama | `pos_transfer_recovery_test.dart` | Pemulihan acknowledgement |
| Laporan dan keputusan tidak diubah menjadi intent baru ketika respons hilang | Dua file pengujian recovery | Repository + widget |
| Koreksi, stok global/lokasi dan jurnal konsisten/rollback bersama | 132 tes server | Integrasi resolver + MongoDB |
| Retry ID sama tidak menggandakan kirim/terima dan batch/seri tetap tepat | 132 tes server | Integrasi |

## Batas yang harus dipahami

- Ini tes otomatis Flutter serta integrasi server, **bukan GUI Android emulator/HP terpasang**. Pengguna sebelumnya memilih melanjutkan audit kode dahulu; tidak ada emulator tersambung ketika audit.
- Tidak membuat APK/AAB, menaikkan versi, memasang aplikasi, menjalankan migrasi, maupun mengubah database produksi. Perbaikan harus masuk build aplikasi baru sebelum terlihat di HP.
- Permintaan dari APK lama yang tidak pernah menyimpan bukti transfer tidak dapat direkonstruksi otomatis. Periksa daftar dan fisik barang; jangan menebak ID lama dari kemiripan data.
- Jika izin dicabut atau dokumen/gudang tidak dapat diakses, pemulihan tetap mengikuti pemeriksaan server. Jangan hapus bukti hanya agar aksi baru bisa berjalan; perlukan petugas berwenang untuk memeriksa keadaan tersebut.
- Tes karakterisasi audit lama sengaja membuktikan perilaku sebelum perbaikan dan memakai fake yang dapat melewati wrapper baru. Gunakan tes recovery pada folder `test/` untuk regresi saat ini.
