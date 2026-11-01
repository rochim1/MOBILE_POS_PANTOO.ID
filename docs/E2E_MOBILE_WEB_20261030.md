# Uji end-to-end Pantoo POS mobile dan web — 30 Oktober 2026

## Lingkungan dan izin

- Klien Flutter diuji lewat Chrome sebagai pendekatan ke UI mobile pada `localhost:65529` (375 × 812); klien admin Vue di `localhost:5173`. Backend yang digunakan terhubung ke database instansi produksi.
- Pemilik secara eksplisit mengizinkan **dua transaksi uji** di `Toko Bandung [Dummy]`: satu dari klien Flutter dan satu dari POS web. Tidak ada transaksi uji tambahan dalam putaran ini.
- Klien Flutter kemudian berpindah ke `localhost:50366`. Port lama berhenti merespons; pada port baru pengguna masuk kembali dan verifikasi stok/shift dilanjutkan.

## Hasil yang dibuktikan melalui UI

| Skenario | Flutter mobile (Chrome) | POS web Vue |
| --- | --- | --- |
| Masuk dan shift | Akun `rochim` masuk di Toko Bandung [Dummy], shift aktif terlihat | Akun dan shift yang sama terlihat |
| Cari produk | `Mi Instan Goreng [Dummy]` ditemukan | SKU `DUMMY6M26-P07` ditemukan; pencarian SKU tepat juga menambahkan item ke keranjang |
| Keranjang | Satu item, 1 pcs, Rp4.000; tab menampilkan `(1)` | Satu item, 1 pcs, Rp4.000 |
| Bayar tunai uang pas | **Lulus:** `PANTOO-20261030-0001`, Rp4.000, kembalian Rp0 | **Lulus:** `PANTOO-20261030-0002`, Rp4.000, kembalian Rp0 |
| Kembali ke kasir | Keranjang kosong setelah `Selesai` | `Transaksi Baru` kembali ke kasir; stok daftar menjadi 470 |
| Riwayat transaksi | **Lulus:** kedua invoice muncul sebagai dua transaksi teratas, `Lunas`, kasir `rochim`, Rp4.000 | **Lulus:** kedua invoice muncul sebagai dua transaksi terbaru, toko/kasir/metode/item/total benar |
| Baca ulang stok setelah login | **Lulus:** katalog port baru menampilkan produk uji dengan stok 470, sama dengan web | **Lulus:** stok daftar 470 |

Saldo stok produk dummy pada lokasi toko sebelum uji 472, setelah transaksi Flutter 471, dan setelah transaksi web 470. Saldo reserved tetap 0 saat pemeriksaan sesudah transaksi Flutter. Ini membuktikan dua checkout tidak menggandakan maupun melewatkan pengurangan stok pada skenario tersebut.

## Temuan dan perubahan

1. **Stok katalog Flutter tertinggal sesudah checkout.** Setelah invoice pertama dan `Selesai`, katalog masih menampilkan 472 meski saldo backend 471. Tombol `Selesai` kini meminta penyegaran produk; callback diteruskan dari halaman bayar ke halaman sukses agar halaman sukses tetap dapat dibuka secara independen. Status BLoC diturunkan dari `paymentSuccess` sebelum refresh supaya dialog sukses tidak muncul ulang. Di sesi port baru, pemuatan katalog menampilkan 470 sesuai backend/web. **Penyegaran instan tepat setelah `Selesai` belum diuji ulang** karena jatah dua transaksi uji sudah dipakai.
2. **Memilih toko lain ketika shift masih aktif membingungkan.** UI Flutter sempat menawarkan pilihan toko tetapi lalu kembali ke toko shift aktif. Selector sekarang dinonaktifkan selama shift aktif dan memberi petunjuk untuk menutup shift lebih dahulu. Ini mengikuti batas satu shift aktif kasir yang terlihat pada alur saat ini; petunjuk tersebut **terlihat di UI port baru** saat shift Bandung aktif.
3. **Tanggal transfer web salah satu hari pada zona WIB.** Modal `Isi Rak Display` awalnya mengisi 29 Oktober ketika tanggal lokal 30 Oktober akibat memakai tanggal UTC. Default dan fallback edit kini memakai tanggal lokal. **Diuji ulang di browser:** modal mengisi `2026-10-30`.
4. **Konsol POS web** setelah checkout masih mengeluarkan peringatan instance Vue terpasang dua kali pada host container dan peringatan fokus dalam elemen `aria-hidden`. Tidak terlihat kegagalan transaksi GraphQL pada checkout yang diuji; peringatan aksesibilitas tersebut perlu investigasi tersendiri.
5. **Tanggal pembuatan GRN web berupa angka mentah.** Riwayat penerimaan semula menampilkan `1793297999612`. Formatter kini menerima timestamp Unix 10/13 digit dan menghasilkan tanggal lokal. **Diuji ulang di browser:** GRN uji menampilkan `30/10/2026, 01.19`.

