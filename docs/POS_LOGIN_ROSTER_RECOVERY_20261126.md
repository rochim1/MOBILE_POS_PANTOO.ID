# Pemulihan pemilih kasir setelah login

Tanggal: 26 November 2026.

## Permintaan dan temuan

Pengguna melaporkan pemilih employee kadang meminta pemeriksaan jaringan setelah login, tetapi dapat dipakai setelah logout/login. Sasaran pekerjaan: memulihkan pemuatan daftar tanpa menghapus sesi/data lokal dan tanpa melewati PIN.

Audit dan reproduksi otomatis menemukan:

- Kegagalan transport sementara langsung menjadi kegagalan daftar; tidak ada satu percobaan ulang terbatas untuk gangguan singkat.
- Pemeriksaan konektivitas platform tidak memiliki batas waktu. Panggilan plugin yang tertahan dapat menghalangi API yang sebenarnya dapat dijangkau.
- Pemilih menunggu pemuatan selesai sebelum modal dibuka. Jika pemuatan gagal, modal menyatakan karyawan tidak ditemukan, bukan kegagalan baca, dan tidak menyediakan retry di tempat.
- Respons GraphQL dengan struktur rusak dapat salah digolongkan sebagai gangguan offline karena `UnexpectedResponseStructureException` adalah turunan `ServerException`.

Tidak tersedia log kejadian dari HP pengguna. Temuan ini adalah celah yang berhasil direproduksi, bukan bukti bahwa satu pemicu server tertentu pasti menyebabkan seluruh kejadian pengguna.

## Perubahan

1. Halaman PIN mendapat **Coba lagi** ketika daftar gagal/kosong dengan error. Saat loading tombol tidak dapat dipicu berulang; PIN belum diproses hanya karena daftar tersedia.
2. Modal pemilih terbuka langsung dengan loader ketika sedang memuat. Kegagalan menampilkan pesannya dan tombol **Coba lagi**; hasil pencarian kosong tetap merupakan keadaan berbeda. Retry memakai pencarian yang sedang diisi.
3. Daftar mencoba ulang satu kali hanya jika gangguan transport muncul dalam dua detik awal. Penolakan otorisasi, validasi, respons rusak, dan error server bukan alasan retry/offline grant.
4. Koneksi lambat yang sehat tetap mendapat jendela respons delapan detik penuh. Timeout delapan detik tidak memicu loop otomatis; pengguna dapat mencoba ulang tanpa logout. Jalur jaringan maksimum sekitar sepuluh detik untuk fast-failure + satu retry.
5. Pemeriksaan plugin konektivitas dibatasi dua detik. Jika plugin gagal/tertahan, API dicoba langsung; ini tidak mengasumsikan pengguna sudah berhak masuk. Status offline eksplisit tetap memakai aturan cache PIN terverifikasi yang sudah ada.
6. Sharing hanya untuk request yang masih berjalan, tetap dipisah berdasarkan endpoint/instansi/akun/operator/client. Request yang selesai gagal tidak disimpan sebagai hasil permanen.
7. Klasifikasi read offline menolak respons yang strukturnya rusak sebelum memeriksa kelas dasar `ServerException`. Tidak memakai cache offline untuk menyamarkan respons rusak.

Tidak menambahkan retry pembayaran, mutasi transaksi, atau verifikasi PIN. PIN salah, cache kedaluwarsa, pencabutan izin, pergantian akun/instansi, dan respons lama setelah logout tetap diuji agar tidak membuka kasir.

## Bukti TDD

Journeys diturunkan dari laporan pengguna, tanpa plan eksternal: daftar pulih setelah gangguan singkat; retry di tempat saat gagal; koneksi lambat tetap diterima; kegagalan izin/format tidak berubah menjadi akses offline.

| Jaminan | Tes | Bukti |
|---|---|---|
| Gangguan singkat mencoba ulang sekali, request bersamaan dibagi, manual retry memakai request baru | `pos_roster_retry_test.dart` | RED: jumlah panggilan 1 saat diharapkan 2; GREEN pada paket akhir |
| Plugin konektivitas yang tertahan tidak menghalangi API yang bekerja | `pos_roster_retry_test.dart` | RED: belum selesai setelah tiga detik; GREEN dengan batas probe dua detik |
| Halaman PIN dan modal memiliki retry yang bekerja dalam ID/EN dan tetap locked | `pin_roster_retry_ui_test.dart` | RED: kedua tombol retry belum ada dan modal belum terbuka selama loading; GREEN |
| Koneksi sehat lima detik tidak dibatalkan menjadi dua kegagalan singkat | `pos_roster_retry_test.dart` | RED pada rancangan awal 4+4 detik; GREEN setelah jendela normal delapan detik dipertahankan |
| Respons rusak tidak memakai proof PIN offline | `pos_roster_retry_test.dart` | RED: hasil Right dari fallback; GREEN: hasil Left dan satu panggilan |
| PIN, sesi, cache dan layout lama tidak dilewati/rusak | Paket regresi di bawah | 88 PASS |
| Klasifikasi sinkronisasi offline dan review transaksi tetap sama | `offline_sync_classification_test.dart` | 10 PASS |

