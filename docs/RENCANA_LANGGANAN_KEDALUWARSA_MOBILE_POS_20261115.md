# Rencana alur langganan Pantoo POS mobile

Tanggal: 15 November 2026. Status: usulan produk dan rencana implementasi; belum mengubah perilaku aplikasi/server atau kebijakan komersial.

## Hasil audit kode

- Backend memiliki GetSubscriptionStatus, access_level (full/read_only/billing_only/blocked), informasi pemilik, tanggal akhir, dan masa tenggang. Sumber: presensi_zera_BE/utils/subscriptionAccess.js dan graphql/instansi/instansi.resolvers.js.
- Pembelian/perpanjangan sudah memiliki quote harga server, transaksi langganan, Midtrans, pembayaran manual, riwayat, dan verifikasi pemilik. Gunakan sistem yang sama; jangan membangun pembayaran langganan terpisah di POS.
- Aturan tanggal tidak konsisten: active dengan tanggal akhir lewat langsung billing_only/blocked; expired mendapat full sampai perhitungan daysSinceExpiry <= 3 dan read_only sampai graceDays. Ini juga menggunakan pembulatan hari, sehingga batas waktunya perlu dibuat eksplisit. grace_period_days || 7 tidak menghormati nilai 0. Trial dan suspended perlu kebijakan terpisah.
- Mobile belum memanggil GetSubscriptionStatus untuk alur akses atau menangani SUBSCRIPTION_REQUIRED secara khusus. Beberapa data subscription_status pada query bukan pengganti pengendalian akses menyeluruh.
- Repository transaksi sudah membedakan respons penolakan API dari gangguan jaringan. Jangan mengubah penolakan langganan menjadi keberhasilan offline.
- Daftar pengecualian server belum menyelesaikan kebutuhan operasional POS seperti verifikasi PIN pada masa baca saja, penutupan shift, dan pemulihan antrean transaksi. Setiap pengecualian harus spesifik serta tetap memeriksa tenant, peran dan kepemilikan transaksi.

## Kebijakan yang disarankan

Untuk paket berbayar, pertahankan arah kebijakan existing: 3 hari tenggang operasional, kemudian 4 hari baca saja, setelah itu akses pemulihan. Angka ini usulan awal dan harus menjadi konfigurasi server. Trial berakhir langsung masuk baca saja/pemulihan, tanpa otomatis memberi tenggang penjualan. Suspended tidak menerima tenggang otomatis.

Hitung state efektif dari waktu server dan tanggal batas yang sama, bukan bergantung pada cron atau string status. Kirim server_now, expires_at, operational_until, read_only_until dan kemampuan yang diperbolehkan. Gunakan timestamp batas tegas: sekarang < operational_until; hindari pembulatan hari sebagai dasar izin. Zona waktu tampilan mengikuti bisnis, waktu penyimpanan tetap UTC.

| Kondisi | Pengalaman pengguna | Operasi |
| --- | --- | --- |
| Aktif | Kasir langsung terbuka | Sesuai paket dan hak operator |
| H-7 / H-3 / H-1 | Banner ringkas; satu pengingat per ambang per tenant | Penjualan tetap berjalan |
| Tenggang operasional | Banner menetap dengan tanggal/jam berhenti penjualan | Penjualan masih boleh sampai batas server |
| Baca saja | Pemberitahuan sekali, lalu navigasi ke riwayat/laporan | Lihat data, cetak ulang dan ekspor sesuai hak; tidak membuat transaksi baru |
| Akses pemulihan | Owner masuk Langganan; kasir melihat instruksi hubungi owner | Login, identitas, dukungan, informasi antrean lokal dan pemulihan tetap tersedia |
| Ditangguhkan | Halaman pembatasan dengan alasan publik dan bantuan | Tidak ada transaksi baru; jalur dukungan dan owner tersedia |
| Verifikasi tidak tersedia | Status jaringan dan waktu pengecekan terakhir | Ikuti izin offline yang masih berlaku; tidak dianggap otomatis kedaluwarsa |

Pembatasan langganan tidak menghapus data. Retensi data merupakan kebijakan terpisah dan tidak menjanjikan penyimpanan tanpa batas. Perpanjangan tidak memberikan akses ke modul, outlet atau terminal melebihi kapasitas paket baru.

## Alur layar

