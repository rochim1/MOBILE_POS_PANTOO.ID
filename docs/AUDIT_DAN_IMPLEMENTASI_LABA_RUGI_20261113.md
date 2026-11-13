# Audit sumber data dan implementasi awal laba rugi

Tanggal: 13 November 2026. Scope implementasi: audit sumber, fondasi laporan, dan laba rugi mobile. Rencana induk: [laporan UMKM](RENCANA_LAPORAN_UMKM_MOBILE_POS_20261113.md). Kontrak backend: [POS profit/loss](../../presensi_zera_BE/docs/pos-profit-loss-report.md).

## Hasil audit

Audit ini memeriksa kode, kontrak, dan data fixture pada database uji sementara. Tidak ada koneksi atau perubahan terhadap data produksi. Kelengkapan pembukuan usaha tertentu belum dinyatakan terverifikasi.

| Sumber | Bukti kode | Temuan dan keputusan implementasi |
| --- | --- | --- |
| Pendapatan/diskon/pajak | `finance_journal.service.js`, `GetProfitLoss` Finance | Gunakan jurnal posted; jangan mengurangi diskon/retur lagi dari pendapatan neto jurnal |
| HPP barang dan BOM | Snapshot `valuation_cost_total`, `harga_pokok`, `qty_base`, `component_consumptions`; jurnal `pos_sales_cogs` | Tidak memakai harga katalog terbaru; audit ketiadaan/perbedaan jurnal ketika biaya historis positif diketahui |
| Retur | `sales_return` dan jurnal pembalik pendapatan/HPP | Nilai bertanda dipertahankan; retur tidak dihitung dua kali |
| Biaya operasional | Akun beban Finance dan jurnal posted, termasuk biaya/penggajian/penyusutan yang sudah dicatat | Data yang belum dicatat tidak dapat diketahui dari POS; disclaimer kelengkapan selalu terlihat |
| Kas keluar shift | Operasi kas shift, bukan klasifikasi biaya Finance | Tidak disamakan dengan biaya operasional atau dihitung sebagai pengurang laba secara otomatis |
| Pemetaan akun | COA `account_type`, `account_category`, seeded system accounts | Kategori eksplisit dipakai; akun custom yang tidak dikenal tetap terlihat untuk ditinjau |
| Scope | Report Finance gabungan `instansi_id` | Tahap awal hanya seluruh instansi dengan izin Finance. Bukan laporan toko aktif |
| Hak akses | `finance_reports.view`; rincian buku besar `ledger.view` | Tidak memberikan izin baru atau melewati izin Finance pada operator POS |
| Tanggal | Layanan laporan Finance memakai batas hari WIB | Filter mobile mengikuti tanggal bisnis yang dikirim server, maksimum 366 hari |
| Offline/cache | Data akuntansi sensitif dan izin operator dapat berubah | Tahap awal online/noCache, tanpa estimasi atau snapshot keuangan persisten |

## Fondasi yang diterapkan

- Model rentang tanggal, konteks instansi, opsi laporan, rincian akun, masalah data, serta entri jurnal.
- Repository laporan keuangan tersendiri; setiap request memakai `FetchPolicy.noCache`.
- Cubit dengan pengabaian respons lama, validasi instansi/periode respons, serta state akses ditolak/error/loading terpisah.
- Filter hari ini, 7 hari, bulan ini, bulan lalu, dan rentang tanggal khusus.
- Panel laporan direset pada pergantian instansi, operator, lock, konteks GraphQL, atau konfigurasi izin yang teramati.
- Rincian jurnal memakai API buku besar yang sudah ada, 20 entri per halaman, dan tetap memerlukan izin buku besar.
- Angka lama dihapus ketika request baru dimulai atau gagal. Tidak ada nilai fallback nol untuk field laporan yang hilang.

## Fitur pengguna

Buka **Report → Laba Rugi**. Laporan menampilkan cakupan seluruh usaha, periode, sumber jurnal, dan waktu pembaruan dalam WIB.

Kartu utama: penjualan bersih, HPP, laba kotor tercatat, dan laba/rugi tercatat. Rincian membedakan HPP, biaya operasional, pendapatan/beban lain, serta akun yang belum dipetakan. Ketuk kelompok, kemudian akun, untuk membaca jurnal sumber. Desain menggunakan komponen statistik bersama POS.

