# Perapian UI Operasional POS — 27 November 2026

## Ringkasan

Shift Kasir, Retur Penjualan/Pembelian, Pelanggan, dan Laporan pada aplikasi Flutter POS telah dirapikan mengikuti pola Inventori: kartu putih berbingkai tipis, aksen teal, ringkasan lebih ringkas, pencarian selalu terlihat, serta filter tambahan yang tidak mengambil ruang utama di HP.

Hasil akhir: **171 pengujian otomatis lulus**, analisis pada **13 berkas tanpa masalah**, dan pemeriksaan whitespace diff bersih. Tidak ada build APK/AAB, deploy, maupun perubahan data produksi dalam pekerjaan ini. Ini bukan klaim seluruh aplikasi sudah lulus E2E perangkat/server nyata.

## Perubahan per halaman

| Area | Perapian | Perlindungan alur |
|---|---|---|
| Shift aktif | Kartu metrik memakai mode ringkas; tombol Kas Masuk, Kas Keluar, dan Tutup Shift lebih cepat dijangkau. | Perhitungan kas, identitas operator PIN, kepemilikan outlet, dan mutasi buka/tutup shift tidak diubah. |
| Riwayat shift | Pencarian selalu tersedia; status dapat dibuka melalui tombol filter. | Menutup filter tidak menghapus pencarian atau memicu mutasi. |
| Retur penjualan | Toolbar seragam, aksi tambah responsif, kartu putih, nomor/status/nilai menyesuaikan lebar layar. | Hak akses, konfirmasi refund, identitas draft, dan pemulihan respons hilang dipertahankan. |
| Retur pembelian | Satu panel filter berisi status/alasan/penyelesaian/tanggal; tidak ada dua lapisan filter. Di HP, tanggal ditumpuk dan panel dapat digulir. | Batal tidak mengubah filter aktif; Terapkan mengirim satu kombinasi filter. Rentang tanggal terbalik ditolak. Respons pencarian lama diabaikan. |
| Pelanggan | Pencarian dan filter sejajar; tombol Tambah satu baris tersendiri di HP dan sejajar di layar lebar. Kartu pelanggan konsisten dengan Inventori. | Penjagaan pembukaan form ganda tetap berlaku. Validasi dan penyimpanan tidak diubah. Loading form tetap berada di modal, bukan berputar terus di halaman belakang. |
| Laporan penjualan/bisnis | Ringkasan dan skeleton lebih ringkas; jenis laporan berupa dropdown; bantuan panjang dapat dibuka sesuai kebutuhan. Pencarian tetap terlihat. | Periode/cutoff, cakupan data, keterangan bukti belum lengkap, hak ekspor, serta validasi identitas/fingerprint ekspor tetap dipertahankan. Nilai belum tersedia tetap “—”, bukan nol. |

Komponen bersama baru: `lib/presentation/widgets/pos_operational_toolbar.dart`. Tombol filter berukuran 48 logical pixel; aksi utama dipindah ke bawah pada lebar di bawah 680 atau pembesaran teks di atas 1,3. Filter internal mempertahankan isian saat ditutup dan tidak menerima fokus ketika tersembunyi.

## Temuan yang diperbaiki saat pengujian

1. Dropdown filter retur pembelian meluap pada HP kecil: dibuat melebar mengikuti ruang dan tanggal ditumpuk pada lebar kecil.
2. Respons pencarian retur pembelian yang lambat dapat menimpa hasil pencarian baru: ditambahkan penanda generasi permintaan, termasuk saat halaman dilepas.
3. Spinner tombol Tambah Pelanggan tetap hidup selama modal terbuka: dihapus dari halaman belakang; tombol tetap dinonaktifkan agar tidak membuka form ganda. Indikator pemuatan/penyimpanan modal tetap tersedia.
4. Skeleton kartu ringkas masih menghabiskan tinggi yang tersedia: ukuran kolom disesuaikan agar mode ringkas benar-benar setinggi 92 logical pixel untuk fixture pengujian.
5. Baris nilai retur meluap pada lebar 320 dengan bahasa Inggris dan teks 140%: diubah menjadi layout yang dapat membungkus; judul nomor diberi ruang fleksibel.
6. Label rentang laporan persediaan berpotensi menyiratkan periode pergerakan: sekarang menampilkan posisi per tanggal untuk laporan cutoff.

## Bukti pengujian

### Matriks tampilan