## Inventori–display yang turut diperiksa

- Daftar transfer web memuat dua transfer `[UJI] E2E-DISPLAY-1B362D43` sebelumnya dengan status `posted`.
- Tombol `Isi Rak Display` membuka modal transfer dan mengisi gudang toko serta lokasi display `[UJI]` yang berpasangan. Tidak ada transfer baru dikirim melalui UI pada putaran ini.
- Daftar PO mobile dan web sama-sama menampilkan `PO-20261030-0001` dari supplier `[UJI]`, disetujui, diterima lengkap, 3 unit senilai Rp3.000. PO yang sudah lengkap tidak muncul lagi di antrean siap terima web; `GRN-20261030-0001` muncul di riwayat penerimaan dengan 3 pcs. Ini adalah **verifikasi baca-saja lintas UI**, bukan pengiriman/penerimaan PO baru dari UI.
- Bukti backend PO → penerimaan → transfer gudang–display → katalog kasir untuk produk `[UJI]` dicatat terpisah pada [rencana gudang dan display](PO_PENERIMAAN_GUDANG_DISPLAY_PLAN.md). Produk `[UJI]` tidak digunakan untuk dua checkout ini karena kasir memiliki shift aktif di Toko Bandung, bukan outlet `[UJI]`.

## Lanjutan pengujian lintas klien (30 Oktober 2026)

- Dengan izin tambahan pemilik, satu transaksi tunai uji lagi dibuat dari Flutter: `PANTOO-20261030-0003` (Rp4.000). Setelah tombol `Selesai`, stok `Mi Instan Goreng [Dummy]` langsung berubah dari 470 ke 469 di katalog Flutter dan cocok dengan POS web. Ini menutup verifikasi penyegaran instan yang masih terbuka pada putaran pertama. Percobaan bayar web Rp3.000 untuk total Rp4.000 ditolak dengan kekurangan Rp1.000, tanpa transaksi baru. Produk stok nol tidak masuk keranjang di kedua klien.
- Form PO web dan form penerimaan web sempat memakai tanggal UTC sehingga tanggal awal mundur satu hari di WIB. Default tanggal, jatuh tempo, dan jadwal termin pada form PO serta tanggal penerimaan sekarang dihitung dalam waktu lokal. Form retur penjualan POS web diperbaiki dengan cara yang sama. Tanggal PO `2026-10-30` dan NET-30 `2026-11-29` telah terlihat benar pada browser; perubahan form retur belum diuji ulang lewat UI.
- Satu PO uji dibuat melalui web: `PO-20261030-0002`, satu unit produk `[UJI] Produk E2E-DISPLAY-1B362D43` seharga Rp1.000 dari supplier `[UJI] Supplier E2E-DISPLAY-1B362D43`. Draft terlihat di mobile, lalu diajukan dari mobile dan menjadi `Disetujui`. PO ini kemudian **diterima melalui aplikasi Android asli** ke `[UJI] Gudang E2E-DISPLAY-1B362D43`; statusnya menjadi `Penerimaan: Lengkap` dan `Selesai`. Saldo gudang naik 7 → 8 pcs, sedangkan display tetap 6 pcs. Transfer `TRF-20261030-0001` dibuat melalui shortcut `Isi Rak Display` di Android, lalu `Proses Stok` berhasil. Saldo akhir gudang 7 pcs dan display 7 pcs: perpindahan tepat 1 pcs, tanpa perubahan total stok.
- Tab `Penerimaan` mobile sebelumnya tidak langsung menampilkan PO yang baru disetujui, sementara web sudah menampilkannya. Penyebab pada kode: daftar penerimaan tersembunyi dalam `IndexedStack` sudah memuat data lama sebelum tab dibuka dan tidak memuat ulang pada perpindahan tab. Widget daftar kini dibuat saat tab dibuka agar mengambil data terkini. **Diuji ulang pada emulator Android:** PO muncul di antrean, penerimaan berhasil, dan PO hilang dari antrean setelah lengkap.
- Pemilih barang di form PO Flutter **web preview** dua kali memunculkan layar error setelah item ditekan, termasuk tanpa mengetik pencarian. Screenshot pengguna hanya menunjukkan assertion Flutter `framework.dart:6268:12`, `_dependents.isEmpty`; pesan error pertama tidak tampak di terminal atau konsol browser. Akar penyebab web preview belum terbukti. **Diuji pada aplikasi Android asli:** dialog `Pilih barang` terbuka, item dipilih, dan item muncul di form tanpa error; PO percobaan ini tidak disimpan. Judul form juga terlihat benar sebagai `Tambah Purchase Order`. Jadi temuan ini belum terbukti menghalangi Android, tetapi regresi Flutter web preview tetap terbuka.

