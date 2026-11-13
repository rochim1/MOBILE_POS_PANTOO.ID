# Rencana laporan UMKM — Pantoo POS mobile

Tanggal: 13 November 2026  
Status: fitur inti audit, fondasi online, laba rugi, arus kas, aging, persediaan dan ekspor sudah diimplementasikan lokal. UAT Android pada staging selesai dan APK 1.0.8+9 tersedia; rilis produksi belum dilakukan.  
Cakupan: laba rugi, arus kas, piutang–utang, dan persediaan pada halaman Report.

## 1. Sasaran produk

Pemilik usaha dapat menjawab empat pertanyaan dari ponsel:

1. Apakah usaha untung, dan biaya apa yang menguranginya?
2. Berapa uang yang benar-benar masuk, keluar, dan tersedia?
3. Siapa yang masih berutang kepada usaha, dan tagihan apa yang harus dibayar?
4. Berapa nilai stok, bagaimana pergerakannya, dan barang apa yang perlu ditambah?

Laporan harus konsisten dengan Finance web, dapat ditelusuri ke dokumen sumber, dan menyebutkan ruang lingkup serta kelengkapan datanya. Kartu memakai `PosMetricCard` dan `PosMetricGrid` yang sudah digunakan mobile POS.

## 2. Kondisi kode yang sudah diperiksa

| Area | Fondasi tersedia | Pekerjaan yang masih diperlukan |
| --- | --- | --- |
| Report mobile | Ringkasan penjualan, produk teratas, pembayaran, kas tunai, performa kasir | Tambah empat kelompok laporan keuangan dan filter yang sesuai |
| Laba rugi | Backend `GetProfitLoss`, tampilan Finance web, pengelompokan pendapatan/beban dari jurnal posted | Hubungkan mobile; pisahkan HPP dan biaya operasional untuk laba kotor; audit kelengkapan sumber |
| Arus kas | Backend `GetCashFlow`: saldo awal/akhir, operasi/investasi/pendanaan, bagian belum terklasifikasi, rekonsiliasi | Tampilan mobile, rincian uang masuk/keluar, pembatasan scope, ringkasan server bila belum tersedia |
| Piutang | Mobile memiliki daftar, detail, penerimaan pembayaran invoice POS; backend Finance memiliki laporan aging | Tambah ringkasan laporan, cutoff historis, kelompok umur, tautan detail |
| Utang | Mobile memiliki detail utang pembelian dan pembayaran; backend Finance memiliki laporan aging | Tambah daftar laporan lintas dokumen, ringkasan jatuh tempo, cutoff historis |
| Persediaan | Statistik stok mobile, saldo lokasi, backend valuasi dan histori mutasi | Satukan laporan; audit metode valuasi, tambahkan scope lokasi dan laporan historis yang benar |
| Desain | Komponen statistik bersama, bahasa Indonesia/Inggris, layout responsif | Gunakan komponen sama untuk laporan baru, loading, error, dan empty state |

Batasan penting hasil pemeriksaan:

- `GetProfitLoss` dan `GetCashFlow` saat ini mengambil gabungan satu instansi; keduanya belum menyediakan argumen filter toko.
- `GetProfitLoss` saat ini mengembalikan total pendapatan, total beban, dan laba bersih. Laba kotor dan HPP belum menjadi field khusus.
- Status `basis_status: verified` pada laporan Finance berkaitan dengan pemeriksaan klasifikasi yang tersedia. Status ini tidak membuktikan seluruh biaya atau dokumen sumber sudah dicatat.
- `GetInventoryValuation` saat ini menyediakan kondisi terkini dengan pencarian/paginasi, bukan valuasi historis berdasarkan tanggal dan lokasi.
- Perhitungan statistik stok alternatif di mobile masih dapat memakai kuantitas × harga pokok dari katalog. Angka ini tidak boleh otomatis menjadi nilai persediaan resmi atau HPP historis.
- Daftar piutang POS yang ada berfokus pada invoice POS. Pesanan belum dibayar tidak otomatis merupakan piutang Finance.

## 3. Struktur navigasi dan filter

Tambahkan kategori pada Report:

1. Ringkasan Penjualan — mempertahankan fungsi yang ada.
2. Laba Rugi.
3. Arus Kas.
4. Piutang & Utang — dua tab di dalam halaman.
5. Persediaan.

Laporan kas kasir tetap menjadi laporan operasional shift/pembayaran tunai, dengan nama dan keterangan yang membedakannya dari arus kas usaha.

Filter bersama:

