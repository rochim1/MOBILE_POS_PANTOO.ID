# Rencana perbaikan hak akses dan E2E seluruh profil POS

Tanggal: 30 Oktober 2026. Dokumen ini melengkapi `QA_SEMUA_PROFIL_POS_INVENTORI_20261030.md`.

## Keputusan bisnis

- Tidak membuat role baru. Role bawaan tetap dapat digabung sesuai tugas pengguna dan dibatasi ke toko/gudang yang menjadi scope-nya.
- Kasir menjalankan shift, order, pembayaran, dan membuat retur. Kasir boleh **memproses** retur yang sudah disetujui, tetapi tidak boleh menyetujui retur sendiri.
- Supervisor meninjau pesanan aktif, dapat membatalkan **order belum dibayar**, dan menyetujui retur. Order lunas wajib melalui retur/refund, bukan dibatalkan. Aksi pembatalan saat item sudah dibuat tetap memakai pemeriksaan tambahan yang berlaku.
- Operator inventori membuat/mengirim PO, menerima barang, transfer, opname, dan memproses retur pembelian. Approver inventori menyetujui PO, transfer, opname, dan retur pembelian. Auditor hanya membaca.
- Usaha satu orang dapat memegang role kasir + operator inventori + approver/supervisor bila pemilik menghendaki. Ini pilihan eksplisit saat memberi role, bukan eskalasi otomatis oleh profil `simple`.
- Hak akhir berasal dari role terpasang, scope toko/gudang, dan batas permission tenant. Perubahan template **tidak otomatis mengubah** role yang sudah diinstal; perlu migrasi/peninjauan terkontrol per tenant.

## Temuan awal yang wajib diperbaiki

| ID | Temuan | Akibat | Perbaikan |
| --- | --- | --- | --- |
| P1 | `CancelPOSOrder` mensyaratkan `pos_table_order.delete`, tetapi template kasir/supervisor tidak punya | Pembatalan order belum lunas buntu | Beri supervisor `view/update/delete` pesanan meja, kasir tetap tanpa `delete` |
| P2 | `ProcessSalesReturn` mensyaratkan `pos_retur.process`, tetapi kedua template POS tidak punya | Retur berhenti sesudah approval | Beri kasir `process`, supervisor tetap `approve`; proses hanya untuk status `approved` |
| P3 | Halaman retur mobile menampilkan Approve/Hapus/Proses tanpa memeriksa izin | Pengguna menekan aksi yang pasti ditolak server | Tambah flag permission spesifik pada runtime config dan sembunyikan aksi yang tidak berhak |
| P4 | Matriks 21 kombinasi memakai konteks admin dan `source: web_order` | Tidak membuktikan role non-admin, shift, maupun UI Android | Tes permission negatif/positif dengan role nyata; tes UI Android terpisah |
| P5 | Template operator inventori tidak memiliki `scrap` sama sekali, sementara approver hanya memiliki `view/approve` | Stok terbuang tidak dapat dibuat/diproses oleh peran bawaan | Operator `view/create/update/process`; approver `view/approve/reject` |
| P6 | Pembatalan item yang sedang dibuat mencari field user `role.permissions`/aksi `void_preparing_item` yang bukan mekanisme role efektif | PIN supervisor sah dapat ditolak | Validasi PIN terhadap pengguna aktif yang memiliki `pos_table_order.delete` dan scope gudang/toko yang sesuai |
| P7 | Nomor retur diisi pada hook `pre('save')`, setelah validasi `required`, sementara GraphQL input tidak menerima nomor | Pembuatan retur POS dari Android gagal validasi | Buat nomor sebelum validasi dari ObjectId unik lintas tenant/kasir |
| P8 | Retur POS baru tidak menyimpan toko/shift/kasir asal dari transaksi | Kasir tidak dapat mengajukan atau memproses draft yang baru dibuat | Salin snapshot sumber dari transaksi yang telah diverifikasi di server |
| P9 | `PosReturnState.copyWith(searchResult: null)` mempertahankan nilai lama | Form tetap terbuka sesudah draft berhasil disimpan; rawan kirim ulang | Bedakan parameter tidak diberikan dengan nilai `null` eksplisit |
| P10 | Sebagian request POS/retur masih mengautentikasi akun terminal walau kasir lain sudah memilih PIN | Kasir QA tanpa shift dapat melihat retur dari shift akun terminal; pemisahan hak kasir/supervisor tidak efektif | Kirim token operator terpilih dari Android dan web POS; middleware memakai identitas operator untuk endpoint POS/retur, kecuali endpoint shift/order/checkout yang sudah memverifikasi token operator terhadap terminal sendiri |
| P11 | Pemilih/verifikasi PIN memakai `status != deleted`, sehingga pengguna `nonaktif` masih dapat dipakai | Akun yang dinonaktifkan masih bisa masuk POS | Batasi hanya pengguna `active`, uji token operator yang kedaluwarsa/nonaktif ditolak |
| P12 | Cache dashboard, permission runtime, dan pesanan tersimpan masih menggunakan akun login terminal sebagai kunci | Sesudah QA kasir masuk tanpa shift, dashboard menampilkan nama rochim dan omzet cache terminal; izin/offline draft berisiko terbaca lintas operator | Kunci cache sensitif per operator PIN dan tampilkan nama operator aktif di sapaan; cache lama tidak dipakai oleh operator baru |
| P13 | `LoadPosData` selalu mengambil riwayat transaksi sebelum shift dibuat; server tepat menolak request itu | Blok startup gagal total, sehingga menu shift hilang untuk kasir QA dan operator tidak bisa mulai | Muat izin/toko/shift lebih dahulu; riwayat dan pelanggan baru diambil setelah shift aktif; keadaan tanpa toko tetap membuka navigasi konfigurasi |