## Uji PO → stok pada emulator Android

Emulator `Medium_Phone_API_36.1` menjalankan build debug Flutter flavor `production` dengan endpoint produksi. Pada shift `Toko Bandung [Dummy]`, PO `[UJI]` yang dibuat di web dapat dilihat, diterima ke lokasi gudang uji, dan dipindah ke lokasi display uji. Di halaman Stok Inventori, pencarian SKU uji dengan filter lokasi menunjukkan 8 pcs di gudang sesudah penerimaan, lalu 7 pcs di gudang dan 7 pcs di display setelah transfer. Riwayat transfer menampilkan `TRF-20261030-0001` sebagai `Selesai`. Tidak ada transaksi penjualan atau PO tambahan yang disimpan selama uji emulator ini.

**Risiko UX yang ditemukan:** form penerimaan awalnya memilih `Cabang Bandung [Dummy]` (lokasi stok aktif shift), meskipun PO web diisi alamat pengiriman gudang `[UJI]`. Alamat pengiriman PO adalah teks, bukan ID lokasi stok terstruktur; sistem tidak bisa otomatis memilih gudang berdasarkan alamat itu. Penguji secara manual memilih `[UJI] Gudang` dan memverifikasi lokasi pada dialog konfirmasi sebelum menerima. Pada operasional nyata, default ini dapat menyebabkan stok masuk ke lokasi yang salah bila operator tidak memeriksa pilihan. Perlu penentuan lokasi stok terstruktur pada PO atau pilihan lokasi eksplisit pada penerimaan sebagai perbaikan terpisah.

Sesi login Vue web lokal kedaluwarsa sebelum verifikasi ulang status PO/GRN/transfer terakhir dari UI web. Kecocokan status akhir lintas UI **belum diklaim lulus**; bukti saldo akhir di atas berasal dari Android. Uji regresi visual tidak memiliki baseline yang disepakati, sehingga hasil visual **inkonklusif**.

## Batas kesimpulan

Pada 30 Oktober 2026 build debug `production` terbaru berhasil dikompilasi dan dipasang pada emulator Android 16 (`Medium_Phone_API_36.1`, `emulator-5554`). Aplikasi berhasil login, membuka shift yang sudah ada, menerima PO, menambah stok gudang, dan memproses transfer ke display. Screenshot startup tersimpan sebagai [bukti emulator](pantoo-emulator-20261030.png). Uji emulator memakai endpoint produksi; backend lokal `localhost:8080` tersedia untuk web lokal tetapi tidak digunakan oleh flavor Android `production`.

**Checkout tunai retail pada dua klien lulus** pada putaran sebelumnya. **PO web → approval Android → penerimaan Android → stok gudang → transfer display Android lulus** pada produk/lokasi `[UJI]` di putaran ini. Ini belum membuktikan semua profil atau seluruh fitur POS solid. Belum diuji end-to-end dalam putaran ini: pembayaran PO, printer, offline/sinkronisasi, dua kasir bersamaan, split payment, retur, pesanan aktif/dapur, restoran/laundry, serta pembacaan ulang hasil PO terakhir dari UI Vue web setelah sesi login diperbarui. Pemilih barang PO pada Flutter web preview masih belum terdiagnosis tuntas; Android asli berhasil.

Verifikasi kode: `git diff --check` pada file terkait di repo Flutter dan Vue lulus. Analisis Dart pada empat file yang diubah melaporkan `No issues found`, tetapi exit CLI terganggu izin berkas telemetri Dart di luar workspace. Perintah Flutter test tertahan tanpa keluaran saat proses Flutter development pengguna aktif, lalu dihentikan. Jangan menganggap tes itu lulus.
