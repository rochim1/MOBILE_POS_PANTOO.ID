# Audit alur transfer dan rilis Android 1.0.26 (27)

Tanggal: 26 November 2026. Permintaan: analisis ulang kesalahan alur setelah pemisahan tab, perbaiki temuan, lalu buat APK dan AAB produksi.

## Temuan dan perbaikan

| Temuan | Dampak sebelum perbaikan | Perbaikan |
|---|---|---|
| Pemuatan barang awal bersifat opsional tetapi kegagalannya memakai error halaman utama | Timeout dapat menutup form yang sudah diisi dan mengarahkan pengguna memuat ulang seluruh form | Pemuatan opsional dipisahkan dari pemuatan dokumen. Kegagalan memberi pemberitahuan tanpa menghilangkan isian; pengguna tetap dapat memilih Tambah barang. Respons lama diabaikan setelah konteks berubah. |
| Respons satuan/kemasan tidak terikat revisi form | Dialog konversi lama dapat muncul setelah pengguna berganti tab dan barangnya sudah dihapus | Respons hanya dipakai pada revisi yang sama, untuk baris yang masih ada, saat tidak menyimpan atau memulihkan permintaan. |
| Ketukan berulang pada satuan/kemasan membuka beberapa permintaan/dialog | Dialog bertumpuk, alur input membingungkan | Satu permintaan aktif per baris, tombol dinonaktifkan sementara, indikator proses tampil selama pengambilan data dan berhenti ketika dialog siap. |

Ketiga masalah direproduksi dengan tes yang benar-benar gagal sebelum perubahan (`test/pos_transfer_flow_release_test.dart`, RED `57e74a2`), kemudian ketiganya PASS setelah perbaikan (`736ef1d`). Iterasi awal indikator loading masih berputar di belakang dialog sehingga tes settle timeout; indikator jaringan dipisahkan dari kunci dialog dan pengulangan menghasilkan 3/3 PASS. Log `output/transfer-flow-release-20261126/red.log`, `green.log`, `green-verified.log` menyimpan riwayat ini.

## Alur yang ditinjau

- Jenis perpindahan → asal → tujuan → barang → jumlah/batch/serial/kemasan → simpan draf → proses persetujuan/pengiriman → penerimaan atau penanganan selisih.
- Pilihan dua tab tetap mengikuti profil inventori. Mutasi gudang toko–display tidak boleh lintas outlet POS. Transfer umum profil terpusat tetap melibatkan gudang pusat; tab internal bukan cara melewati kebijakan ini.
- Ketika jumlah dasar diedit langsung, rincian konversi lama dibersihkan. Perhitungan kemasan tetap memakai faktor master, tidak mengubah faktor atas masukan kasir.
- Mengganti lokasi asal meminta konfirmasi bila ada barang, kemudian membersihkan barang/batch/serial dari asal lama. Tujuan lama yang tidak lagi cocok ditandai dan tidak dapat disimpan sebelum diperbaiki.
- Lokasi fisik asal/tujuan identik tidak boleh dipakai. Pilihan lokasi nonaktif, transit dan karantina tidak menjadi asal/tujuan transfer biasa.
- Create dan tindakan kirim/terima/selisih yang responsnya hilang tetap menggunakan bukti permintaan persisten dan referensi yang sama. Tab form tidak ditampilkan pada keadaan pemulihan yang belum pasti.
- Mengedit draf memakai ID dokumen yang sama; pembaruan draf tidak memposting stok. Pengiriman/penerimaan dan izin tetap diverifikasi server, bukan hanya antarmuka.
- Tidak mengubah data produksi, profil inventori, hubungan gudang–outlet, aturan keuangan, atau konfigurasi penandatanganan Android.

## Spesifikasi pengujian

| Jaminan | Tes | Jenis |
|---|---|---|
| Timeout barang awal tidak membuang catatan atau menutup form | `optional initial product timeout preserves editable form and notes` | Widget Flutter |
| Respons konversi lama tidak membuka dialog setelah tab berubah | `late unit response does not open dialog after movement mode changes` | Widget Flutter |
| Ketukan berulang hanya menghasilkan satu permintaan dan dialog | `repeated unit taps share one request and one dialog` | Widget Flutter |
| Filter profil, lokasi identik, Isi Rak, layar HP dan pemulihan tidak mengalami regresi | Rangkaian transfer modes/editor/operation/parity/recovery, stok awal dan opname | Unit/repository/widget Flutter |
| Rute langsung/transit, persetujuan dan stok kirim/terima tetap konsisten | `inventory_transfer_three_flows`, `inventory_transfer_optional_approval`, `inventory_transfer_dynamic_rules` | Integrasi server dengan database sementara |