Checkpoint pada branch aktif: RED awal `3f92b5c`, RED respons rusak `f9041a1`, GREEN dasar `bc5c9a1`, RED koneksi lambat `fd86bcc`, GREEN akhir `d7ae993`. Fixture respons sesi lama dilengkapi metadata GraphQL yang benar; validasi produksi tidak dilonggarkan agar fixture rusak lolos. Penutupan stream pada uji waktu palsu sempat tertahan; pengujian timeout akhir memakai batas waktu nyata dan selesai.

## Hasil pengujian

**98 PASS, 0 FAIL** dalam dua paket, tanpa build/deployment atau mutasi data produksi.

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path output/pin-roster-20261126/lcov.info test/pos_roster_retry_test.dart test/pin_roster_retry_ui_test.dart test/pos_bootstrap_read_test.dart test/pos_login_roster_resilience_test.dart test/pos_login_lock_loading_test.dart test/pos_auth_error_classification_test.dart test/pos_offline_read_store_test.dart test/auth_session_loading_test.dart test/auth_workspace_session_test.dart test/pin_submit_keypad_test.dart test/pin_lock_responsive_test.dart
flutter test --no-pub --concurrency=1 --coverage --coverage-path output/pin-roster-20261126/offline-classification-lcov.info test/offline_sync_classification_test.dart
```

Analisis Dart pada sembilan file perubahan: **No issues found**, termasuk info sebagai kegagalan. Cakupan gabungan dua paket: helper bootstrap 31/32 baris (96,9%), classifier jaringan 24/26 (92,3%), widget feedback baru 14/14 (100%), halaman PIN 491/582 (84,4%). Ini bukan persentase seluruh repository/aplikasi. Laporan tidak menimpa coverage milik pengguna.

Log kegagalan respons/PIN yang sengaja disimulasikan muncul pada pengujian negatif. Hasil akhir ditentukan oleh assertions dan exit code, bukan sekadar keberadaan log merah.

## Batas dan penerapan

- GUI di HP/emulator nyata dan kejadian Play Store pengguna belum direproduksi pada pekerjaan ini. Pengujian tampilan memakai widget sebenarnya dengan request palsu yang terkontrol; tidak mengklaim uji GUI perangkat.
- Tidak menghapus sesi, cache aplikasi, PIN, atau antrean transaksi pengguna. Proses Flutter development pengguna tetap berjalan; hanya proses tes milik pekerjaan ini yang tertahan yang dihentikan.
- Kode bersama Flutter berlaku pada Android dan pengujian Flutter Chrome. Tidak mengubah kasir Vue atau backend pada pekerjaan ini.
- Untuk Flutter development lakukan hot restart agar kode terbaru dimuat. APK/Play Store memerlukan build dan rilis baru; belum dilakukan di sini.

## Evaluasi hasil

Ringkasan: pemulihan daftar sekarang eksplisit dan terbatas, sementara login akun dan verifikasi PIN tetap terpisah.

| Aspek | Skor | Bukti / batas |
|---|---|---|
| Akurasi | 4/5 | 98 tes lulus dan analisis bersih; pemicu pasti pada HP pengguna belum dibuktikan dari log perangkat. |
| Kelengkapan | 4/5 | Retry, offline, otorisasi, sesi dan tampilan diuji; belum GUI Android nyata dengan build terbaru. |
| Kejelasan | 5/5 | Gagal memuat dibedakan dari pencarian kosong, dengan tombol tindakan langsung dan loader. |
| Keterpakaian | 4/5 | Kode siap diperiksa; aplikasi terpasang masih memerlukan build baru. |
| Keringkasan | 4/5 | Helper kecil memakai batas waktu/guard lama; report memuat perintah panjang agar dapat diulang. |

Rata-rata 4,2/5. Prioritas berikutnya adalah verifikasi pada HP QA dengan build terbaru dan pengumpulan log tanpa token bila kejadian masih muncul. Tidak ada temuan kritis yang masih gagal pada paket yang dijalankan. Pengguna dapat menilai hasil berdasarkan tindakan retry yang terlihat tanpa diasumsikan bahwa versi Play Store sudah berubah.
