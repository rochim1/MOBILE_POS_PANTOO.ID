# Audit dan rencana alur PO → penerimaan → gudang/display → penjualan

Status: audit kode dan rencana implementasi, **bukan bukti lulus end-to-end**. 29 Oktober 2026. Cakupan: backend Pantoo, POS mobile Flutter, dan web admin Vue. Terkait: [rencana Retail Sederhana](RETAIL_SOLO_CAPABILITY_PLAN.md).

## CAPABILITY

Pemilik toko dapat memilih dua cara mengelola barang dagangan: (A) satu lokasi stok untuk UMKM, sehingga barang yang diterima langsung tersedia bagi kasir; atau (B) lokasi bertingkat untuk toko yang memisahkan gudang pusat, gudang belakang toko, dan rak display, sehingga perpindahan antarlokasi tercatat dan kasir hanya memakai stok lokasi jual yang dipilih. PO mencatat pesanan komersial; penerimaan fisik, perpindahan stok, ketersediaan jual, dan pembayaran adalah kejadian berbeda.

## Hasil audit: apa yang sudah ada

| Bagian | Bukti pada kode | Kesimpulan |
| --- | --- | --- |
| Profil Inventory `simple`, `centralized`, `advanced`, `custom` | `presensi_zera_BE/graphql/inventaris_umum/inventory_operation_policy.service.js`; pilihan pada `front_end_template/src/pages/inventory/pengaturan.vue` | **Ada.** `simple` melarang transfer dan mengizinkan receiving ke satu lokasi operasional. `advanced` mengaktifkan gudang pusat/toko, transit, approval, dan display. |
| PO dan penerimaan | `inventory_purchase.resolvers.js`; web `inventory/purchases`, `inventory/receiving`; mobile `pos_purchase_workspace.dart`, `pos_purchase_receiving_page.dart` | **Ada secara fitur.** PO dan penerimaan terpisah, mendukung kuantitas/tujuan penerimaan. Belum dibuktikan selesai di server standalone saat ini. |
| Tujuan barang masuk | `validateReceivingWarehouse` pada `inventory_operation_policy.service.js`; `default_receiving_location_id` pada pengaturan web; selector warehouse mobile | **Ada.** Simple dapat dibatasi ke lokasi default; display/transit/karantina sengaja tidak boleh menerima PO langsung. Gudang toko hanya boleh menerima langsung jika kebijakan mengizinkan. |
| Transfer stok | `inventory_transfer.resolvers.js`, web `inventory/transfer`, mobile `pos_inventory_page.dart` dan `pos_inventory_editor_page.dart` | **Ada.** Buat, submit/approve, kirim, dan terima transfer disediakan. Menu mobile hanya muncul bila profil/kebijakan dan izin memungkinkan. |
| Lokasi yang dijual POS | `pos_toko.model.js`, `pos_selling_policy.service.js`, penjualan pada `inventaris_umum.resolvers.js`; pemilih lokasi pada web `pos/toko.vue` dan mobile `pos_outlet_page.dart` | **Ada.** Setiap toko menunjuk **satu** `lokasi_cabang_id`; checkout memvalidasi dan memotong saldo lokasi itu. Profil Advanced mengizinkan tipe `store` atau `display` bila aktif dan `is_sellable_location=true`. |
| Rantai konfigurasi web/mobile | Pengaturan Inventory ada pada web; lokasi outlet dan transaksi mobile dapat memakai kebijakan runtime yang sama | **Sebagian.** Fondasi bersama ada, tetapi belum ada panduan terpadu yang memastikan lokasi receiving, transfer, dan lokasi jual disetel konsisten untuk tiap pola. |

## Temuan penghalang dan gap

### P0 — Alur gudang toko → display bertabrakan dengan kebijakan Advanced

Preset Advanced mengaktifkan gudang pusat sekaligus display. `validateTransferWarehouses` saat ini menolak setiap transfer yang tidak menyentuh gudang pusat apabila `use_central_warehouse=true`. Maka transfer normal **gudang belakang toko (`store`) → display** akan ditolak walaupun kedua tipe diaktifkan. Rute pusat → display dapat lolos secara bentuk, tetapi itu bukan pengisian rak dari gudang belakang toko dan tidak boleh dipakai untuk menyamarkan kekurangan aturan.

