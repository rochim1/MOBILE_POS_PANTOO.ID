# Rencana setup POS ringkas untuk UMKM dan jasa

Tanggal: 18 November 2026 (Asia/Jakarta).
Status diperbarui 18 November 2026: **inti persiapan toko/lokasi POS baru, pemulihan, form satu tahap, dan guide ringkas telah diimplementasikan serta lulus 136 pengujian otomatis.** Tidak ada migrasi instansi lama, perubahan database produksi, build APK, atau deployment pada implementasi ini. Rincian bukti dan batas pengujian ada di [laporan implementasi](<D:/my node app/zera/mobile_POS_Pantoo/docs/SETUP_POS_OTOMATIS_IMPLEMENTASI_UJI_20261118.md>). Bagian kondisi awal dan rancangan di bawah dipertahankan sebagai baseline; penyederhanaan lanjutan form katalog dan pengukuran waktu pengguna belum termasuk hasil implementasi ini.

## 1. CAPABILITY — hasil yang ingin dicapai

Pemilik usaha satu toko dapat mulai memakai Pantoo POS melalui alur **Profil usaha → Tambah barang/layanan → Mulai berjualan**, tanpa harus memahami perbedaan instansi, cabang organisasi, toko POS, dan lokasi stok. Struktur tersebut tetap disiapkan dan divalidasi oleh server agar stok, kas, piutang, jurnal, serta pertumbuhan ke banyak toko tidak rusak.

Sumber: diskusi pengguna mengenai kerumitan “Selesaikan Setup POS”, pembuatan lokasi stok/toko, dan kebutuhan usaha jasa. Dokumen ini merinci arah UX yang disarankan, bukan bukti fitur sudah tersedia.

### Sasaran pengguna

- UMKM ritel yang dikelola sendiri pada satu tempat.
- Penyedia jasa langsung atau reservasi tanpa barang fisik.
- Usaha campuran, misalnya salon dengan produk perawatan atau bengkel dengan suku cadang.
- Pemilik yang ingin mulai sederhana dan menambah fitur ketika diperlukan.

### Ukuran keberhasilan yang direncanakan

- Akun baru yang memenuhi syarat tidak perlu mengisi formulir lokasi stok dan toko secara terpisah.
- Tidak ada pertanyaan ulang mengenai profil bisnis, operating needs, atau default transaksi.
- Jasa murni tidak diblokir oleh stok awal, HPP layanan, gedung, ruangan, atau rak.
- Retry, dua perangkat, dan respons hilang tetap menghasilkan satu konteks operasional, bukan toko/gudang duplikat.
- Semua kebijakan keamanan dan integritas transaksi tetap berlaku.
- Ukur waktu sampai katalog pertama dan transaksi pertama pada uji pengguna; **belum ada pengukuran waktu pengguna saat dokumen ini dibuat**. Target angka ditetapkan sesudah baseline, bukan diklaim sudah tercapai.

## 2. Kondisi sekarang yang diperiksa

- `BusinessSetupPage` sudah mengumpulkan nama, telepon, logo opsional, dan profil bisnis dalam satu form.
- `PosOnboardingPage` menerapkan profil/default tanpa mengulangi wizard transaksi pada jalur sukses.
- `PosSetupGuidePage` masih menampilkan lokasi stok, toko POS, katalog, konfigurasi, stok awal, PIN, dan shift sebagai unsur kesiapan.
- Runtime backend menghitung `operational_readiness`, termasuk toko yang terhubung, lokasi penjualan, produk, stok awal, PIN, shift, dan kesehatan konfigurasi.
- Toko mempunyai dua tanggung jawab berbeda: `operating_branch_id` untuk organisasi/penanggung jawab dan `lokasi_cabang_id` sebagai sumber stok. Keduanya tidak boleh tertukar.
- Profil `jasa` mempertahankan kemampuan stok untuk katalog campuran. Item layanan dapat tidak melacak stok; ini tidak sama dengan mematikan tracking seluruh POS.
- Rencana historis [Retail Solo](RETAIL_SOLO_CAPABILITY_PLAN.md) mencakup kulakan dan operasional lebih luas. Bagian onboarding dokumen ini menjadi acuan rencana terbaru; asumsi standalone dan opsi onboarding pada dokumen 29 Oktober tidak boleh dianggap kondisi terkini. Ketersediaan transaksi database tetap diperiksa kembali ketika implementasi.

