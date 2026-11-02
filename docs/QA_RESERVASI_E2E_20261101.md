# QA lanjutan reservasi dan meja — 1 November 2026

## Cakupan dan lingkungan

- Android emulator, aplikasi `id.pantoo.pos.qa`, dikendalikan melalui ADB pada display 0. APK QA terbaru dipasang dengan `install -r`; data aplikasi tidak dihapus.
- Backend lokal port 8087, MongoMemoryReplSet sementara melalui `scripts/qa_android_profile_server.js`. Tidak menulis database produksi.
- Profil restoran + inventori simple, fitur appointment dan service order aktif, akun fixture admin. Ini bukan bukti seluruh kombinasi profil atau pembatasan peran sudah lolos UI.
- Reservasi awal dibuat melalui HTTP. Transisi status, pembayaran dan penjadwalan ulang diuji pada layar Android. Alur ini E2E campuran, bukan pembuatan booking dari UI Android.

## Temuan dan perbaikan

1. **Tanggal reservasi tidak konsisten.** GraphQL String dapat mengubah tanggal menjadi string epoch milidetik. Backend sekarang mengeluarkan ISO secara eksplisit untuk order privat/publik. Mobile menerima ISO maupun epoch lama, menampilkan waktu lokal, dan memakai waktu lokal ketika membuka penjadwalan ulang.
2. **Booking pending terlihat sebagai meja terisi / siap diproses.** Booking kini mulai pada status Baru meski berisi layanan instan. Peta meja dan pencarian order aktif meja hanya menganggap reservasi yang sudah seated sebagai okupansi fisik. Slot reservasi tetap diperiksa secara terpisah. Sebelum seated, mobile menawarkan Kelola reservasi dan tidak mengizinkan drag/proses generik; backend juga menolak proses generik sebelum tamu didudukkan.
3. **Penyelesaian melalui kartu umum tidak menutup reservasi dan melepas meja tersimpan.** Status Selesai sekarang sekaligus mengubah reservation_status menjadi completed dan menjalankan pelepasan meja. Booking mendatang yang belum seated tidak menghalangi pelepasan. No-show booking lain tidak boleh melepas meja tamu yang masih seated.

## Hasil pengujian

| Skenario | Metode | Hasil |
|---|---|---|
| Pending → Konfirmasi → Check-in → Dudukkan tamu | Android UI + snapshot HTTP | PASS pada fixture awal; meja bebas sebelum seated dan terisi setelah seated. |
| Menyelesaikan reservasi belum lunas | Android UI | PASS negatif; pesan wajib melunasi tagihan tampil dan pesanan tidak selesai. Bukti `qa-pos-round3-unpaid-reservation.png`. |
| Siap → disajikan → Bayar pesanan → Uang Pas Rp5.000 | Android UI | PASS pada fixture awal; pembayaran lunas. |
| Konfirmasi → Tidak hadir | Android UI | PASS; reservasi no_show/order Batal dan meja tersedia. |
| Selesaikan pesanan melalui kartu umum | Android UI pada server pasca-patch terminal | PASS; order Selesai, reservation_status completed, lunas. Data awal tahap Disajikan/lunas disiapkan HTTP pada fixture baru. |
| Meja benar-benar dapat dipakai kembali | HTTP sesudah klik selesai Android | PASS; dine-in baru pada meja A diterima. Pesanan probe kemudian dibatalkan untuk pembersihan fixture. Marker `QA_RESERVATION_TERMINAL_PASS`. |
| Penjadwalan ulang tanpa perubahan jam | Android UI + perbandingan HTTP sebelum/sesudah | PASS; `12:58Z` tampil `19:58` WIB. Start/end B tetap persis `2026-11-01T12:58:05.502Z` / `2026-11-01T13:58:05.502Z` setelah Simpan. |
| Peta meja akhir | Android UI + HTTP | PASS; A dan B Tersedia. Bukti `qa-pos-round3-tables-released.png`; B tetap booking pending, bukan okupansi fisik. |
| Reschedule ke slot booking lain | HTTP publik + integrasi resolver | PASS negatif CONFLICT; bukan dua perangkat Android sungguhan. |
| No-show booking B saat A masih seated; future booking setelah A selesai | Integrasi resolver/database | PASS; B tidak melepas A dan future booking tidak mengunci meja kosong. |