### P0 — Operasi stok kritis bergantung pada transaksi database

Penerimaan PO memanggil `runInventoryTransaction` dan secara eksplisit menolak session kosong dengan `ATOMIC_TRANSACTION_REQUIRED`. Transfer juga memakai `runInventoryTransaction`; utilitas ini menolak MongoDB standalone secara default. Pengguna telah menyatakan replica set belum tersedia sekarang. Karena itu, **kedua proses belum boleh dinyatakan siap produksi end-to-end pada infrastruktur sekarang**, walaupun halaman dan resolver ada. Fallback non-atomik bukan solusi aman untuk stok, audit, dan jurnal. Keputusan arsitektur ini mendahului aktivasi operasional.

### P1 — Lokasi menerima dan lokasi menjual bisa tidak sama

PO dapat diterima ke lokasi tertentu, sedangkan POS selalu memotong `PosToko.lokasi_cabang_id`. Pada Simple, lokasi default receiving dan lokasi jual harus sama; backend sudah memvalidasi sebagian, tetapi UI perlu memandu pemilihan dan menunjukkan konsekuensi. Pada Advanced, jika POS menunjuk `display` lalu stok masih di `store`, kasir melihat stok display kosong sampai ada transfer. Jika POS menunjuk `store`, transfer ke display justru mengurangi stok yang dibaca kasir. Pengguna perlu memilih strategi lokasi jual secara eksplisit.

### P1 — Profil Advanced menggabungkan terlalu banyak kewajiban untuk sekadar display

Advanced sekaligus menyalakan pusat, approval, dan transit. Untuk toko yang hanya memiliki gudang belakang + rak display, ini menambah langkah yang tidak sesuai fisik. `Cabang.linked_toko_id` tersedia, tetapi belum digunakan dalam validasi transfer untuk memastikan `store` dan `display` milik toko yang sama. Diperlukan kebijakan “replenishment internal” yang ringkas dan tetap diaudit, tanpa membypass keamanan transfer antar-toko.

### P1 — Belum ada aksi kontekstual “Isi rak display” yang terbukti di kedua UI

Web dan mobile menyediakan transfer generik. Dari audit kode, belum ada alur khusus yang memulai dari stok display rendah, otomatis mengisi asal gudang belakang, tujuan display, item, serta menampilkan saldo sebelum/sesudah. Ini adalah gap UX, bukan ketiadaan mesin transfer sepenuhnya.

### P2 — Migrasi profil dan skenario negatif belum terbukti

Mengubah toko Simple menjadi gudang/display dapat meninggalkan stok lama di lokasi yang tidak lagi dibaca POS. Belum ada bukti uji end-to-end untuk PO parsial, barang rusak, transfer parsial, retry jaringan, dua perangkat, lot/expiry, dan retur setelah stok sudah berpindah. Tes kontrak kode yang ada tidak membuktikan seluruh perjalanan ini.

## CONSTRAINTS / aturan yang tidak boleh dilanggar

1. PO **tidak** menambah stok. Hanya penerimaan final yang menambah saldo lokasi tujuan; barang ditolak/rusak tidak masuk stok siap jual.
2. Transfer tidak menambah total stok perusahaan. Qty dan nilai yang keluar dari asal harus seimbang dengan yang masuk ke tujuan atau status `in_transit`; transaksi parsial harus dapat dilanjutkan tanpa menggandakan saldo.
3. Penjualan mengurangi satu lokasi jual yang jelas untuk tiap item; stok gudang belakang tidak boleh disamakan diam-diam dengan stok display. Perubahan strategi stok harus terlihat pada kasir.
4. Pembayaran supplier, approval PO, dan penerimaan fisik adalah state terpisah. Barang dapat diterima sebagian dan dibayar kemudian tanpa memalsukan salah satu status.
5. Semua operasi stok memakai `request_id`/idempotensi, jejak aktor, waktu, alasan, dan sumber dokumen. Retry, refresh, serta sinkronisasi offline tidak boleh menerapkan efek dua kali.
6. Izin warehouse harus diterapkan di backend untuk sumber dan tujuan; `linked_toko_id` atau pengikat toko yang setara harus mencegah replenishment internal lintas toko.
7. Jika backend tidak dapat menjamin konsistensi, UI harus menampilkan `pending/perlu pemulihan`, bukan sukses. Tidak boleh mengaktifkan fallback multi-dokumen non-atomik hanya agar tombol tampak bekerja.

