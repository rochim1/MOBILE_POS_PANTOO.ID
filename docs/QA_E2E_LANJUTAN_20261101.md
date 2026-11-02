# QA E2E lanjutan POS — 1 November 2026

## Batas hasil

Putaran ini memprioritaskan retest Android PO–penerimaan–stok yang belum ditandatangani setelah perubahan tujuan stok, ditambah layout loading katalog. **Bukan sign-off semua profil atau kesiapan produksi.**

- Android: `Medium_Phone_API_36.1`, package `id.pantoo.pos.qa`, build debug flavor QA dengan target `lib/main_staging.dart` dan `POS_QA_ENDPOINT=http://10.0.2.2:8085/graphql`.
- Server: `scripts/qa_android_profile_server.js`, `QA_ANDROID_RUN=1`, port 8085, MongoMemoryReplSet lokal sementara. Database produksi tidak digunakan.
- Profil yang diuji lewat layar: Retail + Inventory Simple; operator fixture QA admin. Bukan bukti pembatasan akses kasir/supervisor.
- APK dipasang dengan `install -r`. Data staging, produksi, maupun antrean offline tidak dihapus.
- Aplikasi awalnya terbuka di display virtual 2, sementara input/screenshot biasa mengenai display 0. Didiagnosis lewat focus/display, lalu QA dipindahkan ke display 0. Ini kendala lingkungan, bukan crash POS.

## Hasil yang benar-benar diuji

| Skenario | Metode | Hasil |
|---|---|---|
| Login akun QA dan PIN 123456 | Android UI melalui ADB | PASS; dashboard memuat toko, 2 produk/layanan dan kesiapan 7/8. Panduan opsional dilewati, lalu Mulai Berjualan dan tour kasir dapat dibuka/ditutup. |
| Navigasi Lainnya → Inventori → Pembelian & Penerimaan | Android UI | PASS; data PO dan GRN dari API dapat dibaca. |
| PO → edit klien lama tanpa field lokasi → ajukan → GRN lokasi salah → GRN lokasi benar | HTTP GraphQL nyata, skrip `tests/qa_purchase_destination.e2e.js` | Awalnya FAIL karena metadata error hilang; setelah perbaikan dan restart fixture, PASS. |
| Retest UI tujuan stok PO parsial | Android UI | PASS; PO-20261101-0001 tampil 50%, dipesan 2/diterima 1/sisa 1; Terima Sisa otomatis memakai Lokasi Toko QA. |
| Jumlah 2 ketika sisa hanya 1 | Android UI | PASS negatif; toast `Jumlah Barang QA Android maksimal 1.0 unit`; form tetap terbuka dengan input dapat diperbaiki. |
| Pemulihan validasi → Terima Semua → Simpan → konfirmasi | Android UI | PASS; konfirmasi menyebut 1 unit dan Lokasi Toko QA; dialog biaya aktual dapat dilewati dengan Nanti. |
| Hasil penerimaan kedua | Android UI | PASS; GRN-20261101-0002 dan GRN-0001 tampil Selesai, tidak ada PO tersisa pada antrean penerimaan. |
| Rekonsiliasi stok terlihat | Android UI | PASS; sebelum penerimaan kedua 51 unit/nilai Rp1.000, sesudahnya 52 unit/nilai Rp2.000. Stok awal fixture 50, kedua GRN masing-masing 1 × Rp1.000. Jurnal tidak diaudit tersendiri pada putaran ini. |
| Skeleton katalog lebar 150/160/180/210 dp | Widget test | Awalnya FAIL overflow 24 px pada lebar 150; setelah footer fleksibel, PASS di semua ukuran. |

Alur PO dibuat/diedit/diajukan dan GRN pertama pada putaran ini berjalan melalui HTTP, sedangkan GRN kedua dan pemulihan jumlah salah berjalan melalui Android. Ini **E2E campuran**, bukan seluruh PO dibuat dari layar Android pada putaran ini.

## Perbaikan

