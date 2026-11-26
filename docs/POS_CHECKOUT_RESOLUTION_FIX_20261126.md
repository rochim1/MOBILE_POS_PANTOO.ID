# Perbaikan pemulihan pembayaran lintas shift/toko — 26 November 2026

## Ruang lingkup dan hasil

Sumber kebutuhan: `docs/POS_CLOSED_SHIFT_RECOVERY_DIAGNOSIS_20261126.md` serta permintaan memperbaiki mobile/web sampai kasus shift ditutup dan toko berganti memiliki penyelesaian aman.

Alur bukti checkout penjualan langsung sekarang memiliki pemeriksaan status server dan penyelesaian eksplisit. Bukti lokal tidak dibuang berdasarkan error replay, perubahan toko, atau klik rekonsiliasi lokal semata. Kasir dapat melanjutkan setelah putusan pembatalan server yang cocok diarsipkan. Pembayaran yang sudah tercatat dipulihkan lewat nota lama.

Implementasi dan pengujian pada sumber selesai; belum deploy server/web, belum membuat APK/AAB baru, dan belum mengubah bukti pada HP pengguna. APK 1.0.25+26 yang dibuat sebelumnya belum berisi perubahan ini.

## Perjalanan pengguna

1. Sebagai kasir, saya bisa mengambil nota lama setelah respons hilang, meskipun shift asal sudah ditutup.
2. Bila percobaan tidak tercatat dan uang belum diterima, saya bisa menyelesaikannya melalui server dan melanjutkan transaksi baru di toko/shift yang sedang dipilih.
3. Bila dana sudah diterima, penyelesaian memerlukan catatan rekonsiliasi dan hak supervisor atau kredensial PIN supervisor yang sah pada lingkup toko asal.
4. Bila respons penyelesaian hilang, pemeriksaan berikutnya menemukan keputusan server yang sama; bukti tidak hilang dan transaksi lama tidak dapat datang terlambat lalu tersimpan.
5. Bila server, referensi, PIN atau penyimpanan tidak valid, bukti tetap terlindungi dan tombol tidak tertahan dalam loading.

## Perubahan server

- Query `GetPOSCheckoutRecovery` memeriksa transaksi dengan ID yang sama, kepemilikan, toko asal, serta konteks shift. Status yang dikenali client: committed, cancelled, retryable, blocked, needs_review.
- Status retryable/not recorded dari query **bukan putusan pembatalan**: request awal mungkin masih berlangsung. Status tersebut hanya mengizinkan replay idempotent dengan input semula.
- Mutation `CancelPOSCheckout` menghasilkan keputusan pembatalan yang persisten. Jika transaksi sudah ada, ia mengembalikan transaksi tersebut, bukan membatalkan penjualannya.
- Koleksi `pos_checkout_fences` memiliki indeks unik instansi + ID transaksi, operator/toko/shift asal, state, revision, catatan, pelaku dan waktu penyelesaian. Tidak ada TTL agar request lama tidak menjadi valid lagi setelah masa kedaluwarsa.
- Penjualan dan pembatalan sama-sama menyentuh dokumen pagar **di dalam transaksi MongoDB masing-masing**. Ini mencegah dua proses server memutuskan hasil yang bertentangan. Antrean Finance process-local tidak dianggap sebagai pengaman lintas proses.
- Pembatalan memerlukan transaksi database; fallback standalone tidak dipakai untuk mengesahkan pembatalan.
- Hak create POS, scope toko dan identitas operator tetap diperiksa. Rekonsiliasi dana diterima memerlukan izin `pos_kasir.delete` yang sudah dimiliki supervisor, atau username/PIN supervisor yang valid dan berhak pada toko tersebut. Percobaan PIN salah dibatasi dengan pengunci yang sudah dipakai model pengguna.
- Token operator dan PIN supervisor tidak masuk dokumen pagar ataupun arsip client.

## Perubahan mobile

- “Pulihkan pembayaran” memeriksa status server sebelum mengirim ulang pembayaran. committed mengambil nota lama; cancelled mengarsipkan putusan dan melepas pengunci; blocked/hasil tidak cocok tidak membuat pembayaran pengganti.
- Tombol “Selesaikan pembayaran” menyediakan pilihan uang belum diterima atau dana sudah dikembalikan/direkonsiliasi, catatan wajib, dan kredensial supervisor bila diperlukan. Setiap field diberi label; PIN mempunyai kontrol tampil/sembunyikan.
- Panel menampilkan toko/shift asal, waktu, nominal dan metode dari bukti, terpisah dari toko yang sekarang sedang dipilih.
- Penyelesaian mempertahankan keranjang dan toko aktif. Tidak mengganti shift/toko di payload lama dan tidak memindahkan kas ke shift lain.
- Arsip `pos_checkout_resolved_v1` disimpan dan dibaca ulang sebelum bukti pending dilepas. Gagal menulis arsip atau menghapus pending tetap menyisakan bukti untuk pemeriksaan berikutnya.
- Pemeriksaan referensi dan scope dilakukan lagi setelah await. Respons yang tidak sesuai ID atau akun tidak membuka kasir.