## IMPLEMENTATION CONTRACT

### Dua alur target

**A. UMKM satu lokasi — default Retail Sederhana**

`PO/draft (bila dipesan terlebih dahulu) → disetujui/auto-approve sesuai policy → barang datang → cek jumlah & kondisi → terima ke Lokasi Stok Toko default → stok siap jual di kasir`.

- Jika kulakan dibawa pulang langsung, UI boleh memakai “Catat Pembelian” yang menggabungkan input pesanan dan penerimaan, **tetapi backend tetap mencatat dua kejadian dan hanya menyatakan selesai setelah keduanya konsisten**. Ini pekerjaan tahap lanjutan, bukan kemampuan yang diasumsikan sudah aman.
- Hanya satu lokasi receiving sekaligus lokasi jual (`is_receiving_location` dan `is_sellable_location`), terhubung ke outlet aktif. Tidak ada transfer ke rak sebagai kewajiban sistem.

**B. Gudang belakang + display — toko yang melacak rak**

`PO → terima di pusat ATAU gudang belakang toko (sesuai kebijakan) → bila dari pusat, transfer ke gudang toko → replenishment gudang toko → display → kasir menjual dari display`.

- Display tidak menerima PO langsung. Replenishment dari gudang toko harus diizinkan hanya untuk lokasi yang terikat pada outlet yang sama; tidak memerlukan persetujuan dan transit fisik bila kebijakan internal toko menyatakan demikian, tetapi tetap memerlukan otorisasi dan audit.
- Outlet harus diikat ke lokasi `display` sebagai lokasi jual jika stok rak benar-benar menjadi batas penjualan. Bila bisnis menjual langsung dari gudang belakang juga, tentukan eksplisit apakah perlu sumber stok per item atau transaksi pemindahan cepat; **jangan** menggabungkan saldo secara implisit.
- Barang rusak/karantina saat penerimaan atau saat di rak tidak masuk qty `available`. Perubahan batch/expiry mengikuti identitas lot saat transfer dan penjualan.

### Perubahan backend yang direncanakan

1. Pisahkan aturan transfer “harus melalui pusat” khusus untuk rute distribusi terpusat, bukan semua rute pada Advanced. Tambahkan rute `store → display` yang tervalidasi untuk satu outlet, beserta tes negatif `store A → display B` dan semua kombinasi tipe/izin.
2. Tetapkan kontrak kebijakan yang independen: `receiving_destination_policy`, `store_display_replenishment`, `approval_required_for_internal_move`, dan `pos_selling_location`. Hindari menafsirkan satu toggle `use_central_warehouse` sebagai aturan untuk semua perpindahan. Kompatibilitas profil lama harus dipertahankan.
3. Putuskan cara operasi stok atomik pada infrastruktur tanpa replica set sebelum mengubah penerimaan/transfer. Opsi yang harus dievaluasi: (a) menyediakan transaksi MongoDB; atau (b) desain ledger operasi idempoten dan recovery yang dapat membuktikan tidak ada saldo ganda/parsial terlihat. Keputusan (b) perlu review arsitektur, tes crash di setiap titik tulis, dan prosedur rekonsiliasi; **bukan** sekadar mengaktifkan fallback.
4. Tambahkan readiness query yang membaca profil Inventory, default receiving, kemampuan gudang, outlet `lokasi_cabang_id`, link toko, izin, dan kemampuan transaksi database; hasilnya memberi pesan tindakan spesifik sebelum PO/transfer/penjualan dimulai.
5. Tetapkan strategi migrasi saldo ketika mengaktifkan display: dokumen pemindahan dari lokasi lama ke gudang toko/display, dengan preview qty dan nilai, rollback/recovery, serta larangan perubahan saat operasi terkait belum final.

