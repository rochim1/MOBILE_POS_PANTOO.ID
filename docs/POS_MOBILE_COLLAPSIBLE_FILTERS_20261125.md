# Panel filter ringkas POS mobile — 25 November 2026

## Permintaan dan batas

Lanjutan perbaikan filter Transaksi: pindai halaman lain dan terapkan pola serupa pada kelompok filter yang menghabiskan ruang HP. Penyaringan dilakukan pada 43 berkas `*page.dart` langsung di `lib/presentation/pages/pos`, ditambah toolbar widget yang dipakai halaman tersebut. Ini audit tata letak filter, bukan audit ulang seluruh proses bisnis 43 halaman.

Kriteria: HP menampilkan tombol Filter; pilihan/isian tetap tersimpan ketika ditutup; daftar mendapat lebih banyak ruang; aksi operasional dan pemulihan tidak ikut disembunyikan; tablet/desktop tetap menampilkan filter. Tidak mengubah query, payload, hak akses, PIN, stok, jurnal, maupun bukti pembayaran.

## Hasil pemindaian dan penerapan

| Halaman/komponen | Perlakuan |
|---|---|
| Stok inventori | Pencarian, status stok dan lokasi dalam panel ringkas. Lokasi yang dipasangi target panduan tetap terlihat di luar panel, agar panduan tidak menunjuk kontrol tersembunyi. Riwayat tetap di luar panel. |
| Daftar dokumen inventori | Panel bersama untuk PO/pembelian, opname, transfer dan stok terbuang. Filter lanjutan lokasi/tanggal/alasan tetap tersedia di dalam panel. Tambah dan Isi Rak tetap terlihat. |
| Retur penjualan | Pencarian dan status diringkas; Tambah Retur dan pemulihan draft tetap terlihat. |
| Retur pembelian | Pencarian/status/filter alasan-metode-tanggal diringkas; Retur ke Supplier tetap terlihat. Dropdown status kini mengisi lebar yang tersedia, mengatasi overflow yang ditemukan pada tablet. |
| Promo | Pencarian dan status diringkas; Tambah tetap terlihat. |
| Riwayat shift | Pencarian dan status diringkas; controller pencarian dipertahankan agar teks tidak hilang ketika panel/list dibangun ulang. |
| Utang & Piutang / trade workspace | Pencarian dan sakelar termasuk lunas diringkas. Detail pembayaran, notifikasi dan bukti belum terkonfirmasi tidak ikut disembunyikan. |
| Piutang & Pelunasan invoice POS | Panel yang sama untuk pencarian dan sakelar termasuk lunas. Form penerimaan di detail invoice tidak diubah. Navigasi halaman menggunakan Wrap supaya tidak meluber pada layar sempit/teks besar. |
| Laporan bisnis | Kelompok periode/tanggal/sumber/pencarian diringkas. Ekspor, refresh, cakupan data dan pemberitahuan tetap terlihat. |
| Pengelolaan meja | Pencarian/urutan/status/lokasi/kapasitas diringkas. Cetak QR semua meja dan Tambah tetap di luar panel. Header kartu meja menggunakan Wrap karena ikon QR dan status meluber pada HP 320/390 dp. |
| Transaksi | Implementasi sebelumnya dipertahankan dan diuji ulang; tidak ditimpa. |

Dipertahankan karena sudah ringkas:

- Kasir/katalog produk, pelanggan dan outlet: pencarian cepat dengan filter popup, bukan banyak baris filter tetap.
- Pesanan aktif dan dapur: sudah memiliki filter mobile ringkas/popup; tidak ditambah lapisan tombol baru.
- Antrean offline: filter status satu baris horizontal. Status kesehatan antrean, tombol sinkronisasi dan pemulihan tetap terlihat karena penting untuk mencegah transaksi ganda.
- Laporan penjualan dan laba-rugi: satu pilihan periode/rentang yang sudah ringkas.
- Notifikasi: satu pilihan status; warehouse: satu pencarian dan tombol Tambah, bukan kelompok filter bertumpuk.

Tidak diperlakukan sebagai filter daftar: tambah/edit produk, impor, stok awal, pembelian langsung, penerimaan, pembayaran/utang PO, uang muka, editor/operasi transfer, pengembalian, onboarding, pengaturan, panduan setup, printer, scanner, pembayaran dan sukses, langganan, navigasi/shell/hub dan menu lainnya. Input wajib transaksi/konfigurasi tidak disembunyikan.

## Implementasi bersama

`lib/presentation/widgets/pos_collapsible_filters.dart` menyimpan state anak ketika panel ditutup (`Visibility.maintainState`). Kontrol tersembunyi dikeluarkan dari fokus/semantik, dan menutup panel melepaskan fokus keyboard. Toggle memiliki tinggi minimal 48 dp dan status expanded untuk aksesibilitas. Lencana menghitung filter nondefault/isian pencarian; menutup panel tidak mereset atau menerapkan ulang filter.

Breakpoint baru <600 dp berdasarkan viewport HP, bukan kolom desktop yang kebetulan sempit. Panel terbuka dibatasi maksimal 240 dp/35% tinggi yang tersedia dan dapat digulir sendiri. Tombol aksi menggunakan Wrap agar tetap muat. Pilihan periode/tanggal dan proses fetch tetap memakai handler lama. Filter Transaksi sebelumnya tetap menggunakan breakpoint 760 dp miliknya.

