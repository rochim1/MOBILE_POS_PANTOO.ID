# Logo dan pembaruan profil usaha POS

17 November2026. Sumber: permintaan pengguna “dan bisa upload logo, juga jika ingin update bisa update di pengaturan”. Journeys diturunkan dari permintaan ini, bukan dari plan terpisah.

## Perilaku yang diterapkan

- Setup profil usaha menyediakan logo opsional: pilih dari galeri, pratinjau, ganti atau hapus pilihan sebelum menyimpan. JPG/JPEG, PNG, WebP, maksimal5MB.
- Instansi dibuat memakai alur CreateInstansi yang sudah ada. Logo disimpan setelah workspace dan pengaturan awal berhasil dibuat. Jika unggah gagal, tampilkan pesan bahwa usaha sudah dibuat; pengguna dapat mengulang unggahan tanpa membuat instansi kedua atau lanjut tanpa logo.
- Pengaturan mempunyai kategori **Profil Usaha**, dengan nama, telepon, alamat opsional, logo dan tombol simpan sendiri. Nama field tetap terlihat. Tombol simpan menampilkan progres dan dinonaktifkan selama proses.
- Logo tersimpan pada `instansis.logo`, bukan hanya perangkat atau tabel profil baru. Nama usaha memakai `nama_instansi`, telepon `telpon_number`, alamat `alamat`; nama resmi/legal tidak ditimpa ketika mengganti nama tampilan usaha. Web admin yang membaca field instansi tersebut tetap memakai data yang sama.
- Profil dapat ditampilkan dari cache tenant/operator yang sesuai ketika transport offline; menyimpan perubahan dan unggah tetap memerlukan internet, tanpa antrean write offline.
- Pembacaan dan pembaruan memakai GetMyPOSBusinessProfile/UpdateMyPOSBusinessProfile, terdaftar pada authMiddleware dan diperiksa izin `pos_pengaturan.view/update`. Input tidak menerima ID tenant, owner, kredensial atau permission.
- Header unggah multipart kini meneruskan token PIN operator aktif, sama dengan GraphQL biasa; kasir pada terminal pemilik tidak memakai hak pemilik secara tidak sengaja.

## Keamanan gambar dan kegagalan

Server membatasi stream5MB dan piksel25juta, memeriksa isi gambar dengan Sharp, melakukan orientasi/resize maksimal1024px, membuang metadata dan menyimpan PNG dengan nama UUID pada folder logo tenant. Nama file dari perangkat tidak menjadi path penyimpanan.

Penyimpanan profil memakai filter tenant, status aktif dan logo saat pembacaan. File lama hanya dihapus sesudah pembaruan database berhasil dan hanya bila berada pada folder logo tenant tersebut. Gagal database membersihkan unggahan baru, tidak menghapus logo lama. Gagal pembersihan setelah commit tidak dilaporkan sebagai save yang gagal. Error server dipisahkan dari error sesi agar tidak muncul false session expiry.

Respons terlambat setelah pergantian akun/operator tidak mengisi cache akun lain. Konteks juga diperiksa kembali sebelum pengiriman unggahan sesudah memperoleh header autentikasi.

## Bukti RED/GREEN

| Checkpoint | Bukti |
|---|---|
| Mobile `6be9b87` | Tes setup dikompilasi dan gagal: teks Logo usaha/pilihan logo belum ada. |
| Backend `abdfc5ee` | Tes AST/kontrak modul POS dikompilasi dan gagal: GetMyPOSBusinessProfile belum ada. |
| Mobile `4052b38` | Reproduksi header operator berhasil berjalan: expected fixture-operator, actual null; sebelum provider diperbaiki. |
| Backend `693ec510` | Endpoint, upload, auth dan schema terimplementasi; final15/15PASS. |
| Mobile `bee23f1` | Setup, repository, form Pengaturan, routing kategori dan header operator terimplementasi; final55/55PASS. |

Ada koreksi fixture/API tes selama pengerjaan: konstruktor GraphQLError lokal dipakai sesuai dependensi terpasang; fixture menyertakan __typename pada Query/Mutation; JWT operator fixture memakai PIN terkonfigurasi. Error kompilasi/fixture tersebut tidak dihitung sebagai bukti RED. Tes GUI juga mereproduksi overflow pada judul/dropdown Pengaturan390px; Expanded dan batas lebar dropdown memperbaikinya tanpa mengubah aturan bisnis.

## Matriks jaminan

