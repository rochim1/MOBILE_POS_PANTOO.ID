# QA Android: profil POS × profil inventori — 30 Oktober 2026

## Lingkungan dan batas pengujian

- Perangkat: emulator Android 16 (`emulator-5554`), APK staging debug dari sumber kerja terkini.
- API: `http://10.0.2.2:8082/graphql`, server lokal dengan MongoDB replica set sementara di loopback. Tidak mengubah tenant/database produksi.
- Fixture: satu tenant QA, akun admin QA, toko, lokasi toko dan gudang pusat, pelanggan, barang stok 50 unit, layanan nonstok. Profil dapat diganti melalui perintah fixture dan aplikasi dimuat ulang.
- Status `PASS Android` hanya diberikan setelah tindakan/hasil terlihat pada emulator. `PASS server` dari laporan terdahulu tidak otomatis dihitung sebagai `PASS Android`.

## Matriks Android

| Profil POS | Simple | Centralized | Advanced | Alur bisnis Android khusus profil |
| --- | --- | --- | --- | --- |
| Retail | PASS Android: login, PIN, katalog, keranjang, tunai Rp1.000, stok 50→49 | BELUM DIUJI | BELUM DIUJI | Checkout produk stok PASS; layanan nonstok terlihat di katalog. |
| Restoran | BELUM DIUJI | PASS Android checkout cepat barang jadi Rp1.000; stok 49→48, invoice `INV-20261030-0004`; menu Pesanan Aktif/Meja dan Dapur muncul | BELUM DIUJI | Alur meja → dapur → saji belum diuji sampai selesai. |
| Laundry | BELUM DIUJI | BELUM DIUJI | PASS Android: detail cucian, validasi pelanggan wajib, tambah pelanggan, pembayaran layanan Rp5.000 | Invoice `INV-20261030-0002` terbit; proses/pickup/delivery cucian belum diuji. |
| Bengkel | PASS Android: detail kendaraan/keluhan, pelanggan wajib, tunai Rp5.000, invoice `INV-20261030-0003` | BELUM DIUJI | BELUM DIUJI | Checkout layanan PASS; pekerjaan teknisi/sparepart/BOM dan reservasi belum diuji. |
| Salon | BELUM DIUJI | PASS Android checkout layanan, detail objek/keluhan, pelanggan, tunai Rp5.000; invoice `INV-20261030-0005` | BELUM DIUJI | Reservasi dan penugasan staf belum diuji. |
| Jasa | BELUM DIUJI | BELUM DIUJI | PASS Android checkout campuran 1 layanan + 1 barang fisik, pelanggan, tunai Rp6.000; stok 48→47, invoice `INV-20261030-0006` | Reservasi, progres pekerjaan, dan konsumsi BOM belum diuji. |
| Custom | PASS Android checkout barang fisik Rp1.000; stok 47→46, invoice `INV-20261030-0007` | BELUM DIUJI | BELUM DIUJI | Variasi toggle custom belum diuji. |

## Bukti awal

- Emulator Android terdeteksi. APK produksi lama pada emulator dapat membuka PIN `rochim` dan memuat katalog Toko Bandung [Dummy], tetapi itu **bukan** hasil untuk matriks QA lokal.
- Fixture lokal awal gagal karena layanan diberi `kategori: layanan` yang bukan enum inventori. Diperbaiki ke `tidak_terlihat`; fixture kemudian hidup dan login akun QA melalui GraphQL berhasil.

## Temuan, perbaikan, dan verifikasi