## 3. CONSTRAINTS — aturan tetap

1. Tidak membuat profil bisnis baru bernama “UMKM” atau “Sederhana”. Kesederhanaan adalah pengalaman setup, bukan pengganti `retail`, `jasa`, atau profil inventory.
2. Tidak menambah pertanyaan “mode sederhana/lanjutan” pada pendaftaran. Jalur ringkas menjadi default hanya untuk workspace baru yang memenuhi syarat.
3. Tidak mengubah instansi lama, lokasi aktif, cabang pengelola, profil inventory, pajak, alur display, atau default transaksi secara diam-diam.
4. Tidak menonaktifkan PIN, shift, batas kredit, izin, subscription, audit, atau larangan stok minus untuk menghilangkan langkah setup.
5. Tidak membuat stok, harga beli, modal kas, rekening, atau jurnal pembukaan fiktif. Nilai nol bukan pengganti data yang belum diketahui.
6. Stok diputuskan pada jenis item dan komponen stoknya. Layanan tidak mengurangi stok; barang/bahan/resep yang dilacak tetap mengikuti mesin inventory.
7. Server menjadi sumber kebenaran. Flag lokal “setup selesai” tidak boleh menggantikan validasi toko/lokasi/izin di server.
8. Operasi bootstrap memakai transaksi database yang didukung dan idempotensi. Tidak mengandalkan fallback non-atomik sebagai jalur produksi.
9. Tidak membuat akun/role kasir baru otomatis. Akun pemilik yang sah tetap memakai identitas dan izin aktual.
10. Mobile Android dan admin Vue memakai policy serta identitas toko/lokasi yang sama. Flutter web hanya permukaan pengujian, bukan pengganti admin Vue.

## 4. IMPLEMENTATION CONTRACT — pengalaman pengguna

### 4.1 Alur baru

1. **Profil usaha:** nama, telepon, profil bisnis; logo opsional. Bahasa tetap tersedia di header, scroll bekerja dari card maupun latar.
2. **Persiapan otomatis:** aplikasi menampilkan progres pada tindakan yang sedang berjalan, misalnya “Menyiapkan toko Anda…”. Tidak meminta pengguna masuk ke halaman lokasi, lalu toko, lalu kembali ke wizard. Jangan menambah card proses login atau pertanyaan profil kedua.
3. **Katalog pertama:** tampilkan aksi “Tambah barang” untuk ritel dan “Tambah layanan” untuk jasa, dengan pilihan jenis lain tetap tersedia. Dapat dilewati untuk melihat dashboard; jangan menyatakan siap bertransaksi bila belum ada item yang bisa dijual.
4. **Mulai berjualan:** toko terpilih otomatis bila hanya ada satu toko yang sesuai izin. PIN tetap disiapkan/diverifikasi menurut policy. Jika shift diwajibkan, tampilkan modal awal sekali saat membuka shift; jangan menanyakan toko lagi bila shift sudah aktif.
5. **Pengaturan lanjutan:** dapat dibuka kemudian untuk cabang/toko tambahan, gudang terpisah, display/rak, pengguna, printer, atau pengaturan lainnya.

### 4.2 Penyesuaian katalog

| Kasus | Form utama | Perlakuan stok dan biaya |
|---|---|---|
| Ritel | Nama barang, harga jual, satuan dasar, stok awal bila ada | Barang yang dilacak tetap memerlukan saldo nyata sebelum bisa dijual; stok awal boleh nol |
| Jasa murni | Nama layanan dan tarif tetap/fleksibel | Tidak meminta stok awal atau HPP wajib; jadwal hanya untuk reservasi |
| Jasa + barang | Form mengikuti jenis item | Layanan tidak melacak stok; barang dan komponen fisik mengikuti stok lokasi default |
| Paket/BOM | Pertahankan aturan komponen yang sudah ada | Jangan menganggap paket berisi jasa saja bila ada bahan/barang fisik yang harus dikurangi |

