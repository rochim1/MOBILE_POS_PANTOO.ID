# QA profil POS dan inventori — 30 Oktober 2026

## Keputusan singkat

**Jalur server order → pembayaran → stok lulus pada seluruh 21 kombinasi (7 profil bisnis × 3 profil inventori), tetapi belum dapat dinyatakan seluruhnya lulus end-to-end pada UI nyata.** Pengujian ini mencakup kontrak backend–Flutter–Vue, logika stok/inventori, dan alur PO → penerimaan → transfer display nyata pada satu instansi uji. Untuk matriks 21 kombinasi, tiap skenario memakai tenant dan stok terisolasi di MongoDB sementara; profil instansi produksi tidak diubah. Status yang belum diuji langsung di UI ditandai jelas, bukan dianggap lulus.

## Lingkungan dan metode

- Repo: `presensi_zera_BE`, `mobile_POS_Pantoo`, `front_end_template` pada 30 Oktober 2026. Emulator Android 16 memakai flavor `production`; Vue lokal di `http://localhost:5173`.
- Tes backend integrasi memakai MongoDB sementara lokal, bukan mutasi database produksi. Tes baru `tests/pos_profile_inventory_e2e.integration.test.js` membuat tenant, pelanggan, toko, lokasi stok, dan produk tersendiri untuk tiap kombinasi profil. Pengujian UI PO–stok yang sudah disetujui pemilik memakai produk, supplier, gudang, dan display berawalan `[UJI]` di instansi `6a856ce9517424ebab833ba9`; rinciannya ada di [laporan PO–stok](E2E_MOBILE_WEB_20261030.md).
- PASS kontrak = aturan/schema diuji otomatis. PASS UI = aksi serta akibatnya diamati langsung. Keduanya tidak disamakan.
- Tidak ada baseline screenshot tiga ukuran layar, sehingga regresi visual keseluruhan **inkonklusif**.

## Matriks semua profil

| Profil | Aturan yang teruji otomatis | Hasil kontrak | Uji transaksi UI profil tersebut |
| --- | --- | --- | --- |
| Retail / Toko | Stok aktif; tanpa meja/dapur/order layanan; takeaway tetap ada; larangan jual dari gudang pusat pada profil lokasi terkait | PASS | Checkout tunai dan stok lintas Flutter–Vue PASS pada toko dummy; variasi retur/batch/offline belum diuji langsung |
| Restoran / Cafe | Stok aktif; meja, dapur, delivery; opsi dine-in, tanpa meja, quick service, takeaway; tidak bocor ke profil lain | PASS | Belum menjalankan order meja → dapur → saji → pembayaran pada instansi restoran terpisah |
| Laundry | Stok aktif untuk material/barang campuran; order layanan, delivery, pelanggan wajib; takeaway tetap tersedia | PASS | Belum menjalankan kiloan/satuan → proses → pickup/delivery → pembayaran dan konsumsi material secara langsung |
| Bengkel | Stok aktif untuk suku cadang; order layanan, reservasi, teknisi, kendaraan, pelanggan wajib | PASS | Belum menjalankan servis + komponen/BOM → pekerjaan teknisi → pembayaran secara langsung |
| Salon / Barbershop | Stok aktif untuk produk perawatan; reservasi/staf/order layanan; tanpa dapur/kendaraan | PASS | Belum menjalankan reservasi → layanan + produk → pembayaran secara langsung |
| Jasa | Stok aktif untuk katalog campuran; reservasi/staf/order layanan; pelanggan wajib | PASS | Belum menjalankan order layanan + material → pembayaran secara langsung |
| Custom | Preset aman, pilihan fitur dipertahankan, stok aktif secara default, takeaway tidak buntu | PASS | Alur PO–penerimaan–transfer produk `[UJI]` diuji pada konfigurasi instansi aktif; kombinasi seluruh toggle custom belum diuji langsung |

Sumber matriks: `tests/pos_profile_policy.test.js` (termasuk tes per profil yang ditambahkan), `tests/pos_profile_parity.test.js`, tes katalog profil Flutter, `npm run profiles:check`, dan tes transaksi 21 kombinasi. Preset `track_stock: true` tidak berarti layanan nonstok dipotong: keputusan stok tetap berdasarkan jenis produk/`tracks_stock`; tes model Flutter memeriksa layanan nonstok dan produk komposisi.

## Pengujian transaksi 7 × 3 pada database terisolasi

Setiap kombinasi profil bisnis `retail`, `restoran`, `laundry`, `bengkel`, `salon`, `jasa`, `custom` dan profil inventori `simple`, `centralized`, `advanced` menjalankan resolver server yang dipakai aplikasi:

1. Membuat toko dengan lokasi stok yang diizinkan (untuk `advanced`, lokasi display), pelanggan, produk fisik 5 unit, dan pengaturan profil.
2. Membuat order 1 unit; saldo tetap 5 dan 1 unit ter-reservasi.
3. Membayar tunai Rp1.000; order menjadi `lunas`, saldo turun ke 4, reservasi menjadi 0.
4. Mencoba membayar ulang dan membuat order 5 unit ketika hanya 4 tersedia; keduanya ditolak dan saldo tetap 4. Profil yang mewajibkan pelanggan juga menolak order tanpa pelanggan.
5. Pada restoran, `dine_in` tanpa meja ditolak; dengan meja, statusnya menjadi `Terisi` dan stok baru ter-reservasi. Pada laundry, membuat order `delivery` dengan jumlah cucian. Pada bengkel/salon/jasa, membuat reservasi dengan jadwal; reservasi belum memotong stok.

