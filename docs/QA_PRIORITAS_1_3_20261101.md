# QA prioritas 1–3 — 1 November 2026

## Ringkasan

Aturan bisnis prioritas 1–3 yang dirinci di bawah sudah PASS pada integrasi database dan HTTP. Perbaikan tersimpan di source; **bukan sign-off seluruh aplikasi atau seluruh perjalanan UI Android/web**. Pengujian putaran ini memakai MongoDB replica set sementara, endpoint lokal 8087 dan APK `id.pantoo.pos.qa`. Tidak ada perubahan data/deploy produksi, tidak menghapus data aplikasi emulator.

| Verifikasi terakhir | Hasil | Bukti |
|---|---|---|
| Regresi backend gabungan | 152/152 PASS, 0 gagal | BE/docs/qa-prioritas123-regression-final.log |
| Inti prioritas lintas profil | 36/36 dalam suite backend: 18 inventori + 18 layanan/Finance | tests/pos_priority_inventory_roles.integration.test.js; tests/pos_priority_service_finance.integration.test.js |
| Penomoran dan migrasi scrap | 2/2 dalam suite backend | tests/scrap_tenant_numbering.integration.test.js |
| HTTP + autentikasi | 6 kelompok alur PASS: inventori, 4 profil layanan, piutang POS–Finance; diulang sesudah server memuat seluruh patch final | BE/docs/qa-prioritas123-http-final.log |
| Flutter suite penuh | 264/264 PASS | docs/qa-prioritas123-flutter-tests.log |
| Flutter analyze | No issues found | docs/qa-prioritas123-flutter-analyze.log |
| Vue terpilih | 26/26 PASS | front_end_template/docs/qa-prioritas123-vue-final.log |
| APK QA | Build/install -r PASS | docs/qa-prioritas123-apk.log |
| Android laundry siap → diambil | PASS, ORD-20261101-0013 menjadi Selesai/diambil | qa-priority-laundry-complete.png; BE/docs/qa-prioritas123-android-verify.log |
| Android riwayat transaksi tempo | PASS: INV-20261101-0014 tampil Sebagian dibayar sesudah Finance menerima 400, melunasi 600, lalu membalik 600 | qa-priority-ar-partial.png |

Angka tes ulangan tidak dijumlahkan. Suite 148 sebelumnya mempunyai satu kegagalan akibat guard layanan terlalu luas pada reservasi restoran; guard diperbaiki dan seluruh suite 152 diulang hingga PASS. Salah tipe input pada helper HTTP dan pengecualian endpoint registrasi publik pada tes kontrak diperbaiki sebagai masalah fixture, bukan temuan aplikasi. Peringatan punycode, ECONNRESET saat shutdown Mongo QA, Unicode PDF dan migrasi Kotlin plugin tetap dicatat; tidak disamakan dengan kegagalan skenario.

Server QA sementara dimuat ulang setelah bukti Android diambil untuk memastikan HTTP memakai semua patch terakhir. Nomor/ID pada screenshot berasal dari fixture sebelum restart; log verifikasi Android tetap disimpan. Fixture HTTP final baru menyiapkan ORD-20261101-0005 untuk pengujian lanjutan. Tidak ada penghapusan data lokal emulator atau database produksi.

## Prioritas 1 — peran operasional inventori

Tiga profil inventori diuji dengan akun database non-admin terpisah: operator, approver, auditor. Hak kasir/supervisor dan Finance diuji terpisah. Tidak menambahkan role produk baru; memakai template yang sudah ada.

- PO: operator membuat dan mengajukan → status pending → approver menyetujui → operator menerima +2 stok. Auditor tidak boleh membuat, maker tidak boleh approve, approver tidak boleh menerima.
- PO lintas lokasi: daftar/detail/edit/submit/approve ditolak atau disaring sesuai lokasi yang sudah tersimpan pada dokumen, bukan lokasi baru yang dikirim untuk mencoba memindahkan scope.
- Transfer Centralized/Advanced: maker → submit → approve terpisah → kirim/transit → terima. Saldo 20/20 menjadi 18/22; retry tidak menambah stok kedua kali.
- Transfer Simple: **ditolak sesuai desain satu lokasi**, stok tidak berubah. PASS pengaman, bukan klaim transfer tersedia pada Simple.
- Opname: hitung 20→19 → submit → approver approve/post. Operator tidak bisa approve/post; stok tidak berubah sebelum posting.
- Scrap: operator membuat → approver approve → operator proses. Salah peran dan proses sebelum approved ditolak; retry tidak mengurangi stok kedua kali.
- Retur supplier: PO diterima → retur 1 dari 2 unit → submit → approve terpisah → proses. Stok 22→21; retry tidak mengurangi lagi.
- HTTP nyata memastikan supplier cepat, PO pending, batas role, GRN dan deduplikasi GRN melewati middleware aplikasi.

