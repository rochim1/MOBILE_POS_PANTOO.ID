# QA putaran 4 — profil, hak akses dan dapur

Tanggal: 1 November 2026. Pengujian memakai emulator Android melalui ADB dan backend QA lokal port 8087 dengan MongoMemoryReplSet sementara. Database produksi tidak ditulis. Data lokal aplikasi tidak dihapus; APK QA dipasang dengan `install -r`.

## Ringkasan cakupan

- Seluruh 7 profil POS × 3 profil inventori diuji pada resolver/database nyata: retail, restoran, laundry, bengkel, salon, jasa, custom; simple, centralized, advanced.
- Tiap kombinasi memeriksa akun non-admin kasir, supervisor dan baca-saja, flag runtime, akses daftar/detail order, dapur dan penolakan lintas cabang. Ini **bukan 21 alur UI Android penuh**.
- API HTTP dengan middleware nyata dan header `apps: pos`: ketujuh profil menjalankan pembuatan order serta pembayaran tunai oleh kasir; tiga peran menerima flag yang sesuai dan akses dapur cabang lain ditolak. Produk uji HTTP ini tidak memotong stok; pengurangan stok 21 kombinasi diverifikasi suite integrasi terpisah.
- Android: login/PIN kasir terbatas, menu/toko/katalog, item dapur campuran, tombol produksi, scroll vertikal, drag horizontal, penyajian dan pergantian PIN ke operator baca-saja. Detail final pembatalan supervisor dicatat di bagian retest.
- Fixture diulang ketika server dimulai ulang untuk memuat patch. ID order sebelum/sesudah restart berbeda; jangan menganggap bukti berasal dari satu database persisten yang sama.

## Temuan yang diperbaiki

| ID | Temuan | Perbaikan | Bukti |
|---|---|---|---|
| T-24 | Izin update order dianggap akses seluruh toko; order cabang lain muncul pada daftar dan dapat dituju langsung | Scope cabang/warehouse diterapkan pada daftar, detail, per item, layanan, reservasi, pembayaran dan pembuatan/idempotent retry. Daftar/detail toko, stasiun dan meja turut dibatasi sesuai modul/aksi pemberi izin | Matriks 21 kombinasi × 3 peran dan HTTP nyata; daftar tidak memuat order luar, akses langsung ditolak |
| T-25 | Pending reservation masuk tiket dapur; endpoint item dapat memproses reservasi sebelum seated atau menghidupkan kembali pesanan terminal | Filter dapur hanya menerima reservasi seated; mutation menolak reservasi belum seated dan order Batal/Selesai | Regresi integrasi query serta mutation |
| T-26 | Status produksi `voided` dapat melewati izin pembatalan dan tidak menghitung ulang tagihan | Mutation produksi menolak voided; pembatalan/perubahan item wajib lewat alur khusus yang mengurus otorisasi dan nilai transaksi | Tes negatif: status item tetap queued |
| T-27 | Akun kasir mode tanpa shift gagal katalog, lalu data toko/menu terlihat kosong | Read katalog tanpa shift hanya saat kebijakan mengizinkan, dengan scope cabang pada permission POS terkait. State mobile mempertahankan toko/izin terverifikasi meski katalog berikutnya gagal | Regresi BLoC, tes katalog own/other branch, Android toko dan katalog berhasil termuat |
| T-28 | PIN operator baca-saja bisa membuat order memakai otoritas akun terminal kasir | Create/Pay memeriksa izin dan scope operator dari token tervalidasi, tidak hanya izin terminal. Validasi ikatan token terhadap terminal/tenant tetap dipertahankan | HTTP sebelum patch benar-benar membuat order QA (tes gagal); setelah patch FORBIDDEN. Integrasi meliputi create/pay baca-saja dan lintas cabang |
| T-29 | Mulai proses di Pesanan Aktif hanya memperbarui header; item dapur tetap queued, sehingga tampilan tidak selaras dan guard PIN menyiapkan barang bisa terlewati | Transisi header menyinkronkan item station, revision, timestamp dan riwayat. Produk instant tidak disentuh. Cancel memperlakukan header Diproses + station sebagai pekerjaan dimulai untuk data lama; dialog Android/Vue juga meminta PIN | Regresi lintas board dan PIN; retest Android final dicatat di bawah |