- Periode: hari ini, 7 hari, bulan ini, bulan lalu, dan rentang tanggal khusus.
- Laba rugi/arus kas/pergerakan stok menggunakan tanggal awal–akhir.
- Piutang, utang, dan saldo/nilai stok menggunakan posisi **per tanggal**, bukan sekadar rentang penjualan.
- Scope wajib terlihat: seluruh usaha, cabang/toko yang diizinkan, atau lokasi persediaan.
- Label tanggal bisnis mengikuti zona waktu usaha yang berlaku; penerapan batas awal/akhir tanggal dilakukan di server.
- Waktu terakhir diperbarui dan status cache ditampilkan.

Rilis awal boleh memakai scope gabungan instansi hanya untuk pemilik/pengguna yang berhak melihat gabungan. Pengguna toko tidak boleh menerima angka instansi lalu menyaringnya di ponsel. Pilihan toko baru diaktifkan setelah filter dan pemeriksaan akses server benar-benar tersedia.

## 4. Spesifikasi laba rugi

### Tampilan

Kartu utama: Penjualan Bersih, HPP, Laba Kotor, Laba Bersih.

Rincian bertingkat:

- Penjualan bruto.
- Pengurang: diskon dan retur penjualan.
- Penjualan bersih.
- HPP barang terjual atau biaya langsung yang sudah dipetakan.
- Laba kotor dan margin laba kotor.
- Biaya operasional per kategori: sewa, gaji, listrik, biaya pembayaran, dan biaya lainnya yang tercatat.
- Pendapatan/beban lain dan beban pajak bila tersedia dalam klasifikasi usaha.
- Laba/rugi bersih.

### Aturan data

- Basis laporan mengikuti jurnal posted; jangan menghitung laba bersih hanya dari omzet POS.
- Penjualan yang sudah tersaji neto dalam jurnal tidak boleh dikurangi diskon/retur untuk kedua kalinya. Detail bruto ditambahkan hanya jika dapat direkonsiliasi dengan buku besar.
- Pajak yang dipungut untuk disetorkan tidak dianggap pendapatan; bedakan dari beban pajak usaha sesuai pemetaan akun.
- HPP berasal dari biaya historis transaksi/valuasi dan jurnal yang sah, bukan harga beli katalog saat laporan dibuka.
- Pembelian stok tidak otomatis menjadi biaya seluruhnya; modal pemilik, pinjaman, dan pengambilan pribadi tidak diperlakukan sebagai penjualan atau biaya operasional.
- Jasa, paket/BOM, deposit, dan retur memakai aturan pengakuan serta biaya sumber masing-masing; tidak dipaksa mengikuti produk stok biasa.
- Tidak menghitung HPP dua kali ketika nilai tersebut sudah termasuk kelompok beban laporan Finance.
- Jika HPP, pemetaan akun, atau pencatatan biaya belum lengkap, tampilkan keterbatasannya. Jangan menampilkan laba kotor/margin yang tidak dapat dihitung sebagai nol yang pasti.
- Margin bernilai tidak tersedia ketika basis penjualan nol; nilai rugi tetap dapat ditampilkan.

Ketergantungan: audit alur biaya operasional, jurnal penjualan/retur, HPP, dan pemetaan akun. Jika input biaya di mobile belum mendukung pencatatan Finance yang benar, sediakan alur input biaya sederhana atau tautan operasional ke pencatatan yang sudah ada. Kas keluar shift tidak otomatis dianggap biaya.

## 5. Spesifikasi arus kas

Kartu utama: Saldo Awal, Uang Masuk, Uang Keluar, Saldo Akhir.

Rincian:

- Aktivitas operasional: penerimaan pelanggan, pembayaran pemasok, dan biaya tunai/bank.
- Investasi: pembelian/penjualan aset.
- Pendanaan: modal, pinjaman, pembayaran pokok, dan pengambilan pemilik sesuai pemetaan.
- Aktivitas belum terklasifikasi tetap ditampilkan terpisah.
- Ketuk ringkasan untuk melihat transaksi/jurnal penyusunnya dengan paginasi.

Aturan:

- Saldo awal + perubahan bersih = saldo akhir.
- Uang masuk/keluar harus dihitung dari pergerakan kas/bank yang relevan di server. Jangan menganggap subtotal aktivitas sebagai total bruto penerimaan/pengeluaran.
- Penjualan kredit dapat masuk laba rugi tanpa menjadi kas masuk pada hari yang sama.
- Pelunasan piutang menambah kas tetapi bukan pendapatan baru.
- Transfer antar rekening kas/bank dalam scope gabungan tidak menggandakan uang masuk dan keluar usaha.
- QRIS/kartu mengikuti pencatatan settlement, biaya, dan akun perantara; tidak otomatis dianggap kas tersedia saat transaksi POS berhasil.
- Saldo kas per toko harus dibedakan dari rekening bersama; bila atribusi belum tersedia, jangan membagi saldo gabungan secara tebakan.