### Perubahan UI web + mobile yang direncanakan

- Wizard konfigurasi “Satu lokasi” / “Gudang & display” dengan ilustrasi rute fisik, pemeriksaan kesiapan, dan preview sumber stok kasir. Jangan menamai kebijakan pembelian langsung-ke-toko seolah sama dengan modul Finance “Pembelian Langsung” yang punya approval terpisah.
- Form PO: tujuan penerimaan default terlihat; jumlah dipesan dan jumlah diterima dipisahkan. Setelah PO, tampilkan aksi utama yang sesuai status: `Terima barang`, `Lihat sisa`, atau `Tutup`.
- Form penerimaan: scan/cari barang, qty datang/baik/rusak, lokasi tujuan, lot/expiry bila perlu, selisih dari PO, dan status parsial. Tampilkan kapan barang baru akan tersedia di POS.
- Halaman stok display: saldo display, saldo gudang belakang, batas minimum rak, dan aksi `Isi rak`. Aksi ini memprefill transfer internal dan hasilnya memperlihatkan qty asal/tujuan sebelum serta sesudah.
- Kasir: label sumber stok (`Toko` atau `Display`), jumlah yang benar-benar dapat dijual, dan penjelasan saat barang ada di gudang tetapi display kosong. Tautan `Isi rak` hanya untuk operator yang berizin.
- Status error/retry: bila transaksi belum final, tampilkan pekerjaan yang tertahan dan tautan ke riwayat operasi, bukan mengulang mutasi tanpa memeriksa `request_id`.

### Rancangan khusus POS mobile (Android)

**Navigasi yang disarankan:** jangan menambah tab bawah baru. Dari `Lainnya → Inventori`, tampilkan tiga pintu utama sesuai izin dan profil: `Barang masuk`, `Stok siap jual`, dan (hanya bila display aktif) `Isi rak`. `Purchase Order`, `Penerimaan`, dan `Mutasi Stok` tetap tersedia di bagian `Dokumen & riwayat` untuk pengguna yang perlu detail. Pada kasir, stok/display yang kosong memberi shortcut kontekstual, bukan memindahkan kasir diam-diam ke transaksi baru.

| Layar mobile | Profil Sederhana | Gudang + display |
| --- | --- | --- |
| Beranda/Inventori | Kartu `Stok perlu dibeli` dan aksi `Catat barang masuk`/`Buat PO`. Satu lokasi stok yang juga dipakai kasir. | Kartu terpisah `Display menipis`, `Gudang belakang tersedia`, `Barang dalam perjalanan`; aksi utama `Isi rak`. |
| Detail produk/stok | Tampilkan `Siap dijual` dan sumber `Stok Toko`; tombol restock membawa produk/qty sebagai prefill. | Tampilkan `Display`, `Gudang belakang`, `Dalam perjalanan`, dan `Total` **tanpa** menjumlahkannya menjadi angka siap jual. |
| PO | Wizard singkat `Supplier → Barang → Tujuan & biaya → Tinjau`; lokasi default terisi tetapi dapat ditinjau. `Buat PO` tidak menaikkan stok. | Wizard yang sama, dengan tujuan `Pusat`/`Gudang toko` sesuai policy; tidak menawarkan `Display` sebagai lokasi terima supplier. |
| Penerimaan | Dari detail PO, tombol `Terima barang`. Scan barcode atau pilih item; isi `Dipesan`, `Datang`, `Baik`, `Rusak/ditolak`, batch/expiry bila wajib. Setelah final, beri pesan `Stok toko siap dijual`. | Setelah terima di pusat/toko, tampilkan langkah berikutnya secara eksplisit: `Kirim ke gudang toko` atau `Isi rak display`; jangan menyebut barang siap dijual jika belum berada di lokasi kasir. |
| Isi rak | Tidak ditampilkan; stok satu lokasi tidak memerlukan mutasi internal. | Bottom sheet penuh: produk, stok belakang, stok display, rekomendasi qty, input qty, scan opsional, ringkasan `Gudang 20→14 • Display 3→9`, lalu konfirmasi. Jika perpindahan tidak instan, tampilkan status `Dalam proses` dan aksi `Terima di display`. |
| Kasir | Badge stok memakai lokasi tunggal. Jika habis, tawarkan `Catat barang masuk` kepada operator berizin. | Badge stok memakai **hanya** lokasi jual yang terikat. Jika display 0 tetapi gudang 10, pesan `Ada 10 di gudang belakang — isi rak dulu`; tombol `Isi rak` hanya untuk operator berizin. |
| Riwayat | Satu timeline `PO dibuat → barang diterima → siap jual`, dengan status pembayaran terpisah. | Timeline `PO → diterima gudang → dikirim → diterima display → dijual`, termasuk kuantitas parsial dan siapa yang memproses. |