Tidak ada role produksi baru yang dibuat dan tidak ada perluasan hak template kasir/supervisor. Identitas baca-saja adalah fixture QA dengan permission view, bukan role bawaan yang ditambahkan ke produk.

## Android yang benar-benar dijalankan

1. Kasir QA login/PIN: setelah perbaikan, Toko QA Android dan empat produk/layanan berhasil dimuat. Sebelum patch, kegagalan katalog membuat toko/menu tampak belum tersedia.
2. Dapur hanya menampilkan order campuran `qa-r4-kitchen-ui`, satu item station. Order instant-only serta order toko lain tidak tampil.
3. Klik Mulai proses → item preparing dan revision berubah di server. Geser vertikal pada kartu → tetap preparing. Geser horizontal → ready. Klik Tandai sudah disajikan → served; antrean dapur kosong. Produk instant tetap not_required. Screenshot `qa-round4-kitchen-preparing.png`.
4. APK pasca-patch pemuatan master dipasang. Terminal kasir beralih PIN ke QA viewer. Dapur menampilkan kartu `qa-r4-viewer-ui` bertuliskan Hanya lihat tanpa kontrol produksi. Geser horizontal tidak mengubah queued di server. Screenshot `qa-round4-kitchen-readonly.png` diperiksa visual; teks dapat dibaca, tidak tampak overflow.
5. Beralih PIN ke supervisor, pencarian order bekerja dan tombol Batalkan pesanan tersedia. Percobaan awal Mulai proses → pembatalan membuka dialog tanpa PIN; penelusuran membuktikan ketidaksinkronan header/item (T-29), bukan dinyatakan PASS.

### Retest final supervisor — PASS

- APK QA dibangun ulang setelah perubahan dialog terakhir, dipasang tanpa clear data, dan server fixture baru memuat semua patch.
- Terminal login `qa_android_cashier`, kemudian memilih PIN supervisor. Pencarian `ORD-20261101-0011` menampilkan order QA khusus.
- Klik Mulai proses menghasilkan header Diproses dan item station preparing/revision 1 di HTTP; item instant tetap not_required/revision 0.
- Batalkan pesanan kini menampilkan peringatan pekerjaan dapur dan field PIN supervisor. Alasan `QA-cancel-round4` dan PIN fixture benar diterima. Toast Pesanan dibatalkan tampil, hasil pencarian aktif kosong, dan HTTP membuktikan order Batal beserta alasan.
- Screenshot: `qa-round4-supervisor-pin.png` dan `qa-round4-supervisor-cancel.png`.
- Verifikasi HTTP pertama salah mencari catatan dengan exact-match, padahal backend menambahkan alasan pada catatan. Skrip QA dibetulkan agar mengenali tepat satu order berawalan identitas fixture dan memvalidasi alasan; setelah itu marker `QA_ANDROID_SUPERVISOR_CANCEL_PASS`. Ini bukan bug transaksi aplikasi.

Saat pergantian PIN, skrip pernah mengetik terlalu cepat ketika animasi belum stabil sehingga terjadi satu penolakan PIN. Input dibersihkan dan PIN fixture yang sama berhasil. Ini kesalahan langkah otomasi; tidak melampaui batas lima percobaan. Nama operator pada layar kunci kembali ke akun terminal sehingga selector QA sempat tidak cocok; tes dilanjutkan berdasarkan dump UI aktual.

## Regresi dan artefak

