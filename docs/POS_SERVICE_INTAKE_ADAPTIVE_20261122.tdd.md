# Detail jasa adaptif — implementasi dan bukti pengujian

Tanggal: 22 November 2026 (Asia/Jakarta).

## Hasil dan lingkup

Sudah diterapkan pada Flutter mobile, Vue POS web, dan backend. Produk jasa tidak lagi otomatis memunculkan pertanyaan objek/keluhan/teknisi yang wajib untuk semua usaha. [Rencana lengkap](../../docs/POS_SERVICE_INTAKE_ADAPTIVE_20261122.plan.md).

| Jenis layanan | Perilaku kasir |
| --- | --- |
| Jasa umum / `none` | Pilih layanan dan tarif, lalu langsung bayar. Catatan opsional melalui Detail layanan. Tidak wajib mengisi keluhan/teknisi. |
| Pekerjaan / `work_order` | Objek/identitas atau catatan pekerjaan wajib; teknisi opsional dan hanya muncul bila fitur staf aktif. |
| Cucian / `laundry` | Berat/jumlah berasal dari keranjang dan satuan terpilih; kg dan satuan tidak tercampur. Tag/catatan opsional. |
| Reservasi | Jadwal wajib di form reservasi saja. Bila layanan membutuhkan detail pekerjaan, isian tersebut ada pada form yang sama. |
| Barang non-jasa | Tidak memicu form jasa meskipun profil usahanya bengkel/laundry. Catatan jasa dari barang yang sudah dihapus tidak ikut dikirim. |

`auto` merupakan default aditif bagi data lama: bengkel → pekerjaan; laundry → cucian; lainnya → tanpa detail wajib. Setiap produk jasa boleh memilih pengecualian. Perubahan ini tidak mengganti harga tetap/fleksibel, kewajiban pelanggan untuk piutang, HPP opsional, role, toko, atau lokasi stok.

Untuk pekerjaan yang belum selesai, gunakan **Jadikan pesanan** agar dapat dipantau dan diserahkan melalui antrean. Bayar langsung tetap merupakan penjualan langsung, bukan otomatis membuat order pekerjaan baru. Pada order pekerjaan, lunas tidak otomatis berarti pekerjaan/penyerahan selesai.

## Perubahan teknis

- Master `service_intake_mode`: enum `auto`, `none`, `work_order`, `laundry`; skema GraphQL input/output, query katalog paginasi dan legacy, form master kedua client, serta template import diperbarui.
- Server menentukan kewajiban dari master terpercaya; penanda `object_type` kiriman client tidak dapat menyamarkan pekerjaan wajib menjadi jasa umum.
- Mobile menyimpan mode di `PosProduct`, cache JSON, hasil tambah/edit produk, dan salinan produk ketika tarif diubah.
- Nama layanan berasal dari produk. Server juga melengkapi nama baris yang kosong dari master, tidak meminta kasir mengetiknya lagi.
- Beberapa objek untuk satu layanan disimpan sebagai baris terpisah. UI mobile/web dapat memisahkan, mengisi tag/catatan, memperbaiki pembagian jumlah, atau menghapus detail objek secara eksplisit.
- Kuantitas total tetap milik keranjang. Pembagian multi-objek yang tidak cocok ditolak dengan pesan perbaikan, bukan digabung/ditimpa diam-diam. Cucian satuan/paket menggunakan jumlah bulat; kg boleh pecahan.
- Jadwal lama dibuang dari layanan langsung. Jadwal reservasi yang sudah disimpan digunakan kembali ketika pengguna melanjutkan pembayaran.
- Payload lama yang memakai status layanan pada tingkat header tetap didukung. Server tidak membuat baris baru yang memaksa aplikasi lama memakai API status per objek.
- Snapshot jasa umum yang sudah diklasifikasikan tidak dipaksa menjadi pekerjaan reparasi/laundry ketika dibayar. Data historis tanpa klasifikasi tetap menggunakan perlindungan alur lamanya.
- Tidak menambah endpoint atau izin publik. Dokumen GraphQL dan pendaftaran autentikasi yang relevan tetap diverifikasi.

## Bukti RED → GREEN

| Area | RED | Perbaikan / GREEN |
| --- | --- | --- |
| Kebijakan server | `d432677c`, modul kebijakan belum ada | `35ad49ca`, aturan profil dan produk |
| Integrasi server | `58f60bcd`, jasa umum ditolak dan override belum diperiksa | `7221207b`, penjualan/order memakai master terpercaya |
| Objek server | `d0e527e7`, satu objek tanpa detail masih terlewat; `5b6321df`, cakupan master/objek/settlement | Tiap objek diperiksa, nama dibaca dari master, status pekerjaan dilindungi |
| Mobile | `c8dda51`, field/model/helper belum tersedia | Metadata, form kontekstual, reservasi tunggal, dan widget editor objek |
| Web | `b9546b8e`, helper belum tersedia; `24f50f52`, objek kedua hilang | `88a9f5c9` untuk kebijakan awal, dilanjutkan integrasi form dan editor objek |