| Jaminan | File executable | Lapisan / hasil |
|---|---|---|
| Logo tersedia pada setup; label dan validasi lama tetap berfungsi pada HP/tablet | `test/business_setup_page_test.dart` | widget integration; PASS |
| Pilih/pratinjau/ganti/hapus, spinner, retry read/write, akses baca saja, kategori Pengaturan nyata, setup retry tanpa workspace ganda dan lanjut ke gate PIN | `test/pos_business_logo_flow_test.dart` | widget integration; PASS |
| Multipart mapping/MIME/auth benar, cache scoped, permission error tidak fallback, respons lama tidak mengisi cache baru, file invalid/oversize ditolak | `test/pos_business_profile_repository_test.dart` | unit/integration transport fake; PASS |
| Schema dan dua dokumen mobile cocok, middleware terdaftar, tenant input ditolak, error/file cleanup aman | `../presensi_zera_BE/tests/pos_business_profile.test.js` | unit/contract, Sharp+filesystem nyata; PASS |
| JWT dan role nyata → unggah → Mongo → baca ulang → ganti → hapus; kasir login/PIN ditolak; tenant lain dan nama legal tetap | `../presensi_zera_BE/tests/pos_business_profile.integration.test.js` | integration GraphQL/JWT/Mongo/FS nyata; PASS |

Path backend pada tabel mengacu ke repo saudara dari root mobile, bukan perintah eksekusi dari folder docs.

## Commands dan hasil final

Dari root mobile:

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/business-logo-20261117/lcov.info test/business_setup_page_test.dart test/pos_business_logo_flow_test.dart test/pos_business_profile_repository_test.dart test/google_redirect_regression_test.dart test/setup_operational_labels_test.dart test/pos_onboarding_profile_test.dart test/pin_lock_responsive_test.dart test/pos_operator_session_recovery_test.dart test/production_endpoint_test.dart test/pos_vendor_invoice_submission_session_test.dart --reporter expanded
dart analyze lib/core/network/graphql_client_provider.dart lib/injections.dart lib/domain/repositories/pos_business_profile_repository.dart lib/presentation/widgets/pos_business_logo_picker.dart lib/presentation/widgets/pos_business_profile_form.dart lib/presentation/pages/login/business_setup_page.dart lib/presentation/pages/pos/pos_settings_page.dart test/business_setup_page_test.dart test/pos_business_profile_repository_test.dart test/pos_business_logo_flow_test.dart
```

**55/55PASS, exit0**, `output/business-logo-20261117/mobile-regression.log`; **No issues found, exit0**, `analyze.log`. Coverage final changed executable source **310/334=92,8%**, dibandingkan HEAD sebelum commit implementasi mobile; semua file source baru ikut dihitung. Bukan coverage seluruh aplikasi atau bukti perangkat native.

Dari root backend, TEMP/TMP pada driveD dan MONGOMS_SYSTEM_BINARY menunjuk binary Mongo lokal yang sudah ada:

```powershell
node --test --test-concurrency=1 --experimental-test-coverage --test-coverage-include='**/pos_business_profile.resolvers.js' --test-coverage-include='**/pos_business_logo.service.js' tests/pos_business_profile.test.js tests/pos_business_profile.integration.test.js
```

**15/15PASS, exit0**, log `mobile_POS_Pantoo/output/business-logo-20261117/backend-regression.log`. Coverage dua file inti backend: line99,29%, branch82,56%, function81,25%. Mongo sementara terisolasi, tidak memakai DB_CONNECT produksi. Root filesystem uji dibatasi ke direktori temporer yang dibuat khusus tes dan dibersihkan setelah selesai.

## Batas dan aktivasi

- Galeri OS dan alur penuh APK Android terbaru belum dijalankan pada emulator/HP; pilihan galeri disuntikkan sebagai fixture pada widget test. Uji database benar-benar menyimpan/membaca/mengganti/menghapus gambar, tetapi input Upload disuntikkan ke GraphQL, bukan dikirim melalui HTTP multipart native. Bentuk multipart mobile diuji terpisah dan schema yang sama divalidasi.
- Belum build APK/AAB dan belum deploy/restart layanan produksi. Backend harus memuat kedua field GraphQL baru dan aplikasi harus memakai source/APK baru agar fitur tersedia.
- Tidak mengubah versi aplikasi, akun/instansi produksi, data Finance atau perubahan kerja pengguna yang sebelumnya sudah ada. Hanya dua hunk registrasi profil pada authMiddleware yang dimasukkan commit; hunk SearchBudgetAccounts milik perubahan lain tetap tidak ikut.
- Kegagalan assertion grid tablet lama pada laporan label sebelumnya tidak dihapus atau diklaim selesai. Rangkaian55tes di sini adalah kelompok terkait fitur, bukan seluruh suite workspace.

## Tinjauan akhir

Ringkasan4,2/5: accuracy5 (hasil dan batas dicatat), completeness4 (setup/settings serta gagal/izin diuji, galeri native belum), clarity4 (penyimpanan dua tahap dijelaskan, laporan teknis terpisah), actionability4 (perlu backend dan aplikasi terbaru), conciseness4 (UI bersama dipakai pada setup/settings, rincian bukti cukup panjang sehingga tidak dibawa ke jawaban singkat). Tidak ada isu kritis dari pemeriksaan ini. Perbaikan berikut paling bernilai: uji galeri Android dan HTTP multipart nyata pada APK baru, kemudian muat ulang Pengaturan setelah login ulang. Penilaian ini diharapkan sesuai dengan pengguna karena tidak menyamakan source/test yang lulus dengan fitur sudah terpasang di HP.