1. Login akun: autentikasi tetap berjalan meskipun paket habis. Ambil status langganan sebelum membuka kasir. Jangan logout karena SUBSCRIPTION_REQUIRED.
2. Bila masih boleh berjualan: masuk PIN dan kasir seperti sekarang. Banner tidak menghalangi transaksi. Pemilik dapat membuka Langganan dari Lainnya; kasir hanya melihat masa berlaku dan instruksi menghubungi pemilik.
3. Bila baca saja: tampilkan pesan "Langganan berakhir. Penjualan baru dinonaktifkan; riwayat dan laporan masih dapat dibuka." PIN dan pemeriksaan peran tetap berjalan. Kontrol mutasi nonaktif dengan alasan yang jelas.
4. Bila hanya pemulihan: pemilik melihat paket/tanggal akhir, tindakan Perpanjang, Cek status pembayaran, Riwayat pembayaran, dan Bantuan. Kasir melihat nama toko, pesan hubungi pemilik, Cek lagi, Ganti akun dan Keluar. Jangan tampilkan rincian tagihan atau informasi pribadi owner kepada kasir.
5. Tambahkan menu Langganan di Lainnya; tidak menambah dashboard atau tab bawah.
6. Di layar pelanggan, tampilkan layar idle biasa saat operasional dibatasi. Informasi tagihan langganan hanya untuk petugas.

## Matriks tindakan saat baca saja/pemulihan

- Penjualan baru, pembayaran invoice belum lunas, retur/refund baru, koreksi stok, pembelian, pencatatan utang/piutang dan pembayaran pemasok: diblokir secara default. Ini semuanya mengubah data/uang; tidak cukup hanya mematikan tombol Bayar.
- Riwayat, detail transaksi, cetak ulang struk, laporan dan ekspor: boleh selama fase baca saja, sesuai hak pengguna. Setelah batas pemulihan, tetap sediakan jalur permintaan salinan data kepada pemilik/dukungan; jangan menjanjikan semua query terbuka.
- Menutup shift yang sudah ada: pengecualian terbatas agar uang kas dapat direkonsiliasi. Tidak membuka shift baru, tidak mengubah penjualan, tetap ada audit.
- Transaksi yang sudah diterima server saat akses masih sah: hasil tetap dapat diambil ulang, dicetak, dan direkonsiliasi dengan ID yang sama, meskipun respons ke perangkat terlambat. Jangan membuat pembayaran kedua.
- Keranjang belum dibayar: pertahankan sebagai draft lokal; jangan menampilkan pembayaran berhasil. Saat diperpanjang, validasi ulang harga/stok sebelum melanjutkan.
- Invoice terbuka setelah batas: tetap terlihat; pembayaran ditunda hingga langganan aktif kembali. Bila bisnis kelak memerlukan pengecualian penagihan, buat kebijakan terpisah dengan audit; jangan diam-diam membebaskannya.

## Offline dan antrean

Cache tampilan status saja tidak cukup untuk izin penjualan. Rencanakan izin offline bertanda tangan server yang terikat tenant, operator, perangkat, toko, kapasitas dan waktu berlaku. Usulan durasi maksimum 24 jam, selalu dipotong pada batas operasional langganan. Pemutusan koneksi tidak mengubah state menjadi aktif tanpa batas. Jam perangkat yang mundur tidak memperpanjang izin.

Jika izin tidak ada atau habis, pengguna masih dapat melihat data lokal/antrean tetapi tidak menyelesaikan penjualan baru. Transaksi cash offline yang sudah sah disimpan secara tahan restart dengan ID idempoten; jangan hapus saat paket habis, logout, atau refresh.

Server boleh menerima replay transaksi sebelum batas hanya jika memiliki bukti izin offline yang dapat diverifikasi dan aturan anti-replay, bukan semata tanggal yang dikirim perangkat. Selama fondasi ini belum selesai, antrean diblokir dengan status "Menunggu perpanjangan" dan dilanjutkan setelah aktivasi; tidak dibuang atau diganti menjadi konflik permanen tanpa penjelasan. Periksa juga bukti, retry dan resolusi konflik sebelum rilis.

Langganan aktif tidak berarti QRIS/non-tunai dapat diproses offline. Pembatasan pembayaran offline yang sudah ada tetap berlaku.

## Perpanjangan

Owner membuka Langganan → pilih paket/periode yang tersedia → ambil quote server (harga, kapasitas, modul, tanggal efektif) → konfirmasi invoice → lanjutkan pembayaran melalui alur billing yang ada.

Untuk rilis pertama, gunakan halaman billing web responsif melalui browser aman, dengan sesi billing singkat hasil otorisasi owner. Jangan menaruh access token POS pada URL atau meneruskan identitas operator sebagai owner. Jika mekanisme handoff belum ada, arahkan owner login di web terlebih dahulu. Kembali ke aplikasi melalui app link aman, lalu minta status ke server.

