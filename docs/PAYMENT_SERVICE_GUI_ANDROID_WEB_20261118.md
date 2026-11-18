# GUI pembayaran jasa: layanan langsung dan reservasi

Tanggal: 18 November 2026, Asia/Jakarta.

## Cakupan dan status

Permintaan: menjalankan GUI Android native dan web sampai pembayaran selesai; layanan langsung tidak wajib jadwal, reservasi tidak menanyakan jadwal dua kali. Status akhir: **4/4 skenario GUI PASS**, disertai audit penyimpanan dan perbaikan yang ditemukan. Tidak menyatakan seluruh fitur POS telah diuji ulang.

| Skenario | Hasil aktual | Invoice / bukti |
| --- | --- | --- |
| Web layanan langsung, tunai Rp10.000 | **PASS** — pelanggan dan detail pekerjaan diisi, tidak ada jadwal; pembayaran berhasil dan jurnal terposting. | `INV-20261118-0001`, `ORD-20261118-0001` |
| Web reservasi, tunai Rp10.000 | **PASS** — mulai 19 November 2026 10.00 WIB, selesai otomatis 12.00 WIB. Jadwal diisi sekali pada panel reservasi, tidak diminta lagi saat bayar. | `INV-20261118-0002`, `ORD-20261118-0002` |
| Android layanan langsung | **PASS** — pelanggan QA dipilih, detail pekerjaan diisi tanpa field jadwal; pembayaran tunai uang pas berhasil, jurnal terposting. | `INV-20261118-0003` |
| Android reservasi | **PASS setelah perbaikan** — 20 November 2026 10.00–12.00 WIB; mode ketik jam berfungsi. Batal konfirmasi lalu coba bayar lagi tidak meminta jadwal/detail layanan ulang. Pesanan kemudian dilunasi tanpa jadwal kedua. | `INV-20261118-0004`, `ORD-20261118-0004`, tampil Paid di riwayat Android. |

## Lingkungan dan perlindungan data

- Backend dan database QA lokal yang sama dengan uji onboarding sebelumnya: API `127.0.0.1:18118/graphql`, database replica set sementara `pos_initial_gui_20261118`.
- Vue POS di Chrome yang tersambung, `http://setup-qa.localhost:5189/pos/kasir`. Android native package `id.pantoo.pos.qa`, bukan Flutter web.
- Hanya instansi sintetis `QA Jasa Android Retest 1811`, ID `6afd6160c4f73be4b05a1a0a`, dan akun QA lokal. Tidak memakai data produksi atau uang nyata.
- Item yang sudah ada `QA Jasa 1811`, ID `6afd6622c4f73be4b05a24ae`, service Rp10.000, HPP 0, tanpa stok.
- Sebelum pengujian: 0 penjualan, 0 pesanan, satu shift aktif, kas awal dan kas perkiraan 0. Baseline dicatat sebelum transaksi pertama, bukan direset setelah ada transaksi.
- Tidak menghapus data aplikasi/AVD. Logout dan restart hanya untuk memulihkan sesi yang sudah kedaluwarsa serta emulator yang tidak merespons. Tidak mengulang pembayaran yang sudah sukses.

## Hasil penyimpanan web yang diperiksa

- Dua invoice berbeda, masing-masing total/terbayar Rp10.000, outstanding 0, status `lunas`, metode tunai, jurnal `posted`, tanpa `journal_error`.
- Layanan langsung: `appointment_at` kosong, `reservation_start_at/end_at` null.
- Reservasi: waktu server UTC `2026-11-19T03:00:00.000Z` sampai `05:00:00.000Z`, setara 10.00–12.00 WIB. Tidak ada perubahan tarif menjadi harga lain.
- Shift yang sama `6afd67c3c4f73be4b05a2507`: total transaksi 2, tunai Rp20.000, kas perkiraan Rp20.000.
- Pesanan layanan langsung juga dibuat oleh lifecycle jasa dan ditautkan ke penjualan yang sudah lunas. Ini bukan reservasi tambahan atau duplikat: satu pesanan layanan per invoice; layanan langsung tetap tidak memiliki jadwal.
- Screenshot sukses kedua transaksi web diperiksa langsung melalui alat Chrome. Tidak diklaim ada file screenshot web yang tersimpan jika alat tidak mengembalikan path.

## Temuan dan perbaikan web

