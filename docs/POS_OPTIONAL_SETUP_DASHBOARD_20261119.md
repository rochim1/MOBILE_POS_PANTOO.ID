# Panduan setup POS opsional — mobile dan web

Tanggal: 19 November 2026. Permintaan: ubah "Selesaikan setup POS" menjadi panduan opsional, pertahankan konfigurasi lama, dan jangan melemahkan pengaman kasir.

## Perubahan

- Web: dashboard tidak lagi mengalihkan pengguna ke `/pos/onboarding` atau membaca default POS hanya untuk mewajibkan wizard. Panduan dapat ditutup, dibuka kembali melalui tombol Panduan POS, dan menampilkan jalan pintas sesuai izin. Preferensi penutupan hanya lokal per instansi. Toolbar dapat membungkus pada layar sempit.
- Mobile: gate tidak lagi memaksa halaman panduan/profil POS ketika flag onboarding belum selesai. Pemulihan toko/lokasi otomatis tetap hanya dicoba untuk konteks baru berstatus pending dengan izin kelola; kegagalan/offline tidak menutup akses home. Konfigurasi lama tidak direset dan penutupan panduan tidak menandai setup operasional selesai.
- Mobile memakai menu Lainnya sebagai pusat operasional, bukan menambahkan dashboard baru. Saran opsional ada di Lainnya, dengan pintu masuk Panduan POS tetap tersedia setelah saran disembunyikan. Tidak ada banner setup permanen yang mengambil ruang kasir.
- Panduan mobile mempunyai tombol tutup eksplisit. Membuka kasir tidak menjalankan tour atau mengubah flag setup. Aksi kasir mengikuti izin `use_cashier`; pengaman PIN, pemilihan toko, shift dan transaksi tetap ada pada lapisan operasional yang sudah digunakan.
- Tidak ada perubahan skema GraphQL, default profil bisnis, pajak, stok, printer, PIN, shift tersimpan, data transaksi, maupun migrasi konfigurasi lama dalam pekerjaan ini. Pemulihan konteks awal tetap memakai operasi idempoten yang sudah ada; tidak ada pemanggilan provisioning untuk konteks legacy/non-owner dalam tes.

## Hasil pengujian

| Jaminan | Pengujian | Hasil |
|---|---|---|
| Dashboard web masuk tanpa redirect, tidak menulis default profil jasa | `front_end_template/tests/pos-optional-setup.test.mjs` | PASS |
| Saran web bisa ditutup dan dibuka kembali; preferensi terpisah antar instansi; storage tidak tersedia tidak mengunci UI | File yang sama | PASS |
| Akun mobile baru, lama, offline dan pending owner/staff dapat mencapai home tanpa wizard paksa atau update settings | `test/pos_optional_setup_test.dart` | PASS |
| Penutupan saran mobile tidak menandai setup selesai; preferensi antar instansi terpisah | File yang sama | PASS |
| Widget saran muat pada lebar 320/900 dp dengan skala teks 150% | File yang sama | PASS |
| Panduan yang belum lengkap bisa ditutup; tombol kasir hanya untuk pengguna berizin; tidak menjalankan tour atau completion otomatis | `test/pos_optional_guide_actions_test.dart` | PASS |
| Tombol tengah membuka workspace kasir tanpa tugas setup tambahan | `test/pos_cashier_setup_entry_test.dart` | PASS |
| Kegagalan pemulihan tidak menjadi loop retry; legacy/staff tidak melakukan provisioning | `test/pos_initial_context_recovery_test.dart` | PASS |
| Konfigurasi/profil lama, menu dan navigasi, pengaman tanpa shift, toko checkout, sinkronisasi operator/shift dan kesalahan PIN | Suite regresi mobile di bawah | PASS |
| PIN/dialog shift web, shift aktif, pesanan belum dibayar offline, dan kegagalan jaringan | Suite regresi web di bawah | PASS |

### Perintah yang benar-benar dijalankan

Web, dari `front_end_template`:

