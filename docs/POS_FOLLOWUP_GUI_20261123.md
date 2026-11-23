# Lanjutan audit POS — 23 November 2026

Sumber: permintaan melanjutkan perbaikan dan pengujian yang belum terverifikasi pada [audit sebelumnya](POS_PRODUCTION_AUDIT_20261123.md). Hasil sebelumnya tetap historis, bukan otomatis bukti skenario baru lulus.

## Target dan urutan

1. TEST-POS-FOLLOWUP-CATALOG-2311 — perbaiki syntax penghambat generator tanpa menghapus halaman atau mengecualikannya; konfirmasi FAQ batal tidak boleh menghapus, konfirmasi setuju menunggu aksi. Jalankan generator dan kompilasi ulang; pertahankan katalog pengguna yang sudah kotor.
2. TEST-POS-FOLLOWUP-COPY-2311 — tinjau kandidat teks hanya dari konteks nyata POS/pembelian/penerimaan/stok. Bedakan label/error yang perlu diterjemahkan dari query, log dan catatan bisnis. Pastikan ID/EN, placeholder dan nama data tetap benar.
3. TEST-POS-FOLLOWUP-PROFILE-GUI-2311 — GUI Android dan Chrome pada profil yang belum terbukti, memakai tenant QA baru. Periksa perbedaan jasa langsung/pekerjaan/laundry/reservasi, pelanggan/jadwal, simpan pesanan dan pembayaran tanpa form berulang. Inventori simple/centralized/advanced diperiksa terpisah sesuai alur yang benar-benar dijalankan; tidak menyalin PASS otomatis ke GUI.
4. TEST-POS-FOLLOWUP-OFFLINE-GUI-2311 — dua klien QA, PIN tetap wajib; antrean, pemulihan jaringan dan status akhir diperiksa tanpa mengulang dokumen yang sudah ada. Cek saldo, journal/source dan request_id, bukan hanya toast sukses.
5. Pulihkan perubahan profil/fitur QA dan skala/jaringan emulator/browser; simpan hasil aktual dan batas yang belum teruji. Tidak ada transaksi/konfigurasi produksi, wipe aplikasi atau penghapusan data hasil audit.

## Lingkungan dan penjagaan

Chrome yang sudah tersambung, Vue5189/API18123, emulator5556 dan package QA terpisah. Mongo hanya loopback replica yang sudah dikenali; tenant follow-up terpisah dari dokumen audit awal. Verifier tidak membuat transaksi bisnis atau melewati middleware/PIN. Printer fisik/Google OAuth nyata tidak dapat dianggap PASS tanpa perangkat/akun uji yang tersedia.

## Ringkasan hasil aktual

Perbaikan penghambat generator, bahasa layanan/PIN/offline/reservasi, overlap tombol Bayar dan pesan teknis antrean sudah diverifikasi pada ruang lingkup di bawah. **Belum merupakan persetujuan produksi seluruh profil.** GUI kali ini memakai profil usaha **jasa**, inventori **simple**, satu akun admin QA pada Android dan Chrome; variasi intake produk bukan bukti bahwa profil laundry/bengkel/salon sendiri sudah seluruhnya diuji.

Verifier akhir: **8 penjualan lunas Rp55.000, 10 pesanan unik, 8 jurnal posted seimbang dan sesuai cabang, stok tracked tetap40**. Empat pesanan belum dibayar Rp20.000 tidak membuat penjualan/jurnal/kas. Shift ditutup via web: kas awal0, expected55.000, actual55.000, selisih0. Angka ini dibaca dari dokumen aktual, bukan asumsi kas awal dalam rencana.

## Temuan dan perbaikan

