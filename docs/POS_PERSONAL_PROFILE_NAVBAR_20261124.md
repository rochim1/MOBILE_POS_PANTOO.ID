# Navbar HP dan profil pribadi POS — 24 November 2026

## Permintaan dan kriteria penerimaan

Sumber: permintaan pengguna agar teks navbar HP lebih proporsional terhadap navigasi bawah, dan halaman profil dapat mengubah foto serta data pribadi yang relevan untuk POS.

1. Judul toko dan nama kasir terbaca pada HP, tanpa memperkecil seluruh halaman atau menutup navigasi bawah.
2. Mengetuk identitas navbar ketika kasir sudah terbuka menampilkan profil kasir yang diverifikasi PIN, bukan otomatis profil pemilik akun terminal.
3. Nama lengkap, nomor telepon, alamat dan foto dapat disimpan; setiap input memiliki label. Email/username hanya-baca; PIN, hak akses, outlet dan identitas login tidak berubah.
4. Menyimpan menampilkan proses, tidak dapat dikirim ganda, dan kegagalan tidak menghilangkan isian. Perubahan bersamaan tidak saling menimpa.
5. Bahasa Indonesia/Inggris tersedia. Data terakhir dapat dibaca ketika jaringan gagal, tetapi perubahan profil tidak dimasukkan antrean offline.

## Hasil implementasi

- Navbar HP: judul 18sp (sebelumnya14), nama kasir12sp (sebelumnya9), avatar berdiameter36dp, toolbar64dp pada ukuran teks normal. Toolbar bertambah mengikuti pembesaran teks perangkat; skala2 diuji. Nama panjang memakai ellipsis, bukan FittedBox.
- `PosNavbarIdentity` dipakai shell sebenarnya. Navigasi bawah inline60dp dari perbaikan sebelumnya tetap dipertahankan; tidak ada FAB yang melayang menutupi konten.
- Halaman profil sebelumnya berisi contoh status/outlet dan tautan perubahan password dengan penyimpanan simulasi. Form baru memakai API nyata. Tautan contoh tersebut tidak ditampilkan sebagai kemampuan yang seolah sudah bekerja; navigasi outlet/logout operasional tetap tersedia melalui menu POS yang ada.
- Nama, telepon, alamat dan foto memiliki label, batas input dan validasi. Foto memakai pemilih galeri yang sudah tersedia; mendukung JPG/PNG/WebP maksimal5MB. Foto terpilih dipratinjau dan dapat dihapus secara eksplisit.
- Simpan menonaktifkan input dan tombol selama proses; keluar halaman diblokir selama pemilih/simpan aktif. Kegagalan mempertahankan draf dan menyediakan tombol muat ulang profil. Muat ulang adalah tindakan eksplisit yang mengganti isian dengan data server.
- Setelah berhasil, nama/foto navbar diperbarui pada `AppLockCubit` tanpa `loadEmployees`, tanpa membuka kunci, mengganti role, memperbarui token, atau mengganti kasir. Preferensi nama akun login hanya diperbarui jika profil yang disimpan memang milik akun login tersebut.
- Cache tampilan profil dipisahkan berdasarkan endpoint, instansi, terminal dan operator. Cache hanya dipakai untuk kegagalan transport, bukan penolakan otorisasi; tombol simpan nonaktif pada data cache. Cache profil bukan sumber izin atau verifikasi PIN.

## API dan perlindungan

Kontrak tunggal: `presensi_zera_BE/graphql/pos_kasir/pos_personal_profile.typedef.js`.

