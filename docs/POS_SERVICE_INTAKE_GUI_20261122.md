# Uji GUI detail jasa adaptif — Android dan Vue web

Tanggal: 22 November 2026 (WIB). Sumber rancangan: [rencana detail jasa adaptif](../../docs/POS_SERVICE_INTAKE_ADAPTIVE_20261122.plan.md). Hasil otomatis sebelumnya tetap dicatat terpisah di [laporan implementasi](POS_SERVICE_INTAKE_ADAPTIVE_20261122.tdd.md).

## Ringkasan

**8/8 skenario utama GUI PASS setelah dua perbaikan.** Jasa langsung, pekerjaan, laundry dan reservasi dijalankan melalui tampilan aplikasi sampai pembayaran. Ini bukan klaim seluruh profil, seluruh metode pembayaran, offline, maupun seluruh siklus penyerahan sudah diuji GUI pada sesi ini.

- Android asli di emulator, bukan Flutter web; APK debug terbaru berisi perbaikan dialog jumlah.
- Vue web melalui Chrome yang sudah tersedia, bukan browser otomatis terpisah.
- Seluruh transaksi menggunakan tenant sintetis `QA Layanan Adaptif 2211`, Mongo replica set lokal terisolasi. Tidak ada transaksi/data usaha produksi yang diubah.
- Profil tenant adalah `jasa`; master produk memiliki override `none`, `work_order`, dan `laundry`. Ini menguji kebutuhan detail per produk, bukan matriks seluruh preset profil bisnis.
- 10 transaksi dibuat melalui GUI (8 skenario utama + 2 pengulangan jasa langsung setelah perbaikan antrean). Total Rp109.000; 10 jurnal posted, masing-masing satu per transaksi dan seimbang.

## Matriks GUI

| ID | Platform / alur | Langkah dan hasil aktual | Hasil / bukti |
| --- | --- | --- | --- |
| W1 | Web — jasa langsung | Pilih jasa Rp5.000, pilih pelanggan, uang pas, bayar. Tidak ada objek/keluhan/teknisi/jadwal wajib. Ulang setelah perbaikan: transaksi lunas tanpa order pekerjaan otomatis. | PASS — `INV-20261122-0001`, ulang `0007`; transaksi ulang tidak memiliki `source_order_id`. |
| A1 | Android — jasa langsung | Katalog → keranjang → pembayaran → pelanggan → uang pas. Tidak ada form servis atau jadwal. Ulang pada server terbaru untuk membuktikan antrean tidak dibuat. | PASS — `INV-20261122-0003`, ulang `0010`; [bukti ulang](../../output/service-intake-gui-20261122/android-direct-retest-paid.png). |
| W2 | Web — pekerjaan | Isi objek `Motor QA WEB 2211` dan catatan sekali di kasir. Batalkan konfirmasi pesanan, ulang: data tetap terisi. Buat pesanan `ORD-20261122-0002`, buka Pesanan Layanan, bayar tunai; tidak ada form pekerjaan kedua. Teknisi tidak wajib. | PASS — `INV-20261122-0002`; objek dan catatan tersimpan. |
| A2 | Android — pekerjaan | Pilih pekerjaan Rp10.000, pelanggan, uang pas. Saat proses bayar muncul satu form pekerjaan. Isi `Motor-QA-Android-2211`, simpan; langsung berhasil tanpa form/jadwal tambahan. | PASS — `INV-20261122-0006`; [form](../../output/service-intake-gui-20261122/android-work-form.png), [lunas](../../output/service-intake-gui-20261122/android-work-paid.png). |
| W3 | Web — laundry campuran | Ubah kiloan menjadi 3,5 kg dan satuan menjadi 2 pcs. Buka detail opsional: ringkasan mengikuti keranjang, bukan input berat kedua. Bayar Rp24.500. | PASS — `INV-20261122-0004`; baris tersimpan `per_kg=3.5` dan `per_item=2`. |
| A3 | Android — laundry campuran | Awalnya gagal saat menerapkan berat; diperbaiki lalu diulang pada APK baru. Terapkan 3,5 kg dan 2 pcs, pelanggan, uang pas, bayar tanpa form berat ulang. | PASS setelah perbaikan — `INV-20261122-0008`; [lunas](../../output/service-intake-gui-20261122/android-laundry-paid.png). |
| W4 | Web — reservasi | Pilih Reservasi, pelanggan, jadwal 23 Nov 2026 pukul 10.00–11.00 WIB sekali di kasir, bayar Rp5.000. Tidak muncul permintaan jadwal kedua. | PASS — `INV-20261122-0005` / `ORD-20261122-0005`; server menyimpan `03:00Z–04:00Z`. |
| A4 | Android — reservasi + pekerjaan | Nota jasa langsung + pekerjaan Rp15.000. Form tunggal memuat jadwal dan objek. Simpan kosong tidak melanjutkan. Isi 23 Nov 18.30 WIB, selesai default 20.30, objek `Reservasi-Motor-Android-2211`. Batalkan konfirmasi lalu lanjut: form tidak ditanya ulang. Buat order, lanjut pembayaran order tersebut sampai lunas. | PASS — `INV-20261122-0009` / `ORD-20261122-0008`; [form gabungan](../../output/service-intake-gui-20261122/android-reservation-form.png), [hasil pelunasan](../../output/service-intake-gui-20261122/android-reservation-paid.png). |