- SKU/barcode, kategori detail, foto, level harga, dan konfigurasi lanjutan tidak menjadi penghalang input pertama bila kebijakan memang mengizinkan.
- Nama dan tarif layanan tetap terbawa ke pembayaran, pesanan, piutang, serta penyimpanan offline; HPP layanan tetap opsional.
- Jika pengguna memasukkan stok awal, gunakan lifecycle pembukaan stok dan valuasi yang berlaku. Nilai/akun yang diwajibkan harus diselesaikan atau ditandai belum diposting; jangan menyimpan saldo tanpa sumber dan jangan membuat HPP nol palsu.
- Sediakan penjelasan dan tautan tindakan ketika barang belum dapat dijual, bukan memaksa ulang seluruh setup.

### 4.3 Ringkasan kesiapan yang ringkas

Tampilkan hasil yang mudah dimengerti, bukan checklist teknis panjang:

- Toko siap — disiapkan otomatis bila memenuhi syarat.
- Barang/layanan — tambahkan pertama atau kelola katalog.
- Kasir — lanjutkan PIN/shift hanya bila policy mewajibkan.
- “Pengaturan lanjutan” — untuk kebutuhan lain, tidak memblokir pengguna sederhana tanpa alasan bisnis.

Pisahkan:

- **Konteks siap:** toko, lokasi operasional, cabang pengelola, izin, dan konfigurasi konsisten.
- **Dapat masuk kasir:** identitas/operator, akses, PIN/shift sesuai policy, dan konteks siap.
- **Dapat menjual item:** item aktif, tarif valid, stok/komponen cukup, dan validasi transaksi terpenuhi.

Tidak adanya stok positif pada barang tertentu tidak boleh memblokir penjualan layanan yang sah. Barang itu sendiri tetap tidak boleh dijual bila stok kurang. Katalog kosong tetap terlihat sebagai kondisi kosong, bukan sukses setup yang menyesatkan.

## 5. Persiapan otomatis di backend

### 5.1 Kelayakan jalur otomatis

- Hanya workspace baru/belum mempunyai setup operasional yang dibuat melalui konteks produk POS dan pengguna berizin.
- Profil inventory simple dapat menjadi default **ketika belum ada konfigurasi inventory eksplisit**. Jangan menurunkan centralized, advanced, atau custom menjadi simple.
- Instansi lama dengan satu pasangan lokasi/toko valid: pakai pasangan tersebut, jangan buat baru.
- Ada transaksi, transfer, stok, konfigurasi display/transit, beberapa kandidat toko/lokasi, atau hubungan yang ambigu: pertahankan data dan masuk pemulihan/pengaturan terpandu yang relevan, bukan menebak.
- Pengguna kasir tanpa izin setup tidak boleh memicu pembuatan toko/gudang; arahkan dengan penjelasan kepada pemilik/admin.

### 5.2 Data yang disiapkan

- Satu toko POS aktif dengan nama/telepon dari profil usaha; nama bisa diubah kemudian.
- Satu lokasi penjualan/stok operasional yang valid bila belum tersedia. Untuk jasa murni, lokasi ini adalah kebutuhan internal model saat ini dan tidak ditampilkan sebagai tugas “buat gudang”.
- Cabang pengelola diambil dari hubungan organisasi yang sah dan tidak ambigu. Jangan mengubah cabang organisasi hasil seed menjadi gudang secara asal.
- Hubungkan toko ke lokasi stok dan cabang pengelola yang benar. Jurnal harus tetap mengikuti cabang penanggung jawab toko, bukan otomatis ID gudang.
- Tidak membuat gedung, ruangan, rak, stok display, lokasi transit, saldo awal, ataupun dokumen transaksi jika tidak diperlukan.
- Jangan membuat satu set lokasi baru setiap kali user/perangkat berbeda login ke instansi yang sama.

### 5.3 Antarmuka yang diusulkan, bukan API yang sudah ada

Audit terlebih dahulu `CreateInstansi`, `UpdatePOSDefaults`, `AddPOSToko`, layanan lokasi, dan runtime/readiness yang sudah tersedia. Hindari merangkai dua mutasi pembuatan terpisah pada client tanpa perlindungan transaksi/idempotensi server.

