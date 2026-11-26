# Pengaturan alur inventori mobile dan kesetaraan web

Tanggal: 26 November 2026.

## Hasil implementasi

Pengaturan alur stok tersedia di **Pengaturan POS → Inventori**. Web tetap memakai **Inventori → Pengaturan Inventaris → Operasional Gudang**. Keduanya membaca dan menyimpan dokumen `InventorySettings` yang sama; tidak ada konfigurasi inventori mobile terpisah.

Pengaturan tidak dipaksakan saat onboarding. Membuka halaman tidak mengubah profil, membuat gudang, memindahkan stok, ataupun mengubah lokasi toko yang lama.

## Cara penggunaan

1. Pemilik/admin membuka Pengaturan POS, lalu memilih Inventori.
2. Pilih **Stok langsung dijual** atau **Pakai perpindahan stok**. Profil teknis tidak ditanyakan di pilihan utama; nilai profil dan preset di belakangnya tetap mengikuti web/server.
3. Tentukan lokasi penerimaan utama. Untuk profil sederhana dengan lebih dari satu gudang aktif, lokasi ini wajib dipilih agar penerimaan tidak buntu.
4. Jika alur membutuhkan transit, pilihan lokasi transit langsung terlihat. Gudang transit harus aktif dan berjenis `in_transit`.
5. Buka **Pengaturan lanjutan** jika perlu memilih konfigurasi rinci Sederhana/Terpusat/Lengkap/Kustom atau mengatur gudang pusat/toko/display, permintaan/persetujuan transfer, pembelian langsung ke toko, toleransi penerimaan, dan aturan pengiriman. Bagian ini dapat dibuka/tutup, bukan profil ketiga.
6. Tekan Simpan alur stok, periksa konfirmasi, lalu simpan. Tombol menampilkan proses dan tidak dapat ditekan berulang selama penyimpanan.
7. Setelah simpan terkonfirmasi, konfigurasi menu dibaca ulang tanpa mengosongkan keranjang, pilihan satuan, harga edit, jenis pesanan, channel, atau level harga. Jika pembacaan ini gagal, gunakan Sinkronkan menu; tombol tersebut tidak menyimpan ulang pengaturan.

Menu **Inventori → Mutasi Stok** muncul sesuai profil/fitur dan izin `view_inventory_transfers`. Mengubah profil tidak memberikan izin transfer otomatis. Di dalam editor transfer, pilihan antar toko/gudang dan mutasi internal tetap mengikuti batasan lokasi yang sudah diterapkan sebelumnya.

Profil Terpusat/Advanced bukan berarti semua jenis transfer diperbolehkan: aturan gudang pusat serta hubungan gudang toko dan display tetap divalidasi oleh server. Lokasi dan tautan toko dikelola melalui Warehouse & Lokasi, bukan diubah diam-diam oleh formulir ini.

## Hak akses dan koneksi

- Akses masuk ke Pengaturan POS tetap mengikuti navigasi POS yang berlaku.
- Di dalam bagian Inventori, `GetMyPermissions` diperiksa untuk izin **inventory_settings:view/update** atau akses penuh. Izin mengelola POS saja tidak dianggap sebagai izin mengubah inventori.
- Pengguna dengan izin view saja mendapatkan tampilan baca-saja. Server tetap memeriksa izin pada setiap penyimpanan; pencabutan izin menghasilkan penolakan, bukan fallback permisif.
- Pengaturan harus dimuat online. Kegagalan izin, jaringan, lokasi, revisi, atau data wajib tidak diubah menjadi formulir default yang boleh disimpan.
- Scope endpoint, instansi, akun, dan operator diperiksa sebelum/sesudah proses. Respons lama tidak boleh diterapkan ke sesi yang sudah berganti.
- Tidak ada perubahan verifikasi PIN, sesi kasir, peran, atau akses stok.

## Perlindungan simpan dan konfigurasi lama

