# Pembuatan instansi: loading di tombol

20 November 2026. Permintaan pengguna: setelah submit pembuatan instansi/profil usaha pertama, tampilkan proses pada tombol seperti pendekatan status proses di web admin.

## Implementasi

- Mobile mempertahankan form selama penyimpanan, unggah logo opsional, persiapan konfigurasi dan konteks PIN. Spinner berada di tombol, dengan teks terlokalisasi `Menyimpan…`, kemudian `Menyiapkan Pantoo POS…`.
- Tombol dinonaktifkan selama proses; field dan pilihan logo/profil tidak bisa diubah saat permintaan berlangsung. Warna tombol ketika sibuk tetap mempunyai kontras dengan teks/spinner putih; teks dibatasi secara responsif pada layar sempit.
- Persiapan workspace dibagi melalui `preparePosWorkspace`, digunakan oleh gate login maupun form instansi. Setelah submit, persiapan dilakukan sebelum navigasi ke shell POS, bukan melalui halaman loading perantara. PIN tetap dimuat/dikunci sebelum melanjutkan; tidak ada bypass autentikasi.
- Error berada di dalam form di atas tombol, bukan snackbar yang dapat menutupi tombol coba lagi. Kegagalan melepaskan loading dan mempertahankan nilai input. Setelah pembuatan usaha berhasil dikonfirmasi, retry persiapan atau logo tidak memanggil pembuatan instansi kedua.
- Web admin `WorkspaceOnboarding.vue` diperiksa sebagai referensi status bertahap; tidak diubah. Tidak ada perubahan skema GraphQL, konfigurasi usaha lama, atau data produksi pada tugas ini.

## Bukti pengujian

Journeys diturunkan dari permintaan: (1) umpan balik di tombol segera setelah submit, (2) form tidak hilang saat akses/PIN disiapkan, (3) retry dapat diakses tanpa duplikasi pembuatan usaha yang telah dikonfirmasi, (4) logo/bahasa/scroll tetap berfungsi.

RED `b0313ae`: tes runtime menunjukkan teks proses belum ada dan form hilang saat persiapan, 2 gagal/1 lulus. GREEN `800317b`: tiga tes yang sama lulus setelah implementasi. RED lanjutan `6a6b3d5`: snackbar menutupi tombol retry sehingga tindakan kedua tidak terpanggil. GREEN `bb86020`: pesan error inline dan regresi lengkap lulus.

Perintah dari root `mobile_POS_Pantoo`:

```text
flutter test test/business_setup_loading_test.dart test/business_setup_page_test.dart test/pos_business_logo_flow_test.dart test/pos_optional_setup_test.dart test/pos_initial_context_recovery_test.dart test/pos_setup_language_test.dart test/pos_setup_scroll_test.dart --no-pub --concurrency=1 --coverage --reporter expanded
```

Hasil: **42/42 PASS**. Mencakup status di dalam tombol, penolakan submit berulang, menunggu konfigurasi dan PIN, lebar 320 dp, error terstruktur/exception, retry tanpa pembuatan usaha kedua setelah konfirmasi, logo gagal/retry/lewati, Bahasa Indonesia/English saat sibuk, serta scroll/keyboard.

Tes bahasa gate lama disesuaikan dengan perubahan panduan opsional yang telah diterapkan sebelumnya: kegagalan konfigurasi opsional menuju home, bukan wizard retry yang memblokir. Bahasa tetap diuji selama gate memuat dan selama konfigurasi profil gagal.

Coverage baris executable: `business_setup_page.dart` **147/161 (91,3%)**; fungsi persiapan bersama **32/34 (94,1%)**. Ini bukan coverage seluruh aplikasi. Log: `D:/my node app/zera/output/business-setup-loading-*.log`.

Analisis statis: `dart analyze lib/presentation/pages/login/business_setup_page.dart` dan `dart analyze lib/presentation/pages/pos/pos_onboarding_page.dart` keduanya exit 0, **No issues found!**. Pemeriksaan diff perubahan tugas juga PASS. Kompilasi diverifikasi melalui tes Flutter; tidak melakukan build distribusi. Tidak menambahkan kredensial, query, atau pelonggaran izin.

## Batas verifikasi

Kompilasi dan interaksi yang dibuktikan adalah unit/widget lokal menggunakan repository palsu; tidak melakukan submit instansi baru pada akun produksi yang baru direset. Tidak mengklaim pengujian kehilangan respons server/idempotensi backend menyeluruh. Tidak melakukan deploy, GUI Android/browser langsung, atau build ulang APK/AAB.
