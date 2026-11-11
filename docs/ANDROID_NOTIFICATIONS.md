# Push notification Pantoo POS Android

Ikon notifikasi menggunakan simbol Pantoo putih dengan latar transparan:
`android/app/src/main/res/drawable/ic_notif.xml`, sama dengan Pantoo HR.
Logo Bimbel dalam lima density PNG lama telah dihapus. Warna aksen `#087F75`.
AndroidManifest menunjuk ikon dan warna default FCM. `res/raw/keep.xml` menjaga
ikon agar tidak dibuang oleh resource shrinking pada rilis.

## Firebase dan lifecycle

Firebase project `pantoo-511802`, sender `941313151223`, dipakai bersama HR.
Lima aplikasi Android telah didaftarkan: `id.pantoo.pos`, `.dev`, `.stg`, `.qa`,
dan `.qa.peer`. `android/app/google-services.json` berisi seluruh client dan
diabaikan Git. Integrasi diaktifkan hanya untuk Android; web/desktop/iOS tidak
memerlukan konfigurasi Firebase baru. Private key backend tidak masuk APK.

`PosPushService.initialize()` membuat channel `pantoo_pos`, listener foreground,
listener tap background, handler background top-level, dan pembacaan cold start.
Setelah login dan instansi siap, `activate()` meminta izin dan mendaftarkan token
beserta project ID, `client_app=pantoo_pos`, dan installation ID tetap per pemasangan.
Refresh token disimpan berurutan dan hasil pembacaan token lama yang terlambat
diabaikan. Kegagalan registrasi dicoba lagi saat aktivasi/koneksi shell pulih.

Foreground menampilkan notifikasi lokal dengan `ic_notif`; message ID dideduplikasi.
Background/terminated notification payload ditampilkan FCM Android. Handler
background tidak menampilkan salinan kedua. Tap membuka daftar notifikasi setelah
login; cold-start tap ditahan sampai autentikasi, instansi, dan navigasi login
siap. URL arbitrer dari payload tidak langsung dibuka. Wrapper kunci POS tetap berlaku.

Logout menghentikan penerimaan foreground untuk sesi itu, menghapus registrasi
backend pengguna/instansi/perangkat, meminta invalidasi token FCM, dan membatalkan
notifikasi lokal. Penghapusan jaringan bersifat best effort ketika offline;
registrasi token yang sama pada akun lain mencabut kepemilikan sebelumnya.
Halaman Notifikasi menampilkan status izin/koneksi dalam Indonesia dan Inggris,
dengan tombol untuk pengaturan Android atau registrasi ulang.

## Backend dan rollout

Deploy backend sebelum APK: input token menambahkan `client_app`/`installation_id`
dan mutation `removeDeviceAppsID` dilindungi middleware Authorized. Registrasi dan
penghapusan dibatasi ke user/instansi dari sesi server. Token POS per installation
ID tidak menimpa token HR. Satu baris inbox dikirim ke semua token aktif sasaran;
POS menerima modul POS/inventory dan dikecualikan dari notifikasi khusus HR.

Project token memilih Firebase Admin app yang sesuai. Gunakan pengaturan
`FCM_PROJECT_ID`/`FCM_SERVICE_ACCOUNT_FILE` yang disiapkan saat integrasi HR.
Token lama tanpa metadata tetap memakai pengirim `PROJECT_ID` lama. Kunci harus
disimpan di penyimpanan rahasia server, bukan folder publik/repositori/APK.

## Validasi 10 November 2026

- 10 tes push mencakup registrasi/refresh, foreground, tap background/cold start,
  izin ditolak, retry, perubahan instansi, logout saat registrasi, dan logout
  saat Firebase masih diinisialisasi.
- Regresi penuh POS: 442 tes lulus; pengujian FCM nyata Android: 1 tes integrasi lulus.
- 12 tes backend mencakup pemisahan proyek, aplikasi/perangkat, batas instansi,
  logout, pengiriman beberapa perangkat dan pengecualian notifikasi HR dari POS.
- Google Services lima varian serta resource development/production tervalidasi.
- APK development dari entry normal `lib/main_development.dart` berhasil dibangun
  ulang setelah fixture selesai: `build/app/outputs/flutter-apk/app-development-debug.apk`.
- Lockfile memakai `image 4.9.2`, kompatibel dengan batas archive/XML `pdf 3.12.0`.
  `image 4.11.0` tidak dapat dikompilasi bersama kombinasi dependensi tersebut.

Tes layanan memakai transport tiruan. Pengujian Android terpisah memakai aplikasi
QA dengan backend tiruan dan token emulator sendiri: pesan FCM nyata foreground
dan background diterima, dan kedua notifikasi aktif dikonfirmasi lewat API Android.
Test memastikan pesan background tidak diterima lewat listener foreground.
Pengujian integrasi Android lulus; tidak ada pengiriman ke pengguna atau perubahan
data kasir. Registrasi bisnis pada backend diuji secara terpisah dengan tes scope.

Fixture manual: `integration_test/pos_push_android_test.dart`, ditargetkan pada
flavor development dan emulator dengan Google Play Services. Token hanya
diekspor ke `private_storage/firebase/pos-push-qa.json` backend (Git ignored),
kemudian `scripts/send-pos-push-qa.cjs foreground|background` mengirim pesan
sintetis ke token fixture itu. Jalankan foreground lebih dulu. Fixture berpindah
ke background lewat API Android menggunakan channel debug-only
`pantoo.pos/push_qa`, lalu mengubah tahap menjadi `foreground_received`.
Kirim skenario background setelah tahap itu. Channel QA tidak didaftarkan pada
build release. Test memeriksa notifikasi Android
aktif dan memastikan pesan background tidak masuk listener foreground. Fixture
tidak boleh dipakai sebagai APK distribusi; bangun ulang entry aplikasi normal.

Backend online dan APK pengguna perlu diperbarui sebelum rollout. Android
force-stop memerlukan aplikasi dibuka lagi sebelum FCM dapat diterima.

Referensi: [Firebase Flutter receive messages](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).