| TEST-ID | Temuan / perubahan | Bukti RED → GREEN | Status |
|---|---|---|---|
| TEST-POS-FOLLOWUP-CATALOG-2311 | FAQ backup memakai await dalam fungsi non-async sehingga generator gagal. Jadikan konfirmasi async, tunggu penghapusan hanya jika dikonfirmasi. Tidak menghapus halaman atau menambah pengecualian. | `tests/ui-catalog-faq-compile.test.mjs`, 3 gagal →3 PASS;711a7c3f→e7584fee. Generator exit0; verifier972berkas,912transformasi,0error baru/lama. | covered scoped; full bundle belum diuji |
| TEST-POS-FOLLOWUP-COPY-2311 | Error validasi layanan, barcode, setup, judul pilihan layanan langsung, pengakuan pesanan offline dan keterangan akhir/durasi reservasi belum konsisten ID/EN. Native: label langsung, retry PIN,10label/detail objek dan2teks reservasi. Nama produk/pelanggan, kuantitas, enum dan payload tidak diterjemahkan. | Web53ed2e6e→0a2bbbc2;84c0e386→2e1450f9;cfcd443c→91afaa4e. Native77c4a85→b68be11;44813e9→b127701;d8b3608→d696ebd. Tes runtime offline dan dialog aktual. | covered pada salinan yang ditinjau |
| TEST-POS-FOLLOWUP-DOCK-2311 | FAB kasir menutupi bagian tengah tombol Bayar: tap mengaktifkan kasir, bukan pembayaran. Body kini menyisakan ruang hanya saat FAB tampil. | b6076f1→7956fba;4tes geometri/aksi ponsel/tablet +2regresi entry PASS. GUI720×1280/density320: Bayar y944–1048, FAB y1056–1168, tidak bersinggungan; tap tengah membuka Payment. | covered |
| TEST-POS-FOLLOWUP-QUEUE-ERROR-2311 | Antrean menampilkan OperationException, alamat API dan stack trace saat jaringan putus. Ringkas hanya pada tampilan; diagnostik tersimpan, status/retry/PIN tetap. Penolakan bisnis sederhana tetap terlihat. | ed1404c→2ef3681;compile RED atas helper yang belum tersedia→2tes PASS. Regresi offline25PASS;helper6/6baris tercakup. GUI APK terbaru menampilkan “No internet connection. Please check your network.”, bukan stack trace. | covered scoped |
| TEST-POS-FOLLOWUP-LEDGER-2311 | Pembayaran dan pesanan operasional harus berbeda; sinkronisasi tidak boleh menggandakan dokumen atau kas. | Verifier database lokal:8sale/10uniqueorder/8balancedjournal; setiap sale tepat1journal posted dengan branch sama;4unpaidorder tanpa invoice penjualan; kas55k/selisih0. | covered untuk fixture ini |
| TEST-POS-FOLLOWUP-PROFILE-GUI-2311 | Selesaikan matriks profil usaha/inventori. | Jasa/simple dengan intake none/work_order/laundry/reservation sudah dijalankan; detail di tabel berikut. | in progress untuk matriks keseluruhan |
| TEST-POS-FOLLOWUP-OFFLINE-GUI-2311 | Offline dan pemulihan dua klien tanpa melewati PIN. | Layanan langsung Android/web dan reservasi web berhasil queue→sync; bukan dua akun kasir serentak atau kehilangan ACK setelah commit. | in progress untuk keseluruhan |

## GUI yang benar-benar dijalankan

Semua angka invoice berawalan `INV-20261123-`; pesanan `ORD-20261123-`. Android native package QA `id.pantoo.pos.qa.service`, bukan Flutter web. Chrome yang tersambung memakai context QA terpisah. API18123 menjalankan schema/auth/resolver/Finance nyata dengan Mongo replica loopback; tidak ada mock penyimpanan transaksi. Payment gateway/bank/printer eksternal tidak dipakai.

