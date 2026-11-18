# Uji GUI setup instansi POS baru — Android dan web

Tanggal: 18 November 2026, Asia/Jakarta. Cakupan: usaha POS baru → toko/lokasi otomatis → PIN → shift → kasir, termasuk akses ulang dan pembacaan lintas client.

**Hasil: PASS untuk alur inti yang diuji di bawah.** Ini bukan pernyataan bahwa semua fitur POS atau seluruh profil telah diuji GUI ulang.

## Lingkungan dan batas data

- Backend aplikasi sebenarnya, schema dan AuthMiddleware sebenarnya, pada `http://127.0.0.1:18118/graphql`.
- Database khusus `pos_initial_gui_20261118`, MongoDB replica set sementara di loopback. Tidak membaca `.env` aplikasi, tidak memakai database produksi, dan tidak mengirim email keluar.
- Vue POS-only pada `http://setup-qa.localhost:5189`, Chrome yang tersambung; Flutter **Android native**, package `id.pantoo.pos.qa`, emulator `emulator-5554`, API emulator `http://10.0.2.2:18118/graphql`.
- Akun sintetis dibuat tanpa instansi/toko/lokasi. Trial lokal disediakan agar subscription tidak menghalangi alur. Pembuatan usaha, PIN, katalog, serta shift dilakukan lewat GUI, bukan menyisipkan konteks operasional langsung ke database.
- Tidak menghapus data aplikasi, instansi lama, atau konfigurasi produksi. APK dipasang dengan pembaruan yang mempertahankan data. Hanya proses Flutter web lama yang sudah diizinkan pengguna dihentikan.
- Android diuji pada 1080×2400, density 420 (sekitar 411 dp). Density dikembalikan ke override awal **240** setelah uji. Web diuji desktop dan jendela sempit; upaya resize 375 menghasilkan viewport aktual 501 px, sehingga bukan bukti viewport CSS 375 px.

## Matriks hasil GUI

| ID | Skenario dan bukti perilaku | Hasil |
| --- | --- | --- |
| GUI-01 | Akun web baru membuka form buat usaha pada bundle khusus POS; halaman tidak lagi 404 dan tidak meminta lokasi presensi HR. | PASS setelah perbaikan route |
| GUI-02 | Buat `QA Toko Web 1811`, profil retail, telepon valid. Langsung ke dashboard; 1 toko aktif; profil tidak ditanyakan ulang. | PASS |
| GUI-03 | Web membuat PIN, membuka shift dengan kas awal 0, lalu masuk kasir. Katalog kosong tampil sebagai keadaan kosong dan pembayaran nonaktif; tidak ada produk/transaksi contoh otomatis. | PASS |
| GUI-04 | Reload kasir web menggunakan shift aktif, tanpa mengulang setup atau membuka shift baru. Halaman Toko menampilkan satu baris dan sumber stok `Stok QA Toko Web 1811`. | PASS |
| GUI-05 | Android pertama: form menolak nomor tidak valid sebelum menyimpan; nomor valid + profil jasa membuat satu toko/lokasi. Ditemukan gangguan lapisan PIN, kemudian diperbaiki dan diuji ulang dengan akun baru. | PASS validasi/data; kegagalan PIN awal ditutup oleh GUI-06/07 |
| GUI-06 | Akun Android baru untuk retest: buat `QA Jasa Android Retest 1811`, pilih Services. Label/bantuan setup berbahasa Inggris, logo tetap opsional, langsung ke PIN tanpa membuat toko/lokasi manual. | PASS pada APK perbaikan |
| GUI-07 | Dialog buat PIN dapat diisi dan disimpan. Layar PIN tidak kosong, tidak selebar nol, dan tidak memunculkan assertion semantics setelah usaha dibuat. | PASS setelah perbaikan |
| GUI-08 | Tambah Produk dibuka di Android; isi `QA Jasa 1811`, tarif Rp10.000, pilih Services (no stock), HPP kosong. Item tersimpan sebagai `service`, HPP 0, lalu muncul di katalog. | PASS setelah perbaikan modal |
| GUI-09 | Android membuka shift dengan kas awal 0 pada toko otomatis, tanpa pemilihan/pembuatan toko ulang. Kasir menampilkan layanan Rp10.000 dan `Stock not tracked`. | PASS |
| GUI-10 | Hentikan proses aplikasi QA dan buka ulang tanpa hapus data. PIN tetap diwajibkan. Dashboard mengenali 1 layanan, PIN, dan shift aktif; Buka Kasir memakai shift yang sama. Panduan interaktif dapat di-Skip, kasir dapat diakses. | PASS |
| GUI-11 | Login akun usaha Android dari Chrome: halaman Toko menampilkan toko dan lokasi yang sama. Setelah PIN valid, kasir web menampilkan `QA Jasa 1811` Rp10.000 tanpa dialog buka shift baru. | PASS |
| GUI-12 | Audit final membaca data server: ID lama tetap sama, tidak ada pasangan toko/lokasi atau shift ganda; tidak ada transaksi penjualan dari pengujian ini. | PASS |