1. `lib/presentation/widgets/skeleton_loading.dart`: footer skeleton tidak lagi memaksakan dua kotak dengan lebar total melebihi kartu tablet. Regresi ditambahkan ke `test/pos_catalog_tablet_grid_test.dart`.
2. `presensi_zera_BE/server.js`: formatter error publik kini mempertahankan boolean `inventory_request_rejected: true` melalui whitelist `utils/publicInventoryError.js`; tidak menyalin stacktrace/metadata privat. `INVENTORY_RECOVERY_REQUIRED` tidak diiklankan sebagai penolakan pasti. Sebelumnya helper validasi sudah memberikan penanda itu tetapi formatter membuangnya; E2E HTTP membuktikan masalah tersebut.
3. Mobile memetakan penanda ini ke `InventoryRequestRejectedFailure`. Form receiving membolehkan pengguna memperbaiki input setelah penolakan yang dikonfirmasi server, alih-alih mempertahankan retry tak pasti. Kegagalan tanpa penanda/hasil ambigu tetap memakai rekonsiliasi dan request ID lama; fallback pesan lokasi untuk server lama tetap ada. Perubahan mobile terakhir ini diverifikasi tes, **belum diuji ulang lewat APK sesudah patch**. APK Android yang dipakai untuk alur di atas dibangun sebelum patch terakhir ini.

## Bukti dan regresi

- `qa-pos-20261101-overreceipt.png`: pesan jumlah melebihi sisa.
- `qa-pos-20261101-receiving-success.png`: dua GRN selesai dan antrean penerimaan kosong.
- `qa-pos-20261101-stock-success.png`: saldo akhir 52 unit/nilai Rp2.000.
- Tes widget gesture/skeleton terarah: **7/7 PASS**.
- Tes backend formatter publik + tujuan receiving: **4/4 PASS**.
- Tes Flutter pemetaan error + kontrak receiving: **9/9 PASS**.
- Suite Flutter penuh sebelum patch pemetaan error terakhir: **256/256 PASS**. Pengulangan setelah patch terakhir dicatat di bawah; angka putaran terpisah tidak dijumlahkan.
- `node --check server.js` dan pemeriksaan whitespace diff backend: PASS.
- Pemeriksaan final enam file Flutter: **No issues found**, exit 0. Sempat ditemukan import tipe error baru yang kurang; dilengkapi sebelum pemeriksaan final.
- Suite Flutter penuh setelah seluruh patch: **258/258 PASS**, exit 0, log `qa-e2e-20261101-flutter.log`. Peringatan font PDF Helvetica Unicode tetap muncul; ini bukan bukti kualitas cetak fisik sudah lolos.

## Belum dibuktikan pada putaran ini

- UI Android seluruh operasi pada 7 profil POS × 3 profil inventori, termasuk hak akses kasir/supervisor lintas toko.
- UI Android reservasi dan konflik jadwal, dapur/kanban berisi pesanan aktual setelah perubahan gesture, retur, FIFO, pajak/PPN recoverable, pembatalan GRN, dan PO beralamat manual.
- Browser Vue terbaru, checkout invoice → piutang → pelunasan Finance, invoice parsial/PPh23/ongkir gabungan, rekonsiliasi jurnal.
- Dua kasir offline bersamaan → online/sinkron, perangkat printer fisik, serta layar pelanggan Wi-Fi.
- Visual grid katalog tablet dengan banyak produk pada APK terbaru; tes skeleton tidak menggantikannya.

Prioritas berikutnya: pasang APK pasca-patch retry, uji validasi server→perbaiki form→simpan, lanjut UI reservasi/konflik dan dapur, lalu matriks inventori/hak akses yang tersisa. Jangan menaikkan status seluruh aplikasi menjadi production-ready berdasarkan putaran terbatas ini.

## Putaran kedua — spreadsheet, penolakan server, pembatalan dan valuasi

Spreadsheet asli `1jXunreofa8mjo1zlrenpIQySTwvtjatLdxGzfLALQTk` diperbarui langsung melalui connector Google Sheets, tanpa mengganti workbook. Ringkasan, Inventori Android, Web dan Backend, Temuan & Perbaikan, serta Belum Diuji memisahkan status UI/API/otomatis. Isi perubahan dibaca ulang. Pemeriksaan format melalui metadata (wrap/top); tidak ada klaim render visual native Google Sheets.