| Klien / skenario | Observasi | Hasil |
|---|---|---|
| Android + web: jasa langsung | Invoice0001/0002, masing-masing5.000. Tidak ada pertanyaan jadwal/keluhan wajib. Pelanggan dipilih; web tanpa pelanggan ditolak terlebih dahulu. | PASS |
| Web: pekerjaan | Form kosong ditolak, objek “QA transport job” + catatan diisi sekali; invoice0003Rp10.000/order0001lunas tanpa meminta detail lagi. | PASS |
| Android: pekerjaan | Objek/catatan diisi sekali pada Service details; Save melanjutkan pembayaran invoice0005Rp10.000/order0003lunas. | PASS |
| Web + Android: laundry kg | Qty2,5×3.000=7.500, invoice0004/0007 dan order0002/0005. Tidak meminta berat ulang atau jadwal. | PASS |
| Web: laundry pcs pecahan | Qty2,5×7.000 ditolak dengan pesan EN whole number. Tidak ada pembayaran/jurnal. Keranjang dibersihkan setelah uji negatif. | PASS |
| Web: reservasi online | Mulai24Nov10.00Jakarta, akhir default12.00. Invoice0006/order0004lunas, tanpa pertanyaan jadwal kedua. | PASS |
| Android: reservasi online | Jadwal24Nov09.33–11.33Jakarta diisi sekali; konfirmasi membuat order0007, lalu Pay Invoice→invoice0008. Tidak ada form jadwal berulang. | PASS; konfirmasi simpan dan pembayaran tetap dua aksi berbeda yang disengaja |
| Web: layanan langsung offline | Browser Offline nyata, pesanan tersimpan lokal; setelah online menjadi order0006belum_bayar. Tidak membuat sale/jurnal. | PASS |
| Android: layanan langsung offline | Hapus hanya ADBreverse API, koneksi ditolak. Sebelum reconnect server tetap8sale/7order/8journal. Queue lokal request `f4065116-535e-4366-b446-7529793ab0e0`; restore+Sync menjadi order0008, satu kali. | PASS |
| Web: reservasi offline | Jadwal25Nov10.00Jakarta; acknowledgement EN baru muncul tanpa jaringan. Server tetap8sale/8order saat offline, setelah online order0009belum_bayar dengan jadwal03.00–05.00UTC. | PASS |
| Android APK terbaru: retry offline | Request `7c724004-b8a8-4d64-a8cf-31f1c87414d1` tetap Pending setelah retry gagal; pesan EN aman. Reconnect+Sync dua kali→order0010tepat satu, Delivered,0pending. | PASS |
| Web: tutup shift | Peringatan cek perangkat lain tampil; Android sudah0pending. Tutup dengan actual55.000→Closed/difference0. | PASS |

Pemilihan pelanggan Android sempat tertutup keyboard otomatis; menutup keyboard membuat daftar dapat dipilih. Itu tidak terbukti sebagai kegagalan data pelanggan. Belum ada perubahan global perilaku keyboard dari observasi ini.

## Bukti dan perintah

