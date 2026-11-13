# Utang & Piutang mobile — 13 November 2026

**Koreksi rilis:** APK 1.0.10+11 tertahan di splash screen akibat registrant plugin Android hilang pada build production. Gunakan APK pengganti 1.0.11+12; lihat PERBAIKAN_STARTUP_ANDROID_20261113.md. Pengujian fitur QA tetap valid, tetapi build production lama tidak boleh dipakai.

Kandidat Android 1.0.10+11 menambahkan menu Lainnya → Utang & Piutang. Seluruh pencatatan dilakukan online pada buku besar Finance yang sama; bukan saldo lokal atau antrean transaksi offline.

## Cara memakai

1. Pilih Piutang atau Utang, kemudian Catat Tagihan Manual.
2. Pilih tagihan baru atau saldo awal yang belum pernah dicatat. Jangan masukkan ulang invoice atau saldo yang sudah ada di Finance.
3. Isi pihak, nomor dokumen, nominal, tanggal dan jatuh tempo. Pilih kategori pendapatan/beban untuk tagihan baru, atau akun ekuitas saldo awal sesuai kebijakan pembukuan usaha.
4. Periksa konfirmasi, lalu simpan. Tagihan dan jurnal dibuat bersama.
5. Buka tagihan dan pilih Catat Pembayaran/Terima Pembayaran. Isi pembayaran penuh atau parsial, nomor bukti, tanggal, serta sumber kas atau rekening transfer. Periksa konfirmasi sebelum melanjutkan.
6. Periksa sisa tagihan dan riwayat. Bukti menampilkan nomor jurnal; dokumen tanpa bukti pengakuan yang valid perlu diperiksa melalui Finance.

Pembayaran pemasok dapat dilakukan pada invoice pemasok yang telah diposting, utang pembelian lama dengan jurnal pengakuan, dan utang manual dari menu ini. Jadwal termin utang pembelian lama tetap diperiksa. Invoice pemasok memiliki saldo sendiri dan tidak menggunakan jadwal PO sebagai tagihan kedua.

## Hubungan pembukuan

- Piutang transaksi: debit piutang, kredit pendapatan. Saldo awal piutang: debit piutang, kredit ekuitas.
- Utang transaksi: debit beban, kredit utang 2100. Saldo awal utang: debit ekuitas, kredit utang 2100.
- Penerimaan: debit kas/bank, kredit piutang. Pembayaran pemasok: debit utang, kredit kas/bank.
- Kas pembayaran pemasok mengikuti akun kas Finance 1006 yang sudah dipakai layanan pembayaran pemasok. Nama akun ditampilkan di mobile. Transfer menggunakan rekening IDR aktif yang terhubung dengan akun Finance aktif.
- Pencatatan manual tidak memindahkan stok, tidak membuat rincian pajak, dan tidak mengubah uang laci shift. Pembelian barang bersediaan tetap melalui alur pembelian/penerimaan/invoice pemasok. Pembayaran rekening harus benar-benar dilakukan di luar aplikasi; fitur ini mencatat pembayaran tersebut.
- Laporan laba rugi, arus kas, dan umur utang/piutang membaca jurnal serta dokumen yang sama. Saldo awal memakai ekuitas sehingga tidak membentuk laba/beban baru.

## Izin

Menu mengikuti izin melihat piutang/utang. Pencatatan manual dan pembayaran utang memerlukan izin Finance berskala instansi; izin cabang tidak dapat memperluas akses ke seluruh usaha.

- Piutang manual: receivables.view, create, update.
- Penerimaan piutang: receivables.view dan create.
- Utang manual: payables.view dan create.
- Pembayaran pemasok: payables.view dan pay_vendor_bill.

Kasir dengan akses piutang POS terbatas tetap hanya melihat invoice POS pada toko yang diizinkan dan tidak memperoleh hak membuat tagihan Finance manual. Tidak ada peran atau izin yang ditambahkan otomatis.

## Koneksi terputus

Aplikasi menyimpan identitas dan isi permintaan sebelum mengirim. Jika hasil belum diketahui, gunakan Konfirmasi ulang. Isi dan identitas permintaan tetap sama, termasuk setelah aplikasi dibuka kembali. Permintaan penerimaan POS dari versi sebelumnya tetap dapat dikonfirmasi. Jangan membuat pembayaran pengganti dari perangkat lain sebelum memeriksa Finance.

Permintaan hanya dihapus setelah server mengakui hasil atau secara eksplisit menyatakan penolakan tanpa pencatatan. Hilangnya login, hak akses, respons yang tidak lengkap, atau waktu tunggu habis tidak dianggap sukses. Penyimpanan yang rusak menghentikan pengiriman dan meminta pemeriksaan administrator.

## Rilis

Backend wajib dirilis sebelum APK ini digunakan. Backend baru menambahkan lima operasi GraphQL privat, jurnal atomik, serta indeks unik permintaan dan referensi manual pada koleksi terkait. Tidak ada migrasi saldo otomatis, deployment produksi, atau pencatatan pada database produksi oleh pekerjaan ini. Periksa indeks menggunakan prosedur rilis backend, lalu uji akun pemilik dan akun kasir sesuai izin yang sebenarnya.

## Verifikasi kandidat

- 11 pengujian integrasi backend: jurnal manual AR/AP, penerimaan/pembayaran parsial, pengulangan dan konflik permintaan, saldo awal, saldo historis, rekening aktif, tenant terpisah, izin cabang/instansi, pencabutan izin, periode terkunci, rollback audit, pembayaran bersamaan, invoice pemasok, dan termin pembelian lama.
- 36 pengujian mobile terkait fitur, laporan dan navigasi lulus. Termasuk form dan konfirmasi, permintaan tidak terkonfirmasi setelah restart, kompatibilitas bukti penerimaan POS lama, respons tenant lain dan perubahan sesi, tanpa pengulangan mutasi otomatis, serta tampilan 360 piksel dengan teks diperbesar.
- Uji Android melalui HTTP GraphQL dengan middleware autentikasi sebenarnya, pada database staging lokal sekali pakai: form utang 100.000, pembayaran 40.000, sisa 60.000, bukti jurnal, piutang transaksi/saldo awal, dan pengulangan penerimaan tanpa duplikasi.
- Analisis Dart bersih. Build production berhasil, identitas id.pantoo.pos / 1.0.10 / build 11, tanda tangan APK v2 terverifikasi, kelas plugin integration_test tidak ikut rilis.
- APK: `output/pantoo-pos-trade-release-1.0.10/Pantoo-POS-1.0.10+11.apk` dari root workspace. SHA-256: `84cc02b977017949aafd5959d3bd59f723028ae7ed8d4acbaa995d777b059b18`.
- Regresi Finance menyeluruh: **591/591 lulus**, 65 suite, termasuk pilot periode tutup. Tidak ada kegagalan, pengujian dilewati, atau dibatalkan. Bukti: `presensi_zera_BE/artifacts/finance/release-gate.json` dan `backend.tap`. Log fitur berada di `output/pantoo-trade-*`.

Drive C hampir penuh saat verifikasi; berkas sementara pekerjaan ini dialihkan ke `output/trade-test-temp` di drive D. Tidak ada berkas pengguna atau data aplikasi yang dihapus. APK QA normal dipasang kembali tanpa menghapus data setelah uji Android.