### Android pasca-patch retry — PASS alur pemulihan

- APK QA terbaru dibangun dan dipasang `install -r`, endpoint tetap fixture 8085. Sesi dan data staging/produksi tidak dihapus.
- PO-20261101-0002 dibuat/disetujui melalui HTTP khusus fixture, 1 unit × Rp1.000. Form Terima Barang dibuka pada Android ketika batch masih opsional.
- Aturan `wajib_batch_number` produk QA kemudian diaktifkan melalui HTTP. Simpan dari Android tanpa batch ditolak server. Menekan Simpan lagi membuka konfirmasi biasa, **bukan** dialog retry tak pasti.
- Dari form yang sama operator mengisi batch `QA-RECOVERY-001` dan kedaluwarsa 1 Desember 2026. Simpan/konfirmasi menghasilkan GRN-20261101-0003 berstatus Selesai. PO keluar dari antrean. API membuktikan satu GRN untuk PO tersebut, qty 1, batch benar, jurnal penerimaan posted dan stok 53; verifikasi nilai buku menemukan masalah terpisah di bawah.
- Ini menutup retest APK untuk penolakan pasti dan pemulihan form, bukan kegagalan jaringan ambigu/offline beberapa kasir.

### Celah navigasi pembatalan GRN — diperbaiki, PASS UI

- Detail GRN global sebelumnya hanya menampilkan ringkasan. PO yang selesai hilang dari daftar siap diterima, sehingga akses riwayat yang menawarkan pembatalan tidak jelas.
- `pos_purchase_workspace.dart` kini menawarkan **Kelola penerimaan PO** bagi pengguna yang memiliki izin menerima atau membatalkan penerimaan. Data PO dimuat ulang dari server sebelum dibuka; ada loading dan penanganan gagal.
- Halaman receiving menerima `canReceive`; baik Simpan maupun jalur kirim/retry menolak aksi menerima tanpa izin. Pembatalan tetap mengikuti `cancel_inventory_receiving` dan otorisasi server. Hak akses ini baru diuji kontrak, belum dua akun dengan peran terpisah pada Android.
- APK QA dibangun/dipasang ulang. Android: Penerimaan → Selesai → Kelola penerimaan PO → Riwayat → Aksi penerimaan → Batalkan Penerimaan → isi alasan → konfirmasi, **PASS**. GRN-0003 menjadi Dibatalkan; PO-0002 muncul kembali 0%/sisa 1. Bukti: `qa-pos-20261101-round2-cancelled.png`.

### Temuan valuasi metadata — diperbaiki dan diverifikasi pada fixture baru

- Rekonsiliasi master membaca Rp2.999,999976, bukan Rp3.000, sesudah perubahan flag batch dan penerimaan. Pencarian pembelian tidak memuat nilai buku; verifikasi diperbaiki untuk membaca `GetOneInventarisUmum`. Ini bukan perbaikan ekspektasi agar lolos: selisih nilai tetap dianggap bug.
- Penyebab: `UpdateInventarisUmum` menghitung ulang `total_nilai = stok × harga_beli` pada semua edit, termasuk metadata. AVCO yang dibulatkan enam desimal menghilangkan presisi nilai buku; snapshot stok/batch lama juga dapat menimpa transaksi serentak.
- `inventory_master_stock_fields.js` melindungi edit metadata dari penulisan stok, batch, biaya yang tidak berubah, dan nilai buku. Kontrak lama untuk perubahan harga eksplisit dipertahankan; FIFO tetap memiliki guard tersendiri. Tidak ada koreksi riwayat produksi secara massal.
- Tes helper + stok AVCO **10/10 PASS**; tes integrasi resolver master sesungguhnya **1/1 PASS**: nilai Rp2.000 tetap persis setelah flag batch berubah, lalu penerimaan berikutnya menjadi tepat Rp3.000.
- Server fixture Android 8085 sudah memiliki data uji yang terkena bug sebelum patch, sehingga tidak dipakai sebagai bukti nilai buku pasca-patch. Fixture baru terisolasi 8086 memuat patch. Skrip `tests/qa_master_valuation_http.e2e.js` membuktikan lewat HTTP publik: terima 2 unit → stok 52/nilai 2000 → edit flag → nilai tetap 2000 → batch kosong ditolak tanpa stok berubah → terima 1 dengan batch → stok 53/nilai 3000 → retry ID sama tidak membuat GRN baru → batalkan GRN kedua dua kali → stok 52/nilai 2000, jurnal pembatalan posted. **PASS**, marker `QA_MASTER_VALUATION_HTTP_PASS`.
- Percobaan pertama skrip HTTP salah memakai argumen pembatalan `_id/reason`; schema aktual memakai `CancelInventoryReceivingInput`. Skrip dibetulkan dan seluruh alur diulang pada fixture baru hingga PASS. Kesalahan ini pada skrip QA, bukan query aplikasi mobile.
- Patch server valuasi belum dipasang ke produksi. Retest UI Android pada server pasca-patch valuasi masih diperlukan; hasil HTTP tidak disamakan dengan UI.