## Hasil verifikasi kode

- Seluruh tes Flutter: **1.425/1.425 PASS**, sekitar 5 menit 30 detik. Perintah `flutter test --no-pub --concurrency=2 --timeout 2m --reporter expanded`, log `output/transfer-flow-release-20261126/full-suite.log`. Sumber perbaikan perilaku pada `736ef1d`; setelah run ini hanya ditambahkan pemeriksaan `mounted` eksplisit yang setara dan kurung lint.
- Pengulangan pada kode final sebelum build (`556c511`): **98/98 PASS**, sekitar 53 detik, mencakup tiga tes baru dan 13 berkas regresi inventori/transfer/stok awal/opname. Log `focused-final.log`; cakupan `coverage.info` pada direktori yang sama.
- Cakupan baris: helper filter **39/39 (100%)**; editor transfer **575/708 (81,21%)**. Bukan cakupan seluruh aplikasi.
- Server: **53/53 PASS**, sekitar 24 detik. Perintah `node --test --test-concurrency=1 tests/inventory_transfer_three_flows.integration.test.js tests/inventory_transfer_optional_approval.integration.test.js tests/inventory_transfer_dynamic_rules.integration.test.js`; log `presensi_zera_BE/output/transfer-flow-release-20261126/server.log`. Database lokal sementara, bukan produksi.
- Analisis `dart analyze --fatal-infos lib test`: **No issues found!**, log `analyze-final.log`. Log `analyze.log` adalah riwayat info lint awal yang sudah ditangani, bukan hasil final.
- `git diff --check` pada berkas perubahan: bersih. Perubahan tidak menambah logging kredensial, penanganan token, atau akses produksi.
- Versi sumber dinaikkan dari `1.0.25+26` ke **`1.0.26+27`** pada `556c511`.

## Hasil build dan integritas paket

- `flutter clean` dan `flutter pub get --offline` berhasil. Build APK melalui `scripts/build-pos-apk.ps1 -Flavor production` berhasil (Gradle 333,1 detik); AAB melalui `flutter build appbundle --release --flavor production --target lib/main_production.dart --no-pub` berhasil (83,8 detik).
- Folder keluaran: `D:/my node app/zera/output/pos-release-1.0.26+27-20261126`.
- APK **131.805.212 byte**, SHA-256 `C4B9DC158AC8301C8509C9F74282998C03AD2BD812FBBABE6FCF8F1013B8A796`.
- AAB **110.046.529 byte**, SHA-256 `0759CC293AA7AFA63D4178E06171C0D12EA6469BCEB5F668923171B6FFCEE6A0`.
- APK `apksigner verify` dan AAB `bundletool validate`/`jarsigner -verify` berhasil. Manifest keduanya: package `id.pantoo.pos`, versionName `1.0.26`, versionCode `27`, minSdk 24, targetSdk 36.
- Sertifikat APK/AAB sama dengan rilis manual sebelumnya; hash kode native cocok pada tiga ABI. Catatan checksum dan penggunaan terdapat di README folder rilis.
- Ada peringatan kompatibilitas Kotlin/Java plugin serta sertifikat upload self-signed/tanpa timestamp; tidak disembunyikan, tidak menyebabkan verifikasi paket gagal. Log build/validasi disimpan pada direktori bukti yang sama.
- Tidak mengubah dependensi, signing, endpoint produksi, atau berkas konfigurasi lingkungan.

## Batas klaim

Audit difokuskan pada alur inventori/transfer yang baru berubah dan regresi aplikasi. Build yang berhasil serta tes otomatis bukan bukti bahwa semua kasus operasional produksi sudah diuji pada HP fisik. Tidak melakukan upload Play Store atau deploy server/web. Jangan hapus data aplikasi untuk memasang pembaruan atau membuang bukti transaksi belum pasti.
