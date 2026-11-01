# Rencana kapabilitas: Retail Sederhana untuk UMKM satu orang

Status: rancangan, **belum diimplementasikan**. Dibuat 29 Oktober 2026.

## CAPABILITY

Pemilik toko kecil dapat menyiapkan satu outlet, mendaftarkan barang, menerima kulakan, menjual, mengembalikan barang, dan melihat hasil harian sendiri melalui Pantoo POS mobile atau web tanpa harus membuat struktur staf, approval berlapis, atau membuka menu yang tidak relevan. Mode ini menyederhanakan pengalaman dan kebijakan yang memang opsional; ia **bukan** profil bisnis baru dan tidak boleh mengurangi kontrol integritas stok, kas, dan audit.

## Kondisi sekarang dan batas yang terbukti

- Profil bisnis `retail` sudah ada: meja, dapur, layanan, reservasi, delivery, dan wajib pelanggan nonaktif; tracking stok aktif; pemenuhan default bawa pulang. Penjualan tunai tanpa pelanggan, pengurangan stok, dan riwayat telah diuji pada toko dummy. Ini menjawab kebutuhan penjualan dasar, tetapi belum menjawab seluruh operasional satu orang.
- Kunci PIN dan shift aktif adalah kebijakan default; `pos_lock_enabled` dan `allow_out_of_shift` sudah dapat diatur. Tidak perlu membuat implementasi paralel untuk mengabaikannya.
- PO dapat memakai workflow `is_auto_approve=true` (“Tanpa Approval”), tetapi workflow harus dikonfigurasi. Form PO dan daftar dokumen tersedia; pengajuan sampai penerimaan belum lulus uji end-to-end pada sesi ini.
- “Pembelian Langsung” saat ini mensyaratkan pemohon, penyetuju, dan pembayar berbeda. Ia bukan jalur kulakan satu-orang. Operasi ini juga menggunakan transaksi MongoDB; pendaftaran autentikasinya baru diperbaiki di kode dan perlu uji runtime setelah backend dimuat ulang.
- `runInventoryTransaction` secara default menolak operasi stok multi-dokumen pada MongoDB standalone. Fallback non-atomik hanya ada jika operator secara eksplisit mengaktifkan `PANTOO_ALLOW_STANDALONE_INVENTORY_FALLBACK=1`; fallback itu **bukan** dasar yang aman untuk menjanjikan kulakan/retur/penerimaan tanpa risiko setengah-terproses. Pengguna sebelumnya menyatakan replica set belum didukung sekarang.

## CONSTRAINTS

### Aturan tetap

1. Mode sederhana tidak mengubah `business_profile=retail` menjadi profil baru; ia adalah preferensi pengalaman/operasional di atas kebijakan POS yang sama. Ganti mode tidak boleh mengubah transaksi historis, izin, atau stok diam-diam.
2. Setiap penjualan dan perubahan stok memiliki identitas operasi, toko/lokasi, aktor, waktu, status, serta jejak audit. Nominal dan kuantitas tidak boleh berubah dua kali akibat ketukan ulang, retry, atau sinkronisasi offline.
3. Produk fisik yang melacak stok tidak boleh tiba-tiba menjadi produk tanpa stok hanya untuk menghindari penolakan transaksi. Pilihan “stok tidak dipantau” harus eksplisit per produk dan terlihat sebelum produk dijual.
4. Transaksi yang masih `pending` akibat koneksi/penyimpanan tidak boleh ditampilkan sebagai berhasil final. Stok yang belum final tidak boleh dianggap tersedia untuk dijual.
5. Kebijakan satu orang hanya berlaku untuk pemilik/operator yang berizin pada instansi tersebut. Pengguna dengan beberapa kasir tetap memakai identitas operator dan batas izin masing-masing. Tidak ada bypass otorisasi dari sisi UI.
6. Web admin dan mobile membaca preferensi serta status operasi dari backend yang sama. Offline mobile boleh menahan antrean lokal, tetapi server tetap otoritas akhir saat sinkronisasi.

### Pilihan arsitektur yang disarankan