| ID | Temuan | Perbaikan | Verifikasi |
| --- | --- | --- | --- |
| QA-01 | Fixture produk layanan memakai kategori inventori tidak valid. | Gunakan kategori `tidak_terlihat` dan `pos_product_type: service`. | Server QA lokal hidup; login GraphQL akun QA berhasil. |
| QA-02 | AndroidManifest memaksa orientasi `landscape`, berlawanan dengan pengaturan Flutter yang mengizinkan potret dan lanskap. Akibatnya UI mode HP tidak dapat diuji pada orientasi alami emulator. | Lepas pengunci orientasi di AndroidManifest; biarkan Flutter dan perangkat menentukan orientasi. | APK staging dibangun ulang dan dipasang. UI potret 1080×2400 terlihat di emulator. Emulator tetap perlu dikunci ke potret saat relaunch karena konfigurasi tablet 720dp mengembalikan lanskap. |
| QA-03 | Layanan `tracks_stock=false` pada layar Stok Inventori masih menampilkan tombol Koreksi Darurat dan saldo/minimum `0`, padahal tidak ada saldo yang bisa dikoreksi. | Sembunyikan aksi koreksi di kartu, tabel, detail saldo; tambahkan guard pada handler. Tampilkan `Tidak dilacak` alih-alih saldo semu. | APK staging dibangun dan dipasang ulang. Pada emulator, barang stok tetap menampilkan `49 unit` dan Koreksi Darurat; layanan menampilkan `Produk ini tidak menggunakan saldo stok` tanpa tombol koreksi. `flutter analyze` berkas terkait lulus. Bukti: `pantoo_qa_stock_fixed.png`. |
| QA-04 | Pelanggan awal yang ditanam langsung pada fixture QA tidak muncul di pemilih. | Investigasi lanjut menemukan penyebabnya sama dengan QA-06: daftar pelanggan tidak dimuat pada toko yang mengizinkan kasir tanpa shift. Bukan masalah bentuk dokumen fixture. | Setelah QA-06 diperbaiki, pemilih Android menampilkan pelanggan fixture dan pelanggan yang dibuat lewat form resmi. |
| QA-05 | Menyimpan dialog `Detail layanan` profil Bengkel setelah input kendaraan/keluhan memunculkan layar merah `_dependents.isEmpty`. Log pertama yang relevan: `TextEditingController was used after being disposed` pada `pos_payment_page.dart:1170`; assertion framework adalah efek susulan. | Tunda `dispose()` semua controller dialog sampai `ModalRoute.completed`, bukan segera setelah `showDialog` mengembalikan hasil saat animasi tutup masih berjalan. | `flutter analyze` kedua halaman yang diubah: `No issues found`. APK perbaikan dipasang; langkah yang sama kini menutup dialog normal dan lanjut ke `Pelanggan Wajib Dipilih`, tanpa layar merah. Bukti gagal: `pantoo_qa_bengkel_crash.png`. |
| QA-06 | Pada konfigurasi `allow_out_of_shift=true`, pemilih pelanggan checkout kosong meskipun pelanggan dibuat melalui form resmi; `PosBloc` hanya memuat daftar pelanggan jika ada shift aktif. | Muat pelanggan bila izin `view_customers` ada dan kasir memang boleh beroperasi tanpa shift. Tetap jangan memuatnya sebelum shift pada konfigurasi yang mewajibkan shift. | Tes `pos_bloc_no_shift_test.dart`: 2/2 PASS (dua kebijakan). APK baru dipasang; pemilih menampilkan pelanggan hasil form dan fixture, pelanggan dipilih, checkout Bengkel berhasil. |
| QA-07 | Dialog layanan Salon/Jasa/Bengkel menandai objek dan keluhan sama-sama `*`, sementara validasi Flutter dan server hanya meminta minimal salah satu. | Selaraskan label: tanpa `*` per field dan tampilkan instruksi bahwa salah satu wajib. | `flutter analyze` lulus; APK staging dibangun dan dipasang. Di emulator Salon, instruksi tampil, hanya keluhan diisi, dialog tersimpan tanpa crash dan alur lanjut ke validasi pelanggan. Tidak membuat invoice kedelapan. |
| QA-08 | Build staging masih memperingatkan bahwa proyek/plugin Android memakai Kotlin Gradle Plugin yang akan tidak kompatibel dengan Flutter mendatang. | Belum diubah pada audit ini karena build saat ini lulus dan migrasi melibatkan toolchain serta beberapa plugin eksternal. | Risiko kompatibilitas versi Flutter berikutnya; perlu dijadwalkan sebelum upgrade Flutter. |

## Jejak E2E yang selesai di Android