## 6. Spesifikasi piutang dan utang

Kartu per tab: Sisa Tagihan, Lewat Jatuh Tempo, Jatuh Tempo Mendatang, Jumlah Dokumen Terbuka.

Daftar berisi pelanggan/pemasok, nomor dokumen, tanggal, jatuh tempo, nilai tagihan, pembayaran/kredit, sisa tagihan, dan status.

Kelompok umur:

- Belum jatuh tempo.
- Terlambat 1–30 hari, 31–60 hari, 61–90 hari, dan lebih dari 90 hari.
- Jatuh tempo tidak diketahui: ditampilkan tersendiri, bukan dianggap lancar.

Aturan:

- Umur keterlambatan dihitung dari jatuh tempo terhadap cutoff.
- Laporan masa lalu hanya mempertimbangkan dokumen, pembayaran, kredit, dan pembatalan yang efektif sampai cutoff. Jangan menggunakan saldo outstanding hari ini untuk tanggal lama.
- Sisa tagihan harus memperhitungkan pembayaran sebagian, nota kredit, retur, dan reversal tanpa hitung ganda.
- Pisahkan scope invoice POS dari seluruh piutang/utang usaha. Label dan total harus mengikuti scope yang dipilih serta izin pengguna.
- Tautan detail memakai halaman piutang/utang yang sudah ada; laporan tidak otomatis menjalankan pembayaran.
- Ringkasan berasal dari seluruh hasil filter server, bukan jumlah item pada halaman daftar yang sudah dimuat.
- Coverage/exclusions dari laporan aging tetap ditampilkan jika ada sumber historis yang belum didukung.

## 7. Spesifikasi persediaan

Kartu utama: Nilai Persediaan, Jumlah Produk Stok, Stok Rendah, Stok Habis.

Tab:

- Posisi stok: kuantitas, satuan dasar, tersedia/reservasi, nilai, serta lokasi yang relevan.
- Pergerakan stok: saldo awal, masuk, keluar, penyesuaian, saldo akhir dalam periode.
- Kebutuhan restok: barang di bawah ambang minimum/reorder yang dikonfigurasi.

Aturan:

- Gunakan layanan valuasi dan metode yang berlaku pada produk, termasuk FIFO atau metode lain yang benar-benar didukung.
- Produk jasa dan deposit tidak ikut dihitung sebagai persediaan fisik.
- Retur, transfer antar lokasi, konversi satuan, batch/serial, biaya tambahan pembelian, dan penyesuaian harus mengikuti sumber mutasinya.
- Transfer internal tidak mengubah nilai stok gabungan usaha tanpa alasan valuasi yang sah.
- Saldo awal + masuk − keluar ± penyesuaian = saldo akhir, dengan rincian jenis gerakan agar transfer tidak dihitung dua kali.
- Nilai stok, jurnal persediaan, dan selisih rekonsiliasi dapat ditelusuri. Selisih tidak ditutup dengan perhitungan harga katalog.
- Untuk tanggal historis, bangun saldo dan nilai dari histori yang didukung. Jika histori awal belum lengkap, beri batas tanggal dukungan; jangan memproyeksikan kondisi sekarang ke masa lalu.

## 8. Arsitektur dan kontrak layanan

### Backend

Gunakan layanan Finance dan Inventory yang sudah ada sebagai dasar perhitungan. Tambahkan adapter/layanan laporan POS hanya bila diperlukan untuk scope, ringkasan mobile, dan paginasi; jangan membuat rumus laba/kas terpisah.

Usulan kontrak tambahan (nama final mengikuti pola modul saat implementasi):

- Filter bersama: periode/cutoff, scope instansi/cabang/toko/lokasi yang tervalidasi, pagination.
- Metadata: periode efektif, timezone, scope, generated_at, basis perhitungan, coverage, serta daftar masalah data.
- Laba rugi: pemisahan HPP, beban operasional, pendapatan/beban lain; nilai yang belum dapat dipetakan tetap terlihat.
- Arus kas: ringkasan bruto masuk/keluar dan detail berpaginasi; rekonsiliasi terhadap saldo awal/akhir.
- Aging: ringkasan cutoff dengan filter sumber dan detail berpaginasi.
- Persediaan: posisi/valuasi historis dan mutasi per lokasi bila API yang ada belum mendukungnya.