- Tambahkan `operating_mode=standard|retail_solo` pada pengaturan POS yang tersimpan per instansi/outlet sesuai model kebijakan sekarang. **Keputusan final tentang scope penyimpanan masih terbuka**; jangan menyimpan flag hanya di perangkat.
- Bangun “Catat Kulakan” sebagai alur terpandu di atas kontrak pembelian/penerimaan yang tervalidasi, bukan mengubah aturan pemisahan tugas pada “Pembelian Langsung”.
- Karena tidak ada replica set, rancang protokol operasi stok yang dapat dilanjutkan ulang: dokumen operasi ber-ID idempoten, perubahan saldo yang menyimpan ID efek yang telah diterapkan, status `pending/applying/completed/needs_reconciliation`, dan proses pemulihan. Sebelum desain ini lulus uji crash/retry/konkurensi, **jangan** mengaktifkan alur satu-klik yang menyentuh beberapa dokumen stok/keuangan. Alternatif yang lebih sederhana secara operasional adalah mengaktifkan transaksi database pada infrastruktur; itu bukan asumsi untuk rilis sekarang.

## IMPLEMENTATION CONTRACT

### Aktor dan permukaan

- **Pemilik/operator solo:** Android POS, kasir, katalog, stok, “Catat Kulakan”, riwayat, laporan harian.
- **Admin web:** pengaturan mode, produk dan supplier lanjutan, rekonsiliasi operasi bermasalah, audit.
- **Backend:** satu policy runtime, validasi GraphQL, idempotensi, audit, sinkronisasi, dan recovery.

### Alur pengguna target

1. **Mulai cepat:** pilih “Retail / Toko” lalu opsi “Saya kelola sendiri”. Buat/pilih outlet dan satu lokasi stok default. Identitas akun pemilik menjadi operator awal; tawarkan PIN perangkat, dengan penguncian tetap dapat diaktifkan. Jelaskan pilihan “Pantau kas per shift” (default aman: aktif) dan izinkan melewati shift hanya bila `allow_out_of_shift` disimpan oleh pengguna berizin.
2. **Tambah barang:** form ringkas berisi nama, harga jual, dan pilihan `Stok dipantau / Tidak dipantau`; jika dipantau, masukkan stok awal dan satuan. SKU/barcode, HPP, pajak, level harga, dan resep tetap tersedia pada “Opsi lanjutan”. Stok awal harus tercatat sebagai pembukaan, bukan angka saldo tanpa sumber.
3. **Jual:** masuk ke kasir, cari/scan barang, pilih kuantitas, bayar tunai atau metode yang sudah aktif, struk opsional. Pelanggan tidak wajib. Produk habis ditolak dengan pesan dan tautan ke stok; hasil penjualan hanya final setelah server mengakui atau ditandai jelas sebagai antrean offline.
4. **Kulakan:** aksi “Catat Kulakan” mengumpulkan barang, jumlah, harga beli, supplier (boleh “Tidak dicatat” hanya bila aturan bisnis mengizinkan), toko/lokasi default, tanggal, bukti opsional/berdasarkan ambang, dan status bayar. Ringkasan memperlihatkan stok sebelum/sesudah dan total biaya. Jika barang sudah datang, proses penerimaan; jika belum, simpan sebagai pesanan/pending tanpa menaikkan stok. Status bayar tidak boleh otomatis disamakan dengan status terima.
5. **Koreksi akhir hari:** tampilkan penjualan, kas masuk, pembelian, retur, stok terbuang, dan operasi yang masih pending. Jika shift diaktifkan, lakukan hitung kas/tutup shift; jika tidak, tampilkan ringkasan harian tanpa angka “kas seharusnya” yang menyesatkan.
6. **Retur dan pembatalan:** rujuk invoice/dokumen asal, pilih jumlah dan alasan, lalu terapkan efek refund/restock sekali saja. Jika kulakan gagal di tengah, tampilkan “Perlu ditinjau”, bukan tombol submit ulang tanpa konteks.

### State dan kontrak data

| Objek | State minimum | Invarian penting |
| --- | --- | --- |
| Setup solo | `not_started → ready` | Mode tidak aktif bila outlet/lokasi/izin minimum belum siap. |
| Pembelian barang | `draft → ordered/received → completed` atau `cancelled` | `ordered` tidak menaikkan stok; `received` mencatat kuantitas diterima, termasuk parsial. |
| Penerapan efek stok | `pending → applying → completed` atau `needs_reconciliation` | ID efek unik; retry tidak menambah stok dua kali. |
| Pembayaran kulakan | `unpaid/partial/paid` | Terpisah dari state penerimaan. |
| Penjualan offline | `queued → syncing → committed/conflict` | Nomor lokal dan idempoten server; konflik tidak diubah menjadi sukses diam-diam. |