**Hasil: 21/21 PASS.** Ini menguji lifecycle backend yang nyata dengan MongoDB replica set sementara, tetapi bukan tap-through UI Android/Vue, bukan printer/offline, dan bukan semua variasi BOM/batch/retur per profil. Order awal memakai `source: web_order` agar tes tidak memerlukan shift kasir; oleh karena itu batas PIN/shift diuji oleh suite terpisah, bukan oleh matriks ini.

## Matriks inventori lintas profil

| Alur | Bukti | Status |
| --- | --- | --- |
| Katalog profil dan kemampuan web/mobile/backend | 13/13 tes backend profil; tes Flutter katalog dan onboarding; pengecekan katalog Vue; 21/21 lifecycle server | PASS kontrak + lifecycle server |
| PO → approval → penerimaan → stok gudang → isi rak display | `PO-20261030-0002` diterima di Android; gudang 7→8; `TRF-20261030-0001` memindah 1; akhir gudang/display 7/7 | PASS UI untuk fixture `[UJI]` |
| Penerimaan parsial, batas jumlah, satuan, batch/serial, jurnal pembatalan | Tes backend `inventory_purchase_receiving.contract.test.js`; tes Flutter penerimaan | PASS kontrak, belum seluruh variasi di UI |
| Transfer lokasi, stok display, alokasi, penjurnalan | Tes backend transfer dan display; tes Vue handoff; satu transfer Android nyata | PASS kontrak + satu jalur UI |
| Stock opname, scrap/terbuang, retur pembelian | Tes backend lokasi/snapshot/retur; tes Flutter hub/retur; tes modal Vue | PASS kontrak, belum mutasi UI per profil |
| FIFO/AVCO, HPP, BOM, sinkronisasi keuangan | 72 tes backend lanjutan mencakup FIFO, HPP snapshot/BOM, koreksi biaya, jurnal POS–inventori | PASS kontrak/integrasi lokal; belum uji kasir per profil dengan BOM nyata |
| Offline dan dua kasir | Tes kontrak mobile safety/offline serta backend multi-kasir | PASS kontrak; sinkronisasi dua perangkat fisik belum diuji |
| Query GraphQL mobile dan web terhadap schema/auth | 24/24 tes kontrak setelah perbaikan | PASS |

## Ketidaksesuaian yang diperbaiki

1. **Riwayat penerimaan mobile dapat gagal dimuat.** Query Flutter meminta `InventoryReceiving.client_request_id`, tetapi tipe GraphQL output belum mendeklarasikannya meski input, model MongoDB, dan proses idempotensi sudah menyimpan field itu. Field output ditambahkan pada `graphql/inventory_purchase/inventory_purchase.typedef.js`. Tes kontrak query mobile + web kini 24/24 PASS. Backend yang berjalan perlu dimulai ulang/deploy agar schema baru aktif.
2. **Gudang penerimaan mobile bisa salah tanpa disadari.** Sebelumnya form memilih lokasi shift/default bila beberapa gudang tersedia, walau alamat PO bisa menunjuk gudang lain. Karena PO hanya menyimpan alamat teks, bukan ID lokasi stok, form sekarang hanya otomatis memilih jika tepat satu gudang penerimaan tersedia; jika lebih dari satu operator wajib memilih. `flutter analyze` pada halaman tersebut: tidak ada masalah. Perilaku baru belum diuji ulang pada APK yang dibangun ulang.
3. **Tes modal konsinyasi web memakai bentuk respons lama.** Fixture `inventory-modal-safety.test.mjs` masih mengirim daftar datar `GetInventoryConsignmentEntries`, padahal UI memakai `GetInventoryConsignmentEntryPage { items, totalCount }`. Fixture diperbarui dan juga memeriksa `entriesTotal`; 27/27 tes web inventori PASS. Ini perbaikan tes, bukan klaim adanya bug produksi pada modal.
4. **Fixture tes dimensi PO menyalin kunci idempotensi.** Salinan PO untuk menguji race approval memakai `client_request_id` dokumen asal, sehingga indeks unik menolak fixture sebelum perilaku yang dituju diuji. Salinan sekarang diberi kunci uji tersendiri.
5. **Tes kontrak uang muka masih mencari nama query lama.** Mobile kini memakai `GetPurchaseAdvancePage` (paginasi), sedangkan tes masih mencari `GetPurchaseAdvanceRequests`. Ekspektasi diperbarui; tes tetap memverifikasi bahwa mobile hanya bisa meminta/membaca DP, bukan menjalankan pembayaran Finance.

## Hasil eksekusi