- Mobile menggunakan `GetInventorySettings` dan `UpdateInventorySettings`, sama dengan web.
- Payload hanya berisi `expected_revision` serta field operasi yang benar-benar berubah. Prefix, notifikasi/penerimanya, template struk, dan POS defaults tidak ikut ditulis ulang.
- Konflik versi, respons hilang, dan respons parsial tidak memicu pengiriman ulang otomatis. Formulir dikunci sampai pengguna memuat ulang data server.
- Membuka kembali formulir membaca revisi terbaru. Menyimpan tanpa perubahan tidak mengirim mutasi.
- Seluruh halaman lokasi dimuat, termasuk ketika jumlah gudang melebihi 200. Lokasi tersimpan yang tidak lagi valid tetap ditampilkan sebagai tidak tersedia; tidak dihapus otomatis.
- Perubahan profil ditinjau ulang oleh validasi server, termasuk kompatibilitas lokasi toko POS yang sudah ada.

## Temuan yang diperbaiki

1. **Profil sederhana dapat menyembunyikan transfer aktif.** Server sekarang menolak perpindahan ke profil sederhana selama masih ada transfer berstatus draft, submitted, approved, rejected, atau in_transit pada instansi yang sama. Selesaikan/batalkan dokumen terlebih dahulu. Dokumen posted/cancelled dan dokumen milik instansi lain tidak menghalangi perubahan.
2. **Profil sederhana dapat tersimpan tanpa lokasi penerimaan meski ada beberapa gudang.** Sekarang ditolak saat simpan, baik dari web maupun mobile, bukan menunggu kegagalan penerimaan berikutnya.
3. **Status simpan tidak sama dengan status menu.** Menu hanya dinyatakan tersinkron setelah pembacaan konfigurasi server yang terverifikasi; cache offline tidak dipakai sebagai bukti keberhasilan pembaruan menu.
4. **Latar pengaturan menutupi efek ListTile pada panel baru.** Panel inventori diberi Material sendiri. Keterlambatan/kegagalan pembacaan POS defaults lama juga tidak menimpa hasil pemuatan pengaturan inventori yang mandiri.
5. **Fixture regresi web tertinggal langkah konfirmasi biaya.** Fixture penerimaan transfer diperbarui, termasuk bukti bahwa konfirmasi biaya yang dibatalkan/gagal tidak mengirim penerimaan. Tidak diperlukan perubahan alur produksi web untuk temuan fixture ini.

Aturan/routing snapshot pada transfer yang sudah dikirim tidak ditulis ulang oleh perubahan pengaturan. Perubahan aturan saja tetap diperbolehkan, dengan perilaku dokumen terkirim diuji melalui regresi server.

## Hasil pengujian terverifikasi

| Pemeriksaan | Hasil |
|---|---|
| Fitur mobile: model, repository, widget, runtime, dan navigasi | 32 PASS |
| Regresi mobile serial: fitur baru + mode transfer, input lokasi/angka, editor, operasi, recovery, parity, konteks rute inventori, hak aksi, dan diskon | 122 PASS pada 16 file; sudah termasuk 32 tes fitur baru |
| Server: pengaturan aman, dokumen GraphQL mobile asli, runtime, operation guard, dan routing transfer | 60 PASS |
| Web: pengaturan aman, aturan transfer, parity mobile, panduan form, dan workflow penerimaan | 74 PASS |
| Analisis kode perubahan | 13 file diperiksa dengan Dart analyzer `--fatal-infos`: No issues found |

Cakupan baris fitur baru dari pengulangan coverage serial yang sukses: model **98/98 (100%)**, repository **92/92 (100%)**, widget **213/244 (87,3%)**, dan helper bahasa **4/5 (80%)**. Ini cakupan baris, bukan klaim seluruh cabang atau seluruh aplikasi teruji. Artefak lokal: `output/inventory-flow-20261126/lcov.info`.

