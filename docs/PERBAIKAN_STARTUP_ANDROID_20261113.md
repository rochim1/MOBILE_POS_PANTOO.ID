# Perbaikan startup Android — 13 November 2026

APK 1.0.10+11 berhasil dibangun dan ditandatangani, tetapi berhenti pada splash screen ketika benar-benar dijalankan. Pengujian fitur sebelumnya memakai APK QA dan belum mendeteksi kegagalan khusus build production.

Log APK production pada emulator menunjukkan `ClassNotFoundException: io.flutter.plugins.GeneratedPluginRegistrant`, diikuti `PlatformException(channel-error)` pada `SharedPreferencesApi.getAll`. Akibatnya bootstrap berhenti sebelum runApp.

Penyebabnya filter sumber Java yang bersifat lazy: tugas kompilasi mengganti sumbernya dengan filter yang masih merujuk sumber tugas itu sendiri. Registrant production dibuat di disk, tetapi kelasnya tidak masuk APK.

Perbaikan mengubah daftar sumber menjadi daftar file yang sudah dievaluasi, lalu secara eksplisit menambahkan registrant production. Plugin integration_test tetap dikeluarkan dari production; pendaftaran plugin Android yang lain tetap dipertahankan. Tugas Java release sekarang juga memeriksa keberadaan kelas hasil kompilasi dan menghentikan build bila kelas itu tidak ada.

12 catatan lint pada layanan, halaman, dan pengujian notifikasi diperbaiki tanpa mengubah perilakunya. `flutter analyze --no-pub` seluruh proyek: No issues found (292,0 detik).

APK pengganti: versi 1.0.11+12. Verifikasi akhir mencakup pemeriksaan DEX, tanda tangan dan identitas APK, instalasi tanpa menghapus data, serta peluncuran APK production sebenarnya sampai melewati splash screen. Hasil: APK production berhasil dipasang sebagai pembaruan tanpa menghapus data dan menampilkan halaman intro. Cold launch kedua juga berhasil, tanpa ClassNotFoundException, channel-error, atau unhandled exception pada proses aplikasi.

Verifikasi DEX memastikan GeneratedPluginRegistrant dan SharedPreferencesPlugin ada, sedangkan IntegrationTestPlugin tidak disertakan. Tanda tangan APK v2 terverifikasi; package id.pantoo.pos, versionName 1.0.11, versionCode 12. Sebanyak 20 tes layanan notifikasi, repository dan workspace utang/piutang lulus.

APK: `output/pantoo-pos-startup-fix-1.0.11/Pantoo-POS-1.0.11+12.apk`. Bukti analisis, build, pengujian, checksum dan tangkapan layar ada dalam folder yang sama. APK 1.0.10+11 dipertahankan sebagai artefak lama dan tidak boleh digunakan lagi.