## Tahapan implementasi

1. **Kontrak dan permission.** Tambah izin minimum pada template role, cek tipe dan query `GetPOSRuntimeConfig`, samakan gating UI mobile. Jangan memperluas izin admin atau mengubah izin role produksi secara massal.
2. **Tes otomatis non-admin.** Untuk kasir, supervisor, operator, approver, dan auditor, uji aksi yang diizinkan dan ditolak. Kasus wajib: kasir tak dapat approve retur/batal order; supervisor dapat batal order belum lunas tetapi tidak yang lunas; retur draft tidak bisa diproses; stok retur diposting satu kali; PO tidak bisa disetujui operator; penerimaan bukan hak approver saja; scope toko/gudang tidak bocor.
3. **E2E Android nyata.** Login/PIN → shift → katalog → order → bayar → struk/riwayat pada retail; meja → dapur → antar → bayar di restoran; terima cucian → proses → pickup/delivery di laundry; reservasi/pekerjaan + material → bayar untuk bengkel, salon, jasa. Lakukan dengan akun non-admin dan fixture tenant uji, catat ID transaksi serta perubahan stok/status.
4. **Inventori Android + web.** PO → approval → penerimaan parsial/penuh → stok gudang → isi rak → penjualan → retur/pembuangan/opname. Uji profil simple, centralized, advanced. Uji putus jaringan, retry idempoten, dan dua kasir offline sebelum menyatakan offline aman.
5. **Regresi dan rilis.** Jalankan tes backend/Flutter/Vue terarah, `flutter analyze`, dan uji UI setelah backend di-restart. Hasil dilaporkan sebagai PASS/FAIL/BELUM DIUJI; jangan menyebut kontrak server sebagai E2E mobile.

## Matriks skenario UI yang harus diselesaikan

| Profil | Jalur utama | Kasus negatif wajib | Bukti akhir |
| --- | --- | --- | --- |
| Retail | shift → jual stok display → bayar → struk → retur | stok nol, bayar ulang, order lunas dibatalkan | invoice, saldo sebelum/sesudah, retur selesai |
| Restoran | meja/quick service → item dapur + instan → siap → antar → bayar | meja terisi, item sedang dibuat dibatalkan tanpa PIN, bayar lebih awal | status item, order, meja, jurnal/stok |
| Laundry | intake kiloan/satuan → catatan/item layanan → proses → pickup/delivery → bayar | pelanggan wajib, berat berubah, layanan dibatalkan setelah dibayar | status layanan dan material |
| Bengkel | reservasi/servis → teknisi + spare part/BOM → selesai → bayar | komponen kurang, jadwal bentrok, retur jasa vs barang | reservasi, konsumsi stok, invoice |
| Salon | reservasi → staf → layanan + produk → bayar | staf bentrok, produk habis, no-show | status reservasi, stok, invoice |
| Jasa | order layanan → komponen biaya → selesai → bayar | tanpa pelanggan, biaya tambahan setelah lunas | status dan invoice |
| Custom | toggle fitur → order sesuai fitur aktif → bayar | toggle bertentangan dengan order aktif | menu dan pembatasan sesuai profil |