Operasi POS khusus, **nama tentatif** `EnsurePOSInitialSetup`, dapat menjadi orkestrator:

| Kontrak | Rencana |
|---|---|
| Input | `client_request_id`, versi setup; profil hanya bila belum diterapkan melalui kontrak yang sah |
| Scope | Instansi dan aktor dari autentikasi server, bukan `instansi_id` pilihan client |
| Output | Status, ID toko/lokasi yang dipakai, apakah dibuat/dipakai ulang, alasan jika perlu tindakan, kesiapan yang otoritatif |
| Efek | Membuat/hubungkan konteks minimum dalam satu transaksi, menyimpan metadata bootstrap dan audit |
| Retry | ID permintaan disimpan per akun + instansi di perangkat; server mengembalikan hasil yang sama sesudah respons hilang |
| Konkurensi | Constraint/identitas bootstrap per instansi dan versi mencegah dua request berbeda membuat dua pasangan default |

Nama field, enum status, model metadata, indeks unik/parsial, dan pemetaan permission di atas harus difinalkan saat audit implementasi. Jangan mengirim operasi/field ini dari aplikasi sebelum terdaftar pada schema, resolver, middleware autentikasi, dan kontrak kedua client.

### 5.4 Readiness dan kompatibilitas

- Pertahankan kebenaran field seperti `has_initial_stock`, `has_linked_store`, dan `has_sellable_warehouse`; jangan sekadar memaksa semuanya `true`.
- Audit seluruh pemakai `operational_readiness.ready` sebelum mengubah definisinya. Versi lama tidak boleh menerima perubahan arti boolean tanpa strategi kompatibilitas.
- Rekomendasi: kontrak kesiapan berversi/field tambahan untuk membedakan konteks, akses kasir, dan langkah opsional. Nama tentatif seperti `can_enter_cashier`, `blocking_reasons`, dan `optional_steps` **belum tersedia**.
- Guide mobile dan Vue menampilkan hambatan yang sama dari server; validasi checkout tetap berjalan walaupun checklist setup sudah selesai.

## 6. Lifecycle, kegagalan, dan offline

| State yang direncanakan | Perilaku |
|---|---|
| `not_started` | Profil usaha belum cukup atau belum ada konteks |
| `provisioning` | Tampilkan progres, cegah submit ganda, bahasa tetap tersedia |
| `ready` | Konteks minimum server valid; lanjut katalog/keamanan yang belum selesai |
| `requires_action` | Ada konfigurasi lama/ambigu/izin kurang; tampilkan tindakan spesifik tanpa menimpa data |
| `retryable_failure` | Gangguan koneksi/layanan; pertahankan input dan identitas request |

- Registrasi/perangkat baru tanpa cache perlu online untuk membuat instansi dan bootstrap. Jangan menghasilkan ID toko/lokasi lokal palsu ketika offline.
- Respons bootstrap hilang: periksa status server dengan identitas operasi yang sama sebelum membuat ulang.
- Aplikasi ditutup setelah workspace dibuat: lanjutkan dari workspace yang sama; jangan kembali membuat instansi kedua.
- Gagal mengunggah logo tidak membatalkan toko yang sudah sah dan tidak mengulangi pembuatan konteks.
- Akun lama yang sudah punya cache valid tetap mengikuti kebijakan offline yang berlaku; proses setup baru tidak boleh menghapus antrean transaksi yang belum tersinkron.
- PIN/izin/shift yang dicabut atau ditutup dari terminal lain tetap diperiksa server saat online/sinkronisasi. Bootstrap bukan bypass keamanan.
- Akun/instansi berganti saat request berjalan: respons lama tidak boleh diterapkan ke scope baru.
- Galat validasi, akses ditolak, dan ketidakkonsistenan konfigurasi tidak disamakan dengan gangguan jaringan yang boleh diantrekan.

## 7. Security, policy, dan observabilitas