Dashboard Android sebelum panduan kasir ditutup menunjukkan 7/8 langkah, tetapi kebutuhan esensial dinyatakan siap. Satu langkah tersisa adalah panduan transaksi, bukan pembuatan toko/lokasi yang gagal. Sesudah Skip panduan, kasir tetap berfungsi dan banner setup tidak menghalangi.

## Temuan dan perbaikan

| Temuan yang direproduksi | Perbaikan | Verifikasi penutup |
| --- | --- | --- |
| Bundle web POS membuang route bersama `/hrms/edit-instansi`, sedangkan akun baru diarahkan ke sana. | Pertahankan hanya route akun/setup/billing bersama pada target non-HR; modul operasional HR tidak ikut dibuka. | Tes route RED → GREEN; GUI akun baru sampai dashboard/kasir. |
| Android memanggil kebijakan runtime sebelum memiliki instansi. | Jangan meminta policy tenant saat tenant belum ada; muat ulang setelah tenant terbentuk, dengan pelindung hasil async yang sudah tidak relevan. | Tes jumlah request; retest pembuatan usaha baru sampai PIN. |
| Router di belakang PIN tetap terekspos ke fokus/semantics. | Sembunyikan router terkunci dengan Offstage dan ExcludeFocus, tanpa membuang state router. | Tes semantics/fokus dan GUI transisi usaha baru. |
| Lapisan PIN di dalam pembatas layout dapat berlebar nol. | Stack lapisan kunci memakai `StackFit.expand`. | Tes lebar RED=0 → GREEN penuh; PIN native terlihat dan dapat dipakai. |
| Bantuan setup/logo memakai teks Indonesia pada sesi Inggris. | Tambahkan padanan kedua bahasa dan lookup hasil generator; tooltip logo ikut diterjemahkan. | 5 tes copy Inggris serta form Android native. |
| Tambah Produk merah/kosong: `dependOnInheritedWidgetOfExactType` sebelum `initState` selesai. | Default satuan memakai kunci kanonis `unit`, bukan membaca Localizations di initState. | 2 tes widget ID/EN RED → GREEN; GUI simpan layanan berhasil. |
| Setelah error init diperbaiki, tes layar sempit menemukan dropdown dan footer modal overflow. | Dropdown jenis/persiapan mengikuti lebar; tombol footer dapat membungkus bila ruang sempit. | Tes modal dua bahasa tanpa exception dan GUI Android. |

Checkpoint perubahan di branch aktif:

- Web route: RED `762e70f7` → GREEN `988f6be5`.
- Android lock/copy: RED `b10c3fb` → GREEN `7880c84`; lebar PIN RED `9da476f` → GREEN `d0da0d3`.
- Modal katalog: RED `ea339df` (dua bahasa mereproduksi assertion) → GREEN `1029308`.

## Hasil audit data akhir

