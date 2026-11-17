# Jasa: layanan langsung dan reservasi — 18 November 2026

## Permintaan dan keputusan

Journeys diturunkan dari permintaan pengguna: profil Jasa memakai Layanan Langsung atau Reservasi; jadwal wajib hanya untuk Reservasi, tidak ditanyakan dua kali; pembayaran, pesanan, piutang, dan offline tidak boleh kehilangan harga atau membuat duplikat.

- `take_away` tetap menjadi nilai API/data lama untuk **Layanan Langsung** pada profil `jasa`. Tidak ada migrasi transaksi, perubahan enum GraphQL, atau penggantian ID antrean.
- Profil restoran/ritel tetap memakai istilah Bawa Pulang. Kapabilitas tambahan yang secara eksplisit diaktifkan di pengaturan tidak dihapus.
- Layanan Langsung pada Jasa tidak menampilkan jadwal. Web juga menghilangkan tanggal booking lama dari payload layanan langsung.
- Reservasi mempunyai satu pemilik jadwal: panel reservasi di web, dialog Detail reservasi di mobile. Dialog intake layanan tidak meminta tanggal reservasi lagi.
- Waktu mulai wajib. Selesai memakai durasi awal 2 jam bila tidak diubah; rentang yang tidak valid ditolak. Jumlah tamu dan deposit tetap divalidasi.
- Mobile menyimpan jadwal yang telah dikonfirmasi selama halaman pembayaran masih terbuka; membatalkan konfirmasi akhir lalu mencoba lagi tidak membuka ulang pengisian jadwal.
- Kebutuhan pelanggan, detail pekerjaan/keluhan, batas kredit, izin, shift, dan stok tetap mengikuti aturan yang sudah ada. Perubahan ini tidak menghapus validasi detail pekerjaan pada profil Jasa.

## Perbaikan yang dilakukan

| Area | Hasil |
|---|---|
| Menu kasir mobile/web | Label Layanan Langsung untuk Jasa, Reservasi tetap berbasis fitur janji temu |
| Katalog profil/pengaturan | Label server, fallback web, katalog bundled mobile, serta cache/remote lama diselaraskan |
| Mobile | Jadwal tidak lagi wajib di intake layanan sebelum dialog reservasi; dialog ditunggu sampai selesai ditutup sebelum controller dibuang |
| Mobile UI | Angka nominal pada panel pembayaran tablet sempit tidak meluber ke kanan |
| Web | Jadwal intake opsional profil lain tidak muncul bersamaan dengan jadwal reservasi |
| Web pembayaran reservasi | Membuat pesanan terlebih dahulu lalu membayar pesanan; bukan sekadar penjualan yang membawa tanggal |
| Web respons hilang | Tunai mempertahankan pesanan/pembayaran di outbox; percobaan ulang pembuatan reservasi piutang memakai request ID yang sama |
| Piutang | Pesanan belum dibayar tidak otomatis menjadi piutang. Metode Tempo menerbitkan piutang dan tidak ditandai tunai lunas |
| Offline | Tunai/pesanan operasional dapat diantrekan sesuai kebijakan lama. Piutang dan metode elektronik tetap perlu validasi online; keranjang tidak dihapus saat ditolak |

## Bukti pengujian

| Cakupan | Hasil aktual | Yang dibuktikan |
|---|---|---|
| Flutter: 9 target regresi | **65 PASS**, exit 0 | Menu kasir, uang pas, transfer/tempo, satu jadwal, pembatalan dan retry, tarif fleksibel, ukuran layar, penyimpanan lokal, identitas kasir dan deduplikasi offline |
| Flutter: ulang 2 target setelah perapian | **30 PASS**, exit 0 | Formulir jasa/reservasi dan outbox SQLite tetap benar setelah perbaikan lint |
| Vue/JS: 11 target | **85 PASS**, exit 0 | Checkout langsung/reservasi online dan offline; tempo offline ditolak; respons create/pay hilang; request ID retry stabil; cache, shift dan outbox |
| Server: 5 target | **48 PASS**, exit 0 | Resolver asli pada Mongo replica set sementara: layanan langsung tanpa waktu; booking dan default durasi; tarif tetap; replay tidak menggandakan order; pembayaran tunai/tempo; saldo piutang; lifecycle layanan, reservasi, Finance dan kebijakan profil |
| Flutter analyze: 6 file berubah | **No issues found**, exit 0 | Tidak ada error/peringatan pada kode dan tes yang berubah |
| Sinkronisasi katalog | **PASS** | `node scripts/sync_pos_profile_catalog.cjs --check` dan pemeriksaan katalog web |

Jumlah 198 tes regresi = 65 mobile + 85 web + 48 server. Ulang 30 tes merupakan subset mobile, bukan tambahan skenario unik.

### Perintah yang benar-benar dijalankan