Konfirmasi “Simpan reservasi dan lanjutkan pembayaran?” adalah persetujuan membuat order, bukan form jadwal kedua. Android tetap memakai dua tahap yang aman: order reservasi disimpan terlebih dahulu, lalu dibayar. Pilihan nominal diterima pada halaman awal belum dibawa ke pembayaran order; pengguna menekan uang pas lagi. Tidak ada input ulang jadwal/objek, tetapi penyederhanaan nominal ini masih peluang peningkatan UX.

## Temuan dan perbaikan

### 1. Android: layar merah setelah mengubah jumlah

Reproduksi nyata: edit jumlah laundry → 3.5 → tutup keyboard → Terapkan. Exception pertama adalah `A TextEditingController was used after being disposed` pada `pos_cart_panel.dart`; `_dependents.isEmpty` hanya error susulannya.

Penyebab: controller dibuang segera setelah hasil dialog diterima, padahal widget dialog masih terpasang selama animasi keluar/perubahan keyboard. Perbaikan: field jumlah dan harga biasa memiliki state/controller internal lewat `TextFormField`; hasil teks tetap ditampung untuk validasi tanpa membuang controller milik route terlalu awal. Perubahan tidak mengubah aturan jumlah, harga minimum, atau izin edit harga.

- RED: dua tes widget apply/cancel mereproduksi error yang sama dengan Android. Checkpoint `ccb9675`.
- GREEN: `2145896`; tes jumlah, harga fleksibel dan pembatalan lolos.
- Tambahan akhir: empat tes lifecycle jumlah/harga + regresi harga fleksibel/satuan: **17 PASS**, cakupan baris `pos_cart_panel.dart` **129/147 = 87,8%**. Ini cakupan file tersebut, bukan seluruh aplikasi.
- Uji ulang GUI pada APK perbaikan: kedua jumlah diterapkan dan pembayaran laundry berhasil. Log proses aplikasi terbaru tidak berisi exception Flutter yang dicari.

### 2. Server: metadata jasa umum dianggap pekerjaan tertunda

GUI menemukan jasa langsung lunas masuk kolom Diterima sebagai pekerjaan. Penyebab: setiap snapshot `service_order` memicu order operasional, termasuk baris generik `object_type=jasa`.

Perbaikan membedakan metadata penjualan jasa generik dari pekerjaan/laundry nyata. Jasa langsung generik lunas tidak membuat antrean baru. Pekerjaan/laundry, reservasi, dine-in/delivery, dapur, dan kompatibilitas snapshot lama tetap dipertahankan. Baris baru diklasifikasikan dari master server, bukan dipercaya dari flag klien.

- RED: `df0ed952`, assertion pembayaran generik tidak boleh membuat `source_order_id` gagal sesuai temuan GUI.
- GREEN: `acd659cb`, **11 tes integrasi PASS** (tunai/tempo, order/retry, jadwal, validasi pekerjaan, per objek).
- GUI ulang: web `0007` dan Android `0010` lunas, tanpa `source_order_id` baru.
- Order QA historis yang terbentuk sebelum perbaikan tidak dihapus atau ditulis ulang; karena itu audit berisi 8 order untuk 10 transaksi, bukan hanya order pascaperbaikan.

## Rekonsiliasi hasil GUI

Verifier read-only memeriksa hasil GUI, bukan membuat pembayaran pengganti:

```text
node scripts/qa_service_intake_gui_audit_20261122.cjs verify-gui
PASS: 10 GUI sales, 8 linked orders, 10 single balanced posted journals,
exact laundry units, preserved objects/schedules, no post-fix direct queue;
cash movement 109000 + opening 100000 = 209000.
```

- Setiap nomor invoice unik; setiap transaksi lunas memiliki tepat satu jurnal posted dengan debit = kredit = total transaksi.
- Kuantitas laundry web/Android sama persis; tidak terjadi pengalian berat kedua.
- Objek pekerjaan, jadwal reservasi dan total tetap tersimpan setelah pembayaran.
- Shift terbuka mencatat 10 transaksi dan mutasi tunai Rp109.000. Saldo teoritis dengan modal awal Rp100.000 adalah Rp209.000. Shift **tidak ditutup melalui GUI** pada pengujian ini. `closing_cash_expected` selama shift terbuka menyimpan mutasi, modal awal ditambahkan saat penutupan sesuai resolver.
- Semua barang uji yang dijual adalah jasa non-stok; pengurangan stok barang fisik tidak menjadi bukti sesi ini.