| Fixture | Instansi | Toko | Lokasi stok | Cabang organisasi | Shift aktif | Item | Penjualan |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Android awal, sebelum perbaikan PIN | 1 | 1 | 1 | 1 | 0 | 0 | 0 |
| Web retail | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
| Android retest jasa, dibaca juga dari web | 1 | 1 | 1 | 1 | 1 | 1 layanan | 0 |

Audit menguji hubungan `toko.lokasi_cabang_id → lokasi stok`, `operating_branch_id → cabang organisasi`, `lokasi.linked_toko_id → toko`, default lokasi penerimaan, dan penanda setup `ready`. ID instansi/toko/lokasi dari baseline awal tetap sama setelah reload, pembaruan APK, dan akses lintas client.

Data Android retest: instansi `6afd6160c4f73be4b05a1a0a`, toko `6afd6161c4f73be4b05a1be0`, lokasi stok `6afd6161c4f73be4b05a1be1`, shift `6afd67c3c4f73be4b05a2507`. Item `6afd6622c4f73be4b05a24ae`: service, harga jual 10000, harga beli 0. ID ini **hanya ada dalam database QA sementara**, bukan data produksi.

## Regresi otomatis pendamping

- Vue: **33/33 PASS**, empat berkas route/onboarding/dashboard permission. Cakupan plugin route: 93,91% baris, 86,32% cabang, 100% fungsi; bukan cakupan seluruh frontend.
- Flutter setup: **58/58 PASS** (logo 7, recovery 2, bahasa 7, scroll 6, profil 26, readiness 10).
- Flutter lock/copy: **17/17 PASS**.
- Flutter katalog: **5/5 PASS** pada run akhir: modal ID/EN, skeleton kartu sempit, pengikatan grid, serta pilihan skeleton tabel/list/grid. Satu assertion lama yang memeriksa teks susunan kode sebelum ekstraksi komponen diperbarui menjadi pemeriksaan perilaku komponen yang sekarang dipakai; logic produk tidak diubah untuk memenuhi assertion lama itu.
- Total regresi pendamping yang lulus pada tindak lanjut ini: **33 web + 80 mobile = 113 tes**. Angka ini tidak dijumlahkan dengan 136 tes tahap sebelumnya karena ada suite yang diuji ulang.
- Analyze berkas lock/logo/tes: **No issues found**. Analyze katalog + tes baru: **No issues found**.
- Cakupan baris executable yang berubah pada perbaikan katalog (default unit, dua dropdown, footer) **4/4 tercapai** pada run coverage. Bukan klaim cakupan 100% seluruh halaman; cabang edit produk lama tidak seluruhnya dijalankan oleh tes buka form baru ini.
- APK QA Android x64 debug terbaru berhasil dibangun dan dipasang; ini bukan APK/AAB rilis Play Store.
- Backend 47 tes pada laporan implementasi sebelumnya tidak dihitung sebagai rerun pada sesi GUI ini. Tidak ada perubahan logic produk backend dalam tindak lanjut ini.

Perintah utama yang dijalankan:

```powershell
# front_end_template
node --test tests/pos-shared-workspace-routes.test.mjs tests/workspace-onboarding.test.mjs tests/pos-onboarding-ui.test.mjs tests/pos-dashboard-inventory-permission.test.mjs

# mobile_POS_Pantoo
flutter test --no-pub --concurrency=1 test/pin_lock_responsive_test.dart test/pos_initial_setup_copy_test.dart
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/pos-initial-gui-20261118/catalog-lcov.info test/pos_catalog_form_initialization_test.dart test/pos_catalog_tablet_grid_test.dart

# presensi_zera_BE, pembacaan database QA sementara saja
node scripts/qa_pos_initial_setup_audit_20261118.cjs final
```

## Bukti lokal

Folder: `mobile_POS_Pantoo/output/pos-initial-gui-20261118/` (artefak lokal, tidak ditambahkan seluruhnya ke Git).