- Backend profil: **13/13 PASS**.
- Backend POS, pembelian, inventori, retur, FIFO/HPP, GraphQL: **242/242 PASS** pada pengulangan berurutan setelah koreksi dua fixture; matriks transaksi 7 × 3: **21/21 PASS**, termasuk stok kurang, pembayaran ulang, pelanggan wajib, dan dine-in tanpa meja. Tes query khusus mobile/web: **24/24 PASS**.
- Flutter seluruh berkas tes yang namanya terkait POS, inventori, pembelian, stok, dan offline: **200/200 PASS**. `flutter analyze` seluruh aplikasi: **No issues found** (210,8 detik).
- Vue seluruh berkas tes yang namanya terkait POS, inventori, pembelian, dan payable: **49/49 PASS**; `npm run profiles:check` PASS.
- Lari backend pertama dalam lingkungan terbatas gagal memulai MongoDB sementara (`EACCES`/`fassert`); ulang dengan akses loopback dan secara berurutan berhasil. Ini hambatan lingkungan, bukan kegagalan fungsional yang tersisa.
- Vue `inventory/receiving` berhasil dibuka dan antrean PO tampil. Upaya membuka tab riwayat GRN ditolak oleh kontrol keamanan browser karena target klik tidak dapat dipastikan; tidak diakali. Verifikasi status akhir PO/GRN/transfer dari UI Vue **belum selesai**.
- Vue `pos/pengaturan-pos` terbuka dalam mode **lihat saja** pada sesi pengujian. Daftar tujuh profil bisnis tampil lengkap, tetapi sesi ini tidak punya izin mengubah pengaturan; tidak dilakukan pergantian profil instansi produksi. Halaman pengaturan inventori juga terbuka dan menampilkan bagian prefix/operasional, tanpa mutasi.

## Yang masih perlu sebelum klaim “semua profil aman”

1. Tenant sementara sudah menguji lifecycle server 21 kombinasi. Untuk klaim UI produksi, tetap perlu instansi uji terpisah bagi restoran, laundry, bengkel, salon, jasa, dan custom agar order/dapur/reservasi/retur dapat ditap langsung pada Android dan Vue tanpa mengganti profil instansi produksi yang sedang beroperasi.
2. Bangun ulang Android dan verifikasi bahwa PO dengan beberapa gudang benar-benar meminta pilihan gudang, serta satu gudang tetap terpilih otomatis.
3. Setelah backend schema baru aktif, buka riwayat penerimaan pada mobile dan pastikan tidak muncul error query. Cocokkan hasil PO/GRN/transfer dari UI Vue ketika kontrol browser mengizinkan verifikasi baca-saja.
4. Uji negatif operasional: penerimaan ganda/idempotensi setelah koneksi putus, dua kasir offline, batch kedaluwarsa, retur parsial, stok nol, pembatalan PO/GRN, serta printer dokumen/struk per profil.

**Verdict saat ini: PASS untuk lifecycle server 21 kombinasi dan jalur PO–stok yang diuji; INCONCLUSIVE untuk klaim end-to-end semua profil di UI.** Jangan menyamakan tes lifecycle server dengan uji tap-through Android/Vue pada tujuh instansi nyata.

## Tambahan verifikasi operator dan retur Android (30 Oktober 2026)

- Emulator Android development diuji dengan dua akun QA terbatas di Toko Bandung `[Dummy]`. Keduanya masuk lewat PIN; sapaan, menu, dan identitas toko mengikuti operator. Katalog dan riwayat berhasil dimuat pada shift bersama setelah scope terminal/operator diselaraskan. Sebelum perbaikan, kasir QA tertahan karena query stok/retur mencari shift atas ID operator, sedangkan shift bersama dimiliki akun terminal.
- Retur uji `RTJ/2026/10/6AE433906FB61619E82AE4CE`: draft diajukan, supervisor QA melihat tombol `Setujui` setelah bug kondisi UI diperbaiki, lalu kasir QA melihat tombol `Proses` setelah scope retur shift bersama diperbaiki. Status akhir database `completed`; stok item pada lokasi Toko Bandung naik 469 → 470. Tidak ada perubahan stok kedua yang diamati. Retur draft `RTJ/2026/10/6AE42F196FB61619E82AE205` dibiarkan sebagai data uji, belum diproses.
- Perbaikan kode: identitas operator PIN berlaku pada request POS/inventori/retur yang relevan; cache dan favorit lokal dipisah per operator; data riwayat/pelanggan tidak diminta sebelum shift; timeout konfigurasi izin 10 → 30 detik; query shift bersama mengenali terminal terverifikasi; pembacaan katalog dan retur memakai scope shift yang sama; tombol persetujuan retur pending dirender. `flutter test` startup tanpa shift 1/1 PASS, `flutter analyze --no-pub` seluruh aplikasi No issues, tes backend PIN 8/8 PASS dan kontrak stok/retur 38/38 PASS.
- Kedua akun QA dan role sementara sudah dinonaktifkan; PIN dikosongkan dan status diverifikasi. API QA di port 8081 dihentikan. Hasil ini tetap **bukan** bukti E2E tujuh profil UI atau dua perangkat offline; bagian yang belum diuji pada tabel di atas tetap terbuka.