Untuk setiap profil di atas, ulangi minimal pada inventori `simple`, `centralized`, dan `advanced`: produk fisik, layanan nonstok, produk BOM/bundle bila relevan, PO–penerimaan, transfer/display bila diaktifkan, retur pembelian, stok terbuang, dan opname. Nilai stok harus dibandingkan pada lokasi, bukan hanya angka total produk.

## Urutan penerapan aman

1. Deploy/restart backend terlebih dahulu; pastikan tipe `POSRuntimePermissions` baru dan mutation `SubmitSalesReturn` tersedia.
2. Dry run migrasi role untuk satu instansi: `node -r dotenv/config scripts/upgrade_pos_role_templates_v3.js --tenant=<id>`. Tinjau role yang `SKIP`, backup dokumen role, baru jalankan ulang dengan `--apply` untuk instansi yang disetujui. Jangan menjalankan terhadap semua tenant sekaligus.
3. Rilis web dan APK yang memakai flag baru. Selama klien lama masih berjalan, endpoint lama tetap ada; aksi lama yang salah tetap ditolak oleh aturan status server.
4. Uji akun kasir/supervisor/operator/approver di instansi uji, cek log permission dan saldo, lalu perluas rollout bertahap. Untuk rollback, kembalikan role dari backup dan versi aplikasi sebelumnya; jangan rollback transaksi stok/retur yang sudah terposting dengan menghapus dokumen.

## Kriteria selesai

- Tidak ada tombol aksi pada mobile yang sengaja mengirim mutation tanpa permission.
- Tidak ada status order/retur/PO yang tidak punya aktor berwenang untuk melanjutkannya.
- Pembatalan order lunas ditolak dan diarahkan ke retur; refund dan stok tidak diproses dua kali.
- Per profil bisnis dan inventori, hasil UI Android, backend, dan web dilaporkan terpisah dengan akun, status, dan bukti.
- Role yang sudah terpasang di produksi ditinjau atau dimigrasikan secara opt-in; template baru saja tidak dianggap cukup.

## Status pelaksanaan

### Selesai di kode

- Template kasir/supervisor POS dan operator/approver inventori disesuaikan tanpa role baru. Instalasi template baru menyimpan versi template aktual. Migrasi **opt-in per instansi**, mode awal hanya pratinjau, tersedia di `presensi_zera_BE/scripts/upgrade_pos_role_templates_v3.js`. Satu role operator inventori pada instansi uji produksi telah dimigrasi setelah dicadangkan; role lainnya belum berubah.
- `GetPOSRuntimeConfig` menampilkan flag izin retur dan pembatalan. Mobile/web hanya menampilkan aksi retur sesuai izin. Urutan retur kini `draft → pending → approved → completed`; tombol Ajukan ditambahkan, tombol Setujui pindah ke status pending.
- Retur selesai/pending/approved tidak dapat dihapus oleh endpoint delete; hanya draft/ditolak/dibatalkan. Proses retur tetap hanya menerima status approved dan klaim atomik untuk mencegah dua kali proses.
- Supervisor dapat melihat pesanan aktif di mobile dan membatalkan order belum bayar. Order lunas tetap ditolak server. Pembatalan item sedang dibuat memeriksa PIN pengguna aktif berizin dan scope lokasi toko.
- Kasir pemroses retur dibatasi ke toko pada shift aktif, tidak memperoleh akses retur lintas toko hanya karena memiliki izin `process`.
- Nomor retur dibuat sebelum validasi dan unik per dokumen tanpa `countDocuments`. Retur POS mengambil toko, shift, kasir, nomor invoice, dan pelanggan dari transaksi asal; input klien tidak dipercaya sebagai sumber snapshot.
- State form retur mobile dapat mengosongkan hasil pencarian setelah simpan; form akan menutup dan kembali ke daftar pada build berikutnya.
- Identitas operator PIN diteruskan pada request POS/retur Android dan web; cache GraphQL Android dibangun ulang saat pergantian operator. Endpoint shift, pembuatan order, dan checkout tetap memakai identitas terminal karena sudah punya validasi `operator_session_token` sendiri. Operator nonaktif tidak muncul di pemilih dan tidak bisa memakai PIN.
- Cache dashboard, izin runtime, favorit, dan pesanan tersimpan Android dipisahkan per operator; sapaan dashboard mengikuti kasir PIN aktif. APK QA terbaru telah dipasang pada emulator dan sapaan kasir/supervisor sesuai identitas PIN.
- Startup kasir tanpa shift tidak lagi meminta riwayat/pelanggan yang semestinya tertutup; runtime izin dan daftar toko tetap dimuat agar halaman buka shift dapat tampil. Tes Flutter khusus kondisi tanpa shift lulus.