- `GetMyPOSPersonalProfile` dan `UpdateMyPOSPersonalProfile` didaftarkan pada modul POS serta auth middleware. Identitas mengikuti operator PIN yang ditandatangani server. Input tidak menerima ID pengguna/instansi, email, username, role, outlet atau PIN.
- Resolver memfilter pengguna aktif berdasarkan ID dan instansi dari konteks autentikasi. Konteks anonim, eksternal dan lintas instansi ditolak. Data PIN/password tidak ikut proyeksi respons.
- Revisi `updatedAt` dibandingkan secara atomik sebelum perubahan dan selalu maju minimal1ms. Dua penyimpanan dengan revisi sama menghasilkan satu keberhasilan dan satu `CONFLICT`, termasuk jika jam berubah. Pengguna diminta memuat ulang, bukan diam-diam menimpa perubahan.
- Penyimpanan gambar menggunakan validasi isi Sharp, batas25juta piksel, rotasi, resize maksimal1024px dan enkode ulang PNG. Nama file dibuat server, bukan dari nama unggahan. Penghapusan hanya di direktori instansi/kategori yang diizinkan.
- Foto lama dihapus setelah perubahan database berhasil; jika commit gagal, hanya foto baru dibersihkan. Detail internal database/HTML proxy tidak ditampilkan pada kegagalan unggah.
- Perubahan profil pribadi diizinkan dalam mode pemulihan langganan sebagaimana pengaturan akun; ini tidak menambah akses transaksi, stok, jurnal atau perubahan konfigurasi usaha.

## Pengujian yang benar-benar dijalankan

Di `mobile_POS_Pantoo`:

```text
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/personal-profile-20261124/lcov.info test/pos_personal_profile_test.dart test/pos_navbar_identity_test.dart test/pos_mobile_bottom_bar_layout_test.dart test/pin_lock_responsive_test.dart test/pos_dashboard_language_test.dart test/pos_business_profile_repository_test.dart
64 passed, exit 0, tanpa skip/cancel; 35 detik.
flutter analyze --no-pub
No issues found!, exit 0; 19.8 detik.
```

Pratinjau dibuat pada pengujian sebelumnya yang memakai `--dart-define=CAPTURE_PERSONAL_PROFILE=true` (63PASS sebelum penambahan satu regresi pesan proxy). Menggunakan widget dan font aplikasi sebenarnya; bukan screenshot emulator.

Di `presensi_zera_BE`:

```text
node --test --test-concurrency=1 --experimental-test-coverage --test-coverage-include=graphql/pos_kasir/pos_personal_profile.resolvers.js --test-coverage-include=graphql/pos_kasir/pos_business_logo.service.js tests/pos_personal_profile.test.js tests/pos_business_profile.test.js tests/pos_business_profile.integration.test.js
27 passed, exit 0, tanpa skip/cancel; 10.8 detik.
```

Backend memakai MongoDB sementara, JWT operator, middleware, eksekusi GraphQL, model pengguna, Sharp dan filesystem nyata. Dokumen query/mutation diekstrak dari repository Dart, divalidasi dan dieksekusi terhadap schema provider yang sama. Tes Flutter memakai GraphQLClient dengan link/transport palsu dan widget form dengan repository palsu; pemilih galeri native dan HTTP multipart ujung-ke-ujung belum diuji dalam aplikasi Android terbaru. Tidak ada database produksi atau data akun pengguna yang diubah.

| TEST-ID | Bukti perilaku | Level / hasil |
|---|---|---|
| TEST-POS-NAV-READABLE-2411 | Lebar320/360/768, judul18/nama12, tap profil, skala teks2 tanpa overflow; navigasi bawah tetap aman | unit/integration, covered scoped |
| TEST-POS-PROFILE-SELF-2411 | JWT operator pada terminal pemilik; hanya profil diri; penolakan anonim/eksternal/lintas instansi/field terlarang; PIN/role tetap | contract/integration, covered scoped |
| TEST-POS-PROFILE-PHOTO-2411 | Unggah/ganti/hapus foto nyata, batas dan format; foto lama tetap utuh jika commit gagal; konflik revisi dan pesan proxy aman | unit/integration, covered scoped |
| TEST-POS-PROFILE-CACHE-2411 | Cache per operator, tidak dipakai pada forbidden, respons operator lama dibuang, cache hanya-baca | unit/integration, covered scoped |
| TEST-POS-PROFILE-FORM-2411 | Label dan email readonly, loader/simpan satu kali, draf bertahan saat gagal, pratinjau foto, ID/EN, state kunci/token/role tetap | unit/integration, covered scoped |
| TEST-POS-PROFILE-NATIVE-2411 | Galeri Android → simpan melalui HTTP nyata → buka ulang profil dan kunci PIN | E2E, unverified pada APK terbaru |

