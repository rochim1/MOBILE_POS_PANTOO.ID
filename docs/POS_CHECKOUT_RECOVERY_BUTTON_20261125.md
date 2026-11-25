# Tombol Pulihkan Pembayaran Android — 25 November 2026

## Laporan dan kriteria

Pengguna melaporkan layar kasir **Periksa pembayaran sebelumnya**, lalu tombol **Pulihkan pembayaran** terasa tidak merespons; platform dikonfirmasi Android. Log error perangkat pada upaya tersebut belum tersedia. Audit menemukan/reproduksi cacat penanganan error yang menjelaskan beberapa bentuk gejala tersebut, bukan mengklaim telah mengetahui error server spesifik pada HP pengguna.

Tujuan: tap memberi feedback, selesai/gagal tidak meninggalkan loader, penyebab kegagalan terlihat, dan recovery tetap mengacu bukti/request asal tanpa menerima pembayaran kedua atau membuang cart lain.

## Temuan dan perbaikan

1. `_recoverCheckout` menghitung perbandingan receipt sebelum menyalakan busy dan tidak mempunyai try/catch/finally. Receipt lokal yang tidak sesuai tipe dapat melempar sebelum feedback; exception async dapat meninggalkan tombol disabled tanpa akhir. Kini busy disetel dahulu, seluruh alur ditangani, dan finally selalu melepas loader bila halaman masih aktif. Exception tak terduga memakai pesan generik yang sudah diterjemahkan, bukan detail internal.
2. Kegagalan hanya mengganti paragraf peringatan awal. Kini peringatan **jangan menerima pembayaran kedua** tetap terlihat; kegagalan tampil pada panel error kontras tersendiri dengan live-region aksesibilitas.
3. Recovery saat offline mengembalikan pesan ketidakpastian generik. Kini menyebut masalah koneksi, tidak mengirim request baru atau menghapus bukti.
4. Penolakan server pada replay (misalnya izin kasir) disembunyikan oleh pesan ketidakpastian. Kini alasan penolakan ditampilkan lewat error handler existing, **tetapi proof tetap dipertahankan**: penolakan retry tidak membuktikan request pertama belum commit. Guard PIN/scope/otorisasi dan syarat matching ACK tidak dilonggarkan.
5. Pemeriksaan jaringan native Android di-await tanpa batas sebelum request dikirim. MethodChannel yang tidak menjawab membuat recovery tidak pernah selesai. RED terpisah membuktikan belum selesai sesudah5detik. Khusus recovery kini probe dibatasi **3detik**; timeout mengembalikan kegagalan koneksi dan melepas lock melalui finally, tanpa menulis sale/queue baru atau menghapus proof. Batas ini bukan timeout3detik untuk seluruh pembayaran/server dan tidak membatalkan transaksi server yang sudah dikirim.

## Peta efek samping

| Langkah | Read / write dan batas |
|---|---|
| Baca pendingCheckout | Proof scoped endpoint/tenant/terminal/operator; tidak menghapus data |
| Tap recovery | Local busy=true, error kosong; tap ganda ditolak |
| Bandingkan cart | Baca snapshot, harga/satuan/pelanggan/toko; bukan izin mengubah cart |
| Repository recovery | Lock request, muat ID/input asal, lampirkan sesi operator saat ini; tidak membuat ID pengganti |
| Offline/penolakan replay | Left beralasan; proof dan cart tetap, bukan offline sale baru |
| Matching ACK | Repository menghapus hanya proof request yang diakui, lalu hasil transaksi asli |
| Hasil UI | Error tampil terpisah atau buka struk tanpa auto-print; ClearCart hanya jika snapshot dan state awal masih cocok |
| Finally/unmount | Lepas busy bila mounted; tidak setState pada halaman yang sudah ditutup |

## Bukti RED → GREEN

- `0a27f21`: widget halaman kasir aktual, **2kontrol PASS/3FAIL**. Kasus gagal ialah panel error/warning terpisah, receipt rusak melempar sebelum request, dan exception async meninggalkan loader. Matching-customer-segment fixture awal dirapikan sebelum checkpoint; bukan dianggap bug produk.
- `aeb59e6`: repository dengan GraphQL link terkontrol dan SQLite temporer, **13PASS/2FAIL**. Dua failure membuktikan alasan offline/izin tersamarkan.
- `1cbc138`: perbaikan minimal; dua suite **20/20PASS**. Tambahan kontrol cart berbeda, double tap dan unmount membawa jumlah terkait menjadi22tes (tercakup gate regresi, bukan angka unik tambahan di luar gate).
- Regresi delapan suite **77/77PASS**, exit0,27detik pada `output/operational-readiness-20261125/recover-button-regression.log`. Tidak menghapus atau skip tes.
- Analisis pertama menemukan satu info curly-braces pada test baru; dibenahi. Analisis akhir lima berkas langsung `dart analyze --fatal-infos`: **No issues found**, exit0, `recover-button-dart-analyze-final.log`. Wrapper Flutter awal175,1detik mencatat info yang sama sebelum dibenahi, bukan dianggap kelulusan bersih.
- Follow-up native probe: checkpoint `fe1a3c2`, satu kasus dieksekusi **0PASS/1FAIL** karena5detik terlewati (`recover-native-probe-red.log`). Final setelah timeout3detik: **78/78PASS**, exit0,28detik, delapan suite (`recover-button-complete.log`); analisis lima berkas **No issues found**, exit0 (`recover-button-complete-analyze.log`). Coverage final `recover-button-complete-lcov.info`. Angka77 sebelumnya riwayat, bukan tambahan77tes unik.

