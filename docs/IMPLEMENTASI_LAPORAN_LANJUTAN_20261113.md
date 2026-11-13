# Implementasi laporan lanjutan — 13 November 2026

Status: kandidat rilis Android 1.0.8+9 sudah dibangun; UAT Android dan rekonsiliasi staging selesai. Deployment produksi belum dilakukan. Lihat [kesiapan rilis terkini](KESIAPAN_RILIS_LAPORAN_ANDROID_20261113.md).

## Hasil

| Kelompok | Implementasi |
| --- | --- |
| Audit, fondasi, laba rugi | Increment sebelumnya; ditambah izin ekspor dan fingerprint data laporan |
| Arus kas | Saldo awal/akhir, bruto masuk/keluar dari net per jurnal, aktivitas operasi/investasi/pendanaan/belum dipetakan, selisih rekonsiliasi dan rincian berpaginasi |
| Piutang dan utang | Cutoff historis dari replay jurnal, saldo terbuka, jatuh tempo, kelompok umur, pembayaran/kredit/potongan pajak, pengecualian sumber, pencarian dan pilihan invoice POS untuk piutang |
| Persediaan | Valuasi historis beserta pembanding buku/selisih, saldo awal/akhir dan pergerakan kuantitas yang dapat dibuktikan, serta daftar restok terkini |
| Ekspor | CSV UTF-8 BOM dan PDF/share; memeriksa ulang izin, seluruh hasil filter dan fingerprint sebelum membuat berkas |
| Konsistensi UI | Semua ringkasan memakai PosMetricCard/PosMetricGrid; tanggal WIB, skeleton, error, akses ditolak dan nilai tidak tersedia dibedakan |

Navigasi Report mempunyai Laba Rugi, Arus Kas, Piutang & Utang, serta Persediaan. Tab Persediaan mencakup valuasi, pergerakan dan restok. Detail invoice POS dan PO pembelian memakai halaman operasional yang sudah ada apabila sumber tersebut dapat ditautkan. Tombol bernama **Buka dokumen terkini**: dokumen yang dibuka mengikuti kondisi saat ini, sedangkan angka laporan tetap mengikuti cutoff. Laporan tidak otomatis mencatat pembayaran. Sumber lain tetap menampilkan referensi dan rincian di dalam laporan; belum semua dokumen Finance mempunyai halaman detail mobile.

## Kontrak dan akses

- `GetPOSBusinessReport` berada di modul Finance backend. Jenis: `cash_flow`, `receivables`, `payables`, `inventory`, `movement`, `restock`.
- Scope rilis awal hanya gabungan instansi, online tanpa cache persisten. Pergantian instansi/operator/klien GraphQL membuang state lama; respons terlambat dan respons beda filter/instansi ditolak.
- Semua laporan memerlukan `finance_reports.view`; ekspor juga `finance_reports.export`. Aging tetap memerlukan `receivables.view` atau `payables.view`. Valuasi/mutasi memakai izin sumber histori (`journal.view`). Restok memerlukan `inventory_reports.view` dan akses seluruh lokasi. Tidak ada pemberian role otomatis.
- Server memvalidasi tanggal kalender, periode maksimum 366 hari, masa depan, sumber dan pagination. Ringkasan memakai seluruh hasil filter, bukan halaman aktif.
- Default 20 baris/halaman, maksimum 100. Ekspor meminta seluruh baris dengan sidik data yang sama. CSV maksimum 5.000 baris, PDF maksimum 1.000 baris. Kelebihan batas atau perubahan data menampilkan kegagalan yang jelas; tidak dipotong diam-diam.
- CSV mempertahankan null sebagai kosong, angka sebagai numerik, quotes/newline dan Unicode; teks yang dapat menjadi formula spreadsheet dinetralkan. PDF menggunakan font Roboto berlisensi Apache yang dibundel, tanpa mengambil font dari internet. Karakter di luar dukungan font meminta pengguna memilih CSV sehingga nama tidak hilang.