- Tidak mempercayai klaim owner/admin atau scope dari payload. Audit otorisasi setup terhadap ownership/permission yang sudah ada; jangan memberi role tambahan otomatis.
- Wajib terdaftar pada auth middleware bila ada operasi baru. Pastikan user tenant lain atau POS operator tanpa izin tidak dapat membaca/mengubah hasil bootstrap.
- Jangan menerbitkan trial/langganan tambahan setiap retry, mengubah paket, atau mengubah akses lintas aplikasi HR/Finance lewat bootstrap POS.
- Simpan aktor, instansi, versi/request ID, hasil reuse/create, waktu, dan alasan `requires_action` pada audit. Jangan mencatat token, PIN, password, atau payload sensitif ke log.
- Pantau keberhasilan bootstrap, duplikasi, waktu sampai katalog/transaksi pertama, error konfigurasi, dan frekuensi pengguna membuka pengaturan lanjutan. Metrik adalah rencana instrumentasi, bukan hasil pengukuran sekarang.

## 8. NON-GOALS

- Tidak merombak alur pembelian, penerimaan, transfer, opname, retur, refund, dan akuntansi yang sudah ada.
- Tidak menghapus menu inventory atau kemampuan multi toko/gudang.
- Tidak membuat fitur penjualan jasa tanpa stok menjadi alasan meniadakan tracking bahan/resep.
- Tidak mematikan PIN/shift atau mengisi modal awal Rp0 secara diam-diam.
- Tidak menambah wizard operating needs/default transaksi/mode usaha baru.
- Tidak melakukan reset akun, migrasi massal, aktivasi produksi, build, atau perubahan data hanya karena dokumen rencana ini dibuat.

## 9. Tahapan implementasi dan kriteria selesai

| Tahap | Pekerjaan | Kriteria selesai |
|---|---|---|
| 0. Audit kontrak | Petakan create workspace, seed cabang, toko/lokasi, izin, policy inventory, Finance branch, readiness, dan dukungan transaksi | Daftar kontrak/consumer dan keputusan schema/permission/kompatibilitas disetujui; tidak ada mutasi produksi |
| 1. Bootstrap server | Layanan POS khusus, guard kelayakan, transaksi, idempotensi, audit, reuse data | Tes respons hilang, dua perangkat/request berbeda, rollback parsial, cross-tenant, dan hak akses PASS pada database terisolasi |
| 2. Integrasi mobile | Form usaha yang ada → progres otomatis → katalog pertama → PIN/shift sesuai policy | Tidak membuka form toko/lokasi manual pada jalur baru; gagal/retry/resume tidak buntu; header bahasa/scroll tetap benar |
| 3. Integrasi Vue | Gunakan kontrak dan readiness sama; akses pengaturan lanjutan tetap tersedia | Toko/lokasi yang dibuat mobile terlihat benar di web dan sebaliknya; tidak ada query/schema mismatch |
| 4. Guide/katalog ringkas | Langkah kontekstual, input barang/jasa sederhana, stok nol bukan pemblokir jasa | UI tidak memalsukan kesiapan atau melemahkan validasi item; profil campuran dan BOM aman |
| 5. Regresi dan E2E | Jalankan matriks berikut; perbaiki temuan | Hasil tertulis, tidak ada klaim PASS bagi skenario yang belum dijalankan |
| 6. Aktivasi bertahap | Mulai tenant/perangkat QA, lalu workspace baru yang memenuhi syarat | Konfigurasi lama identik, metrik diperiksa, jalur pemulihan dan rollback disepakati sebelum aktivasi lebih luas |

## 10. Matriks pengujian yang wajib dijalankan

Semua baris di bawah **BELUM DIUJI untuk rencana fitur ini**. Tes setup/header yang telah ada adalah baseline, bukan bukti bootstrap otomatis sudah bekerja.