Pengujian server memakai MongoDB replica set **sementara**, bukan database produksi. Uji roundtrip benar-benar mengeksekusi dokumen GraphQL mobile melalui skema/resolver server, membaca hasil dari jalur web, menyimpan perubahan web, lalu membuktikan revisi mobile lama ditolak. Pengujian juga membuktikan field POS, notifikasi, dan template struk tetap utuh.

Uji widget mencakup izin baca-saja, konfirmasi/loading, larangan simpan ulang saat hasil belum pasti, pemulihan baca, sinkronisasi menu saja, tampilan Inggris selebar 320 px dengan teks 1,3×, akses halaman saat loader lama belum selesai, dan kemunculan Mutasi Stok tanpa membuka ulang inventori.

### Perintah reproduksi

Dari mobile:

```powershell
flutter test --no-pub --concurrency=1 test/pos_inventory_flow_settings_test.dart test/pos_inventory_flow_page_test.dart test/pos_inventory_flow_runtime_test.dart test/pos_inventory_flow_navigation_test.dart
```

Dari backend:

```powershell
node --test --test-concurrency=1 tests/inventory_settings_safe_save.integration.test.js tests/inventory_mobile_graphql.contract.test.js tests/pos_inventory_runtime.contract.test.js tests/inventory_operation_guard.test.js tests/inventory_transfer_dynamic_rules.integration.test.js
```

Dari web:

```powershell
node --test tests/inventory-settings-safe-save.test.mjs tests/transfer-dynamic-rules.test.mjs tests/transfer-mobile-parity.test.mjs tests/transfer-form-guidance.test.mjs tests/transfer-workflow.test.mjs
```

## Batas verifikasi dan penerapan

- Tidak ada pengaturan produksi yang diubah, tidak ada migrasi stok/lokasi, dan tidak ada data pelanggan/transaksi yang dihapus.
- Tidak dilakukan build APK/AAB atau deployment pada pekerjaan ini. Perlu memperbarui backend untuk pengaman bersama dan memasang build mobile baru agar menu pengaturan tersedia di aplikasi terpasang.
- Uji tampilan di atas adalah widget/navigasi otomatis. GUI emulator/HP fisik dan browser nyata dengan build baru belum dijalankan pada pekerjaan ini; hasil ini bukan klaim semua skenario produksi telah lulus.
- Regresi paralel sempat kehabisan memori komputer. Pengulangan dilakukan serial agar tidak perlu menutup aplikasi pengguna.

## Checkpoint perubahan

- Mobile RED: `58bc2f6`, `e46fb59`, `bec61fa` — kontrak fitur yang belum tersedia, UI, dan sinkronisasi menu.
- Mobile GREEN: `f63e2a5` — implementasi, pengujian navigasi, dan pemulihan pengaturan.
- Backend RED: `297e0677`, `9a2f274e` — transfer aktif serta kesiapan lokasi penerimaan; kegagalan awal direproduksi sebelum perbaikan terkait.
- Backend GREEN: `5b6cc3ca` — pengaman penyederhanaan profil dan validasi lokasi dalam transaksi.
- Web: `2bfbb285` — perbaikan fixture dan pengujian konfirmasi biaya penerimaan.

Perubahan pengguna yang sudah ada di working tree dipertahankan. Hanya bagian pembaruan konfigurasi runtime pada `pos_bloc.dart` yang dimasukkan ke checkpoint fitur ini, bukan perubahan pemuatan katalog yang sudah ada sebelumnya.

## Evaluasi hasil

Ringkasan: implementasi memakai sumber konfigurasi bersama, dengan verifikasi otomatis dan batas rilis yang dinyatakan jelas.