1. Saat kolom pelanggan kehilangan fokus, template memakai `setTimeout` yang dikompilasi menjadi `_ctx.setTimeout`, sehingga muncul `TypeError: _ctx.setTimeout is not a function`. Direproduksi di GUI dan dengan handler input hasil kompilasi Vue, bukan handler tiruan.
2. Setelah timer template dihapus, GUI mengungkap respons pencarian terlambat masih dapat membuka dropdown lagi sesudah blur. Tes tambahan mereproduksi urutan request → blur → respons terlambat.
3. Perbaikan akhir: `closePelangganDropdown` menutup daftar, membatalkan debounce yang belum berjalan, membatalkan validitas hasil request lama, dan memulihkan status loading. Pemilihan pelanggan tetap dilakukan pada `mousedown.prevent`, sehingga tidak memerlukan timer penutupan.
4. Retest GUI setelah reload: ketik pelanggan lalu pindah fokus ke jenis servis; dropdown tetap tertutup setelah respons selesai dan console tidak memuat error. Tidak perlu membuat transaksi tambahan untuk memverifikasi perbaikan fokus ini.

Checkpoint branch aktif frontend:

- RED `7b2b7d54` → GREEN `0a18d970` untuk exception timer.
- RED `73d5fb26` → GREEN `b492b4b8` untuk respons yang terlambat membuka dropdown kembali.

Regresi fokus: **25/25 PASS**, terdiri dari handler blur, pencarian/cache pelanggan, dan checkout jasa/reservasi online/offline. Regresi web diperluas kemudian menjadi **88/88 PASS** pada 12 target checkout/shift/outbox/PWA; angka 25 adalah subset, tidak dijumlahkan lagi. Ini bukti regresi kode, terpisah dari 4 skenario GUI yang benar-benar dijalankan.

## Temuan dan perbaikan Android

- Sesudah emulator pulih, pembayaran langsung selesai dengan invoice `INV-20261118-0003`; audit `android-direct` menunjukkan 3 penjualan/pesanan dan kas shift Rp30.000. Belum ada penagihan untuk percobaan reservasi yang gagal.
- Pada reservasi, menekan Simpan tanpa jadwal tetap di dialog dan menampilkan validasi waktu/jumlah tamu. Detail layanan sebelumnya tidak menanyakan jadwal. Ini perilaku yang diharapkan.
- Bug yang direproduksi: beralih dari dial jam ke mode ketik saat typography POS diperkecil menghasilkan `BoxConstraints has non-normalized height constraints`, dengan minimum 216 dan maksimum 211,7 pada APK. Baris `ExcludeFocus` pada log adalah ancestor, bukan penyebab perhitungan ukuran jam.
- Penanganan terpusat `showPosTimePicker` menahan skala teks pemilih jam minimal 1; tidak mematikan pembesaran aksesibilitas dan tidak membesarkan seluruh aplikasi. Dipakai pada empat call-site pemilih jam pembayaran/pesanan aktif agar kasus yang sama tidak tersisa pada jadwal layanan dan reservasi.
- RED `ed6f410`: tes mode ketik pada skala 0,85 mereproduksi invalid constraints. GREEN `2d9cd0a`: 13/13 tes layanan/reservasi lulus, termasuk skala 0,85/0,98 dan retry jadwal yang tidak diulang.
- Uji GUI ulang pada APK yang memuat perbaikan **sudah PASS**: mode ketik menampilkan field Hour/Minute, diisi 10:00 AM, hasil reservasi 20 November 10.00–12.00 WIB. Tidak ada error rendering pada proses APK terbaru saat pembayaran selesai.

## Retest reservasi Android sampai lunas