- Lebar 320, 390, dan 800 logical pixel.
- Bahasa Indonesia dan Inggris.
- Skala teks 100% dan 140%.
- 48 kombinasi utama: Pelanggan, Shift aktif, Retur penjualan, dan Laporan bisnis.
- Pengujian filter tambahan mencakup Retur pembelian dan Riwayat shift pada ketiga lebar, termasuk pencarian yang bertahan setelah filter ditutup.
- Pengujian interaksi: cari pelanggan melalui telepon, filter level harga, tambah/simpan pelanggan tepat satu kali; batal/terapkan filter supplier; respons pencarian supplier tiba tidak berurutan.
- Penangkapan sembilan gambar fixture lokal; gambar HP untuk shift, retur, pelanggan, laporan, dan form pelanggan telah diperiksa secara visual.

### Regresi alur operasional

Satu eksekusi gabungan atas 20 berkas berikut menghasilkan **171 PASS / 0 FAIL**:

```text
test/pos_shift_cash_test.dart
test/pos_shift_close_refresh_test.dart
test/pos_shift_outlet_recovery_test.dart
test/pos_shift_guide_test.dart
test/pos_cashier_shift_sync_test.dart
test/pos_list_filter_pages_test.dart
test/pos_return_refund_ui_test.dart
test/pos_return_process_recovery_test.dart
test/pos_return_draft_repository_test.dart
test/pos_return_draft_request_store_test.dart
test/purchase_return_contract_test.dart
test/pos_customer_form_validation_test.dart
test/pos_customer_payment_contract_test.dart
test/pos_quick_customer_open_test.dart
test/pos_business_report_page_test.dart
test/pos_business_report_test.dart
test/pos_financial_report_test.dart
test/pos_metric_card_test.dart
test/pos_report_profit_loss_navigation_test.dart
test/pos_operational_inventory_theme_test.dart
```

Regresi mencakup perhitungan kas awal, penutupan dan penyegaran shift, perlindungan outlet/operator, sinkronisasi kasir ke shift aktif, loading/konfirmasi refund, pemulihan proses/draft retur saat respons hilang, kontrak retur pembelian, validasi pelanggan, navigasi laporan, izin ekspor, dan kondisi bukti laporan tidak tersedia. Pengujian ini menggunakan fixture/fake; bukan mutasi ke server produksi.

Analisis kode pada 10 berkas implementasi dan 3 berkas pengujian yang berubah: **No issues found**. Perintah `git diff --check` untuk berkas terkait juga lulus.

### Gambar hasil

Disimpan di `output/operational-ui-20261127/`:

- `shift-390-id.png`, `shift-800-id.png`
- `return-390-id.png`, `return-800-id.png`
- `customer-390-id.png`, `customer-800-id.png`
- `customer-create-390-id.png`
- `report-390-id.png`, `report-800-id.png`

## Batas pengujian dan tindak lanjut

- Implementasi ini pada Flutter POS. Tidak ada perubahan Vue web atau server dalam lingkup perapian ini.
- Belum dilakukan smoke test pada emulator/HP Android nyata di pekerjaan ini; pengujian tampilan menggunakan renderer widget Flutter dengan ukuran layar dan pembesaran teks di atas.
- Belum menguji keyboard OEM, navigasi sistem Android, printer, atau mutasi server sungguhan untuk perubahan ini. Aturan bisnis yang bersinggungan diperiksa melalui regresi otomatis yang disebutkan, bukan dianggap terbukti untuk seluruh konfigurasi produksi.
- Langkah berikut yang aman: smoke test perangkat untuk buka/tutup filter, tambah pelanggan, detail retur, serta kas masuk/keluar dan penutupan shift pada akun QA. APK/AAB tidak dibuat karena tidak diminta pada tugas ini.

## Evaluasi hasil

Nilai keseluruhan 4,0/5. Tidak ada masalah kritis yang tersisa dari pengujian otomatis; verifikasi perangkat nyata masih menjadi batas bukti.

| Aspek | Nilai | Bukti / peningkatan berikutnya |
|---|---|---|
| Ketepatan | 4/5 | 171 PASS dan analyzer bersih; tambahkan pembuktian pada perangkat/server QA nyata. |
| Kelengkapan | 4/5 | Empat area dan kedua jenis retur tercakup; keyboard serta navigasi OEM belum diuji langsung. |
| Kejelasan | 4/5 | Pola toolbar/kartu seragam dan periode laporan terlihat; validasi kenyamanan dengan pengguna kasir tetap bermanfaat. |
| Dapat ditindaklanjuti | 4/5 | Implementasi, daftar tes, dan gambar tersedia; paket aplikasi belum dibangun sesuai lingkup tugas. |
| Keringkasan | 4/5 | Komponen toolbar dipakai bersama; beberapa dekorasi input lokal tetap dipertahankan agar perubahan tidak melebar. |

Prioritas peningkatan: smoke test HP Android QA, terutama panel filter dengan keyboard terbuka dan teks diperbesar. Penilaian ini dapat ditinjau dari bukti yang tersedia, bukan pernyataan siap produksi secara menyeluruh.