## Pemeriksaan kode dan artefak

Perintah benar-benar dijalankan:

```text
node --test tests/pos_service_fulfillment.integration.test.js
11 PASS

flutter test test/pos_cart_dialog_lifecycle_test.dart test/pos_flexible_service_test.dart test/pos_cart_units_test.dart --no-pub --coverage --coverage-path=../output/service-intake-gui-20261122/cart-dialog-lcov.info --reporter expanded
17 PASS

flutter analyze lib/presentation/pages/pos/widgets/pos_cart_panel.dart test/pos_cart_dialog_lifecycle_test.dart
No issues found
```

Artefak lokal:

- [Audit hasil GUI](../../output/service-intake-gui-20261122/audit-latest.json), [verifikasi hasil](../../output/service-intake-gui-20261122/gui-reconciliation.log).
- [RED antrean](../../output/service-intake-gui-20261122/queue-red.log), [GREEN antrean](../../output/service-intake-gui-20261122/queue-green.log).
- [RED dialog](../../output/service-intake-gui-20261122/cart-dialog-red.log), [regresi dan coverage akhir](../../output/service-intake-gui-20261122/cart-dialog-coverage.log), [analisis](../../output/service-intake-gui-20261122/analyze.log).
- APK debug khusus QA: `build/app/outputs/flutter-apk/app-qaservice-debug.apk`, package `id.pantoo.pos.qa.service`. Tidak mengubah data package produksi/staging/QA lama dan tidak menguji integrasi Firebase/push.
- Fixture: `presensi_zera_BE/scripts/qa_service_intake_gui_20261122.cjs`. Pengaman eksplisit `POS_SERVICE_GUI_QA=1`, bind loopback, database QA tertentu, tanpa `.env` produksi/email eksternal. Server pembaruan menempel ke database QA sama, tidak menyemai ulang transaksi.

## Batas verifikasi / tindak lanjut

- Tidak mengulang GUI offline/respons hilang, piutang/cicilan, refund, pencabutan izin, multi kasir, printer fisik, atau seluruh variasi profil inventori di sesi ini. Bukti otomatis lama tidak disamakan dengan GUI baru.
- Penyelesaian pekerjaan/laundry sampai penyerahan fisik dan siklus reservasi datang/tidak hadir/batal tidak diulang GUI; yang PASS di sini ialah pengisian, pembuatan pesanan yang diuji, dan pembayaran tanpa form berulang.
- Web diuji desktop Chrome; audit mobile viewport Vue, perbandingan visual otomatis, aksesibilitas menyeluruh, dan Core Web Vitals belum dilakukan.
- Ada campuran bahasa pada label form reservasi dalam locale Inggris, serta badge keranjang Android menjumlahkan angka kg+pcs (mis. 5.5), bukan jumlah baris. Keduanya tidak memengaruhi total/transaksi, tetapi belum dirapikan pada sesi ini.
- Emulator sempat ANR dan build pertama kehabisan memori host. Pengujian diulang setelah pemulihan; bukan ditandai sebagai bug transaksi. Flutter web lama dihentikan hanya setelah izin pengguna; tidak ada penghapusan data aplikasi. Batas memori build sementara dikembalikan ke konfigurasi awal setelah APK selesai.
- Backend perlu diperbarui bersama client; perubahan ini belum dideploy produksi. Hasil ini bukan sertifikasi “seluruh POS siap produksi”.

## Evaluasi hasil

| Aspek | Nilai | Bukti dan batas |
| --- | --- | --- |
| Ketepatan | 5/5 | GUI, nomor invoice dan rekonsiliasi read-only saling cocok; kegagalan awal tidak disembunyikan. |
| Kelengkapan | 4/5 | Delapan alur utama dijalankan; penyerahan dan kondisi offline tidak diklaim sebagai GUI PASS. |
| Kejelasan | 4/5 | Matriks memisahkan platform dan bukti; detail teknis tetap diperlukan untuk reproduksi. |
| Dapat ditindaklanjuti | 4/5 | Perbaikan, tes dan artefak tersedia; deploy produksi tetap langkah terpisah. |
| Keringkasan | 4/5 | Ringkasan singkat tersedia; bukti rinci sengaja disimpan di laporan ini. |

Rata-rata 4,2/5. Peningkatan berikutnya: bawa nominal pembayaran saat reservasi menjadi order, rapikan label/badge, dan uji GUI penyerahan. Penilaian ini bukan ukuran kesiapan produksi.