**Temuan:** PO sebelumnya belum konsisten membatasi lokasi pada seluruh jalur. Ditambahkan `purchase_scope.js` dan guard sebelum pembacaan/perubahan dokumen. PO lama tanpa lokasi hanya terlihat oleh pembuat/admin; approver terbatasi tidak otomatis mendapat akses seluruh instansi. PO lama ambigu tetap perlu admin menetapkan lokasi penerimaan.

## Prioritas 2 — lifecycle layanan

Laundry, bengkel, salon dan jasa masing-masing diuji pada Simple/Centralized/Advanced:

- Intake layanan → tambah barang/sparepart sebelum ditagih → progres bertahap → siap diambil.
- Laundry: sortir → cuci → keringkan → QC → kemas → siap diambil. Profil lain: dikerjakan → selesai produksi → siap diambil.
- Serah sebelum pembayaran ditolak. Sesudah bayar, stok barang berkurang satu kali dan status diambil menutup pesanan sebagai Selesai.
- Per item: tidak boleh menyerahkan tanpa pembayaran, tidak boleh menutup header melewati status tiap barang, dan sesudah seluruh item diserahkan pesanan ditutup.
- Pembatalan layanan melewati `CancelPOSOrder`: izin pembatalan harus ada dan reservasi stok dilepas. Status layanan tidak dapat menjadi jalan pintas izin update biasa.
- Layanan bertempo: invoice AR sah memperbolehkan serah terima, tetapi tidak ditandai kas dibayar lunas. Tidak bisa membayar/menagih ulang atau mengedit item transaksi yang sudah diposting; tambahan dibuat sebagai pesanan baru.
- BOM layanan 2 komponen + 1 barang tambahan: reservasi 3, konsumsi 3 sekali, snapshot komponen tersimpan pada transaksi.
- HTTP menjalankan progres, blokir unpaid, bayar dan serah sampai Selesai pada empat profil. Android menguji penyerahan laundry representatif dari Pesanan Aktif dan memverifikasi hasilnya kembali lewat HTTP.

**Temuan/perbaikan:** serah unpaid sebelumnya lolos; batal layanan melewati izin cancel; header/line yang ditutup masih dapat diubah; penyerahan tidak selalu menutup pesanan utama. Guard dan penutupan disatukan. Tombol batal per-line yang sebelumnya tidak merekonsiliasi tagihan/stok tidak lagi ditawarkan; pembatalan seluruh pesanan tetap melalui alur resmi. **Pembatalan parsial line dengan repricing/refund lengkap belum tersedia dan bukan diberi status PASS.**

## Prioritas 3 — invoice POS menjadi piutang Finance

- `IssuePOSCreditInvoice` menerbitkan AR, menghubungkan invoice Finance dan mengurangi stok atomik.
- Ulangan client_transaction_id tidak membuat invoice/stok kedua kali.
- Transaksi 100 → terima 40 → sisa 60 → terima 60 → lunas → balik penerimaan terakhir → sisa 60 lagi. Pengumpulan/pembalikan tidak memindahkan stok.
- Kasir tidak boleh menjalankan penerimaan Finance; finance_operator boleh. Lebih bayar ditolak; retry penerimaan tidak menduplikasi nominal.
- Snapshot POS ikut berubah unpaid/partial/lunas; pembacaan transaksi lama dengan sales_invoice_id mengambil saldo Finance sebagai sumber kebenaran. Tender/total penjualan awal tidak ditimpa oleh pembayaran piutang.
- Kasus pajak: neto 100 + pajak 11 → AR 111; terima 61 lalu allowance neto45+pajak5 → sisa0. Kas masuk tetap61, kredit50, stok tetap19; jurnal debit=kredit.
- HTTP benar-benar menjalankan IssuePOSCreditInvoice → Finance partial/full/reverse → GetPOSPenjualan dan memeriksa status/saldo.