1. `retail + simple`: login QA → PIN → dashboard/guide → katalog menampilkan Barang QA Android 50 tersedia dan Layanan QA Android tidak dilacak → tambah 1 Barang QA Android → keranjang (1) → Bayar → Tunai/Uang Pas → Proses Bayar → `Pembayaran Berhasil`, invoice `INV-20261030-0001`, total Rp1.000, kembalian Rp0 → Stok Inventori menampilkan 49 unit. Database ini hanya QA lokal.
2. `restoran + centralized`: pengaturan fixture diganti, aplikasi Android dimuat ulang → kartu profil onboarding menandai Restoran/Cafe → menu Lainnya menampilkan Pesanan Aktif & Meja dan Tampilan Dapur → Stok Inventori menampilkan barang 49 unit. Checkout barang jadi restoran kemudian diuji pada jejak nomor 6; produksi dapur tetap belum diuji.
3. `laundry + advanced`: kartu profil onboarding menandai Laundry dan inventori Advanced → tambah Layanan QA Android ke keranjang → pilih tunai uang pas → isi detail cucian Kiloan → aplikasi menolak pembayaran tanpa pelanggan dan menawarkan pemilih → tambah pelanggan lewat form Android → transaksi otomatis lanjut hingga `Pembayaran Berhasil`, invoice `INV-20261030-0002`, total Rp5.000 dan kembalian Rp0. Ini E2E checkout layanan, **bukan** E2E produksi/pengantaran laundry.
4. Semua tujuh kartu profil bisnis terlihat terpilih dengan benar di Android. Pada bengkel, pengaturan fitur operasional (order layanan, reservasi, teknisi, kendaraan, pelanggan wajib, stok) juga terlihat.
5. `bengkel + simple`: setelah perbaikan QA-05/QA-06, pilih pelanggan yang sudah tersimpan → tambah 1 layanan → tunai uang pas → isi objek kendaraan `Motor test` dan keluhan `Servis rutin` → dialog tertutup tanpa crash → `Pembayaran Berhasil`, invoice `INV-20261030-0003`, Rp5.000, kembalian Rp0. Ini checkout servis, belum lifecycle pekerjaan bengkel.
6. `restoran + centralized`: tambah 1 Barang QA Android sebagai barang jadi/cepat → bayar tunai Rp1.000 → invoice `INV-20261030-0004`; stok 49→48. Ini tidak menguji pesanan meja dan produksi dapur.
7. `salon + centralized`: tambah layanan → isi objek/keluhan → pilih pelanggan → bayar tunai Rp5.000 → invoice `INV-20261030-0005`. Belum menguji reservasi dan staf.
8. `jasa + advanced`: tambah 1 barang fisik dan 1 layanan → isi objek/keluhan → pilih pelanggan → bayar tunai Rp6.000 → invoice `INV-20261030-0006`; stok barang 48→47. Belum menguji progres pekerjaan/BOM.
9. `custom + simple`: tambah 1 barang fisik → bayar tunai Rp1.000 → invoice `INV-20261030-0007`; stok 47→46. Belum menguji seluruh variasi toggle custom.

## Cakupan inventori di Android

- `simple`: kartu onboarding inventori menampilkan profil Simple pada kombinasi Custom; jalur retail Simple juga diuji hingga stok fisik 50→49.
- `centralized`: kartu onboarding inventori menampilkan Centralized pada kombinasi Restoran; lokasi stok dan saldo barang dapat dibuka.
- `advanced`: kartu onboarding inventori menampilkan Advanced pada kombinasi Laundry; checkout layanan nonstok berhasil. Transfer, batch, dan gudang bertingkat belum diuji pada kombinasi ini.
- Dengan demikian, ketiga profil inventori **termuat** di Android. Itu tidak sama dengan menuntaskan seluruh operasi inventori pada masing-masing profil.

## Bukti layar Android

- `pantoo_qa_laundry_success.png`: invoice laundry tunai Rp5.000 setelah validasi pelanggan.
- `pantoo_qa_bengkel_crash.png` dan `pantoo_qa_bengkel_success.png`: sebelum/sesudah perbaikan dialog servis.
- `pantoo_qa_restoran_quick_success.png`, `pantoo_qa_salon_success.png`, `pantoo_qa_jasa_success.png`, `pantoo_qa_custom_success.png`: invoice dari profil yang tersisa.
- `pantoo_qa_stock_fixed.png`: barang fisik 49 unit vs layanan nonstok tanpa aksi koreksi.
- `pantoo_qa_restoran_centralized_inventory.png`, `pantoo_qa_laundry_advanced_inventory.png`, `pantoo_qa_custom_inventory.png`: masing-masing profil inventori terlihat pada onboarding Android.

## Pemeriksaan akhir perubahan

- `flutter analyze --no-pub` pada halaman pembayaran, `PosBloc`, dan tes regresi: **No issues found**.
- `flutter test --no-pub test/pos_bloc_no_shift_test.dart`: **2/2 PASS**.
- `flutter build apk --debug --flavor staging` dengan endpoint QA lokal: **berhasil**; APK terbaru dipasang pada emulator dan dialog layanan diverifikasi kembali.
- Build tersebut adalah **staging debug untuk QA**, bukan APK/AAB rilis produksi.

## Batas kesimpulan sementara

Ketujuh profil POS dan ketiga profil inventori sudah dibuka di Android; **tujuh kombinasi representatif** mencapai invoice nyata. Yang diuji langsung pada Android adalah checkout dasar per profil, bukan semua fitur spesifik profil atau seluruh 21 kombinasi. Matriks server 21/21 dan tes lain sebelumnya tercatat terpisah di `QA_SEMUA_PROFIL_POS_INVENTORI_20261030.md`.

Jangan menyatakan seluruh alur operasional siap produksi berdasarkan matriks ini saja: PO/penerimaan/transfer per profil inventori, retur, opname, pembuangan, offline multi-kasir, printer, reservasi, dapur, pekerjaan layanan, serta semua variasi kebijakan Custom masih memerlukan uji Android tersendiri.