**Interaksi penting:** setiap aksi mutasi mempunyai label field, ringkasan qty/biaya, tombol yang menunjukkan loading, dan layar hasil yang membedakan `Berhasil`, `Menunggu sinkronisasi`, serta `Perlu ditinjau`. Tombol tidak boleh mengirim ulang dengan ID baru setelah timeout. Pada mode offline, pembuatan draft boleh lokal; penerimaan dan pemindahan yang mengubah saldo **tidak boleh ditampilkan final** sampai server mengakui operasi dan strategi konsistensi database tahap 0 tersedia. Bottom sheet tetap dapat digulir ketika keyboard terbuka; scan barcode menyediakan input manual.

**Penerapan bertahap di mobile:** (1) rapikan label dan penjelasan stok lokasi pada halaman yang sudah ada; (2) buat pintu `Barang masuk`/`Stok siap jual` yang mengambil data backend, bukan menduplikasi logika; (3) setelah backend rute dan atomisitas siap, tambahkan `Isi rak` dan petunjuk langkah berikutnya pascapenerimaan; (4) uji pada Android nyata ukuran kecil, kamera barcode, offline/online, dan akun operator dengan izin berbeda. Flutter web hanya alat uji, bukan target rilis mobile.

**Kriteria selesai mobile:** pemilik Simple dapat menyelesaikan alur supplier → terima → kasir tanpa membuka menu transfer; operator gudang-display dapat melihat lokasi barang yang benar dan memindahkannya dari gudang toko ke display tanpa diarahkan ke gudang pusat; kasir tidak dapat menjual stok yang hanya ada di gudang ketika kebijakan menjual dari display; tidak ada klaim sukses palsu saat jaringan atau backend gagal.

### UI lebih ringkas khusus profil Inventory Sederhana

Rekomendasi: gunakan **progressive disclosure**, bukan menghapus kemampuan. Tampilan pertama di `Lainnya → Inventori` cukup memuat ringkasan `Stok siap jual`, pencarian/scan, dan satu tombol utama `Tambah stok`. Dokumen PO, penerimaan, supplier, pembayaran, serta riwayat tetap dapat dibuka melalui `Lihat dokumen`/`Opsi lanjutan`; semua tetap memakai backend dan izin yang sama. Mode ringkas diterapkan hanya bila `inventory_profile=simple` **dan** konfigurasi satu lokasi receiving/jual lolos readiness; profil POS `retail` saja tidak cukup untuk mengaktifkannya.

Alur tombol utama:

1. Pilih `Barang sudah datang` (kulakan yang dibawa langsung) atau `Pesan ke supplier` (PO untuk barang yang belum datang). Ini dua keadaan bisnis yang berbeda walau berasal dari satu pintu `Tambah stok`.
2. `Barang sudah datang`: layar/form penuh yang ringkas berisi `Barang` (scan/cari), `Jumlah diterima`, `Harga beli`, `Supplier` sesuai kebijakan, dan `Kondisi` jika ada selisih/rusak. Lokasi stok toko terisi otomatis dan tampil sebagai teks `Masuk ke: [nama lokasi]`, bukan dropdown yang harus dipilih setiap kali. Tombol `Tinjau & simpan` membuka ringkasan sebelum mutasi.
3. `Pesan ke supplier`: input supplier, barang, jumlah dipesan, estimasi harga/tanggal; tombol `Buat PO`. Setelah dibuat, kartu dokumen menampilkan `Menunggu barang` dan aksi tunggal `Terima barang` saat barang datang. PO tidak menaikkan stok.
4. Setelah penerimaan final, tampilkan `X unit siap dijual di [lokasi]` dengan tombol `Lihat di kasir`. Jika belum final, tampilkan `Menunggu diproses`/`Perlu ditinjau` dan jangan menampilkan stok sebagai tersedia.