Pisahkan status berikut: akses ditolak, data belum lengkap, tidak ada transaksi, layanan gagal, dan hasil dari cache. `verified` tidak boleh diganti menjadi klaim bahwa semua transaksi bisnis sudah tercatat.

### Mobile

- Tambahkan model, repository, query, dan state laporan keuangan terpisah dari data dashboard penjualan.
- Gunakan filter bersama dan state per jenis laporan; pergantian filter membatalkan/mengabaikan respons lama.
- Pakai `PosMetricCard`, `PosMetricGrid`, skeleton, format rupiah, dan bahasa Indonesia/Inggris yang konsisten.
- Detail memakai daftar bertahap, bukan memuat seluruh jurnal ke perangkat.
- Cache memakai kombinasi instansi, scope, filter, dan cutoff. Bersihkan saat organisasi/izin berubah.
- Offline: boleh melihat snapshot terakhir yang ditandai dengan tanggal dan scope; jangan mengklaim laporan terbaru atau membuat estimasi laba tanpa basis yang jelas.

## 9. Hak akses

- Pemeriksaan izin wajib dilakukan di server; menyembunyikan menu mobile hanya melengkapi pemeriksaan tersebut.
- Gunakan pemetaan izin Finance yang sudah tersedia, termasuk `finance_reports/view`, lalu audit kesesuaiannya dengan role/paket POS.
- Izin melihat penjualan tidak otomatis memberi hak melihat HPP, laba, saldo seluruh bank, atau data seluruh cabang.
- Kasir hanya menerima laporan dan scope yang diizinkan. Pemilik/admin juga harus lolos pemeriksaan instansi dan scope yang berlaku.
- Tombol membuka dokumen atau mencatat pembayaran mengikuti izin dokumen sumber.
- Ekspor hanya tersedia untuk pengguna yang berhak dan tidak boleh memperluas cakupan data.

## 10. Tahapan implementasi dan hasil yang wajib tersedia

| Tahap | Pekerjaan | Hasil / syarat selesai |
| --- | --- | --- |
| 0 — Audit kesiapan | Petakan akun pendapatan/HPP/beban/kas, alur posting, cutoff historis, scope, dan izin; periksa biaya operasional | Matriks sumber data, gap API, dan contoh transaksi yang dapat direkonsiliasi |
| 1 — Fondasi laporan | Filter tanggal/scope, metadata, adapter API, repository/state mobile, komponen detail dan cache | Kontrak data disepakati dan diuji; scope server serta batas historis jelas |
| 2 — Laba rugi | Pemisahan HPP dan beban, status kelengkapan biaya, ringkasan/rincian mobile | Penjualan, HPP, laba kotor, dan laba bersih sesuai sumber; kasus biaya hilang tidak menyesatkan |
| 3 — Arus kas | Klasifikasi aktivitas, masuk/keluar, rekening bersama, transfer internal, settlement | Saldo awal/akhir cocok dengan Finance dan transfer internal tidak menggandakan arus usaha |
| 4 — Piutang & utang | Aging, cutoff, coverage, filter sumber, tautan dokumen | Outstanding dan umur tagihan sesuai pembayaran/kredit/reversal pada tanggal laporan |
| 5 — Persediaan | Posisi/valuasi, mutasi, kebutuhan restok, histori lokasi | Kuantitas dan nilai sesuai sumber valuasi; selisih jurnal terlihat |
| 6 — Penyelesaian rilis | Ekspor CSV dan PDF/share bila fasilitas tersedia, pemeriksaan izin, performa, aksesibilitas, UAT | Angka mobile/web konsisten untuk filter identik; hasil ekspor sama dengan layar |

Urutan prioritas: fondasi → laba rugi → arus kas → piutang/utang → persediaan → ekspor dan UAT akhir. Tahap dapat dipecah menjadi rilis kecil; layar yang belum lengkap tidak ditampilkan sebagai laporan final. Tidak menetapkan tanggal rilis sebelum hasil audit sumber biaya dan histori diketahui.

## 11. Matriks pengujian penerimaan