| Aspek | Skor | Bukti / batas |
|---|---|---|
| Akurasi | 5/5 | Dokumen mobile dieksekusi terhadap skema/resolver sebenarnya; konflik dan pelestarian field diuji. |
| Kelengkapan | 4/5 | Izin, validasi, pemulihan, navigasi, dan bahasa tercakup; GUI perangkat nyata belum dijalankan. |
| Kejelasan | 4/5 | Ada jalur menu dan uraian profil; istilah gudang/transit tetap membutuhkan bantuan untuk pemula. |
| Keterpakaian | 4/5 | Kode dan tes tersedia; pengguna aplikasi terpasang masih membutuhkan rilis baru. |
| Keringkasan | 4/5 | Pemisahan model/repository/copy/widget mencegah duplikasi konfigurasi; halaman tetap memiliki sejumlah kontrol lanjutan. |

Rata-rata: 4,2/5. Perbaikan lanjutan paling bernilai adalah uji GUI emulator/HP dan web setelah build/deployment QA diperbarui. Penilaian tidak menyamakan lulus tes otomatis dengan kesiapan produksi tanpa batas. Pengguna semestinya dapat menyetujui batas ini karena tidak ada klaim uji perangkat yang belum dilakukan.

## Pembaruan UX: dua pilihan utama

Screenshot pengguna menunjukkan empat nama profil teknis masih menjadi pilihan utama. Tampilan mobile diperbaiki menjadi **Stok langsung dijual**, **Pakai perpindahan stok**, dan bagian lipat **Pengaturan lanjutan**. Konfigurasi teknis tetap tersedia di bagian lanjutan; tidak ada nilai profil baru di API atau migrasi database.

Membuka profil Terpusat/Advanced/Kustom hanya menampilkannya sebagai Pakai perpindahan stok, tanpa mengganti nilai profilnya. Memilih alur langsung lalu kembali ke perpindahan mengembalikan konfigurasi rinci yang tadi dipilih, termasuk persetujuan, display, transit, dan toleransi.

Jika sebelumnya memakai profil sederhana dan baru memilih perpindahan, draf disiapkan sebagai Kustom dengan gudang toko dan permintaan transfer aktif. Tidak otomatis mengaktifkan gudang pusat, persetujuan, atau mengubah aturan lintas cabang menjadi langsung. Aturan sistem lintas cabang tetap memerlukan lokasi transit. Tidak ada penulisan sampai pengguna mengonfirmasi Simpan.

- RED: `51a4c55`; tes mengharapkan dua opsi `simple/movement`, tetapi menemukan `simple/centralized/advanced/custom`.
- GREEN implementasi: `f783879`; 10 tes widget/navigasi lulus setelah perubahan.
- Verifikasi tambahan: **36 PASS** pada empat file `pos_inventory_flow_{settings,page,runtime,navigation}_test.dart`, dijalankan serial dengan `flutter test --no-pub --concurrency=1 --coverage --coverage-path output/inventory-flow-20261126/plain-choices-lcov.info ...`.
- Cakupan baris widget terbaru: **245/276 (88,8%)**; helper bahasa **4/5 (80%)**; model **98/98 (100%)**.
- Hasil 122/60/74 pada bagian sebelumnya adalah regresi implementasi awal; pembaruan UI ini mengulang paket 36 tes fitur, bukan mengklaim seluruh paket luas dijalankan ulang.
- Tidak ada perubahan server/web UI, build APK/AAB, atau uji GUI perangkat nyata pada pembaruan label ini.

Evaluasi pembaruan: akurasi 5 (opsi dan pelestarian diuji), kelengkapan 4 (GUI perangkat nyata belum diulang), kejelasan 5 (dua pilihan + bagian lanjutan), keterpakaian 4 (aplikasi terpasang memerlukan pembaruan build), keringkasan 4 (kontrol rinci tetap tersedia tanpa menjadi pilihan utama); rata-rata 4,4/5. Prioritas berikutnya adalah memeriksa GUI build terbaru. Pengguna dapat menilai hasil berdasarkan opsi yang terlihat, tanpa diasumsikan bahwa aplikasi terpasang sudah diperbarui.