## Batas data yang disengaja

1. Arus kas mengikuti akun kas/bank dan jurnal Finance; transfer kas internal tidak menggandakan masuk/keluar. Jika jurnal campuran tidak dapat dipisah secara pasti, bruto masuk/keluar tidak ditampilkan sebagai angka pasti.
2. Aging memakai layanan historis Finance yang sama dengan web. Sumber yang tidak memiliki bukti lengkap dikecualikan dan jumlah pengecualiannya terlihat. Jatuh tempo legacy historis yang dapat berubah masuk kelompok tidak diketahui. Total merupakan total sumber yang didukung, bukan klaim seluruh tagihan usaha lengkap.
3. Valuasi historis memakai snapshot dan histori stok yang sudah tersedia. Tanpa bukti, nilai tidak diganti dengan stok/harga katalog terkini. Mutasi memerlukan baseline live yang sama dan rantai event terpercaya, dibatasi 20.000 event; jika tidak dapat dibuktikan, coverage tidak diketahui. Tidak membuat baseline sintetis atau mengubah data historis.
4. Restok hanya posisi hari ini dan produk stok aktif; tidak dianggap valuasi historis. Kuantitas antar satuan berbeda tidak dijumlahkan sebagai satu angka usaha.
5. Belum tersedia pemilihan toko/lokasi atau snapshot offline keuangan. Tidak membagi angka gabungan ke toko secara perkiraan. Pengguna harus memiliki akses gabungan yang sesuai.
6. Belum menambahkan formulir jurnal/biaya baru, neraca, perhitungan pajak, atau memperbaiki data Finance usaha secara otomatis. Biaya yang belum dicatat tetap menjadi keterbatasan laba rugi.

## Verifikasi

- Rangkaian mobile: 28 pengujian lulus, meliputi state/filter/instansi, izin, repository tanpa cache, navigasi laporan, nominal tidak tersedia, ponsel 360 px, teks diperbesar, dua bahasa, CSV dan PDF. Setelah penambahan tautan sumber dilakukan pemeriksaan ulang halaman yang berubah.
- Backend: 51 pengujian pada rangkaian gabungan lulus, termasuk adapter AP dan tautan sumber. Cakupan: laporan Finance pembanding, cutoff, reversal/kredit, kas internal, bukti stok, ringkasan lintas halaman, ekspor/fingerprint, tenant isolation, izin dan autentikasi.
- Kontrak seluruh query GraphQL mobile divalidasi terhadap schema backend lengkap.
- PDF contoh 70 baris dirender menjadi empat halaman dan diperiksa; baris terakhir dan metadata ikut tersimpan. Artefak QA berada di `../output/pantoo-report-export-qa.pdf`, bukan data usaha nyata.
- Pemeriksaan kode Dart tidak menemukan masalah; pemeriksaan whitespace perubahan bersih.

Pengujian tahap awal memakai fixture dan basis data sementara. Kelanjutan telah menyelesaikan UAT Android dengan API staging serta share sheet asli; bukti terbaru ada di dokumen kesiapan rilis. Verifikasi iOS dan data usaha produksi belum dilakukan.

## Urutan rilis dan pemulihan

Deploy backend yang memuat kontrak baru terlebih dahulu, kemudian build/rilis mobile. Verifikasi role dan sumber data pada instansi uji yang berwenang, lalu UAT laporan serta share sheet. Bila backend lama masih aktif, halaman baru menampilkan kegagalan layanan dan tidak mengarang angka.

Tidak ada migrasi data untuk adapter ini. Pemulihan dilakukan dengan mengembalikan versi aplikasi dan adapter/schema/auth baru melalui prosedur rilis biasa. Jangan menghapus snapshot, jurnal, atau histori stok saat rollback. Perubahan lain yang sudah ada pada working tree tidak termasuk cakupan increment laporan.