Yang **tidak** tampak pada halaman utama Simple: `Mutasi Stok`, `Isi Rak`, pemilihan gudang asal/tujuan, approval transfer, transit, dan kolom-kolom akuntansi lanjutan. Pembelian Langsung modul Finance tidak diganti nama menjadi `Tambah stok`; ia mempunyai aturan pemisahan tugas yang berbeda. Jika operator memilih `Semua fitur`, navigasi lanjutan tetap ada sesuai izin tanpa mengubah data atau mode transaksi.

Pengaman perubahan UI: render menu dari kebijakan backend, bukan hanya flag lokal; tidak mengubah skema maupun status dokumen lama; sediakan fallback layar lengkap bila konfigurasi satu lokasi tidak siap; tampilkan penjelasan sebelum pengguna pindah ke profil gudang/display; uji dua arah pergantian profil, izin operator, offline, draft lama, dan kesamaan status di web. Bentuk UI ringkas dapat dibangun lebih awal, tetapi aksi yang memfinalkan stok tetap dibatasi oleh gerbang atomisitas tahap 0.

### Matriks penerimaan minimal

| Skenario | Hasil yang harus dibuktikan |
| --- | --- |
| Simple: PO 100, terima 96 baik + 4 rusak | Stok lokasi jual naik 96; sisa/selisih dan kondisi tercatat; kasir menjual maksimal stok tersedia. |
| Simple: dua lokasi aktif, default receiving belum dipilih | Setup menahan penerimaan dengan pesan penentuan lokasi; tidak ada stok masuk ke lokasi salah. |
| Advanced: supplier → pusat → gudang toko → display → kasir | Tiap saldo dan status transit benar; stok kasir hanya sesuai lokasi display. |
| Advanced: supplier langsung ke gudang toko | Hanya diizinkan jika kebijakan penerimaan toko aktif; tidak dapat langsung ke display. |
| Advanced: gudang toko → display satu outlet | Transfer/replenishment berhasil tanpa wajib melewati gudang pusat; qty total tetap. |
| Gudang toko A → display toko B | Ditolak sekalipun operator punya izin transfer umum, kecuali memakai alur antartoko yang sah. |
| Retry/crash/dua perangkat pada penerimaan dan transfer | Efek stok, lot, audit, dan jurnal tepat sekali; status dapat dipulihkan tanpa edit database manual. |
| Mengubah Simple → display dengan stok historis | Ada preview migrasi; tidak ada stok menghilang dari kasir atau tergandakan. |
| Retur penjualan dari display dan retur supplier dari gudang | Efek stok diterapkan pada lokasi asal yang tepat; tidak mengembalikan qty ke lokasi lain secara diam-diam. |

## NON-GOALS

- Tidak memaksa semua toko memakai gudang dan rak display terpisah.
- Tidak menjadikan PO sebagai bukti barang sudah tiba atau sudah dibayar.
- Tidak mengubah saldo secara langsung lewat koreksi darurat untuk menutupi transfer yang gagal.
- Tidak membuka penjualan dari gabungan seluruh gudang tanpa kebijakan stok yang eksplisit.
- Tidak mengklaim siap produksi hanya karena kontrak GraphQL atau halaman tampil.

## OPEN QUESTIONS / keputusan produk dan arsitektur

1. Infrastruktur stok: apakah transaksi database akan disediakan, atau sistem harus dibangun untuk konsistensi tanpa replica set? Ini **blocker P0** untuk penerimaan dan transfer yang aman.
2. Toko model display: apakah kasir hanya boleh menjual stok rak, atau boleh mengambil barang langsung dari gudang belakang? Rekomendasi awal: hanya lokasi display; pengambilan dari belakang dicatat sebagai replenishment cepat.
3. Apakah supplier boleh mengirim langsung ke gudang toko pada profil Advanced? Rekomendasi: ya, sebagai pilihan kebijakan, tanpa memaksa lewat pusat.
4. Apakah replenishment satu toko membutuhkan approval? Rekomendasi: tidak untuk pemilik/operator berizin dan di bawah batas yang dapat diatur; tetap audit penuh. Transfer antartoko/pusat tetap mengikuti approval yang berlaku.
5. Apakah stok display akan dipantau per rak atau cukup satu lokasi display per outlet? Rekomendasi tahap pertama: satu lokasi display per outlet; detail rak menyusul bila kebutuhan nyata terbukti.

