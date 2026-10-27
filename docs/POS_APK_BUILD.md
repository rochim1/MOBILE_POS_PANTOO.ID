# Profil POS runtime dan build APK

Web dan Flutter mengambil pilihan profil melalui query GraphQL terautentikasi `GetPOSProfileCatalog` setiap membuka onboarding atau Pengaturan POS (`network-only`). Backend mengirim ID, label, deskripsi, preset fitur, tipe pemenuhan beserta persyaratan fiturnya, default tipe pesanan, dan versi hash katalog.

Sumber utama adalah `presensi_zera_BE/graphql/pos_kasir/pos_profile_policy.service.js`. Tambahkan entri `POS_PROFILE_DETAILS` beserta `features`, `default_order_type`, dan bila perlu `extra_order_types` (`free_table`/`quick_service`). ID yang diizinkan model dan validator berasal dari entri yang sama. Deploy backend; web dan app yang mendukung katalog runtime akan memperoleh pilihan baru ketika halaman dibuka kembali. Profil yang sudah tersimpan tidak berubah otomatis.

Contoh entri backend:

```js
studio_baru: {
  label: 'Studio Baru', description: 'Layanan dan reservasi', icon: 'ri-store-2-line',
  features: { use_service_order: true, use_appointments: true, require_customer: true, track_stock: true },
  default_order_type: 'reservation',
},
```

Klien menerima profil dengan ID baru tanpa daftar enum profil lokal. Kemampuan operasional dan tipe pesanan tetap dibatasi pada fitur yang sudah didukung versi app; fitur UI atau alur baru memerlukan pengembangan dan update app.

Jika jaringan/endpoint gagal atau respons tidak valid, gunakan katalog terakhir yang valid, lalu snapshot bawaan bila cache belum tersedia. UI menampilkan penggunaan katalog tersimpan. Cache tidak menggantikan otorisasi atau validasi penyimpanan pengaturan. Pilihan profil tersimpan yang tidak ada di katalog tetap dipertahankan.

Snapshot offline dapat diperbarui secara opsional:

```powershell
node presensi_zera_BE/scripts/sync_pos_profile_catalog.cjs
```

Snapshot tidak wajib sama dengan katalog backend terbaru. Build web dan Android tidak bergantung pada checkout backend atau pemutakhiran snapshot untuk menerima profil baru.

## APK

Dari `mobile_POS_Pantoo`:

```powershell
.\scripts\build-pos-apk.ps1 -Flavor production
```

Build memakai signing Android yang tersedia, memeriksa semua label fallback serta marker query runtime pada setiap ABI `libapp.so`, dan menyalin APK beserta metadata SHA-256 ke `output/pos-apk-latest`. Gunakan `-OutputDirectory` untuk tujuan lain. Task merge JNI menunggu output kompilasi Flutter agar library lama tidak masuk build incremental.

Versi **1.0.6+7** memuat mekanisme runtime. Pengguna versi sebelumnya perlu memasang APK ini sekali. Backend dan web yang melayani pengguna juga perlu menggunakan source terbaru. Setelah itu penambahan profil dengan kemampuan yang sudah tersedia cukup melalui backend, tanpa build ulang web atau APK.

Salon tersedia pada onboarding dan Pengaturan POS. Pemasangan APK tidak mereset pengaturan instansi maupun data transaksi.