- Verifier read-only: `node scripts/qa_pos_followup_gui_20261123.cjs verify` dari backend, exit0. [Log](../../presensi_zera_BE/artifacts/pos-production-audit-20261123/followup-final-verification.log), [snapshot final](../../output/pos-continuation-gui-20261123/audit-verify.json). Verifier tidak membuat penjualan, order, shift, atau jurnal.
- Snapshot sebelum/sesudah reconnect tersimpan pada `output/pos-continuation-gui-20261123/audit-native-offline-*.json` dan `audit-web-reservation-*.json` di root workspace. [XML error aman](../../output/pos-continuation-gui-20261123/android-safe-offline-error.xml), [antrean akhir](../../output/pos-continuation-gui-20261123/android-final-clean-queue.xml).
- [Tombol Bayar tidak tertutup FAB](../../output/production-audit-20261123/followup-android-pay-dock-clear.png); [pesan offline terbaru](../../output/production-audit-20261123/followup-android-safe-offline-error.png).
- Vue: kelompok `pos-|purchase-|inventory-|ui-i18n|ui-translation|ui-catalog-faq|app-language|sidebar-i18n`, `node --test --test-concurrency=1 $qaFiles`: **408/408PASS**, exit0. [Log](../../front_end_template/docs/production-audit-20261123/web-followup-final.log).
- Flutter full final sesudah semua perubahan: **1.004/1.004PASS**,5menit42detik, exit0. [Log](../output/production-audit-20261123/mobile-followup-final-all.log). Regresi final bahasa/PIN/dock21PASS; offline25PASS. `flutter analyze --no-pub`: **No issues found**,43,5detik. [Analyze](../output/production-audit-20261123/analyze-final.log). Semua tes memakai worktree termasuk perubahan pengguna yang dipertahankan, bukan klaim clean HEAD.
- Coverage helper antrean baru6/6baris (100%) pada `offline-error-lcov.info`; bukan coverage seluruh Flutter. Pengukuran Node terdahulu88,74%line/80,80%branch mencakup berkas tes/import terinstrumentasi, tidak dipromosikan menjadi coverage seluruh aplikasi/SFC.
- Generator final1.295berkas,27.760hasil ekstraksi;20entry lama yang tidak lagi diekstrak dipertahankan untuk menjaga dirty work pengguna. Katalog final**27.780entry**, web/server identik;60sumber web ditinjau. Audit1.298berkas:0extractable missing;836kandidat absent masih perlu klasifikasi, termasuk log/query/data yang tidak semestinya diterjemahkan. **Bukan klaim semua terjemahan aplikasi lengkap.** [Audit](../../front_end_template/docs/production-audit-20261123/i18n-followup-final.log), [compile972/0error](../../front_end_template/docs/production-audit-20261123/compile-followup-final.log).
- QA debug APK dibangun/pasang `-r` tanpa wipe dengan `POS_QA_ENDPOINT=http://127.0.0.1:18122/graphql`; log `android-build-followup-verified-endpoint.log`. Build ini bukan rilis produksi. SDK memberi peringatan kompatibilitas Kotlin plugin untuk versi Flutter mendatang; build saat ini berhasil.
- Console akhir halaman shift web:0error,1warning token notifikasi Firebase (`src/additional/firebase.js`), bukan token login kasir. Halaman1280×900tidak overflow horizontal; tidak ada baseline visual/axe/Core Web Vitals sehingga tidak diklaim lolos seluruh pemeriksaan aksesibilitas/performa.

## Pemulihan dan batas tersisa

Pengaturan QA dikembalikan ke snapshot: profil jasa/simple, fitur asli dan auto-lock5menit, PIN tetap aktif. Shift telah Closed. Browser online/1280×900, emulator density kembali480; ADBreverse18122→18123 aktif. Tidak ada produksi, sesi staging, password pengguna, versi aplikasi pengguna, data lokal, atau konfigurasi tenant lama dihapus. Dua layanan pemilik Mongo/API QA dibiarkan hidup agar bukti dapat diperiksa.

Prioritas berikutnya, **belum PASS GUI pada run ini**:

1. Dua akun kasir berbeda secara bersamaan, mode per-kasir/laci bersama, revoke offline, kehilangan respons sesudah commit, restart saat sync dan race tutup shift. Dua klien dengan akun sama yang diuji berurutan bukan pengganti skenario itu.
2. Ulangi matriks GUI profil retail/restoran/laundry/bengkel/salon/custom dan inventori centralized/advanced, termasuk PO→GRN parsial→display/transfer→retur/opname multi-rak/batch. Bukti integrasi146 dari audit sebelumnya tetap historis, bukan GUI21kombinasi baru.
3. Reservasi offline Android, invoice/piutang, refund serta kas aktual lintas akun pada perubahan terbaru; layanan pekerjaan offline dengan detail objek. Reservasi online Android dan offline web bukan bukti pengganti.
4. Minor EN: usia antrean masih dapat berbunyi “1 menit” dalam ringkasan English; perlu menerjemahkan unit durasi sebelum memasukkannya ke template. Belum diperbaiki dan tidak disembunyikan dari laporan.
5. Printer Bluetooth/USB/Wi-Fi nyata, layar pelanggan dan Google OAuth asli; full bundle web, baseline visual, audit aksesibilitas dan pengukuran performa produksi terpisah. Tidak ada deploy atau persetujuan siap produksi global dari laporan ini.

Pemetaan ini pemeliharaan inkremental registry, bukan sensus ulang seluruh tes. Tidak ada tes dihapus/di-skip atau guard dilonggarkan agar hijau; tidak ada kandidat stale/duplicate test baru. Checkpoint RED/GREEN berada pada branch aktif; katalog yang sebelumnya sudah kotor tidak di-commit seluruhnya.