### Hasil verifikasi sesi ini

| Pengujian | Hasil | Batas bukti |
| --- | --- | --- |
| Kontrak GraphQL POS mobile/web, role, migrasi, dan keamanan stok | PASS 69/69 pada regresi terarah terakhir; matriks 21 kombinasi pernah PASS 21/21 terpisah | 21 kombinasi adalah lifecycle server dengan admin, bukan UI Android |
| Integrasi Sales DO/retur dengan MongoDB sementara | PASS 17/17 setelah dijalankan dengan akses loopback | Mencakup retur B2B; belum E2E retur POS dengan kasir/supervisor nyata |
| Integrasi kasir/supervisor non-admin dengan MongoDB sementara | PASS 1/1: kasir ditolak membatalkan, supervisor membatalkan order belum bayar, reservasi stok dilepas, PIN item sedang dibuat salah/benar, supervisor ditolak di cabang lain, order lunas ditolak | Belum mencakup retur POS sampai refund; saat penghentian MongoDB sementara muncul log `ECONNRESET` meski semua assertion lulus |
| Tes scope gudang dan flag inventori | PASS 4/4 | Unit/kontrak, bukan layar |
| Tes Flutter kasir/order realtime/shift | PASS 6/6 | Belum menguji tombol retur baru di emulator |
| `flutter analyze --no-pub` seluruh aplikasi | PASS, No issues found | Bukan build APK atau tap-through emulator |
| Parse komponen Vue retur | PASS | Bukan tap-through web |
| APK development Android pada emulator | Build + install PASS; login/PIN, kasir, Pesanan Aktif kosong, halaman Retur, dan filter `Menunggu persetujuan` PASS | Pada awal sesi belum ada retur; uji tambah draft berikutnya dicatat di baris terpisah |
| Retur POS non-admin pada MongoDB sementara | PASS 1/1: kasir membuat draft → ajukan → supervisor setujui → kasir proses; stok 2 → 3; ulang proses dan hapus retur approved ditolak | Tes resolver nyata, bukan tap-through dua akun Android |
| Penomoran retur serentak | PASS 1/1: 20 draft memperoleh nomor unik sebelum validasi | Nomor baru memakai suffix ObjectId, bukan nomor urut pendek |
| Regresi profil POS × inventori dan gudang/display | PASS 25/25: 21 kombinasi jual-bayar-potong stok lokasi + 4 transfer/display | Tes server, bukan tujuh profil UI Android |
| Regresi offline, PO/penerimaan, transfer, scrap | PASS 30/30 | Utamanya kontrak/unit; belum uji dua perangkat fisik offline |
| Android tambah retur pada instansi uji | PASS: invoice dummy `PANTOO-20261030-0003` dicari, item dipilih, draft `RTJ/2026/10/6AE42F196FB61619E82AE205` tercatat dengan 1 item dan refund Rp4.000. Pada APK baru, invoice `PANTOO-20261030-0002` menghasilkan draft kedua, form menutup otomatis, kartu muncul; tombol Ajukan mengubahnya menjadi `PENDING`. | Belum ada akun supervisor kedua pada APK untuk approval/proses Android. Dua retur uji tersimpan: satu pending dan satu draft; belum mengembalikan stok. |
| Tes dan analisis Flutter state retur | PASS: 1/1 tes baru, `flutter analyze --no-pub` seluruh aplikasi No issues found; APK development dibangun dan dipasang ulang pada emulator | Belum uji rilis produksi |
| Regresi Flutter profil/offline/pembelian/pesanan/retur | PASS 27/27 | Tes widget/unit, bukan tujuh profil Android end-to-end |
| POS web regresi dan build | PASS 43/43 tes terarah dan `npm run build:pos` sukses | Build memberi peringatan ukuran chunk besar dan data Browserslist lama; belum tap-through web dengan dua akun |
| Pengikatan identitas operator PIN pada auth middleware | PASS 8/8 tes keamanan termasuk kasir nonaktif, retur memakai identitas operator, serta shift/order/checkout tetap memakai identitas terminal | Tes server; verifikasi tap-through Android untuk build terbaru masih berlangsung |
| Login QA kasir/supervisor pada emulator Android | PASS: dua akun PIN berbeda masuk; header, sapaan, dan menu mengikuti identitas; shift bersama Toko Bandung dan katalog tampil pada keduanya | Masih satu profil toko dummy, bukan tujuh profil UI |
| Retur POS Android dua peran | PASS: draft `RTJ/2026/10/6AE433906FB61619E82AE4CE` diajukan → supervisor menyetujui → kasir memproses. Status DB `completed`, stok lokasi Toko Bandung 469→470 tepat satu unit. | Refund Rp4.000 tercatat sebagai retur uji; verifikasi metode refund eksternal/bank tidak dilakukan. Draft uji lain tetap berstatus draft. |
| Regresi tambahan shift bersama dan retur | PASS: kasus katalog/riwayat/retur pada operator PIN diperbaiki; 38/38 tes kontrak stok/retur dan 8/8 tes keamanan PIN lulus; tes Flutter tanpa shift 1/1, analisis seluruh aplikasi No issues | Tes kontrak bukan pengganti semua profil UI. |