```text
flutter test --no-pub --concurrency=2 --coverage --coverage-path=output/operational-readiness-20261125/recover-button-complete-lcov.info test/pos_checkout_recovery_flow_test.dart test/pos_checkout_recovery_test.dart test/pos_payment_single_flight_test.dart test/pos_checkout_cart_lock_test.dart test/pos_pending_payment_flow_test.dart test/pos_success_print_nonblocking_test.dart test/pos_payment_mobile_layout_test.dart test/pos_edit_order_primary_action_test.dart
dart analyze --fatal-infos lib/presentation/pages/pos/pos_page.dart lib/presentation/pages/pos/widgets/pos_checkout_recovery_panel.dart lib/domain/repositories/pos_repository.dart test/pos_checkout_recovery_flow_test.dart test/pos_checkout_recovery_test.dart
```

| Jaminan | Aset / jenis |
|---|---|
| Loading terlihat, tombol nonaktif, tap ganda tidak mengulang request, error terlihat dan warning uang tetap | `pos_checkout_recovery_flow_test.dart`, integration/widget nyata + fake repository |
| Exception receipt/transport tidak lepas tanpa penanganan; retry tetap tersedia | Suite widget yang sama |
| Sukses membuka invoice asal; hanya cart cocok dibersihkan, cart lain dan state baru aman; unmount tidak crash | Suite widget yang sama |
| Offline tidak menulis ulang; penolakan server tetap punya alasan dan proof; restart/ID/ACK/scope aman | `pos_checkout_recovery_test.dart`, repository nyata + fake GraphQL link/SQLite temporer |
| Probe native tidak menjawab melewati batas → lock dilepas, proof sama, write tetap1request asal | Suite repository yang sama, MethodChannel palsu/deferred dan timeout waktu nyata, bukan pengujian radio Android nyata |
| Payment/order edits, single-flight, layout HP, pending-customer dan sukses tanpa printer tidak regresi | Enam suite lain pada gate78 |

Cakupan lcov terukur: metode `_recoverCheckout`44/45baris (**97,8%**), seluruh recovery-panel32/32 (**100%**). Ini bukan coverage80% seluruh PosPage/repository/aplikasi. Scope jaringan server, bank, izin produksi dan hardware tidak dibuktikan oleh link palsu.

## Batas dan langkah perangkat

Tidak menghapus pending proof, cache, PIN, aplikasi atau transaksi pengguna; tidak melakukan mutation produksi, mengubah backend/schema/Finance, ataupun melewati otorisasi. Tidak menjalankan GUI native/fresh release build dalam perbaikan ini. **APK/AAB1.0.22+23 yang dibagikan sebelum laporan ini belum memuat patch ini**; paket tersebut tidak diam-diam ditimpa. Diperlukan build/pemasangan terbaru untuk menilai ulang di Android pengguna.

Kelulusan perbaikan kode tidak berarti pembayaran lama pengguna sudah berhasil dipulihkan. Setelah paket terbaru terpasang: login/PIN operator asal, buka kasir, tap Pulihkan pembayaran dan lihat spinner/alasan error; jika berhasil, cocokkan nomor invoice/request serta kas/jurnal dan jangan menerima uang kedua. Jika masih gagal, pesan error yang kini tampil menentukan apakah perlu koneksi, login/izin, versi server atau pemeriksaan admin. Jangan clear data atau membuat sale pengganti untuk menghilangkan fence.

## Evaluasi

Akurasi4/5: RED/GREEN dan coverage tersedia, tetapi penyebab spesifik HP pengguna belum ditangkap. Kelengkapan4/5: jalur error/sukses/retry dijaga, pemasangan ulang dan GUI perangkat belum dilakukan. Kejelasan5/5: perubahan UI dipisahkan dari hak akses dan bukti finansial. Tindak lanjut4/5: source/reproducer siap, paket lama tetap perlu diganti untuk mencoba. Keringkasan4/5: detail disimpan di dokumen agar jawaban pengguna singkat. Rata-rata4,2/5. Prioritas berikutnya: build/pasang paket terbaru lalu ulangi recovery request yang sama dan rekonsiliasi hasil, bukan menghapus proof. Self-check: pengguna menerima perbaikan kode teruji dan batas yang jujur, bukan klaim transaksi pribadinya sudah selesai. Tidak ada sumbu≤3; serahkan perubahan scoped dengan batas pemasangan tersebut.