Mobile:

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/service-fulfillment-lcov.info test/pos_service_fulfillment_test.dart test/pos_offline_revocation_sync_test.dart test/pos_flexible_service_test.dart test/pos_reservation_time_test.dart test/pos_service_quantity_test.dart test/pos_service_line_flow_contract_test.dart test/pos_service_intake_profile_test.dart test/pos_profile_catalog_test.dart test/pos_payment_mobile_layout_test.dart --reporter expanded
flutter test --no-pub --concurrency=1 test/pos_service_fulfillment_test.dart test/pos_offline_revocation_sync_test.dart --reporter expanded
flutter analyze --no-pub lib/domain/models/pos_remote_profile_catalog.dart lib/presentation/pages/pos/pos_payment_page.dart lib/presentation/pages/pos/widgets/pos_product_panel.dart lib/presentation/pages/pos/pos_settings_page.dart test/pos_service_fulfillment_test.dart test/pos_offline_revocation_sync_test.dart
```

Web:

```text
node --test tests/pos-service-fulfillment.test.mjs tests/pos-unpaid-offline.test.mjs tests/pos-flexible-service.test.mjs tests/pos-customer-offline.test.mjs tests/pos-local-store-offline.test.mjs tests/pos-kasir-shift-sync.test.mjs tests/pos-outbox-revocation.test.mjs tests/pos-outbox-merge.test.mjs tests/pos-offline-network-failure.test.mjs tests/pos-pwa.test.mjs tests/pos-kasir-onboarding-modal.test.mjs
```

Server:

```text
node --test --test-concurrency=1 tests/pos_service_fulfillment.integration.test.js tests/pos_flexible_service_pricing.integration.test.js tests/pos_reservation_lifecycle.integration.test.js tests/pos_priority_service_finance.integration.test.js tests/pos_profile_policy.test.js
node scripts/sync_pos_profile_catalog.cjs --check
```

### RED → GREEN dan checkpoint

- Mobile `1f5c85b`: reproduksi label Bawa Pulang dan jadwal intake ganda. `5341216`: 5 tes awal GREEN; setelah perluasan pengujian, 65 tes regresi dan 30 tes fokus ulang PASS.
- Web `cf082539`: 6 tes awal RED. `d2e38cd7`: 31 tes GREEN. `8a05249a`: cache pengaturan lama RED; `ff3d0e09`: 17 tes GREEN. `11f65f2a`: retry kredit memakai ID baru, 17 PASS/1 RED; `f47a25c4`: 85 regresi PASS setelah request ID dipertahankan.
- Server `c9edfd64`: 6 PASS/1 RED pada label katalog canonical; `d1a82faf`: 48 tes PASS setelah label diselaraskan.
- Kegagalan penyiapan awal (provider widget, import model invoice, atau izin database sementara) diperbaiki sebelum dihitung sebagai bukti RED perilaku aplikasi.

### Cakupan dan batas pengujian

- LCOV Flutter tersedia di `output/service-fulfillment-lcov.info`. Dibandingkan baseline sebelum `1f5c85b`, tiga file yang terukur mencakup 92/96 baris executable yang berubah (95,8%): payment 83/87, product panel 5/5, remote catalogue 4/4. Cabang label halaman pengaturan belum dieksekusi oleh tes widget pengaturan; bukan klaim coverage seluruh aplikasi.
- Pengukuran V8 web dijalankan, tetapi tidak dipakai sebagai klaim coverage produksi: metode Vue pada harness dijalankan melalui fungsi hasil ekstraksi sehingga persentase laporan Node tidak mewakili seluruh komponen Vue.
- Tes web menjalankan metode kasir sebenarnya dengan transport/storage palsu dan mengompilasi template Vue. Tes mobile menjalankan widget, BLoC, repository dan SQLite lokal. Tes server menjalankan resolver dan pencatatan Finance sebenarnya pada database sementara. Ini bukan satu sesi GUI Android–Chrome terhubung ke server.
- Tidak ada build APK/AAB, pemasangan emulator, restart/deploy server, perubahan data produksi, atau update spreadsheet pada pekerjaan ini.
- Memuat ulang/menutup halaman pembayaran bukan skenario yang dibuktikan oleh guard jadwal in-memory; guard tersebut menjamin retry dalam halaman yang masih terbuka. Antrean offline diuji terpisah pada penyimpanan persisten.
- Log MongoMemoryServer memuat pesan putus koneksi saat teardown pada beberapa suite; hasil runner akhir tetap exit 0, 48 PASS, 0 FAIL.

## Evaluasi hasil

| Aspek | Skor | Bukti / batas |
|---|---|---|
| Akurasi | 5/5 | Hasil runner, saldo invoice, tarif, tipe pesanan, dan request ID diperiksa langsung; batas simulasi dijelaskan |
| Kelengkapan | 4/5 | Permintaan implementasi tercakup; belum ada verifikasi GUI pada APK Android terbaru |
| Kejelasan | 4/5 | Alur pengguna dan bukti dipisahkan; daftar perintah teknis cukup panjang dan ditempatkan di dokumen saja |
| Dapat ditindaklanjuti | 4/5 | Kode dan tes siap ditinjau; pemakaian di perangkat membutuhkan build/deploy terpisah yang tidak dilakukan di sini |
| Keringkasan | 4/5 | Ringkasan pengguna singkat; rincian uji disimpan untuk audit dan dapat diringkas lagi bila diperlukan |

Rata-rata 4,2/5. Tidak ada aspek kritis ≤2. Peningkatan berikutnya: uji GUI pada Android/web yang terhubung server dan pengukuran coverage Vue dengan instrumentasi komponen penuh. Penilaian ini masuk akal bila pengguna membedakan pengujian otomatis yang sudah PASS dari verifikasi perangkat/deploy yang belum dilakukan.