| Kasus | Hasil yang diharapkan |
| --- | --- |
| Penjualan tunai 100.000, HPP 60.000, beban dibayar 10.000, saldo awal kas 50.000; tanpa pajak/diskon | Laba kotor 40.000, laba bersih 30.000, kas akhir 140.000; penurunan persediaan sesuai HPP |
| Penjualan kredit 100.000 dan pelunasan 40.000 | Pendapatan diakui satu kali sesuai sumber, piutang 60.000, kas bertambah 40.000 |
| Pembelian stok 80.000 secara kredit | Stok/utang bertambah sesuai dokumen; tidak otomatis menambah beban 80.000 pada laba rugi |
| Pembayaran utang pembelian | Kas dan utang berkurang; HPP tidak dicatat untuk kedua kalinya |
| Transfer kas 50.000 antar rekening sendiri dalam scope gabungan | Saldo masing-masing berubah, arus kas bersih usaha tidak bertambah |
| Retur, kredit, pembayaran sebagian, dan reversal | Nilai penjualan/HPP/tagihan/kas berubah hanya sesuai transaksi sumber; tidak ganda |
| Laporan sebelum tanggal pembayaran | Outstanding masih mencerminkan saldo pada cutoff tersebut |
| Biaya atau akun belum dipetakan; dokumen belum posted | Status keterbatasan terlihat, tidak ditutupi sebagai data lengkap |
| Produk jasa/deposit, batch/FIFO, transfer lokasi, perubahan biaya | Pengakuan dan valuasi sesuai jenis sumber; data historis tidak berubah mengikuti harga katalog terbaru |
| Lebih dari satu halaman data | Total ringkasan sama dengan seluruh hasil filter server |
| Pengguna toko mencoba scope instansi lain/seluruh instansi | Akses ditolak server; cache tidak membocorkan data scope sebelumnya |
| Offline, ganti filter cepat, dan sambungan putus | Snapshot/error jelas; respons filter lama tidak menimpa filter baru |
| Ponsel kecil, teks diperbesar, nominal panjang, dua bahasa | Tidak meluber; angka utuh, satuan dan konteks terbaca |

Rekonsiliasi mobile vs web dilakukan pada instansi, scope, tanggal, basis, serta waktu snapshot yang sama. Selisih definisi antara omzet operasional POS dan pendapatan akuntansi harus dijelaskan, bukan dipaksa menjadi sama.

## 12. Batas cakupan awal

Rencana ini mencakup empat kelompok laporan dan prasyarat pencatatannya. Neraca, perpajakan/pelaporan pajak, anggaran, proyeksi kas, dan konsolidasi lintas instansi menjadi pekerjaan lanjutan tersendiri. Fitur Finance web yang sudah ada tetap digunakan sebagai pembanding dan sumber layanan.

## 13. Referensi kode yang diperiksa

- Mobile report: `lib/presentation/pages/pos/pos_report_page.dart`, `lib/data/graphql/pos_report_queries.dart`.
- Komponen bersama: `lib/presentation/widgets/pos_metric_card.dart`.
- Mobile piutang: `lib/presentation/pages/pos/pos_receivables_page.dart`, `lib/data/graphql/pos_receivable_queries.dart`.
- Mobile utang: `lib/presentation/pages/pos/pos_purchase_payable_page.dart`.
- Mobile stok: `lib/domain/repositories/pos_stock_repository.dart`, `lib/data/graphql/pos_stock_queries.dart`.
- Backend Finance: `../presensi_zera_BE/graphql/finance_report/finance_report.resolvers.js`, `finance_report.typedef.js`, `report_basis.service.js`.
- Backend dimensi: `../presensi_zera_BE/graphql/finance_reporting/finance_reporting.typedef.js`.
- Backend valuasi: `../presensi_zera_BE/graphql/inventory_valuation/index.js`.
- Web Finance: `../front_end_template/src/pages/finance/finance-reports.service.js`, `reports/profit-loss.vue`, `reports/cash-flow.vue`.
- Pemeriksaan integrasi yang dapat diperluas: `../presensi_zera_BE/tests/unified_finance_reports.integration.test.js`, `finance_cashflow_mapping.integration.test.js`, `pos_receivables.integration.test.js`.

## Progres implementasi 13 November 2026

Audit sumber, fondasi laporan online, laba rugi, arus kas, aging piutang/utang, persediaan historis/pergerakan/restok, dan ekspor CSV/PDF tersedia pada kode lokal. Detail increment awal ada di [audit laba rugi](AUDIT_DAN_IMPLEMENTASI_LABA_RUGI_20261113.md); kelanjutan dan batas rilis ada di [implementasi laporan lanjutan](IMPLEMENTASI_LAPORAN_LANJUTAN_20261113.md). UAT Android dan rekonsiliasi staging telah selesai; lihat [kesiapan rilis Android](KESIAPAN_RILIS_LAPORAN_ANDROID_20261113.md). Audit data usaha produksi, verifikasi iOS dan deployment belum dilakukan.