### Masih terbuka — jangan klaim lulus

1. Backend produksi perlu deploy/restart dan aplikasi Android/web perlu build/rilis ulang supaya perbaikan retur serta flag GraphQL baru tersedia. Satu role operator inventori instansi uji sudah dimigrasi; role lain/tenant lain belum.
2. E2E Android pembatalan pesanan belum lunas/sedang dibuat/bayar lunas dan pergantian shift/scope toko negatif masih terbuka. Alur retur dua peran sampai stok sudah lulus pada toko dummy, tetapi jalur refund eksternal belum diverifikasi.
3. E2E Android untuk tujuh profil bisnis dan tiga profil inventori sebagaimana matriks di atas. Bukti 21/21 server tidak menggantikan tes ini.
4. E2E offline dua kasir, printer, batch kedaluwarsa, BOM per profil, penerimaan parsial, scrap/opname/retur pembelian pada akun operasional; semuanya belum dibuktikan dalam sesi ini.
5. Dua akun QA sementara sudah dinonaktifkan, PIN dikosongkan, dan role QA dinonaktifkan setelah uji. Pemeriksaan ulang menunjukkan keduanya `nonaktif`, tanpa PIN dan tanpa role aktif.

APK development pertama ternyata masih menampilkan daftar filter lama pada emulator walaupun sumber sudah berubah. Kompilasi ulang paksa dengan `--dart-define=POS_QA_BUILD=20261030_return_pending` dan pemasangan ulang membuat opsi `Menunggu persetujuan` tampil. Untuk perbaikan form retur, APK dibangun kembali dengan `POS_QA_BUILD=20261030_return_fix`; uji simpan kedua menutup form, menampilkan draft baru, dan pengajuan mengubah kartu menjadi `PENDING`. Itu belum membuktikan approval/proses memakai dua akun Android.

### Pratinjau role instansi uji

Dry run pada instansi `6a856ce9517424ebab833ba9` menemukan satu role terpasang `inventory_operator` yang perlu mendapat `scrap.view/create/update/process`. Cadangan satu role dibuat di `presensi_zera_BE/scripts/backups/pos_role_6ae03c273d58437d0c7d1edc_20261030.json` (diabaikan Git), lalu migrasi `--apply` berhasil pada role `6ae03c273d58437d0c7d1edc`. Dry run ulang menunjukkan **tidak ada izin baru** yang tertinggal. Tidak ada role template kasir/supervisor POS pada instansi ini; role lain/tenant lain belum diubah.
