# Rencana offline-first Pantoo POS mobile

Status: P0 sebagian diimplementasikan; P1 dan validasi perangkat masih terbuka.
Fokus utama: aplikasi Android/iOS yang
pernah disiapkan saat online tetap dapat dibuka, menampilkan dashboard yang
jujur, dan memproses operasi offline yang memang aman. Flutter Web hanya untuk
pengujian; antrean SQLite saat ini tidak tersedia di Web.

## Progres implementasi (11 Oktober 2026)

- Dashboard dibaca dari snapshot SQLite terenkripsi saat membuka POS, tanpa
  menunggu riwayat pesanan. Snapshot dipisahkan per instansi, akun, dan periode;
  waktu simpan serta status data tidak real-time terlihat di UI. Perangkat tanpa
  snapshot menampilkan petunjuk aktivasi online, bukan omzet nol yang tampak
  resmi. Jumlah transaksi lokal yang belum selesai disinkronkan ditampilkan
  terpisah dan dapat membuka antrean offline.
- Riwayat, shift, pelanggan, toko, runtime config, dan katalog memakai data
  lokal pada gangguan transport. Error bisnis/izin/schema tidak lagi otomatis
  dianggap offline. Snapshot shift lokal dibatasi 8 jam dan menolak jam perangkat
  yang mundur; ini batas sementara di klien, **bukan lease resmi dari server**.
- Katalog dipisahkan per akun dan lokasi stok. Transaksi offline menolak cache
  lokasi yang tidak cocok dan kegagalan simpan antrean ditampilkan sebagai
  kegagalan transaksi. Snapshot stok lokasi diperbarui bersama antrean transaksi.
  Audit lanjutan menahan refresh stok lokal ketika transaksi lokasi tersebut
  masih belum tuntas, termasuk jika pemetaan toko-ke-lokasi sudah berubah.
- Snapshot shift lama dihapus saat server mengonfirmasi pembukaan atau
  penutupan shift agar shift yang telah ditutup tidak hidup lagi saat offline.
- Saat login dengan akun berbeda, cache baca lama dibersihkan. Antrean
  transaksi pending tidak dibersihkan oleh pergantian akun.
- Pemulihan sesi hanya memakai kredensial lokal ketika jaringan memang putus;
  error izin atau kontrak API tidak lagi diam-diam dianggap offline. Request
  bootstrap independen berjalan paralel dengan timeout, sementara dashboard
  dapat menampilkan snapshot sebelum seluruh data kasir selesai dimuat.
- Favorit katalog disimpan per instansi dan akun. Perubahan yang dibuat saat
  offline ditandai pending dan dicoba sinkron kembali ketika koneksi tersedia.
- Cache stok yang sempat ditahan oleh transaksi ditolak dapat diperbarui lagi
  setelah operator menyelesaikan penolakannya.
- Uji unit cache, klasifikasi error, masa berlaku shift, isolasi favorit, dan
  status antrean ditambahkan. `flutter analyze` dan seluruh `flutter test`
  lulus pada 11 Oktober 2026.

**Belum selesai untuk klaim offline production:** lease shift yang diterbitkan
dan divalidasi server per perangkat, koordinator kebijakan seluruh request,
pengujian cold start/kill/restart pada Android nyata, dan uji dua kasir offline
dengan konflik harga/stok/shift. Jangan menganggap hasil Flutter Web sebagai
bukti kesiapan offline native.

## Kondisi awal sebelum implementasi

- Dashboard menyimpan snapshot `GetPOSDashboardData` per instansi, pengguna,
  dan periode filter. Saat request gagal, snapshot ditampilkan dengan penanda
  offline. Tanpa snapshot, BLoC menghitung statistik dari order yang ada di
  memori; hasilnya bisa kosong/tidak lengkap.
- `LoadPosData` masih memuat riwayat pesanan dan shift aktif melalui request
  server tanpa fallback lokal. Kegagalan salah satunya dapat menggagalkan
  persiapan dashboard meskipun snapshot dashboard tersedia.
- GraphQL `ErrorLink` menangani sesi/token, bukan kebijakan offline umum.
  Penjualan tunai dan beberapa order memakai antrean SQLite + `SyncService`;
  operasi lain tidak otomatis boleh diantrekan.
- Fallback snapshot dashboard saat ini menerima semua jenis error, termasuk
  kemungkinan error otorisasi atau kontrak API. Itu dapat menyamarkan masalah
  server sebagai kondisi offline.