- Backend final: **77/77 PASS**, exit 0, `presensi_zera_BE/docs/qa-kitchen-roles-round4-final4.log`.
- Sesudah suite tersebut, pemeriksaan akhir menambahkan edge case izin kustom hanya `pos_kasir.create` tanpa `view`/izin shift: pemilihan module scope diperbaiki agar tidak salah menuntut izin shift. Tes terarah **1/1 PASS**, log `qa-kitchen-roles-round4-minimal-grant.log`; daftar/detail own-store boleh dan toko lain tetap ditolak. Suite 77 tidak dijumlahkan dengan pengulangan atau disebut full 78. Patch dua kondisi ini belum dimuat ulang pada fixture Android; diuji resolver/database secara terarah.
- Tes baru mula-mula **1/24 PASS dan 23 FAIL**: 21 kombinasi membocorkan daftar cabang lain, pending booking terlihat di dapur, voided tidak ditolak. Setelah patch dan perluasan tes, semua lulus.
- Satu pengulangan awal gagal karena fixture pengguna kedua tidak diberi email unik; data fixture dibetulkan, bukan assertion dilemahkan. Tes berikutnya mendeteksi dan menutup celah PIN operator.
- Tes HTTP final menggunakan `tests/qa_kitchen_roles_http.e2e.js`; marker per profil `QA_PROFILE_HTTP_PASS`, dan `QA_OPERATOR_CREATE_BOUNDARY_PASS`. Sempat dicoba sebelum server siap listen (fetch failed); diulang setelah server siap, bukan disamakan dengan kegagalan aplikasi.
- Flutter suite penuh final setelah patch dialog terakhir: **263/263 PASS**, exit 0, log `qa-kitchen-roles-round4-flutter-final-full.log`. Tes terarah pasca-patch dialog: **9/9 PASS**, analisis tiga file No issues found. Angka pengulangan suite tidak dijumlahkan.
- Vue dialog PIN diselaraskan. SFC parse/script compile PASS; tidak ada klaim E2E browser atau build produksi Vue pada putaran ini.
- Node syntax dan diff whitespace PASS. Peringatan akhir Mongo shutdown ECONNRESET, punycode, plugin Kotlin dan Helvetica Unicode tetap tercatat; printer/PDF fisik belum diuji.
- C: tersisa sekitar 100 MB. TEMP/TMP pengujian dipindahkan ke D:. Dua fixture QA lama milik pengujian dihentikan untuk mengurangi beban; data staging/produksi dan aplikasi emulator tidak dihapus.

## Batas hasil dan antrean lanjutan

Belum seluruh skenario berstatus PASS. Yang masih perlu diuji: UI 21 kombinasi lengkap pada semua operasi PO/retur/opname/scrap, pemisahan pembuat/approver/pemroses inventori tiap modul, laundry dan layanan lengkap beserta BOM/material/staf, race update dua perangkat nyata, offline multi-kasir, printer nyata dan layar pelanggan Wi-Fi. Query/middleware yang dijalankan pada HTTP tidak mengalami schema mismatch, tetapi tidak membuktikan seluruh query aplikasi sudah diuji.

Patch source dan APK QA tersedia; **belum deploy server produksi atau merilis APK produksi**. Jangan mengubah status kesiapan seluruh aplikasi menjadi production-ready berdasarkan hasil terbatas ini.

## Pemeriksaan mutu akhir

Evaluasi hasil putaran ini: **3,8/5**, bukan skor kesiapan produksi.

| Aspek | Skor | Bukti / peningkatan |
|---|---|---|
| Akurasi | 4/5 | Bukti 77 backend, 263 Flutter dan snapshot Android; bedakan patch scope minimum terakhir yang baru diuji terarah, bukan UI. |
| Kelengkapan | 3/5 | Semua profil punya bukti API/integrasi dan tiga peran; 21 perjalanan UI dan seluruh maker/approver inventori belum selesai. Lanjutkan matriks UI/modul itu untuk menutup gap. |
| Kejelasan | 4/5 | Metode dan fixture terpisah; istilah teknis tetap diperlukan pada laporan bukti. Spreadsheet menyediakan ringkasan. |
| Dapat ditindaklanjuti | 4/5 | Source, tes regresi, screenshot dan laporan tersedia; deploy/rilis produksi belum termasuk hasil. |
| Keringkasan | 4/5 | Laporan detail panjang untuk audit; gunakan ringkasan spreadsheet untuk status harian. |

Tidak ada aspek ≤2. Prioritas perbaikan kelengkapan: uji UI matriks profil dan pemisahan peran seluruh operasi inventori, kemudian perangkat/offline nyata. Self-check: pengguna dapat memverifikasi perbaikan nyata, tetapi tidak semestinya menganggap seluruh aplikasi sudah PASS. Verdict: serahkan hasil putaran dengan sisa pengujian tetap terbuka. Google Sheets dibaca ulang beserta wrap/top; render native browser tidak diperiksa pada putaran ini.