Verifikasi teknis putaran kedua: analisis tiga file Flutter **No issues found**; tes receiving/error terarah **10/10 PASS**; APK QA pasca-navigasi berhasil dibangun. Pemeriksaan sintaks Node dan diff whitespace pada perubahan lulus. Suite Flutter penuh terakhir **259/259 PASS**, exit 0, log `qa-e2e-20261101-round2-flutter.log`. Reservasi UI/konflik, dapur dengan pesanan aktual, matriks profil/izin, printer fisik dan offline dua perangkat tetap terbuka.

## Putaran ketiga — reservasi Android dan pelepasan meja

Hasil lengkap dan batas cakupan ada di [QA_RESERVASI_E2E_20261101.md](QA_RESERVASI_E2E_20261101.md). Android membuktikan konfirmasi/check-in/seated, penolakan selesai belum lunas, pembayaran uang pas, no-show, penyelesaian kartu umum dan penjadwalan ulang tanpa pergeseran waktu. Perbaikan mencakup tanggal ISO/lokal, pemisahan booking dari okupansi meja, pengamanan proses sebelum seated dan pelepasan meja/status completed melalui jalur selesai generik. Dine-in baru pada meja yang dilepas benar-benar diterima melalui HTTP, lalu dibatalkan sebagai probe QA.

Regresi terakhir: backend **46/46 PASS**, Flutter penuh **262/262 PASS**, analisis terarah bersih. Menggantikan angka suite sebelumnya, bukan dijumlahkan. Dua perangkat booking bersamaan, UI semua profil/peran, dapur aktual, offline multi-kasir dan perangkat fisik tetap belum selesai diuji. Tidak ada deploy produksi.

## Putaran keempat — seluruh profil, scope peran dan dapur aktual

Rincian ada di [QA_PROFIL_HAK_AKSES_DAPUR_20261101.md](QA_PROFIL_HAK_AKSES_DAPUR_20261101.md). Regresi final backend **77/77 PASS**, Flutter penuh **263/263 PASS**. Semua 21 kombinasi POS/inventori diuji untuk order/stok dan batas akses tiga peran pada resolver/database; ketujuh profil juga diuji create/pay kasir melalui HTTP bermiddleware nyata. Ini bukan 21 perjalanan UI Android lengkap.

Android membuktikan item campuran dapur, scroll vertikal tanpa drag, perpindahan horizontal, served, PIN baca-saja dengan Hanya lihat dan tanpa perubahan status, serta supervisor memulai proses dan membatalkan dengan PIN. Temuan yang diperbaiki: scope cabang order/toko/meja/stasiun, pending booking/closed order pada mutation dapur, bypass voided, bootstrap katalog/toko, pewarisan izin terminal oleh PIN operator dan sinkronisasi header/item pesanan. Data produksi dan penyimpanan lokal aplikasi tidak dihapus; source/APK QA belum dirilis produksi. Pemisahan maker/approver/processor seluruh modul inventori dan skenario perangkat tetap terbuka.
