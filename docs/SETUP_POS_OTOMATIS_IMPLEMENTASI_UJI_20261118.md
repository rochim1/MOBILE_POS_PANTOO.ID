# Setup POS otomatis — implementasi dan hasil uji

Tanggal: 18 November 2026, Asia/Jakarta.
Status: **PASS untuk matriks otomatis perubahan ini: 136 tes, 0 gagal; pemeriksaan Flutter 10 berkas tanpa masalah.**

## Hasil untuk pengguna

Usaha POS baru mengisi nama, telepon, dan profil usaha. Server menyiapkan satu toko dengan nama usaha dan satu lokasi `Stok <nama usaha>`. Cabang organisasi/pengelola tetap terpisah dari lokasi stok, sehingga hubungan transaksi dan Finance tidak ditukar. Lokasi awal menjadi default penerimaan pada Inventory sederhana.

Mobile mengirim pilihan profil saat membuat instansi. Admin Vue menggunakan satu tahap untuk POS tanpa meminta lokasi presensi; HR tetap memakai alur lokasi yang sudah ada. Wizard profil tidak ditanyakan lagi bila persiapan baru sudah dikonfirmasi server. Guide/dashboard sederhana menyembunyikan langkah teknis yang sudah selesai, bukan menyembunyikan masalah yang belum selesai.

Katalog, PIN, dan shift tetap mengikuti aturan yang berlaku. Tidak dibuat produk contoh, saldo stok, HPP layanan, kas awal, atau transaksi fiktif. Jasa murni tidak diwajibkan memiliki stok/HPP. Barang fisik dan komponen tetap mengikuti aturan stok masing-masing item.

## Pembatasan agar konfigurasi lama aman

- Penanda `pos_initial_setup` hanya ditambahkan server pada pembuatan instansi POS baru melalui `CreateInstansi`; input GraphQL tidak menerima penanda ini.
- Tidak ada migrasi massal, inferensi dari instansi kosong, atau auto-setup saat membaca runtime.
- Instansi lama, HR, ERP, konfigurasi centralized/advanced/custom yang telah dipilih, lokasi sebagian, dan data operasional yang sudah ada tidak ditulis ulang oleh bootstrap.
- Pasangan toko/lokasi yang sudah valid digunakan kembali tanpa menulis ulang dokumennya. Hubungan ambigu/rusak menghasilkan `requires_action`, bukan perbaikan diam-diam.
- Pemulihan hanya untuk pemilik aktif pada instansi yang benar. Flag admin saja, akun instansi lain, staf, dan permintaan anonim tidak cukup.
- Tidak ada field stok/izin/biaya yang dilonggarkan untuk membuat setup terlihat siap.

## Idempotensi dan pemulihan

- Pendaftaran diproteksi kunci per pemilik yang diperpanjang selama proses; permintaan bersamaan yang bersaing mendapat konflik yang dapat dicoba lagi.
- Toko, lokasi, default penerimaan, dan penanda selesai disimpan dalam satu transaksi replica set. Kegagalan di tengah proses membatalkan seluruh pasangan otomatis.
- Penguncian record instansi di dalam transaksi mencegah dua perangkat membuat pasangan berbeda, termasuk ketika ID permintaan berbeda.
- `EnsurePOSInitialSetup(client_request_id: String!)` terdaftar pada schema, resolver, dan AuthMiddleware. Identitas instansi/aktor diambil dari sesi, bukan parameter client.
- Mobile dan web menyediakan retry untuk status pending milik pemilik yang memenuhi syarat; timeout tidak membuat toko lokal pengganti.
- `operational_readiness.ready` tidak diubah maknanya. Field baru `context_ready` membedakan kesiapan toko/lokasi dari katalog, PIN, dan shift.
- Instalasi baru tetap memerlukan koneksi untuk membuat usaha. Cache dan antrean offline pengguna lama tidak dimigrasi/dihapus oleh perubahan ini.

## Hasil pengujian akhir

| Lapisan | Hasil | Cakupan |
| --- | --- | --- |
| Backend | **47/47 PASS** | 33 integrasi setup pada MongoDB replica set sementara, 1 kontrak query/schema/middleware, 13 regresi profil/policy |
| Vue admin | **31/31 PASS** | Form POS satu tahap, HR lama, draft/retry, pemulihan, tidak mengulang profil selesai, checklist dan izin dashboard, kompilasi template |
| Flutter mobile | **58/58 PASS** | Pengiriman profil, retry logo tanpa instansi ganda, pemulihan pending, exclusion staf/legacy, bahasa, scroll, profil lama, guide dan ID walkthrough stabil |
| Flutter analyze | **PASS** | 10 berkas perubahan, `No issues found` |
| Cakupan service bootstrap | **96,80% baris; 88,61% cabang; 91,67% fungsi** | Pengukuran pada run backend akhir; bukan angka cakupan seluruh aplikasi |

### Kasus penting yang dibuktikan