## Perubahan web

- Targeted recovery bukti checkout sale memanggil query status yang sama. Tidak otomatis mengulang penjualan bila hasilnya blocked/cancelled/committed.
- “Selesaikan manual” pada bukti checkout sale sekarang membutuhkan putusan server. Catatan lokal saja tidak lagi menandai pembayaran belum pasti sebagai selesai.
- Penyelesaian menyimpan baris reviewed/server_cancelled beserta jejak audit; bukan menghapus antrean diam-diam. Transaksi baru dengan toko/shift berbeda kemudian dapat dibuat.
- Dialog pemeriksaan dana, catatan dan supervisor memiliki loading/error serta terjemahan Indonesia/Inggris. PIN supervisor hanya dikirim dalam permintaan persetujuan, tidak dimasukkan ke penyimpanan antrean.
- Untuk bukti pembayaran pesanan, tombol mengarahkan ke alur detail pesanan yang sudah ada (`/pos/table-order`), bukan membatalkan transaksi sumber order dengan pagar sale. Setelah pembayaran pesanan terkonfirmasi, recovery order lama tetap memverifikasi invoice/status melalui jalur yang sudah ada.

## Spesifikasi pengujian

| Kasus | Bukti yang harus terjadi | Hasil |
|---|---|---|
| Shift asal closed, transaksi belum tercatat | Pemeriksaan blocked; pembatalan persisten; replay UUID lama ditolak | PASS, integrasi server |
| Berganti toko dan membuka shift baru | Setelah penyelesaian, UUID baru dapat dijual pada toko lain; shift lama tidak bertambah | PASS, integrasi server + repository mobile + komponen UI |
| Transaksi sudah committed sebelum shift ditutup | Invoice/ID lama dikembalikan; satu transaksi dan satu rangkaian stok/kas/jurnal | PASS, integrasi server |
| Pembatalan bersamaan dengan penjualan | Tepat satu putusan committed atau cancelled; tidak ada late commit setelah cancelled | PASS, MongoDB replica set lokal; pembatalan tidak memakai admission process-local penjualan |
| Respons pembatalan hilang | Bukti tetap ada; query berikutnya menemukan cancelled dan membuka kasir dengan arsip | PASS, repository mobile/web |
| Respons milik request lain atau server gagal | Bukti tidak dilepas dan tidak ada mutation pembayaran tambahan | PASS, repository mobile/web |
| Kasir lain mencoba bukti asal | Ditolak, invoice tidak bocor | PASS, integrasi server dan regresi operator |
| Dana sudah diterima | Kasir tanpa otorisasi ditolak; PIN supervisor yang sah pada scope toko diterima | PASS, integrasi server + dialog mobile/web |
| PIN salah, catatan pendek/panjang, ID tidak valid | Ditolak tanpa posting transaksi/jurnal | PASS |
| Arsip lokal gagal tersimpan | Bukti pending tidak dihapus | PASS, unit penyimpanan |
| Penyelesaian gagal/exception | Loading dilepas, pesan tampil, keranjang/bukti tetap ada | PASS, widget mobile + fungsi UI web |
| Tampilan HP 320px bahasa Inggris | Label dan penjelasan diterjemahkan, dialog tidak overflow | PASS, widget mobile |
| Kontrak GraphQL | Dokumen mobile/web valid terhadap schema; middleware kedua operasi terdaftar | PASS |

### Jumlah dan perintah aktual

- Mobile regresi penuh: **1.360 PASS**, `flutter test --no-pub --concurrency=2 --reporter expanded`, durasi tes 6 menit 47 detik.
- Mobile terfokus terakhir: **70 PASS**, empat berkas `pos_checkout_request_store_test.dart`, `pos_checkout_recovery_test.dart`, `pos_checkout_recovery_flow_test.dart`, `pos_checkout_resolution_dialog_test.dart`, dengan concurrency 2 dan LCOV.
- Web: **466 PASS**, semua `tests/pos*.mjs`, `node --test --experimental-test-coverage`.
- Server: **28 PASS**, `node --test --experimental-test-coverage --test-concurrency=1` pada `pos_checkout_resolution.integration.test.js`, `pos_checkout_optimization.integration.test.js`, `pos_order_payment_recovery.integration.test.js`, `pos_promo_order.contract.test.js`.
- Semua tes server memakai replica set lokal sementara. Tidak menggunakan DB_CONNECT produksi.
- Analisis akhir `dart analyze --fatal-infos`: **No issues found!**, exit 0. Log `output/shift-recovery-analysis-20261126/analyze-clean.log`.

Log mobile: `output/shift-recovery-analysis-20261126/mobile-full.log`, `mobile-release-targeted.log`. Log server pada folder output yang sama di proyek backend: `server-final-expanded.log`. Log web pada root workspace: `output/pos-checkout-resolution-web-complete-20261126.log`.