| Skenario | Bukti kelulusan yang diminta |
|---|---|
| Ritel baru + inventory simple | Satu toko/lokasi valid, tanpa input gudang/toko manual; tambah barang → saldo pembukaan nyata → jual |
| Jasa murni | Tambah layanan tanpa HPP/stok awal; jual langsung dan reservasi; tidak diblokir inventory |
| Jasa campuran | Layanan dapat dijual saat barang fisik lain stoknya nol; barang tersebut tetap tidak dapat terjual tanpa stok |
| Tarif fleksibel jasa | Tarif yang disepakati bertahan sampai tunai, pesanan, piutang, dan pemulihan offline |
| Restoran, laundry, bengkel, salon, custom | Profil/fitur tetap benar; meja/dapur/berat/booking tidak hilang karena UI ringkas |
| Inventory centralized, advanced, custom | Tidak diubah ke simple; aturan sumber stok, display, transit, batch dan serial tetap berlaku |
| Tenant lama punya toko/lokasi | Reuse tanpa menambah duplikat atau mengubah default, saldo, dan riwayat |
| Konfigurasi ambigu/belum lengkap | Tindakan pemulihan spesifik; tidak mengikat toko pada cabang/gudang sembarang |
| Dua login/perangkat bersamaan | Hanya satu pasangan konteks default; identitas aktor dan izin tetap benar |
| Submit ganda/timeout/respons hilang | ID tetap; query/status/retry mengembalikan hasil yang sama |
| Crash setelah workspace atau di tengah bootstrap | Resume tidak membuat instansi/toko/lokasi kedua; transaksi parsial tidak tertinggal |
| PIN, shift, izin dan subscription | Tidak ada bypass; shift aktif otomatis dipakai; modal awal tidak diasumsikan |
| Offline pertama kali | Pesan butuh koneksi, tidak ada toko lokal palsu atau data setengah siap |
| Offline akun yang sudah siap | Cache/antrean lama utuh; sinkronisasi tetap idempoten dan mengecek aktor/shift/izin |
| Pembelian–terima–transfer–opname–retur | Sumber stok dan jurnal tetap memakai lokasi/cabang yang benar, tidak berubah oleh bootstrap |
| Pembayaran dan piutang | Nominal, pajak, pelanggan, jurnal/cabang, outstanding, dan status pembayaran konsisten |
| Logo gagal/bahasa/keyboard/scroll | Konteks yang sudah tersimpan tidak dibuat ulang; input dan akses bahasa tetap tersedia |
| Scope berganti/cross-tenant/kasir terbatas | Tidak ada data dari instansi lain atau pembuatan konteks tanpa otorisasi |
| Tampilan | Android HP/tablet, portrait/landscape; Vue responsif; empty/loading/error/retry terlihat jelas |

## 11. OPEN QUESTIONS dan HANDOFF

Rekomendasi produk sudah cukup untuk mulai audit implementasi. Hal-hal berikut perlu difinalkan pada tahap 0, bukan dijawab oleh pengguna UMKM pada wizard:

1. Nama operasi, penyimpanan metadata bootstrap, serta constraint unik/idempotensi yang kompatibel dengan koleksi produksi.
2. Cara menandai workspace baru yang memenuhi syarat tanpa menganggap semua tenant minim data sebagai tenant baru.
3. Versi readiness dan perilaku client lama; jangan mengganti makna boolean existing tanpa kajian.
4. Pemilihan cabang pengelola default bila hasil seed/ownership tidak menghasilkan satu kandidat yang sah.
5. Pemetaan hak setup pemilik/admin terhadap izin pembuatan toko dan lokasi yang berlaku; tidak menambah role diam-diam.

**Handoff:** lanjutkan tahap 0 (audit kontrak dan keputusan arsitektur), lalu implementasi bertahap dengan tes gagal terlebih dahulu, perbaikan, dan bukti kelulusan. Jangan langsung mengaktifkan bootstrap otomatis untuk seluruh instansi.

### Rujukan

- [Setup usaha terpadu yang sudah diterapkan](combined-business-setup-20261117.md).
- [Header bahasa dan scroll setup](setup-language-header-20261118.md).
- [Layanan langsung dan reservasi](service-direct-reservation-20261118.md).
- [Rencana historis Retail Solo](RETAIL_SOLO_CAPABILITY_PLAN.md) — konteks terdahulu, bukan bukti kondisi sekarang.
- [Shopify: initial inventory setup](https://help.shopify.com/en/manual/inventory-and-locations/setup/initial-inventory-setup) — pembanding UX untuk satu lokasi default dan layanan tanpa pelacakan stok; bukan spesifikasi atau kebijakan Pantoo.