Log awal tersimpan di `../../output/service-intake-policy-red-20261122.log`, `service-intake-integration-red-20261122.log`, `service-intake-mobile-policy-red-20261122.log`, `service-intake-web-policy-red-20261122.log`, `service-intake-web-objects-red-20261122.log`, dan `service-intake-server-objects-red-20261122.log`.

## Hasil pengujian

Tidak menjumlahkan tes induk dan tes Flutter di dalamnya sebagai skenario yang berbeda. Tes ulang dengan skenario sama juga tidak dihitung sebagai cakupan tambahan.

| Pemeriksaan | Hasil terverifikasi | Bukti di `../../output/` |
| --- | --- | --- |
| Regresi backend, GraphQL dan inventori | 79 PASS, 0 gagal pada run akhir | `service-intake-backend-regression-20261122.log` |
| Fokus kebijakan, master dan dua objek server | 19 PASS | `service-intake-server-objects-final-20261122.log` |
| Flutter unit/widget/regresi pembayaran | 61 PASS | `service-intake-mobile-regression-20261122.log` |
| Vue policy, checkout, offline, tarif fleksibel dan katalog | 57 PASS | `service-intake-web-regression-20261122.log` |
| Client nyata → HTTP/GraphQL → database uji | 10 skenario web PASS + 11 skenario Flutter PASS; runner Node melaporkan 11 tes induk PASS | `service-intake-cross-client-20261122.log` |
| Tes pemeliharaan onboarding/FAB | 7 PASS | `service-intake-test-harness-maintenance-20261122.log` |
| Analisis Dart pada sumber yang diubah | No issues found | `service-intake-analyze-20261122.log` |
| Flutter analyze seluruh proyek, setelah pemeliharaan alat tes | No issues found, 0 masalah | `service-intake-flutter-analyze-full-20261122.log` |
| Kompilasi template Vue | Kasir, tambah/edit master dan daftar Inventory OK | `service-intake-vue-template-20261122.log` |

Cakupan yang benar-benar diuji:

- Tunai, transfer dan tempo dari tampilan pembayaran jasa umum tanpa popup wajib; tarif hasil edit tidak kembali ke harga awal.
- Reservasi tanpa jadwal ditolak; jadwal tidak ditanya lagi pada percobaan berikutnya; form reservasi pekerjaan memuat isian wajib di tempat yang sama.
- Objek/keluhan wajib untuk produk pekerjaan, termasuk override pada profil jasa umum; pilihan teknisi tidak menjadi syarat.
- Campuran laundry kg+satuan dan satuan terpilih yang berbeda dari satuan dasar; pecahan kg valid, pecahan jumlah item ditolak dengan pesan yang jelas.
- Dua objek mempertahankan identitas/catatan masing-masing. Pembagian jumlah tidak sesuai ditolak sebelum order tersimpan; server tidak mempercayai `object_type` client.
- Mode kebutuhan detail tersimpan lewat mutasi master, tidak hilang pada edit parsial, dan terbaca kembali melalui katalog. Nilai enum tidak valid ditolak.
- Barang stok, jasa BOM, tambahan barang, reservasi stok, pembatalan berizin, serta status pekerjaan/penyerahan setelah pembayaran.
- Payload layanan lama dan status header pada profil laundry, bengkel, salon, jasa dengan inventori simple/centralized/advanced.
- Pesanan belum dibayar online/offline, pembukaan ulang SQLite, sinkronisasi, serta pengiriman ulang memakai identitas permintaan sama.
- Respons pembayaran hilang setelah commit tidak membuat transaksi/jurnal ganda. Perubahan harga master setelah kesepakatan tidak mengubah harga order.
- Piutang mempertahankan nilai tagihan; cicilan/pelunasan dan retry pencatatan memiliki bukti jurnal/saldo. Pembayaran kredit offline tetap diblokir sesuai kebijakan lama.
- Penolakan izin tidak disamarkan sebagai keberhasilan offline; cart tidak dibuang saat penyimpanan lokal gagal.
- Layout pembayaran pada HP sempit/landscape, ukuran teks berbeda, keyboard nominal dan formulir split; siklus controller modal diuji.

## Pemeliharaan alat tes yang ditemukan saat verifikasi