Jika HPP belum dapat dipastikan, kartu terkait menampilkan tanda tidak tersedia, bukan angka nol. Biaya/transaksi yang belum dicatat atau belum posted tidak tersirat sudah termasuk. Total pendapatan/beban jurnal tetap ditampilkan untuk rekonsiliasi dengan Finance web.

Bahasa Indonesia dan Inggris tersedia melalui ARB dan generator l10n yang sudah ada.

## Kriteria penerimaan dan bukti

- Pendapatan, HPP, beban, dan laba sesuai hasil layanan Finance untuk periode/instansi yang sama.
- Diskon, retur, pembalikan biaya, biaya historis akun nonaktif, hari terakhir WIB, dan organisasi berbeda diperiksa dengan fixture database.
- HPP belum dipetakan, jurnal HPP hilang, selisih biaya, jurnal draf, dan klasifikasi belum lengkap tampil sebagai keterbatasan.
- Rentang terbalik/tidak valid/masa depan/lebih dari 366 hari ditolak.
- Akses laporan penjualan tidak otomatis memberi akses laporan keuangan.
- Respons lambat tidak menimpa periode baru; pergantian klien/sesi dan respons instansi lain tidak menampilkan data lama.
- UI diuji pada ponsel sempit; akun dan rincian jurnal dapat dibuka tanpa memuat semua jurnal sekaligus.

Perintah verifikasi mobile:

```powershell
flutter test test/pos_financial_report_test.dart test/pos_financial_report_repository_test.dart test/pos_profit_loss_page_test.dart test/pos_report_profit_loss_navigation_test.dart test/pos_metric_card_test.dart
```

Backend dan pengujian regresi mengikuti [kontrak backend](../../presensi_zera_BE/docs/pos-profit-loss-report.md#verification). Semua pengujian integrasi menggunakan database sementara. Pemeriksaan visual menggunakan data fixture, bukan angka usaha pengguna.

## Batas rilis awal

- Scope per toko/cabang belum diaktifkan karena filter server dan atribusi pendapatan/beban menyeluruh belum tersedia pada kontrak ini.
- Audit sumber masih terbatas: belum membuktikan kelengkapan seluruh vendor bill, payroll, pajak, biaya belum dicatat, atau histori lama tanpa snapshot.
- Belum menambahkan input biaya baru, memperbaiki jurnal lama, mengubah COA otomatis, atau memigrasikan data.
- Arus kas, aging piutang/utang, persediaan historis, snapshot offline, dan ekspor laporan baru tetap merupakan tahap berikutnya dalam rencana.
- Belum dilakukan deploy atau pengujian data usaha produksi. Backend harus dirilis sebelum aplikasi mobile yang memakai query baru.

## Catatan perubahan dan pemulihan

Pemilik perhitungan tetap modul Finance; mobile hanya konsumen tambahan. API Finance lama tidak diubah perilakunya. Tidak ada migrasi database atau perubahan saldo. Rollback dilakukan dengan mengembalikan entry laporan mobile dan dua query backend tambahan; tidak memerlukan pembalikan transaksi bisnis.

## Hasil verifikasi increment ini

- 21 pengujian mobile pada lima berkas di atas lulus, termasuk navigasi kategori Report dan penghapusan angka pemilik saat operator berganti.
- 26 kasus backend unik lulus pada suite laba rugi baru, konsistensi Finance, batas periode, kontrak GraphQL, serta permission/authentication. Beberapa suite dijalankan ulang selama perbaikan; angka ini tidak menghitung pengulangan.
- Analisis Dart pada kode/model/repository/state/UI dan pengujian baru: tidak ada masalah.
- Query mobile divalidasi terhadap schema GraphQL backend lengkap.
- Pemeriksaan visual dilakukan pada ukuran ponsel dengan data fixture; data produksi dan performa pada volume produksi belum diuji.


Kelanjutan arus kas, aging, persediaan dan ekspor telah ditambahkan setelah increment awal ini. Lihat [implementasi lanjutan](IMPLEMENTASI_LAPORAN_LANJUTAN_20261113.md) untuk status terkini dan batas rilis.