Pembayaran mempunyai state menunggu bayar, diproses, menunggu verifikasi manual, berhasil/aktif, gagal, kedaluwarsa, dibatalkan. Unggah bukti bayar atau redirect sukses tidak mengaktifkan paket. Aktivasi hanya mengikuti verifikasi server/webhook atau persetujuan resmi. Retry webhook dan callback tidak menambah periode dua kali. Tampilkan satu invoice tertunda yang dapat dilanjutkan, hindari invoice baru akibat ketukan berulang.

Setelah server menyatakan aktif: muat ulang status, entitlement dan kapasitas → validasi tenant/perangkat → lanjutkan antrean aman → kembalikan pengguna ke kasir tanpa login ulang. Jika akun/perangkat tidak masuk kapasitas paket baru, tampilkan langkah pengaturan kapasitas untuk owner, tanpa menghapus data.

Tanggal mulai/akhir perpanjangan mengikuti kontrak billing existing dan ditampilkan pada quote, termasuk kasus perpanjangan sebelum habis, sesudah habis, dan ganti paket. Jangan menghitung harga atau menambah bulan sendiri di mobile.

## Fondasi implementasi

- Kontrak status tunggal di backend, termasuk ability/capability untuk penjualan, baca, penutupan shift, sinkronisasi dan billing. Server tetap otoritatif; guard Flutter hanya membantu pengalaman pengguna.
- Subscription repository/state di Flutter; refresh saat login, app resume, perubahan tenant, kembali dari billing, serta berkala saat online. Polling tidak berlangsung di background terus-menerus.
- Handler SUBSCRIPTION_REQUIRED terpusat, termasuk GraphQL error dalam HTTP 403. Bedakan dari sesi kedaluwarsa, izin peran, kapasitas paket, dan gangguan jaringan. Gabungkan respons error serentak menjadi satu transisi layar.
- Guard pada seluruh jalur mutasi, shortcut, deep link dan retry; pengecualian pemulihan mengikuti allowlist yang diaudit, bukan semua mutation dibuka.
- Identitas pemilik billing ditentukan server dari akun yang sah, bukan PIN kasir, flag is_admin, atau nilai lokal.
- Tidak ada data langganan yang tampil pada customer display. Pengingat tunduk hak akses dan tidak membocorkan rincian tagihan.

## Tahapan pengerjaan

1. Audit menyeluruh expiry/trial/grace, billing owner, transaksi berjalan, shift, antrean dan kapasitas. Tetapkan kontrak waktu dan matriks izin.
2. Perbaiki perhitungan server dan pengecualian pemulihan; tambah pengujian batas waktu, trial, suspended dan owner/operator.
3. Integrasikan status/handler/guard mobile, banner, layar baca saja dan halaman Langganan/pemulihan.
4. Hubungkan perpanjangan ke billing existing, status pending/verifikasi, dan pemulihan otomatis.
5. Selesaikan kebijakan offline, antrean, penutupan shift dan idempotensi sebelum membuka penjualan offline pada state baru.
6. UAT Android di staging untuk semua state dan transaksi; rilis bertahap setelah kriteria di bawah lulus.

## Kriteria siap rilis

- Peralihan active → expiry konsisten tanpa menunggu cron, termasuk tepat pada batas waktu dan grace=0.
- Owner dan kasir mendapat layar/hak yang benar; PIN operator tidak bisa dipakai mengambil alih billing owner.
- Habis saat kasir terbuka atau saat submit tidak menyebabkan transaksi ganda, uang hilang, struk palsu, atau draft/antrean terhapus.
- Read-only benar-benar menolak seluruh mutasi bisnis di backend, termasuk akses langsung API; sesi, PIN pemulihan, dukungan dan penutupan shift yang diizinkan tetap aman.
- Offline/restart/jam perangkat berubah/koneksi kembali tidak dapat melewati batas izin; transaksi sah dapat dipulihkan.
- Pending pembayaran belum membuka akses; webhook valid baru mengaktifkan, retry tidak menggandakan periode; batal/gagal/expired ditampilkan jujur.
- Setelah renew, tenant, modul, outlet dan kapasitas terminal benar; tidak ada akses bocor dari cache tenant/operator sebelumnya.
- Android layar kecil/keyboard/teks besar nyaman; back navigation tidak menembus pembatasan; customer display bebas informasi billing.
- Semua skenario diuji dengan data staging; tidak ada pengujian transaksi pada produksi.
