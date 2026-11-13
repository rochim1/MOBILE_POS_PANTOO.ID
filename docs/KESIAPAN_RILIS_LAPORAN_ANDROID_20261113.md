# Kesiapan rilis laporan Android — 13 November 2026

Kandidat Android **1.0.8+9** berhasil dibangun dan diverifikasi. Pengujian teknis pada staging terisolasi selesai. Backend produksi belum diperbarui dan aplikasi belum dipublikasikan.

## Cakupan kandidat

Laba rugi, arus kas, aging piutang/utang, valuasi historis, pergerakan stok, restok, dan ekspor CSV/PDF. Seluruh laporan keuangan memakai scope gabungan instansi dan koneksi online. Ini bukan rilis filter per toko/lokasi, snapshot offline, atau seluruh halaman dokumen Finance.

Penyempurnaan kesiapan produksi:

- Server sekarang memeriksa **cakupan izin**, bukan hanya tindakan `view`. Role cabang/self tidak dapat mengambil gabungan instansi. Izin ekspor harus berlaku untuk seluruh instansi; tidak dapat diwarisi dari role cabang. Aging dan histori juga mempertahankan cakupan izin sumber.
- Permintaan laporan dibatasi 30 detik. Satu koneksi transport yang putus dapat dicoba ulang sekali untuk query baca saja; kesalahan izin/bisnis tidak diulang. Respons sesi/filter lama tetap ditolak.
- Ekspor mempertahankan nama berkas dan MIME di Android. Perubahan pengguna/filter selama pembuatan berkas membatalkan berbagi. Tidak ada pengiriman otomatis kepada penerima.
- Restok mengikuti pergantian hari bisnis server. Pencarian karakter khusus diperlakukan literal, pembacaan berlebihan ditolak, dan arus kas tidak memangkas jurnal secara diam-diam.
- Pengelompokan event mutasi memakai satu lintasan, diuji dengan 10.000 produk.
- Build release memakai salinan registrasi plugin yang mengeluarkan plugin pengujian. Registrasi debug/QA asli tetap utuh. Pemeriksaan build gagal bila format registrasi berubah secara tidak dikenal.

## Bukti verifikasi

| Pemeriksaan | Hasil |
| --- | --- |
| Gate Finance lengkap, 64 suite | **577/577 lulus**, tanpa skipped/cancelled/todo; period pilot lulus |
| Regresi final laporan mobile | **34/34 lulus** |
| Regresi backend tambahan pada kode final | **22/22 lulus**, termasuk role nyata, pencabutan izin dan volume mutasi |
| UAT Android emulator, API + JWT + Mongo staging | **Lulus**: tujuh jenis laporan, saldo historis, pergantian tab |
| Dialog berbagi Android asli | **Lulus** untuk CSV dan PDF; nama, MIME dan isi diverifikasi; dialog ditutup tanpa memilih penerima |
| Rekonsiliasi HTTP baca-saja | **30/30 lulus** terhadap Finance dan hasil ekspor |
| Analisis Dart area perubahan | **Tidak ada masalah** |
| APK produksi | Build release berhasil; signature v2 valid, paket `id.pantoo.pos`, versionCode 9/versionName 1.0.8 |
| Isi APK | Query laporan ada pada arm64-v8a, armeabi-v7a, x86_64; font PDF dan lisensi ada; plugin pengujian tidak masuk release |

Staging menggunakan transaksi buatan, akun uji dan database sementara yang terpisah. UAT ini tidak menyatakan seluruh biaya atau histori setiap usaha produksi sudah lengkap. Kondisi bukti yang tidak lengkap tetap ditampilkan sebagai batas data. iOS belum diverifikasi pada Mac/perangkat iOS.

## Artefak lokal

Semua jalur berikut relatif terhadap akar workspace `zera`:

