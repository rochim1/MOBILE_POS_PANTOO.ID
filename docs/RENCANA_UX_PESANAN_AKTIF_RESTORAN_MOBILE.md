# Rencana UX Pesanan Aktif Restoran — HP dan layar besar

## Keputusan

Kanban empat kolom cocok untuk operator yang memantau banyak pesanan sekaligus
di tablet lanskap atau desktop. Kanban yang sekarang memiliki lebar minimum
1120 dp, sehingga di HP hanya sebagian kolom/kartu terlihat dan perpindahan
status memerlukan geser horizontal jauh. Tabel alternatif juga perlu digulir
horizontal. Keduanya tidak ideal sebagai tampilan utama HP.

Gunakan **antrean satu kolom di bawah 1120 dp** dan pertahankan kanban
drag-and-drop di lebar 1120 dp ke atas. Tampilan Dapur tetap punya layar
tersendiri untuk alur produksi per item; Pesanan Aktif memantau pesanan,
pembayaran, pemenuhan, dan pelayanan.

## Kondisi saat ini

- Filter HP sebelumnya memakan tiga baris dengan ruang kosong. Ini sudah
  diringkas menjadi pencarian + tombol filter, dengan pilihan tipe, status,
  dan urutan di bottom sheet. Filter aktif terlihat tanpa membuka sheet.
- PosTableOrderPage mensyaratkan `use_tables` dan izin `view_tables`. Karena
  itu pesanan restoran tanpa meja/layanan cepat berisiko tidak punya pintu
  Pesanan Aktif meskipun status produksi tetap dibutuhkan.
- Pengurutan bawaan “terbaru” menguntungkan pencarian order baru, tetapi
  untuk antrean operasional perlu menonjolkan pesanan terlama dan yang
  melampaui SLA.

## Tahap implementasi

### 1. Model navigasi dan izin

- Pisahkan akses Pesanan Aktif dari fitur Peta Meja. Peta Meja hanya tampil
  bila `use_tables` dan `manage_tables` aktif; order nonmeja tetap dapat
  dilihat sesuai izin baca pesanan.
- Audit kontrak izin backend sebelum memilih nama izin baru. Jangan
  menganggap `view_tables` sebagai izin semua order tanpa verifikasi.
- Pertahankan tab Peta Meja untuk profil yang mendukung meja; bila tidak,
  buka Pesanan Aktif langsung tanpa tab kosong.

### 2. Antrean HP

- Di bawah 1120 dp, gunakan satu daftar vertikal kartu selebar layar.
  Status “Baru / Dibuat / Siap / Disajikan” menjadi segmented filter
  horizontal dengan jumlah per status dan opsi “Semua”.
- Prioritaskan kartu kritis SLA dan pesanan terlama; urutan manual tetap
  tersedia. Tampilkan nomor order, meja atau tipe pemenuhan, pelanggan,
  waktu/durasi, ringkasan item, status bayar, dan aksi utama.
- Aksi status menggunakan tombol eksplisit (“Mulai proses”, “Tandai siap”,
  “Sudah disajikan”) dengan indikator loading hanya pada kartu terkait.
  Drag-and-drop boleh menjadi akselerator opsional, bukan satu-satunya cara.
- Ketuk kartu membuka detail lengkap untuk catatan item, pembayaran,
  perubahan pesanan, dan histori; tidak menjejalkan semuanya di kartu.

### 3. Kanban layar besar dan dapur

- Pertahankan empat kolom Pesanan Aktif dengan drag-and-drop di >=1120 dp.
  Perpindahan yang pending tetap menampilkan skeleton di kolom tujuan.
- Samakan istilah status serta warna SLA dengan Tampilan Dapur, namun jangan
  menyatukan status order dengan status produksi item: order campuran
  (barang siap + barang dapur) memerlukan keduanya.
- Pertahankan pembatasan transisi status di backend; UI tidak boleh
  menganggap drop berhasil sebelum server mengonfirmasi.

### 4. Filter dan data

- Filter tipe, status, tanggal operasional (default hari ini bila data
  historis besar), dan urutan harus menghasilkan jumlah/status yang benar
  tanpa menyembunyikan pesanan tertunda saat refresh atau reconnect.
- Saat filter menghasilkan nol data, tampilkan empty state dengan aksi
  “Atur ulang filter”, bukan papan kosong yang seolah tidak ada pesanan.
- Simpan pilihan filter selama sesi halaman; pulihkan secara aman saat
  profil/toko berganti.

## Kriteria terima

- Pada 320/360/600 dp tidak ada overflow atau kartu/aksi terpotong.
- Semua status dapat ditemukan dan diperbarui tanpa geser horizontal.
- Restoran dengan meja, layanan cepat tanpa meja, take-away, dan order
  campuran barang jadi+dapur mempunyai jalur Pesanan Aktif yang jelas.
- Kasus offline/reconnect, update status gagal, dua operator memproses
  pesanan yang sama, bayar sebelum disajikan, dan pending drag menampilkan
  hasil yang benar tanpa menggandakan kartu.
- Uji widget responsif dan tes transisi status lulus; lakukan uji perangkat
  fisik untuk gestur, keterbacaan, dan tinggi layar pendek.

## Hasil implementasi dan audit (13 Oktober 2026)

- HP (<1120 dp) kini memakai antrean vertikal, tab status dengan jumlah,
  kartu dengan status bayar/catatan, serta tombol perpindahan status. Tablet
  lebar/desktop tetap memakai kanban atau tabel sesuai pilihan tampilan.
- Peta Meja hanya muncul bila fitur meja aktif dan operator memiliki izin
  mengelola meja. Pesanan Aktif bisa dibuka tanpa fitur meja bila operator
  punya izin `pos_table_order:view` (`view_tables` pada runtime config).
- Filter tipe, status, tanggal opsional, dan urutan tersedia di sheet HP.
  Default semua tanggal mencegah pesanan lama yang belum selesai tersembunyi.
  Saat filter kosong, ada aksi untuk mengatur ulang.
- Permintaan pesanan aktif sekarang mengambil semua halaman server (masing-
  masing maksimal 100) dan mendeduplikasi ID; jumlah tab tidak lagi diam-diam
  dibatasi pada 100 order pertama.
- Status `Selesai` mensyaratkan pembayaran lunas. Pesanan Web Order yang
  dikonfigurasi bayar-sebelum-proses diarahkan ke pembayaran sebelum tombol
  proses dijalankan. Status bayar tidak disamakan dengan status pengerjaan.
- Skeleton muncul pada antrean HP saat pemuatan awal dan saat perpindahan
  status. Kegagalan server membersihkan status pending serta menampilkan pesan.
- `flutter analyze --no-pub` dan tes widget/unit terkait lulus. Belum ada uji
  gestur pada perangkat fisik atau uji integrasi dua operator bersamaan;
  keduanya tetap perlu dilakukan sebelum dinyatakan teruji end-to-end.