```text
node --test tests/pos-optional-setup.test.mjs tests/pos-onboarding-ui.test.mjs tests/pos-kasir-onboarding-modal.test.mjs tests/pos-kasir-shift-sync.test.mjs tests/pos-unpaid-offline.test.mjs tests/pos-offline-network-failure.test.mjs
```

Hasil terakhir: 53 tes, 53 PASS, 0 gagal. Template Vue juga dikompilasi dalam pengujian. Laporan coverage Node dari evaluasi script tidak dianggap sebagai persentase coverage file Vue SFC.

Mobile, dari `mobile_POS_Pantoo`:

```text
flutter test test/pos_optional_setup_test.dart test/pos_optional_guide_actions_test.dart test/pos_initial_context_recovery_test.dart test/pos_cashier_setup_entry_test.dart test/pos_setup_readiness_test.dart test/pos_onboarding_profile_test.dart test/pos_more_menu_visibility_test.dart test/pos_mobile_navigation_policy_test.dart test/pos_bloc_no_shift_test.dart test/pos_checkout_store_test.dart test/pos_cashier_shift_sync_test.dart test/pos_shift_outlet_recovery_test.dart test/pos_pin_setup_error_test.dart --concurrency=1 --no-pub --coverage --reporter expanded
```

Hasil terakhir: `+112: All tests passed!`. Coverage widget saran baru `pos_setup_suggestion.dart`: 27/30 baris executable = 90%; bukan klaim coverage seluruh aplikasi.

Analisis statis terakhir: `dart analyze lib/presentation/pages/pos/widgets` dan `dart analyze lib/presentation/pages/pos` keduanya selesai dengan exit 0, `No issues found!`. Pemanggilan awal melalui `flutter analyze --no-pub ...` tersendat tanpa output dan dihentikan hanya untuk proses milik tugas ini; hasil di atas berasal dari analyzer Dart langsung, bukan klaim bahwa pemanggilan Flutter yang tersendat berhasil.

Verifikasi lokal: kompilasi dalam tes Flutter/Vue PASS; analisis seluruh direktori halaman POS PASS; 165/165 tes relevan PASS; pemeriksaan diff perubahan tugas PASS. Tidak menambahkan kredensial, query, atau pelonggaran otorisasi backend. Pemeriksaan distribusi APK/AAB dan penerimaan pada perangkat produksi tidak dilakukan pada tugas ini.

Log lokal berada di `D:/my node app/zera/output/optional-setup-*.log` dan `optional-guide-actions-*.log`.

## Bukti RED → GREEN

- Web `393bb937`: tes awal membuktikan redirect `/pos/onboarding` masih terjadi serta aksi saran opsional belum tersedia (5 gagal, 1 lulus). `e000e42f`: implementasi lolos 35 tes awal, lalu regresi diperluas menjadi 53 PASS.
- Mobile `b7af597`: tes baru menginstansiasi jalur gate/saran yang belum tersedia, menghasilkan compile-time RED yang disengaja. `ff1a582`: implementasi awal lolos 10 tes.
- Mobile `9423aed`: compile-time RED untuk aksi tutup/pintu masuk kasir pada panduan. `71cc71e`: aksi diimplementasikan dan 13 tes lulus.
- Regresi luas pertama menemukan satu ekspektasi label tes lama `Laporan Penjualan`, sementara menu sudah menggunakan `Laporan` sebelum perubahan ini. Label tes diselaraskan dengan aplikasi, animasi scroll ditunggu, lalu suite yang sama diulang: 112/112 PASS. Tidak mengubah nama menu aplikasi untuk memenuhi tes.

## Batas pengujian

Pengujian ini lokal (unit, widget, kontrak/kompilasi Vue dan regresi flow). Tidak membuat data produksi, tidak melakukan pengujian GUI transaksi baru di perangkat Android/browser tersambung, tidak deploy server/web, dan tidak membangun ulang APK/AAB. File APK/AAB 1.0.20+21 yang dibuat sebelumnya belum memuat perubahan setelah build tersebut. Pengujian perangkat dan build distribusi terbaru tetap merupakan langkah rilis berikutnya.
