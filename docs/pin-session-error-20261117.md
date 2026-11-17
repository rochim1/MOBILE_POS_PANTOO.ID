# “Session expired” setelah Buat PIN — 17 November 2026

Sumber laporan: pengguna memastikan pesan muncul setelah menekan **Buat PIN**, memakai login **username/password Pantoo**, bukan Google. Sasaran: penolakan password tidak disamakan dengan sesi kedaluwarsa; password benar tetap dapat membuat PIN dengan sesi yang sama, tanpa melemahkan autentikasi.

## Temuan dan perubahan

- `SetMyPOSPin` mengembalikan `UNAUTHORIZED`/HTTP401 ketika password ditolak. Mobile mengubah kode itu menjadi pesan sesi berakhir. Ini berhasil direproduksi, tetapi bukan bukti bahwa password yang dimasukkan pengguna pada perangkatnya memang salah; respons perangkat pengguna belum direkam.
- Backend kini membedakan password tidak cocok (`INVALID_PASSWORD`, HTTP400, tanpa menyimpan PIN) dari akun/sesi tidak valid (`UNAUTHORIZED`, HTTP401). Pemeriksaan password dan hash PIN tidak dihapus.
- Mobile menampilkan pesan password asli dan mempertahankan form. Untuk kompatibilitas backend lama, pengecualian hanya berlaku pada `UNAUTHORIZED` dengan pesan tepat `Password akun tidak valid`, atau kode eksplisit `INVALID_PASSWORD`. Error HTTP/GraphQL ganda ditangani. Jika ada error sesi asli bersamaan, hasil tetap `AuthFailure`, bukan diabaikan.
- Widget modal diuji: tiga field diisi, Buat PIN ditekan, password ditolak, modal dan nilai PIN tetap ada, password bisa diperbaiki dan tombol dapat dicoba lagi. Lock tetap aktif. Backend dengan JWT/middleware POS nyata juga membuktikan password salah → password benar → baca status PIN menggunakan **token sesi yang sama**.

## Test point dan bukti

| TEST-ID | Status / boundary | Bukti |
|---|---|---|
| TEST-POS-PIN-CHALLENGE-1711 | covered scoped; integration / regression protection; resolver, JWT, middleware dan Mongo sementara asli | `tests/pos_lock.security.test.js`: kode400 untuk password ditolak, tidak menulis PIN, akun hilang tetap401, password benar dan same-session retry berhasil |
| TEST-POS-PIN-ERROR-1711 | covered scoped; unit/integration / regression protection; transport disimulasikan, handler dan modal asli | `test/pos_pin_setup_error_test.dart`, `test/pin_lock_responsive_test.dart`: kode baru/lama, HTTP/GraphQL, duplikasi, mixed auth error, pesan modal dan retry |
| TEST-POS-PIN-DEVICE-1711 | unverified; E2E perangkat pengguna / critical path | Perlu source baru/hot restart/APK dan respons server saat mereproduksi. Tidak memakai password, token, atau data akun pengguna untuk tes |

Perintah yang benar-benar dijalankan:

```powershell
# mobile_POS_Pantoo
flutter test --no-pub --coverage test/pos_pin_setup_error_test.dart test/pos_auth_error_classification_test.dart test/pin_lock_responsive_test.dart test/google_login_test.dart test/auth_workspace_session_test.dart --reporter expanded
dart analyze lib/core/error/error_handler.dart test/pos_pin_setup_error_test.dart test/pin_lock_responsive_test.dart
# presensi_zera_BE
node --test tests/pos_lock.security.test.js tests/login_credentials.security.test.js tests/google_login.security.test.js
```

Final: **28/28 mobile**, **22/22 backend**, exit0; analyze tiga file **No issues found**, exit0. Subset15kasus setelah formatting juga lulus dan tumpang tindih dengan total; tidak dijumlahkan sebagai E2E. Backend0skip/0cancel. LCOV mengukur7/7baris executable baru handler terlewati (changed-line100%), bukan coverage seluruh aplikasi/backend.

Folder bukti workspace `output/pin-session-error-20261117/`: `mobile-red.log`(dua kegagalan legacy401), `backend-red.log`(kode challenge salah), `duplicate-red.log`, `mobile-final.log`, `backend-final.log`, `formatted-green.log`, `lcov-final.info`, `analyze-final.log`. Semua kegagalan reproduksi dipertahankan. Checkpoint mobile RED `95d3542`/`23d751f`, GREEN `2643b18`/`41eae9a`, formatting `0a6f74b`; backend RED `115e4728`, GREEN `20dd6d16`, bukti retry middleware `7d1f7ce9`.

Tidak ada build APK, deploy/push, reset sesi, pembersihan data aplikasi, perubahan password atau mutasi database produksi. Perubahan Finance lain dan versi pubspec pengguna dipertahankan. Backend berjalan lama perlu restart/deploy untuk mengirim kode baru; mobile baru juga kompatibel dengan kode lama. Jika memakai source Flutter, lakukan hot restart; APK terpasang membutuhkan build baru.

Jika sesudah memakai perbaikan tetap muncul sesi berakhir ketika password diyakini benar, periksa respons asli `SetMyPOSPin` (kode dan pesan saja; **jangan kirim password/token**) untuk membedakan akun/instansi yang tidak cocok, sesi dicabut, atau token kedaluwarsa. Pengecekan ini tidak diganti dengan bypass PIN atau memaksa sesi tetap sah.

Evaluasi4,0/5: akurasi4(bukti RED/GREEN nyata, belum respons perangkat pengguna); kelengkapan4(perbaikan pesan, retry, true-auth guard, belum deploy/E2E HP); kejelasan4(status lokal dan penerapan dibedakan, rincian teknis panjang); dapat ditindaklanjuti4(source/bukti tersedia, perlu hot restart/APK/backend baru); keringkasan4(detail dipisah dari jawaban). Prioritas berikut: TEST-POS-PIN-DEVICE-1711 pada versi baru, tanpa mengirim kredensial. Self-check: hasil valid untuk bug yang direproduksi, bukan klaim telah memverifikasi password atau memperbaiki sesi produksi pengguna.