1. Pembaca kontrak GraphQL inventori sebelumnya mencoba mengurai konstanta daftar field sebagai query mandiri. Sekarang konstanta disisipkan sebagaimana dilakukan Dart sebelum validasi operasi; validasi schema tidak dinonaktifkan.
2. Fixture provider pada tes client Flutter belum menyediakan `endpointUrl`, sedangkan pemulihan pembayaran menggunakannya untuk memisahkan data antar endpoint. Fixture diperbarui; perilaku produksi tidak diubah.
3. Tes FAB masih mengirim dua parameter onboarding yang sudah tidak ada. Tes disesuaikan ke konstruktor aktual; dua blok teardown diperbaiki gaya penulisannya.
4. Analyzer mengecualikan `output/**` yang berisi runner tes sementara, bukan sumber aplikasi. Source `lib/` dan tes sebenarnya tidak dikecualikan.

## Cara menjalankan ulang

Dari backend, gunakan database replika sementara yang dibuat oleh tes, bukan koneksi aplikasi produksi:

```powershell
node --test --test-concurrency=1 tests/pos_service_intake_policy.test.js tests/pos_service_fulfillment.integration.test.js tests/pos_flexible_service_pricing.integration.test.js tests/pos_reservation_lifecycle.integration.test.js tests/pos_priority_service_finance.integration.test.js tests/pos_graphql.contract.test.js tests/inventory_mobile_graphql.contract.test.js
$env:QA_FLUTTER_BIN='D:\aplikasi\flutter_sdk\flutter\bin\flutter.bat'
node --test --test-concurrency=1 scripts/test-pos-flexible-checkout-clients.cjs
```

Dari mobile:

```powershell
flutter test --no-pub test/pos_service_intake_policy_test.dart test/pos_service_intake_fields_test.dart test/pos_service_fulfillment_test.dart test/pos_service_intake_profile_test.dart test/pos_service_line_flow_contract_test.dart test/pos_service_quantity_test.dart test/pos_reservation_time_test.dart test/pos_flexible_service_test.dart test/pos_payment_single_flight_test.dart test/pos_payment_mobile_layout_test.dart test/pos_payment_locale_contract_test.dart test/pos_product_import_test.dart
flutter analyze --no-pub
```

Dari Vue web:

```powershell
node --test tests/pos-service-intake-policy.test.mjs tests/pos-service-fulfillment.test.mjs tests/pos-unpaid-offline.test.mjs tests/pos-flexible-service.test.mjs tests/pos-catalog-pagination.test.mjs
```

## Batas verifikasi dan penerapan

- Belum diuji dengan sentuhan langsung pada HP/emulator Android atau browser pengguna dalam pekerjaan ini. ADB mengembalikan daftar perangkat kosong. Widget test dan client HTTP bukan pengganti bukti GUI perangkat nyata.
- Tidak membuat APK/AAB atau menjalankan build web. Tidak mengubah data instansi produksi maupun pengaturan QA pengguna.
- Backend perlu diperbarui lebih dahulu sebelum client meminta field GraphQL baru. Setelah itu perbarui client/katalog online; cache lama memiliki default `auto`.
- Perubahan master setelah transaksi offline dapat membuat antrean membutuhkan peninjauan saat sinkronisasi. Ini tidak diberi jalur bypass: aturan server dan penyimpanan antrean lama tetap berlaku.
- Perubahan pengguna yang sudah ada, termasuk versi paket, coverage dan perubahan startup yang tidak terkait, dipertahankan.

## Evaluasi hasil

Ringkasan: implementasi dan tes otomatis tersedia, tetapi penerimaan GUI perangkat nyata masih diperlukan sebelum mengklaim semua tampilan produksi sudah teruji.

| Aspek | Nilai | Bukti / perbaikan berikutnya |
| --- | --- | --- |
| Akurasi | 5/5 | Hasil dibedakan menurut jenis tes dan log; tidak mengklaim GUI Android atau deploy. |
| Kelengkapan | 4/5 | Master, ketiga lapisan, pembayaran/offline/Finance tercakup otomatis; perlu uji sentuh Android. |
| Kejelasan | 4/5 | Panduan pemakaian dan batas tersedia; laporan teknis cukup panjang untuk pembaca nonteknis. |
| Dapat dijalankan | 5/5 | Kode, tes, perintah ulang dan urutan deployment disediakan. |
| Keringkasan | 4/5 | Ringkasan terpisah dari rincian; sebagian prinsip diulang agar laporan berdiri sendiri. |

Rata-rata: 4,4/5. Prioritas lanjutan: uji GUI HP pada jasa umum, dua objek pekerjaan dan laundry campuran; verifikasi form yang sama di browser setelah backend diperbarui. Penilaian ini seharusnya sejalan dengan kebutuhan pengguna karena tidak menyamakan tes otomatis dengan penerimaan perangkat nyata.