- `output/pantoo-pos-reports-release-1.0.8/Pantoo-POS-1.0.8+9.apk`
- `output/pantoo-pos-reports-release-1.0.8/build.json` — ukuran, SHA-256 dan pemeriksaan APK.
- `output/pantoo-pos-reports-release-1.0.8/readiness.json` — ringkasan dan hash sumber laporan yang diuji.
- `presensi_zera_BE/artifacts/finance/release-gate.json` — hasil gate Finance lengkap.
- `output/pantoo-report-final-mobile.log`, `output/pantoo-report-final-backend.log`.
- `output/pantoo-report-android-uat.log`, `output/pantoo-native-share-evidence.json`.
- `output/pantoo-report-staging-reconciliation.json`.

Kandidat berasal dari working tree saat ini, termasuk perubahan lain yang sudah ada sebelumnya; commit aplikasi dan backend harus ditinjau serta dipilih secara eksplisit untuk deployment. Tidak ada push, merge, penggantian role, pembuatan baseline produksi, atau perubahan transaksi produksi pada pekerjaan ini.

## Prosedur rilis

1. Tinjau dan simpan commit backend/mobile yang akan dirilis. Gate CI backend sudah mencakup pengujian laporan POS yang baru. Jalankan Flutter test dan build secara berurutan karena keduanya menghasilkan registrasi plugin.
2. Deploy backend terlebih dahulu melalui pipeline Finance yang ada. Kontrak baru `GetPOSFinancialReportOptions`, `GetPOSProfitLoss`, dan `GetPOSBusinessReport` harus tersedia sebelum aplikasi baru didistribusikan.
3. Periksa akun pemilik/admin dan pengguna terbatas. Akses keuangan gabungan memerlukan `finance_reports.view` untuk seluruh instansi; ekspor juga `finance_reports.export` untuk seluruh instansi. Piutang/utang memakai izin sumber yang setara; histori membutuhkan izin jurnal. Jangan memperluas role kasir untuk mengatasi pesan akses ditolak.
4. Jalankan rekonsiliasi baca-saja pada instansi staging/produksi yang diizinkan menggunakan skrip backend `scripts/audit-pos-financial-reports.cjs`. Token disediakan melalui `POS_REPORT_AUDIT_TOKEN`, bukan argumen atau berkas contoh. `POS_REPORT_AUDIT_API_KEY` opsional bila gateway mewajibkannya. Gunakan `--url`, `--tenant`, `--from`, `--to`, dan `--out`; gunakan HTTPS di luar loopback.
5. Tinjau masalah sumber pada instansi tersebut: jurnal draft, HPP, pemetaan akun, pengecualian aging, snapshot/jejak stok. Perbaikan data harus memakai proses Finance yang berwenang dan bukti asli. Angka lengkap tidak boleh dipaksakan dari stok terkini.
6. Distribusikan kandidat Android melalui kanal rilis yang dipilih setelah backend dan role sesuai. Untuk Play Store, buat app bundle dari commit serta versi yang sama dan pastikan nomor build belum pernah dipakai. APK ini belum diunggah.

Perubahan adapter tidak membutuhkan migrasi transaksi. Bila terjadi masalah, hentikan distribusi aplikasi baru dan pulihkan versi aplikasi/backend sebelumnya melalui prosedur rilis. Jangan menghapus jurnal, histori atau snapshot saat rollback.

## Pengulangan UAT terisolasi

Backend menyediakan `scripts/qa-pos-financial-reports.cjs`, dengan opt-in `POS_REPORT_QA=1`. Script ini membuat replika Mongo sementara, memakai kunci JWT khusus QA, menolak pemakaian koneksi aplikasi, dan membuka port loopback 18097. Tidak memuat berkas `.env` aplikasi. Runtime berhenti otomatis setelah 30 menit atau SIGINT.

Pengujian native berada di `integration_test/pos_financial_reports_android_test.dart`, flavor `qa`. Forward port 18097 menggunakan ADB sebelum menjalankannya. Saat dialog berbagi muncul, tutup tanpa memilih penerima; bukti native harus mencakup kedua format. Jangan menghapus data aplikasi staging/QA untuk menjalankan pengujian. Kandidat produksi memakai entrypoint `lib/main_production.dart`, bukan entrypoint pengujian.