## HANDOFF / urutan kerja

| Tahap | Keluaran dan gerbang selesai |
| --- | --- |
| 0. Putuskan keamanan data | Uji kemampuan transaksi database aktual; pilih arsitektur atomik/recovery. Catat jaminan dan failure mode. Tanpa ini jangan meluncurkan penerimaan/transfer baru. |
| 1. Benahi aturan rute | Perbaiki aturan Advanced `store → display`, batas antar-outlet, receiving tujuan toko, dan migrasi policy; tes unit/kontrak seluruh kombinasi profil. |
| 2. Setup terpandu | Sinkronkan lokasi receiving, gudang toko, display, serta lokasi jual POS pada web/mobile; readiness menahan konfigurasi kontradiktif. |
| 3. UI operasional | Buat aksi kontekstual `Isi rak`, status stok siap jual, penerimaan selisih/rusak, dan pesan error yang dapat dipulihkan di kedua klien. |
| 4. End-to-end & rollout | Uji dua alur, partial, batch/expiry, retur, offline/retry, dua perangkat, dan migrasi pada instansi dummy; aktifkan bertahap dengan telemetry operasi stok. |

Kesimpulan audit: **kedua proses telah disediakan sebagai kerangka fitur, tetapi belum solid end-to-end**. Alur Simple paling dekat dengan kebutuhan UMKM; alur gudang→display mempunyai gap aturan transfer yang spesifik. Keduanya tertahan oleh keputusan konsistensi database pada lingkungan tanpa replica set.

## Status implementasi 29 Oktober 2026

- **Sudah:** aturan transfer gudang toko ↔ display pada profil Advanced dibuka hanya bila kedua lokasi terhubung ke outlet POS aktif yang sama dalam instansi yang sama. Rute antartoko dan lokasi yang belum ditautkan ditolak; tes unit rute lulus.
- **Sudah:** formulir gudang di POS mobile dan web menyediakan pilihan outlet terkait. Pengaturan sebelumnya tetap dapat dibuka; lokasi lama yang belum ditautkan belum otomatis dimigrasikan.
- **Sudah sebagian:** halaman pembelian mobile profil Simple menonjolkan `Pesan ke supplier` dan `Penerimaan`, sedangkan pembelian langsung/DP berada di menu lanjutan. Halaman daftar PO web memberi penjelasan alur satu lokasi dan akses ke penerimaan. Ini penyederhanaan navigasi, bukan wizard transaksi baru.
- **Belum siap produksi:** penerimaan PO dan mutasi stok tetap memerlukan transaksi MongoDB. Database standalone yang tidak mendukung transaksi masih mengembalikan `SERVICE_UNAVAILABLE`; jangan mengaktifkan `PANTOO_ALLOW_STANDALONE_INVENTORY_FALLBACK` untuk produksi. Implementasi ledger/recovery yang aman atau penyediaan database transaksional adalah gerbang wajib sebelum dua alur dapat dinyatakan berjalan end-to-end.
- **Belum dikerjakan:** tombol `Isi rak` kontekstual, angka stok gudang belakang vs display berdampingan, migrasi saldo saat mengaktifkan display, readiness setup menyeluruh, serta pengujian dua perangkat/offline/retur. Fitur-fitur ini tidak boleh dianggap selesai hanya karena rute dan formulir outlet sudah ada.

## Pembaruan 30 Oktober 2026