- `ConnectivityResult` berguna sebagai sinyal awal, bukan bukti API dapat
  diakses. Keputusan antre harus mempertimbangkan error transport aktual.

## Prinsip dan batasan

1. **Offline hanya setelah aktivasi online pada perangkat itu.** Login pertama,
   verifikasi awal PIN operator, dan pengambilan konfigurasi/izin awal wajib
   online. Jangan pernah menyimpan kata sandi.
2. **Data server tetap sumber kebenaran.** Dashboard offline adalah snapshot,
   bukan laporan real-time; transaksi belum tersinkron ditampilkan terpisah.
3. **Bukan semua mutasi masuk antrean.** Pembayaran non-tunai, persetujuan,
   perubahan izin/pengaturan, dan operasi stok yang memerlukan keputusan
   lintas perangkat harus tetap online sampai protokol konflik khusus tersedia.
4. **Gagal autentikasi, validasi, dan bisnis bukan gangguan jaringan.** Jangan
   menggantinya diam-diam dengan cache atau mengantre request tersebut.
5. **Isolasi data.** Cache/antrean harus di-scope minimal dengan instansi,
   pengguna, toko, dan perangkat; logout/pindah akun tidak boleh memperlihatkan
   data akun sebelumnya. Data sensitif di penyimpanan lokal perlu dienkripsi
   atau diminimalkan menurut kebutuhannya.

## Kebijakan request yang dituju

| Jenis operasi | Saat offline | Saat online kembali |
| --- | --- | --- |
| Login pertama / aktivasi perangkat | Tolak dengan petunjuk jelas | Verifikasi dan siapkan cache |
| Sesi/PIN yang sudah disiapkan | Izinkan sesuai masa berlaku kredensial lokal | Verifikasi ulang, cabut akses lokal bila ditolak server |
| Dashboard, katalog, toko, pelanggan | Baca snapshot lokal bertimestamp | Refresh dari server lalu ganti snapshot secara atomik |
| Shift aktif | Baca snapshot/izin kerja offline yang masih valid; jangan menganggap shift lama selalu terbuka | Rekonsiliasi status shift sebelum sinkron transaksi |
| Penjualan tunai dan order yang sudah didukung | Simpan lokal dengan ID idempoten dan status `menunggu sinkronisasi` | Kirim berurutan, deduplikasi, tandai konflik untuk review |
| Non-tunai, persetujuan, pengaturan, mutasi stok berisiko | Blokir dengan alasan dan jalur kembali | Jalankan normal setelah konfirmasi server |

## Tahap implementasi

### 1. Kontrak status offline dan pemuatan dashboard mandiri (P0)

- Pisahkan pemuatan dashboard dari `LoadPosData`. Saat app dibuka, baca
  snapshot dashboard lebih dulu tanpa menunggu riwayat/shift; refresh server
  berlangsung setelahnya. Jika belum ada snapshot, tampilkan empty state
  “Hubungkan internet sekali untuk menyiapkan dashboard”, bukan angka nol yang
  tampak resmi.
- Simpan metadata `cached_at`, `account_scope`, `store_scope`, dan periode.
  Tampilkan “Data terakhir diperbarui”, status koneksi, serta jumlah transaksi
  lokal yang belum tersinkron. Jangan gabungkan antrean lokal ke omzet resmi
  tanpa label terpisah.
- Cache hanya boleh dipakai untuk kegagalan transport/timeout yang terklasifikasi.
  Error `UNAUTHENTICATED`, `FORBIDDEN`, validasi, dan schema harus muncul
  sebagai error yang tepat. Pertahankan data terakhir di layar bila refresh
  gagal, tanpa menandainya sebagai pembaruan baru.
- Sediakan aksi Coba lagi dan status loading yang berakhir pasti; jangan
  biarkan overlay “Mempersiapkan dashboard” menunggu request sampai tak jelas.

**Selesai bila:** cold start tanpa jaringan pada perangkat yang sudah disiapkan
menampilkan snapshot dan cap waktu; perangkat baru mendapat petunjuk aktivasi;
error otorisasi tidak disamarkan sebagai offline.

### 2. Bootstrap POS offline yang aman (P0)

- Buat snapshot minimum untuk runtime config/izin, toko aktif, katalog,
  pelanggan yang diperlukan, dan status shift operator. Ambil snapshot saat
  online setelah identitas dan toko dipastikan valid; simpan secara atomik agar
  tidak ada campuran versi lama/baru.