1. Tujuh profil baru: retail, restoran, jasa, laundry, bengkel, salon, custom.
2. Enam permintaan bersamaan dan retry dengan ID berbeda menghasilkan satu toko/lokasi.
3. Dua pendaftaran bersamaan untuk pemilik sama tidak menghasilkan instansi ganda; retry menggunakan instansi yang sudah dibuat.
4. Pendaftaran `CreateInstansi` sungguhan membuat profil jasa sesuai pilihan dan runtime context siap, tanpa memalsukan katalog/PIN/shift.
5. Instansi POS lama tanpa penanda, HR, ERP, dan pengaturan Inventory lanjutan tidak ditulis ulang.
6. Kegagalan sengaja setelah pembuatan dokumen membatalkan toko/lokasi/default, lalu retry berhasil.
7. Saldo operasional, opname, pembuangan, retur pembelian, dan retur penjualan yang sudah ada menghalangi auto-setup baru yang tidak semestinya.
8. Pajak yang sudah diisi dan profil usaha yang dipilih eksplisit tetap dipertahankan pada settings sederhana yang telah ada.
9. Marker selesai yang tidak sesuai lagi dengan toko memerlukan pemeriksaan, bukan membuat duplikat.
10. Jasa aktif tanpa stok/HPP dapat dinyatakan siap ketika PIN/shift memang opsional menurut policy; tanpa produk, readiness tetap belum siap.
11. Gangguan koneksi mobile menampilkan retry dan tidak membaca pengaturan sebagai sukses sebelum pemulihan dikonfirmasi.
12. Jalur lama/staf tidak memanggil mutasi pemulihan otomatis. Nomor tampilan guide boleh ringkas, tetapi ID tujuan walkthrough tetap benar.
13. Semua dokumen GraphQL setup/runtime yang diubah di Flutter dan Vue divalidasi terhadap schema backend lengkap serta registry authorization.

## Bukti dan cara mengulang

Backend, dari `presensi_zera_BE`:

```powershell
node --test --test-concurrency=1 --experimental-test-coverage --test-coverage-include=graphql/pos_kasir/pos_initial_setup.service.js tests/pos_initial_setup.integration.test.js tests/pos_initial_setup.contract.test.js tests/pos_profile_policy.test.js tests/pos_profile_parity.test.js
```

Web, dari `front_end_template`:

```powershell
node --test tests/workspace-onboarding.test.mjs tests/pos-onboarding-ui.test.mjs tests/pos-dashboard-inventory-permission.test.mjs
```

Mobile, dari `mobile_POS_Pantoo`: jalankan `flutter test --no-pub --concurrency=1` per berkas berikut. Run terakhir sengaja per berkas karena Windows sempat mengunci output compiler saat beberapa suite digabung; gangguan alat itu tidak dihitung sebagai PASS.

- `test/pos_business_logo_flow_test.dart`: 7 PASS.
- `test/pos_initial_context_recovery_test.dart`: 2 PASS.
- `test/pos_setup_language_test.dart`: 7 PASS.
- `test/pos_setup_scroll_test.dart`: 6 PASS.
- `test/pos_onboarding_profile_test.dart`: 26 PASS.
- `test/pos_setup_readiness_test.dart`: 10 PASS.

Log lokal: `mobile_POS_Pantoo/output/initial-setup-backend-final.log`, `initial-setup-web-final.log`, `initial-setup-analyze-final.log`, dan `initial-setup-final-<nama berkas tes>.log`. Log RED awal juga disimpan sebagai bukti tes mendeteksi implementasi yang belum lengkap.

## Batas verifikasi dan penerapan

- Tidak ada data produksi yang dibuat/diubah untuk tes ini. Database integrasi bersifat sementara dan dihentikan setelah run.
- Uji Flutter di atas adalah widget/unit, bukan klaim E2E GUI pada APK terbaru di emulator/HP. Uji Vue menjalankan metode komponen serta kompilasi template, bukan sesi browser checkout produksi.
- Pembayaran, piutang, retur, dan sinkronisasi offline secara menyeluruh tidak diuji ulang end-to-end pada pekerjaan onboarding ini; tidak boleh menjadikan angka 136 sebagai klaim semua fitur POS telah dites ulang.
- Belum build APK/AAB, restart layanan produksi, atau deployment. Backend/schema perlu diperbarui sebelum client baru karena client meminta field runtime baru. Tidak perlu backfill penanda untuk instansi lama.
- Penyederhanaan lanjutan form input katalog, pengukuran waktu pengguna sampai transaksi pertama, dan uji visual perangkat nyata merupakan tindak lanjut terpisah dari persiapan toko/lokasi otomatis ini.

## Pemeriksaan kualitas akhir

Ringkasan evaluasi: **4,0/5**. Akurasi 4: 136 tes otomatis dan analyze mendukung hasil, namun GUI APK/browser terbaru belum dibuktikan. Kelengkapan 4: jalur otomatis, retry, konfigurasi lama dan izin tercakup; penyempurnaan katalog lebih luas tetap terpisah. Kejelasan 4: hasil dan batas dipisahkan, detail teknis tetap ada untuk audit. Keterpakaian 4: perubahan sudah tersedia di tiga repo, tetapi belum dirilis. Keringkasan 4: laporan teknis cukup panjang untuk mengulang pengujian, jawaban pengguna diringkas.

Peningkatan berikut paling bermanfaat: smoke test akun baru melalui Android dan Vue setelah client/server terbaru dijalankan bersama, lalu ukur waktu pengguna sampai katalog pertama. Self-check: penilaian ini tidak menyamakan tes otomatis dengan bukti seluruh aplikasi siap produksi.