### Cakupan terukur

- Repository profil pribadi111/119baris (93.3%); halaman profil148/162 (91.4%); identitas navbar39/39 (100%). Ini cakupan berkas terkait, bukan seluruh POS.
- Resolver profil: line100%, branch90%, function81.82%. Penyimpanan gambar bersama: line100%, branch75.68%, function85.71%. Gabungan dua berkas: line100%, branch85.05%, function83.33%.
- Log timeout pada tes cache adalah simulasi yang disengaja. Backend mencetak peringatan deprecation `punycode` dan experimental coverage/glob; tidak ada tes gagal pada run akhir.

## Jejak RED → GREEN

- Backend `ae7e612a` → `ed004e56`: endpoint belum tersedia → implementasi profil diri; 23tesPASS pada tahap awal.
- Mobile `370f170` → `e09a6cb`: repository/form/navbar belum tersedia → 10tesPASS.
- `07eb333` → `d145415`: teks Inggris baru belum terpetakan → 15tesPASS; cache/state/foto ikut diperkuat.
- Backend `45e73df1` → `f239e72b`: revisi tidak monoton setelah perubahan jam → 26tesPASS. `21bf00b3` menambahkan bukti pembersihan foto saat commit gagal →27PASS.
- `c4ec6c8` → `2429d4a`: tinggi navbar belum mengikuti pembesaran teks →63tesPASS gabungan.
- `99b55bb` → `fd8e52b`: error HTML proxy masih tampil mentah → pesan aman dan64tesPASS.
- Kegagalan awal fixture GraphQL diperbaiki menjadi respons error GraphQL nyata dan `__typename` yang lengkap; tes HP menyelesaikan perpindahan fokus/scroll sebelum tap. Assertion keamanan tidak dihapus atau dilemahkan.

## Batas dan langkah verifikasi berikutnya

Belum ada build/deploy/restart server produksi atau GUI Android baru pada pekerjaan ini. APK/AAB1.0.21+22 yang dibuat sebelumnya belum memuat perubahan ini. Server tujuan harus memakai kedua API profil baru sebelum dipasangkan dengan aplikasi baru; server lama akan menolak query, bukan memakai API HR luas sebagai fallback.

Setelah build yang sesuai tersedia: masuk PIN kasir uji → ketuk identitas navbar → ubah nama/telepon/alamat → unggah, ganti dan hapus foto → buka ulang halaman. Ulangi dengan operator berbeda pada terminal yang sama dan pastikan pemilik terminal tidak berubah; kunci PIN dan pastikan tetap meminta verifikasi. Uji galeri dibatalkan, internet putus saat simpan, kemudian muat ulang sebelum mencoba lagi. Cache daftar operator PIN tetap menggunakan siklus verifikasi yang sudah ada dan dapat memuat identitas tampilan lama sampai diperbarui online; tidak diperbarui melalui profil pribadi agar metadata izin/PIN tidak tersentuh.

Pratinjau lokal: `output/personal-profile-20261124/profile-320.png`, `profile-768.png`, `navbar-320.png`, `navbar-360.png`, `navbar-768.png`. `lcov.info` berisi cakupan akhir. Pratinjau navbar memakai body/ikon navigasi contoh untuk mengisolasi geometri; bukan bukti checkout native.

## Evaluasi hasil

Akurasi5/5: angka dan kontrak diverifikasi dari tes nyata. Kelengkapan4/5: GUI galeri Android/HTTP terpasang belum diverifikasi. Kejelasan5/5: data pribadi dan identitas login dibedakan. Keterlaksanaan4/5: server dan aplikasi perlu diperbarui bersama; build lama tidak berubah. Keringkasan4/5: laporan sengaja rinci untuk jejak keamanan/RED–GREEN. Rata-rata4.4/5; tidak ada isu kritis terbuka dari suite terkait. Perbaikan prioritas berikutnya adalah E2E native pada build baru, bukan klaim seluruh POS siap produksi.