- Ubah `LoadPosData` supaya kegagalan riwayat pesanan tidak menggagalkan seluruh
  bootstrap. Baca riwayat lokal jika tersedia; jika tidak, tampilkan status
  “Riwayat belum tersedia offline”.
- Definisikan **offline shift lease** dari server: siapa operatornya, toko,
  perangkat, batas waktu, dan hak yang boleh dilakukan offline. Tolak transaksi
  baru bila lease habis atau akun/toko tidak cocok. Jangan membuka shift baru
  secara offline tanpa protokol server tersendiri.
- Pastikan PIN offline hanya untuk operator yang telah terverifikasi pada
  perangkat, dengan batas percobaan yang tetap berlaku tanpa jaringan.

**Selesai bila:** dashboard dan kasir dapat dibuka offline setelah persiapan
online; shift tidak tampil sebagai “aktif” hanya karena snapshot lama.

### 3. Koordinator request berbasis kebijakan, bukan antre semua GraphQL (P1)

- Tambahkan komponen `OfflineRequestCoordinator`/policy layer yang digunakan
  repository: klasifikasi error transport, kebijakan baca-cache, kebijakan
  mutasi queueable, timeout, dan hasil bertipe (`fresh`, `stale`, `queued`,
  `needs_review`, `blocked`). `GraphQLClientProvider` tetap mengurus token;
  komponen ini **tidak** otomatis mengantre setiap mutation.
- Pindahkan keputusan fallback yang tersebar ke kebijakan eksplisit per
  operasi. Kegagalan 4xx/GraphQL bisnis tidak diantrekan; timeout/putus koneksi
  yang hasil servernya belum pasti harus memakai ID idempoten saat dicoba lagi.
- Tambahkan logging aman (tanpa token/PIN/data pembayaran), metrik antrean,
  dan pesan UI yang membedakan `tersimpan di perangkat` dari `diterima server`.

**Selesai bila:** setiap request POS punya perilaku offline yang terdaftar dan
teruji; tidak ada error validasi yang berubah menjadi transaksi pending.

### 4. Rekonsiliasi dan konflik lintas kasir (P1)

- Pertahankan antrean SQLite dan `SyncService`, tetapi audit `client_request_id`,
  urutan transaksi per toko/shift, retry dengan backoff, dan pemulihan bila app
  mati saat status `syncing`.
- Server harus menduplikasi secara idempoten dan mengembalikan status yang dapat
  direkonsiliasi. Konflik harga, stok, promo, shift ditutup, atau operator tidak
  valid masuk `needs_review`, bukan dianggap sukses.
- Tampilkan ringkasan pending/konflik di dashboard dan detail tindakan di
  halaman antrean offline. Penutupan shift tetap diblokir selama transaksi
  relevan belum selesai atau belum diputuskan secara eksplisit.

**Selesai bila:** dua perangkat pada toko yang sama dapat offline lalu online
lagi tanpa transaksi ganda atau kehilangan transaksi; konflik terlihat jelas.

### 5. Uji skenario dan rollout (P0 sebelum rilis)

- Unit: pemilihan snapshot per akun/toko/periode, klasifikasi error, masa
  berlaku shift, idempotensi dan status antrean.
- Integrasi: pertama kali online -> tutup app -> offline cold start -> PIN ->
  dashboard -> penjualan tunai -> restart app -> online -> sinkron.
- Negatif: belum pernah login, logout, ganti akun/toko, cache rusak/penuh,
  token dicabut, API mati tetapi Wi-Fi hidup, timeout setelah server menerima
  transaksi, dua kasir offline, stok/harga berubah, shift ditutup perangkat lain.
- UI/perangkat: Android kecil/tablet, banner stale, loading/empty/error,
  antrean setelah app killed/restarted. Flutter Web testing tidak dipakai untuk
  menyimpulkan kesiapan offline aplikasi native.
- Rilis bertahap dengan logging konflik dan rollback flag untuk kebijakan
  offline baru; jangan menghapus data pending saat upgrade.

## Urutan kerja yang direkomendasikan

Kerjakan Tahap 1 dan 2 dahulu karena itulah penyebab utama dashboard tidak
andal saat offline. Tahap 3 merapikan kebijakan request setelah jalur masuk
stabil; Tahap 4 memperkuat sinkronisasi multi-kasir. Tahap 5 dijalankan pada
setiap tahap, bukan hanya di akhir.