- Database yang dikonfigurasi untuk backend terkonfirmasi sebagai replica set `bt_main`; transaksi baca berhasil. Ini menghapus penghalang infrastruktur transaksi yang dicatat pada 29 Oktober. Pemeriksaan ini **tidak** melakukan mutasi data produksi.
- Tombol `Isi Rak Display` kini tersedia pada halaman mutasi stok web dan POS mobile bila fitur display aktif dan operator punya izin membuat transfer. Sistem mencari pasangan gudang toko–display yang ditautkan ke outlet sama, lalu mengisi asal/tujuan pada formulir mutasi resmi. Jika pasangan belum ada, UI memberi petunjuk setup, bukan membuat mutasi salah lokasi.
- Posting transfer internal gudang toko ↔ display tidak lagi melewati gudang transit; stok berpindah secara atomik pada transaksi database yang sudah ada. Approval/dispatch yang dikonfigurasi tetap berlaku; tombol ini **bukan** pintasan untuk melewati otorisasi.
- Tes kontrak transfer/penerimaan dan aturan rute lulus. Tes integrasi pada replica set sementara membuktikan mutasi gudang toko → display memindahkan 4 dari 10 unit tanpa transit, retry tidak menggandakan saldo, serta permintaan melebihi stok tidak mengubah saldo/status. Belum ada uji end-to-end lengkap atas batch dari PO sampai checkout, migrasi saldo historis, atau layar perbandingan saldo gudang belakang/display. Hal-hal ini masih diperlukan sebelum alur Advanced dinyatakan tuntas.

### Verifikasi instansi produksi uji, 30 Oktober 2026

Atas izin pemilik, pengujian backend dilakukan pada instansi `6a856ce9517424ebab833ba9` memakai outlet, gudang, display, produk, supplier, PO, penerimaan, dan transfer khusus berlabel `[UJI] E2E-DISPLAY-1B362D43`. Saldo lokasi/produk lain tidak dipakai. Pengaturan profil inventory tetap `custom`, sementara `use_display_stock` diaktifkan; seluruh lokasi POS lama divalidasi sebelum perubahan. Outlet uji ditautkan ke lokasi display uji. Dokumen dan lokasi uji **tetap ada** untuk pemeriksaan; jangan menghitungnya sebagai transaksi bisnis nyata.

| Tahap teruji | Hasil |
| --- | --- |
| Gudang → display awal | 10 unit awal menjadi gudang 6, display 4; transfer `posted`, total tetap 10. |
| PO → persetujuan → penerimaan | PO uji `6ae38e4c0bf7b8657bbbd5a6` otomatis disetujui sesuai workflow instansi. Penerimaan `6ae38e4d0bf7b8657bbbd5d0` dan jurnal `posted`; 3 unit masuk **gudang**, sehingga saldo 9/4. |
| Isi rak setelah penerimaan | Transfer `6ae38e8a55c69d79d2271f28` berstatus `posted`; 2 unit berpindah ke display. Saldo akhir gudang 7, display 6, total 13. |
| Baca katalog kasir | Query `GetPOSCatalogPage` pada lokasi display uji menemukan produk uji dengan stok siap jual **6**, tidak menjumlahkan 7 unit di gudang belakang. |

Skrip uji satu kali dengan preflight dan penanda data uji: `presensi_zera_BE/scripts/verify_pos_inventory_display_prod.js` serta `presensi_zera_BE/scripts/verify_pos_purchase_to_display_prod.js`. Pada percobaan PO pertama ditemukan fixture produk belum memiliki konversi satuan `pcs`; tidak ada PO/penerimaan yang dibuat pada percobaan gagal itu. Satuan **produk uji saja** diselaraskan, lalu uji dilanjutkan dan lulus.

**Belum terbukti:** checkout POS untuk produk uji, tampilan stok gudang/display berdampingan di kasir, retur, migrasi stok historis saat profil diubah, offline/dari dua perangkat, dan pengujian UI Android/web nyata. Uji backend ini membuktikan rute data, jurnal, dan pembacaan katalog kasir pada instansi tersebut, bukan bahwa seluruh skenario rilis sudah selesai. Supplier/PO/penerimaan uji meninggalkan dokumen akuntansi bernilai uji; tag `[UJI]` harus dikecualikan dari pembacaan laporan bisnis nyata sampai ditangani sesuai prosedur pembatalan yang sah.