Antarmuka backend minimum: baca/update policy mode, `GetRetailSoloReadiness`, buat/ambil operasi kulakan dengan `request_id`, terima barang parsial dengan ID efek per item, baca status rekonsiliasi, dan aksi koreksi terbatas bagi operator berizin. Nama operasi final harus mengikuti skema GraphQL yang ada setelah audit kontrak; **jangan** mengasumsikan endpoint baru sudah tersedia.

### Kegagalan yang wajib ditangani

- Submit ganda, jaringan putus setelah server menerima, aplikasi ditutup saat proses, dua perangkat menerima barang yang sama, stok berubah sebelum penerimaan, supplier/produk dihapus, harga beli berubah, retur melebihi jumlah asal, pembayaran parsial, dan penjualan offline dari beberapa kasir.
- Setiap kasus memiliki status terlihat, instruksi pemulihan, dan tes otomatis. Bukti sukses bukan hanya respons HTTP, tetapi saldo stok, dokumen, audit, dan tampilan mobile/web yang konsisten.

## NON-GOALS rilis pertama

- Tidak membuat akuntansi penuh, penggajian, approval bertingkat, manajemen banyak gudang, atau invoice tempo kompleks lewat UI sederhana.
- Tidak menonaktifkan keamanan PIN/shift secara diam-diam untuk semua tenant.
- Tidak menggunakan fallback stok non-atomik sebagai jalan pintas produksi.
- Tidak menggantikan profil restoran, laundry, bengkel, atau fitur lanjutan yang sudah ada.

## OPEN QUESTIONS

1. Apakah “Retail Sederhana” dipilih per instansi atau per outlet? Rekomendasi: per outlet dengan default instansi, karena satu instansi bisa memiliki toko kecil dan besar sekaligus.
2. Apakah shift default tetap aktif? Rekomendasi: ya, tetapi pembukaan kas awal Rp 0 dan tutup shift dibuat satu layar ringkas; pemilik dapat memilih tanpa shift secara sadar.
3. Apakah supplier boleh kosong dan apakah pembelian belum dibayar masuk tahap pertama? Rekomendasi MVP: supplier opsional untuk pembelian tunai langsung; utang/tempo tetap jalur PO dan payable yang lebih lengkap.
4. Apakah backend akan dibawa ke replica set atau dibangun protokol idempotensi/recovery untuk standalone? Keputusan ini **menghalangi** janji kulakan/penerimaan stok satu-klik yang aman. Selama belum diputuskan, mulai dari penyederhanaan penjualan/setup tanpa mengubah alur stok kritis.

## HANDOFF / urutan implementasi

| Tahap | Hasil dan kriteria selesai |
| --- | --- |
| 0 — kontrak dan uji baseline | Audit GraphQL, izin, stok, dan database produksi; jalankan E2E PO→terima→jual→retur pada toko dummy. Tidak ada klaim “aman standalone” sebelum hasil ini. |
| 1 — pengalaman solo penjualan | Pilihan mode di onboarding mobile/web; wizard toko/lokasi/operator; form produk ringkas; menu sederhana dengan akses “Semua fitur”; shift opsional sesuai policy. Tes kasir tunai, PIN, tanpa pelanggan, stok habis, dan offline. |
| 2 — mesin kulakan aman | Putuskan strategi database; implementasikan idempotensi, state operasi, recovery, dan tes crash/retry/dua perangkat. Integrasikan PO tanpa approval untuk skenario satu orang tanpa melemahkan “Pembelian Langsung” ber-approval. |
| 3 — UI Catat Kulakan | Wizard mobile dan web, penerimaan parsial, status bayar, bukti, dan penanganan pending. E2E lengkap dari barang dibeli sampai stok terjual dan retur. |
| 4 — rollout | Aktifkan per toko dummy, observasi error/rekonsiliasi, migrasi preferensi aman, baru buka untuk tenant lain. |

Tahap 1 siap dirinci dan diimplementasikan. Tahap 2–3 membutuhkan keputusan arsitektur stok standalone dan audit transaksi sebelum pembangunan UI yang menjanjikan finalisasi instan.