- `audit-web-created.json`, `audit-android-created.json`, `audit-retest-created.json`, `audit-final.json`: jumlah dan ID data.
- `android-retest-form.png`: form usaha jasa baru sebelum submit.
- `android-add-service-state.png`: bukti kegagalan init katalog sebelum perbaikan.
- `android-cashier-pass.png/.xml`: kasir native pertama berhasil setelah shift dibuka.
- `android-reopen-pass.png/.xml`: kasir setelah buka ulang dan panduan ditutup.
- `android-final-runtime.log`: pemeriksaan error pada proses APK terbaru; tidak menggabungkan log kegagalan versi lama.
- `web-tests-final.log`, `web-route-coverage.log`, `lock-copy-green-final.log`, `catalog-form-red.log`, `catalog-form-green.log`, `catalog-final-tests.log`, `analyze-final.log`, `catalog-analyze.log`, dan `regression-*.log`.
- `android-build-catalog.log`: build APK terakhir sukses. Screenshot web diperiksa langsung melalui pengendali Chrome; penyimpanan file screenshot web ditolak oleh pembatas path alat, sehingga tidak diklaim ada file screenshot web yang tersimpan.

## Yang tidak boleh disimpulkan dari PASS ini

- Tidak menguji ulang pembayaran, invoice/piutang, retur, printer, Finance posting, seluruh profil, atau offline multikasir. Tidak melakukan transaksi penjualan untuk menuntaskan onboarding secara semu.
- Tidak membuktikan upload logo ke storage produksi; logo dibiarkan opsional pada uji ini.
- Tidak membuktikan performa HP nyata, semua ukuran layar, atau regresi visual berbasis baseline. **Visual regression lengkap: belum diuji/inconclusive**; tidak ada baseline gambar yang disetujui.
- Log server lengkap masih memuat kegagalan tahap awal, login uji dengan username terpotong oleh input emulator, penolakan token kedaluwarsa/tidak valid setelah sesi lama, serta kegagalan registrasi push QA. Sesi web dipulihkan dengan login ulang; tidak ada bypass autentikasi. Tidak diklaim bahwa seluruh `server.log` bebas error. Console halaman web akhir bersih; proses Android akhir mencatat 0 kecocokan error Flutter/rendering yang diperiksa.
- Beberapa gangguan alat/lingkungan terjadi: RAM rendah, ANR emulator, Chrome terputus/komputer sleep, cache Vite lama, dan log notifikasi QA `Firebase project tidak dikenali`. Isolasi origin/cache memperbaiki akses web; gangguan ini tidak dihitung sebagai PASS notifikasi atau bukti performa produksi. Pendaftaran push notification tidak termasuk kelulusan alur setup.
- Core backend sebelumnya menguji tujuh profil serta retry/concurrency dan legacy preservation secara otomatis. GUI sesi ini khusus retail web dan jasa Android, bukan tujuh profil GUI.

## Evaluasi akhir

Ringkasan: bukti sekarang mencakup GUI native, browser, dan audit penyimpanan, bukan hanya widget/unit. Akurasi **4/5** (klaim dibatasi ke dua profil GUI dan data lokal); kelengkapan **4/5** (setup sampai kasir serta akses ulang tercakup, upload logo bukan bagian yang dibuktikan); kejelasan **4/5** (hasil awal gagal dipisahkan dari retest PASS); keterpakaian **4/5** (perbaikan dan reproducer tersimpan, belum deployment); keringkasan **4/5** (detail audit dipertahankan agar dapat dilacak). Rata-rata **4,0/5**.

Tindak lanjut paling bernilai: smoke test perangkat fisik dengan koneksi stabil dan upload logo, lalu ukur waktu pengguna baru sampai item pertama. Penilaian ini tidak menyamakan PASS setup dengan kesiapan seluruh aplikasi untuk produksi.

Self-check: hasil dapat ditelusuri dari GUI, JSON audit, dan log; klaim PASS tidak meliputi fitur yang tidak diuji. Tidak ada sumbu bernilai ≤2; hasil dapat diserahkan dengan batas di atas.