1. APK QA perbaikan dipasang tanpa menghapus data. Kasir tetap memakai toko/shift yang sama.
2. Pilih Reservations dan pelanggan QA, tambah satu layanan Rp10.000, pilih tunai uang pas.
3. Dialog Service details hanya diisi objek pekerjaan dan catatan; tidak ada tanggal/jam di situ.
4. Dialog Reservation details menjadi satu-satunya pengisi jadwal. Pemilih tanggal → mode ketik jam berhasil, termasuk field 10 dan 00 serta AM. Selesai otomatis +2 jam; deposit kosong/0, tamu 1.
5. Simpan jadwal → konfirmasi Create Order. Tekan Cancel, kemudian Process Payment lagi: **langsung kembali ke konfirmasi Create Order**, bukan dialog Service details/Reservation details.
6. Audit pada titik itu masih 3 penjualan dan 3 pesanan, kas Rp30.000. Pembatalan belum membuat booking atau tagihan ganda.
7. Tekan Create Order: `ORD-20261118-0004` dibuat dan halaman pembayaran invoice dibuka. Pilih uang pas → Pay Invoice. Tidak ada permintaan jadwal lagi; toast menyatakan invoice pesanan telah dibayar dan keranjang kembali kosong.
8. Riwayat Android menampilkan `All (4)` dan invoice `INV-20261118-0004` berstatus Paid, Rp10.000, kasir QA. Audit server mengonfirmasi lunas dan jurnal posted.

Catatan alur: Android membuat reservasi terlebih dahulu, kemudian melunasi invoice pesanannya. Ini dua tahap operasional, bukan dua kali input jadwal. Nominal tunai pada halaman invoice dipilih kembali dengan Exact Amount; tidak diubah menjadi klaim alur satu-klik. Layanan langsung telah lulus sebelum patch pemilih jam; patch hanya menyentuh pemilih jam, dan regresi pembayaran langsung juga lulus pada kode terbaru.

## Audit final — PASS

| Invoice | Client / jenis | Nilai | Pembayaran | Jurnal |
| --- | --- | --- | --- | --- |
| INV-20261118-0001 | Web / langsung | Rp10.000 | lunas, terbayar 10000, sisa 0 | posted |
| INV-20261118-0002 | Web / reservasi | Rp10.000 | lunas, terbayar 10000, sisa 0 | posted |
| INV-20261118-0003 | Android / langsung | Rp10.000 | lunas, terbayar 10000, sisa 0 | posted |
| INV-20261118-0004 | Android / reservasi | Rp10.000 | lunas, terbayar 10000, sisa 0 | posted |

- Empat invoice unik, empat pesanan layanan yang masing-masing terhubung satu-ke-satu ke invoice; hanya dua yang bertipe reservation. Tidak ada invoice/pesanan tambahan dari dialog gagal atau retry konfirmasi.
- Kedua layanan langsung tidak memiliki appointment/start/end reservasi. Kedua reservasi mempunyai awal yang sesuai `service_order.appointment_at` dan akhir +2 jam; jam tersimpan UTC sesuai WIB, bukan bergeser karena konversi ganda.
- Tetap satu shift `6afd67c3c4f73be4b05a2507`: total transaksi 4, total penjualan/tunai Rp40.000, non-tunai 0, kas perkiraan Rp40.000.
- Semua item satu unit dengan tarif Rp10.000; tidak ada input HPP yang dipaksakan ke kasir.
- Assertion script final lulus dua kali, termasuk pemeriksaan link invoice/pesanan seluruh layanan langsung dan reservasi, status lunas, jurnal posted, serta selisih kas. Script audit tidak menciptakan transaksi untuk membuat hasil terlihat PASS.

## Verifikasi kode dan lingkungan akhir

- Flutter: **13/13 PASS** untuk layanan/reservasi dan konversi waktu. Web: **88/88 PASS** untuk regresi diperluas. Total pendamping **101** pada run akhir, bukan 101 skenario GUI.
- Flutter analyze empat berkas: `No issues found`.
- LCOV helper pemilih jam baru: **4/4 baris executable tercakup (100%)** pada run akhir. Bukan cakupan seluruh halaman pembayaran atau seluruh aplikasi.
- APK QA debug x64 terbaru sukses dibangun (`assembleQaDebug`, 129 detik) dan dipasang; bukan build rilis/Play Store.
- Console web setelah retest perbaikan blur: tidak ada error. Proses Android terbaru: 0 kecocokan error Flutter/rendering yang diperiksa; log lama yang mereproduksi bug tidak disamakan dengan proses hasil perbaikan.
- Restart AVD mempertahankan userdata. Render host/auto dan 4 CPU membuat pengendalian kembali berjalan; ini pemulihan lingkungan QA, bukan bukti performa HP fisik.
- Ukuran emulator dikembalikan ke kondisi awal: physical 1080×2400, tanpa override ukuran, density override 240. Saat tes dipakai 720×1600/density 280 agar lebar logis tetap sekitar 411 dp dan beban render berkurang. Tidak ada perubahan konfigurasi toko/profil/izin produksi.