Fixture awal dihentikan untuk memuat patch terminal, lalu fixture bersih dibuat pada port sama. Jangan menganggap seluruh rangkaian di atas berjalan pada satu pasangan ID tanpa reset fixture server. Tidak ada penghapusan data lokal emulator.

## Regresi terakhir

- Backend lifecycle + matriks profil/inventori + kontrak GraphQL: **46/46 PASS**, exit 0. Log backend `docs/qa-reservation-round3-backend-retest-d.log`.
- Lifecycle baru sendiri: **2/2 PASS**. Pembayaran pada tes resolver diset langsung sebagai prasyarat; pembayaran sungguhan dibuktikan terpisah lewat UI/HTTP di atas.
- Suite Flutter penuh: **262/262 PASS**, exit 0. Log `qa-e2e-reservation-round3-flutter-retest-d.log`. Angka suite dari putaran berbeda tidak dijumlahkan.
- Analisis tiga file Flutter terkait: **No issues found**. Sintaks Node dan pemeriksaan whitespace diff: PASS.
- Percobaan suite awal gagal pada startup Mongo / tes PDF tersendat saat C: hampir penuh. Pengulangan memakai TEMP/TMP di D: dan concurrency terbatas berhasil tanpa mengubah assertion. Ini kendala lingkungan yang tetap dicatat, bukan diabaikan.
- Peringatan Helvetica Unicode masih muncul; kualitas PDF/cetak fisik belum dinyatakan PASS.

## Belum dibuktikan

- Semua operasi UI Android pada 7 profil POS × 3 profil inventori dan akun kasir/supervisor terpisah.
- Booking baru dari UI, konflik booking dua perangkat sesungguhnya, dapur dengan produksi nyata setelah perubahan reservasi/gesture.
- Browser admin Vue terbaru dan perjalanan invoice → piutang → pelunasan Finance pada putaran ini.
- Dua kasir offline bersamaan, printer fisik, layar pelanggan Wi-Fi lintas perangkat.
- Retest Android valuasi metadata di server bersih; putaran sebelumnya membuktikannya melalui HTTP/resolver.

Perubahan berada di source dan APK QA; belum deploy server produksi atau membuat rilis APK produksi. Hasil terbatas ini tidak berarti seluruh aplikasi production-ready.

## Evaluasi akhir hasil kerja

Ringkasan: **3,8/5**, menilai hasil putaran terbatas, bukan nilai kesiapan aplikasi.

| Aspek | Nilai | Bukti dan perbaikan berikutnya |
|---|---|---|
| Akurasi | 4/5 | Log 46 backend/262 Flutter PASS dan snapshot UI/server cocok; belum verifikasi perangkat fisik. Lanjutkan bukti lintas perangkat sebelum memperluas klaim. |
| Kelengkapan | 3/5 | Reservasi yang sebelumnya belum diuji UI sudah dicakup, tetapi permintaan semua skenario hingga PASS belum tercapai. Lanjutkan booking baru/race dua perangkat, dapur aktual dan matriks profil/peran. |
| Kejelasan | 4/5 | Metode UI/HTTP/integrasi dan fixture sebelum/sesudah restart dipisahkan; pembaca perlu dua laporan untuk seluruh riwayat. Spreadsheet menjadi indeks ringkas. |
| Dapat ditindaklanjuti | 4/5 | Source, tes regresi, bukti gambar dan spreadsheet tersedia; belum deploy atau rilis produksi. Pertahankan QA terisolasi untuk skenario tersisa. |
| Keringkasan | 4/5 | Ringkasan ada di spreadsheet; laporan detail tetap panjang untuk menjaga jejak bukti. Gunakan tab Belum Diuji sebagai antrean berikutnya. |

Tidak ada aspek ≤2. Perbaikan prioritas: lanjutkan skenario UI/perangkat yang belum diuji, bukan menandainya PASS dari hasil integrasi. Self-check: pengguna semestinya dapat memverifikasi hasil terbatas ini, tetapi tidak akan menganggap permintaan seluruh aplikasi hingga PASS telah selesai. Verdict: serahkan hasil putaran beserta batasnya; cakupan keseluruhan masih terbuka.