Pemeriksaan ulang setelah perapian terakhir: **70 PASS** pada target yang sama, log `mobile-final-check.log`; checkpoint refactor `bca35ee`. Tidak ada kegagalan yang diketahui tersisa pada target yang dijalankan.

### Bukti RED/GREEN

- Server: 5 FAIL karena endpoint/putusan belum tersedia (`04d5a417`) lalu 5 PASS setelah pagar atomik (`159e0c0a`). Kasus supervisor gagal pada persetujuan valid (`973cdb40`), lalu 6 PASS dengan persetujuan (`27359583`); diperluas menjadi 7 kasus resolusi.
- Web: 26 PASS/2 FAIL saat pembatalan hanya lokal (`9a273c5b`), lalu 28 PASS (`e58e729a`). Navigasi pesanan 1 FAIL (`38d55aa1`), lalu PASS (`9141a63c`). Seluruh suite terbaru 466 PASS.
- Mobile repository: compile RED karena `cancelPendingCheckout` belum ada (`e679bbd`). UI resolution gagal karena tombol tidak ada (`f1f461c`), lalu kedua berkas 39 PASS (`873b549`).
- Arsip: tes meniru setString mengembalikan sukses tetapi data hilang, 1 FAIL (`4ec742f`). Pembacaan ulang arsip sebelum acknowledge memperbaikinya (`b1253d8`); suite terfokus diperluas menjadi 70 PASS.
- Commit berada pada branch aktif masing-masing; tidak melakukan squash/reset atau memasukkan perubahan pengguna yang tidak terkait.

### Cakupan terukur

- Mobile: **172/183 = 93,99%** baris executable yang ditambah/diubah pada lima berkas logika/UI utama terhadap checkpoint e679bbd. Generated translations dan dokumen query tidak dihitung sebagai logika executable. LCOV: `resolution-release.info`.
- Service pemulihan server: **100% baris/fungsi, 83,33% cabang**. Model pagar 100% pada laporan Node coverage.
- Web pengukuran sebelum tambahan tes kredensial: 39/39 baris outbox dan 29/35 baris UI penyelesaian (82,86%). Tiga tes kredensial/cancel supervisor ditambahkan dan termasuk suite final 466 PASS; raw V8 final berada di `output/pos-checkout-resolution-v8-complete-20261126`. Pengukuran hanya berkas/metode yang berubah, bukan klaim cakupan seluruh aplikasi.

## Penerapan dan batas

1. Deploy schema, middleware dan pagar posting backend pada **seluruh worker/API server**, lalu restart/drain worker versi lama sebelum fitur pembatalan dipakai client. Worker lama yang belum mengenal pagar tidak boleh dicampur dalam deployment aktif. MongoDB harus mendukung transaksi replica set; indeks unik pagar dibuat melalui model init.
2. Deploy web dan perbarui build mobile setelah backend siap. Client yang belum menemukan endpoint baru tetap mempertahankan bukti; tidak fallback ke penghapusan lokal.
3. Jangan clear data, uninstall, mengganti UUID/shift pada payload, menonaktifkan kontrol shift atau menghapus dokumen pagar untuk membuka kasir.
4. Bukti pada HP pengguna belum disentuh. Dana nyata harus diperiksa oleh kasir/supervisor melalui pilihan yang benar, bukan disimpulkan dari tidak adanya baris transaksi.
5. Hak akses operator/toko asal tetap wajib. Pencabutan izin tidak dilewati oleh fitur ini. Perangkat offline murni tidak dapat mengesahkan pembatalan sampai dapat menghubungi server.
6. Pengujian adalah widget/repository mobile, fungsi/kompilasi Vue, kontrak dan resolver dengan DB lokal. Belum GUI Android fisik/emulator aktif, belum browser pengguna aktif, belum build APK/AAB dan belum deploy produksi dalam tugas ini.

## Evaluasi penyerahan

Akurasi 4/5: ada reproduksi, hasil DB terisolasi dan angka tes; GUI perangkat/produksi belum dijalankan. Kelengkapan 4/5: kasus shift/toko yang diminta dan konflik late request selesai pada sumber; penerapan ke aplikasi terpasang memerlukan deploy/build. Kejelasan 4/5: putusan server dibedakan dari lookup dan catatan lokal. Dapat ditindaklanjuti 4/5: kode, tes, syarat deployment dan prosedur kasir tersedia; tidak melakukan mutasi dana produksi tanpa pemeriksaan. Keringkasan 4/5: ringkasan pengguna dipisahkan dari bukti panjang ini. Rata-rata 4,0/5; tidak ada isu kritis pada kasus yang diuji. Tindak lanjut paling bernilai adalah smoke-test GUI setelah deployment backend dan build mobile baru. Self-check: memenuhi perbaikan sumber dan pengujian yang diminta, bukan klaim bahwa APK lama atau layar HP sudah otomatis pulih.