```powershell
# front_end_template
node --test tests/pos-customer-input-blur.test.mjs tests/pos-service-fulfillment.test.mjs tests/pos-customer-offline.test.mjs

# presensi_zera_BE, read-only pada database QA yang dijaga loopback
node scripts/qa_pos_service_gui_audit_20261118.cjs web-reservation
```

## Artefak lokal

Folder `mobile_POS_Pantoo/output/pos-service-gui-20261118/`:

- `audit-baseline.json`, `audit-web-direct.json`, `audit-web-reservation.json`: data pembayaran/pesanan dan shift, hanya fixture QA.
- `customer-blur-red.log`, `customer-late-response-red.log`, `web-regression-green.log`: RED dan 25 tes GREEN.
- `web-full-regression.log`: 88 tes web PASS.
- `android-direct-no-schedule.png/.xml`, `android-direct-paid.png/.xml`: detail layanan tanpa jadwal dan sukses invoice 0003.
- `android-time-input-state.png`, `android-time-error.log`, `time-input-red.log`: reproduksi bug pemilih jam, bukan bukti PASS.
- `android-time-input-fixed.png`, `android-reservation-retry-no-repeat.png/.xml`: input jam hasil perbaikan dan konfirmasi retry tanpa jadwal ulang.
- `android-reservation-paid.xml`, `android-history-four-paid.png/.xml`: toast pelunasan dan riwayat invoice 0004 Paid / All (4).
- `audit-android-reservation-retry.json`, `audit-final.json/.log`: sebelum konfirmasi akhir tetap 3, kemudian tepat 4 invoice/pesanan lunas.
- `time-input-green.log`, `mobile-final-regression.log`, `time-picker-lcov.info`, `time-picker-analyze.log`, `android-build-time-picker.log`: regresi, cakupan, analyze, build.
- `android-fixed-errors.log`: pemeriksaan error rendering hanya proses APK terbaru.
- `android-small-current.png`: peringatan ANR Android, bukan bukti pembayaran berhasil.
- `emulator-recovery.log` / `emulator-recovery-error.log`: restart AVD QA yang sama, tanpa wipe. CPU dinaikkan 2→4 dan render dari software ke auto/host untuk mengurangi beban; ini perubahan lingkungan uji, bukan perbaikan produk.

Script audit `presensi_zera_BE/scripts/qa_pos_service_gui_audit_20261118.cjs` hanya boleh memakai URI loopback database sementara tersebut. Mode final mensyaratkan 4 penjualan unik yang lunas, 2 reservasi, pesanan layanan terkait, jurnal terposting, dan selisih kas Rp40.000. **Mode final sudah PASS setelah keempat pembayaran GUI selesai.**

## Batas kesimpulan

Tidak menguji printer, pembayaran bank nyata, pelunasan piutang, refund, semua profil, offline GUI, atau konkurensi dua kasir. Tidak melakukan build/deploy produksi. Tidak ada baseline visual yang disetujui, sehingga regresi visual penuh tetap **INCONCLUSIVE**. Bukti Android dan web dipisahkan; kelulusan ini bukan jaminan seluruh fitur POS bebas bug.

## Evaluasi penyerahan

Ringkasan: empat skenario yang diminta selesai, temuan GUI diperbaiki dengan reproducer RED/GREEN, hasil diperiksa sampai penyimpanan dan kas shift. Akurasi **4/5** (bukti GUI/data ada, performa perangkat fisik tidak diukur); kelengkapan **4/5** (empat pembayaran, validasi dan retry tercakup, bukan seluruh matriks metode bayar); kejelasan **4/5** (kegagalan awal dan hasil retest dipisahkan, detail teknis panjang disimpan di file); keterpakaian **4/5** (kode, tes dan APK QA tersedia, belum rilis produksi); keringkasan **4/5** (ringkasan singkat, artefak rinci untuk audit). Rata-rata **4,0/5**, tidak ada aspek kritis ≤2.

Peningkatan berikutnya: smoke test pada HP fisik dengan keyboard berbeda dan pembayaran non-tunai pada lingkungan uji. Self-check: klaim dapat ditelusuri dari invoice, screenshot/XML, log, dan audit; tidak memakai kelulusan tes otomatis untuk menggantikan GUI yang tidak dijalankan.