## Pengujian

TEST-POS-FILTERS-{STATE,RESPONSIVE,ACTIONS,TOUR,REGRESSION}-2511: unit/integration/widget; regression protection, critical path. Renderer dan widget halaman nyata; repository/bloc/transport jaringan terkontrol. Tidak ada write server/produksi atau pengujian Android native baru pada pekerjaan ini.

- RED komponen: `filter-scan-red.log` gagal karena komponen belum ada; checkpoint `3e82bb0`.
- RED halaman stok dan pembelian: 12 PASS/2 FAIL sebelum penerapan; `filter-scan-pages-red.log`, checkpoint `9909094`.
- Uji tambahan menemukan overflow header kartu meja dan dropdown status retur pembelian. Bukti kegagalan: `filter-scan-targeted4.log`; uji ulang diterima setelah perbaikan.
- Fixture piutang tambahan sempat salah constructor Response/nama operasi/typename; diperbaiki di test saja, bukan dengan melonggarkan client/cache. `filter-scan-receivable-green4.log` kemudian mereproduksi overflow navigasi halaman; perbaikan Wrap lulus pada `filter-scan-receivable-final.log`.
- Paket terarah awal: **61/61 PASS**, exit 0, `filter-scan-final.log`, 32 detik. Melindungi pencarian tersimpan, status/satuan pilihan, aksi tetap terlihat, tidak ada fetch karena toggle, resize, panduan lokasi, peralihan rak opname dan hak akses stok.
- Seluruh suite Flutter saat dijalankan: **1.175/1.175 PASS**, exit 0, `filter-scan-all-tests.log`, 3m28s. Berkas tes piutang tambahan dibuat setelah inventaris runner penuh dimulai; hasilnya dilaporkan terpisah, bukan dimasukkan ke angka 1.175.
- Uji piutang tambahan: **1/1 PASS**, exit 0, `filter-scan-receivable-final.log`. Memakai dokumen query asli; toggle tidak menambah request dan tidak membuka form penerimaan bagi pengguna baca-saja.
- Gabungan final sepuluh suite: **62/62 PASS**, exit 0, `filter-scan-complete.log`, 34 detik. Mencakup patch piutang terakhir setelah suite penuh selesai.
- Analisis 16 berkas utama bersih (`filter-scan-analyze-final.log`); halaman piutang dan dua tes tambahan juga bersih (`filter-scan-extra-analyze.log`). Satu lint kurung pada percobaan sebelumnya sudah diperbaiki.
- Cakupan komponen bersama pada paket terarah awal **50/50 baris executable (100%)**. Ini bukan cakupan seluruh halaman/aplikasi atau bukti E2E perangkat.

Semua log di `output/operational-readiness-20261125/`. Perintah utama:

```powershell
flutter test --no-pub --concurrency=2 --timeout 2m
flutter test --no-pub --concurrency=2 --timeout 30s --coverage --coverage-path=output/operational-readiness-20261125/filter-scan-final-lcov.info test/pos_collapsible_filters_test.dart test/pos_list_filter_pages_test.dart test/pos_stock_summary_layout_test.dart test/pos_inventory_route_context_test.dart test/pos_business_report_page_test.dart test/pos_trade_workspace_test.dart test/pos_return_refund_ui_test.dart test/pos_transaction_filter_collapse_test.dart test/pos_opname_stock_handoff_test.dart test/pos_receivable_filter_collapse_test.dart
```

## Batas rilis dan verifikasi perangkat

TEST-POS-FILTERS-DEVICE-2511 unverified. Tidak membangun APK/AAB atau menjalankan E2E emulator/perangkat baru. APK lama belum memuat perubahan ini. Untuk aplikasi development yang sedang berjalan, lakukan hot restart; untuk HP terpasang diperlukan APK berikutnya.

Langkah perangkat berikutnya: buka stok/PO/retur/promo/meja/riwayat shift/piutang/laporan, buka panel, pilih filter dan ketik pencarian, tutup/buka kembali; pastikan data tetap terfilter. Uji keyboard, teks besar, rotasi dan tombol Tambah/QR/pemulihan tetap dapat dijangkau. Bukan klaim kesiapan produksi seluruh profil bisnis.

## Evaluasi penyerahan

Keakuratan 4/5: hasil runner/analisis terukur, batas widget vs native dinyatakan; tindak lanjut verifikasi pada APK. Kelengkapan 4/5: 43 berkas disaring dan kelompok padat ditangani, bukan UAT semua kontrol; tindak lanjut daftar perangkat di atas. Kejelasan 4/5: matriks perubahan/pengecualian dan bukti dipisah; perbaikan berikutnya tambahkan tangkapan perangkat setelah rilis. Keterpakaian 4/5: perubahan siap dites dari source, APK perlu dibangun pada permintaan rilis. Keringkasan 4/5: laporan mengelompokkan layar alih-alih menyalin semua fungsi; ringkasan pengguna tetap singkat. Rata-rata 4,0/5, tidak ada kelemahan skor ≤3 yang ditutupi. Self-check: pengguna dapat membedakan implementasi selesai, tes terukur, dan verifikasi perangkat yang belum dilakukan.