**Temuan/perbaikan:** IssuePOSCreditInvoice belum masuk peta autentikasi meskipun terdaftar sebagai identitas terminal. Didaftarkan sebagai Authorized. Model POS belum menyimpan status/saldo pelunasan dan Finance tidak menyinkronkannya. Ditambahkan snapshot dan sinkronisasi dalam transaksi Finance yang sama. Mobile/web membaca field status/saldo; data tempo tanpa field tidak lagi diasumsikan lunas. Order layanan tempo juga memperbaiki enum belum_lunas yang tidak valid menjadi belum_bayar.

## Temuan tambahan — nomor scrap

Indeks no_scrap unik global menyebabkan instansi kedua gagal membuat SCR/YYYY/MM/0001. Counter sebelumnya memakai countDocuments sehingga rentan tabrakan simultan dan penggunaan kembali nomor setelah penghapusan.

Perbaikan: unique compound instansi_id+no_scrap; counter atomik per instansi/bulan, diinisialisasi dari nomor lama tertinggi. Tes 8 pembuatan paralel, lintas instansi, penghapusan nomor terakhir, duplicate dalam instansi, dry-run dan apply migrasi semuanya PASS.

Migrasi `presensi_zera_BE/scripts/migrate_scrap_tenant_number_index.js` **belum dijalankan di produksi**. Dry-run menjadi default; apply wajib `--apply --expect-db=<nama_target>`. Hentikan sementara penulisan scrap saat penerapan, buat indeks compound dahulu sebelum melepas indeks lama. Tidak menghapus/menomori ulang dokumen. Setelah nomor sama dipakai dua instansi, rollback ke indeks global lama tidak aman; gunakan perbaikan maju. Uji ini belum mengukur waktu pembuatan indeks pada ukuran data produksi.

## Batas hasil dan langkah rilis

Spreadsheet diperbarui pada tab Ringkasan, Web dan Backend, Temuan & Perbaikan, Profil POS Android, Belum Diuji, dan Matriks21 Kombinasi. **157 sel perubahan dibaca ulang dan cocok**, termasuk wrap/top; dropdown/formula/chip di luar target tidak diubah. Browser pengujian hanya menyediakan about:blank, sehingga verifikasi spreadsheet memakai metadata sel/format native API, bukan klaim render Google Sheets di browser.

1. Deploy backend sebelum klien baru karena field GraphQL bertambah; terapkan migrasi indeks terkontrol sesudah backup dan preflight target.
2. UI lengkap semua 21 kombinasi dan seluruh pergantian akun maker/approver per modul **belum diulang seluruhnya**. PASS backend/HTTP tidak diubah menjadi PASS Android/web.
3. Vendor/rework/komplain layanan, deposit parsial, jadwal staf, retur/refund layanan dan pembatalan parsial line belum tercakup penuh dalam pengujian putaran ini. Reservasi restoran tetap lolos regresi.
4. Printer/perangkat pelanggan fisik dan offline multi-kasir bukan cakupan prioritas 1–3 kali ini, tetap terbuka.
5. Vue menjalankan kontrak/schema dan tes terpilih, bukan klaim browser E2E baru. Android memakai akun QA admin untuk penyerahan representatif; batas peran inventori dibuktikan integrasi/HTTP, bukan seluruh UI.

## Pemeriksaan mutu

Pemeriksaan memakai skill agent-self-evaluation: akurasi4 (152/264/26 dan bukti HTTP, bukan semua UI), kelengkapan3 (batas UI/perangkat dan variasi layanan di atas masih ada), kejelasan4 (metode dipisahkan), dapat ditindaklanjuti4 (patch, tes, migrasi dry-run tersedia; deploy belum), keringkasan4 (detail bukti di laporan, ringkasan di spreadsheet). Rata-rata3,8/5 adalah evaluasi hasil kerja, **bukan skor kesiapan produksi**. Perbaikan terpenting berikutnya: E2E UI lintas akun pada semua modul lalu variasi layanan yang masih terbuka. Self-check: hasil dapat diverifikasi tanpa membuat pengguna menyangka seluruh aplikasi sudah PASS. Verdict: laporkan PASS sesuai cakupan dan sisakan antrean yang belum diuji secara eksplisit.
