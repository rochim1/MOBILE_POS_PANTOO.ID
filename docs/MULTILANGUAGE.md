# Bahasa Pantoo POS Mobile

POS mendukung Indonesia (`id`) dan Inggris (`en`). Pilihan Sistem mengikuti perangkat, dengan Indonesia sebagai cadangan untuk bahasa lain. Pemilih tersedia pada login, pendaftaran, profil, dan Pengaturan Kasir.

Preferensi disimpan lokal di SharedPreferences dengan kunci `pos_app_locale`, terpisah dari akun, instansi, operator, PIN, dan shift. Pergantian bahasa membangun ulang tampilan tanpa membuat ulang penyedia state aplikasi. Logout tidak menghapus preferensi bahasa.

## Menambahkan teks

- Tambahkan kunci yang sama di `lib/l10n/app_id.arb` dan `app_en.arb`, beserta metadata parameter. Gunakan nama semantik untuk fitur baru.
- Gunakan `posLocale(context).namaKunci` dan metode berparameter untuk teks baru. Parameter nama pelanggan, produk, outlet, serta isi pengguna dikirim utuh.
- `PosText` dan `.tr(context)` menjembatani salinan UI lama yang sudah ditinjau melalui `legacy_ui_aliases.json`. Jangan gunakan untuk nama atau isi bebas pengguna.
- Untuk pesan yang dirender tanpa context, seperti struk, gunakan `posCurrentLocale()`. Mata uang tetap Rupiah; format pengiriman API, kode status, ID, dan nilai filter tidak diterjemahkan.
- Form dengan validator menggunakan `errorBuilder: posValidationError` agar pesan yang sudah tersimpan tetap mengikuti bahasa tanpa menghapus isian.
- Jangan mengedit berkas Dart di `lib/l10n/generated` atau `pos_translation_lookup.dart` secara langsung.

## Pembuatan dan pemeriksaan

```powershell
flutter gen-l10n
python scripts/build_pos_translation_lookup.py
flutter analyze --no-pub lib
flutter test --no-pub --concurrency=1
```

Katalog awal mencakup 3.270 kunci per bahasa. Alat AST untuk migrasi satu kali diarsipkan dalam `../output/pos-i18n-20261110/migration-tools`, terpisah dari aplikasi. `scripts/build_pos_catalog.py` memerlukan hasil inventaris dalam folder output tersebut; pengembangan berikutnya cukup mengedit pasangan ARB dan alias bila diperlukan.

Pemindaian ulang 10 November 2026 melengkapi katalog menjadi **3.331 kunci per bahasa**. Daftar tambahan yang ditinjau disimpan dalam `lib/l10n/supplemental_ui.json`. Terjemahan juga diterapkan pada judul komponen bersama, label dinamis, teks bersyarat, tooltip, tabel dokumen PO, label jenis pesanan pada struk, nama bulan pada riwayat, dan layar pelanggan Wi-Fi lokal. Layar lokal menggunakan katalog yang sama dan memperbarui salinan melalui koneksi aktif saat bahasa POS berubah.

Untuk status dari API, `posStatusLabel` mengubah label tampilan saja; kode asli tetap dipakai untuk logika dan pengiriman. Kategori buatan pengguna, nama produk/pelanggan/lokasi, serta teks struk khusus tetap dipertahankan.

Audit kata pendek lanjutan melengkapi katalog menjadi **3.377 kunci per bahasa**. Pemeriksaan mencakup teks dalam tuple, peta opsi, getter, label gabungan, filter stok, dan dokumen thermal. Gunakan `posStockMovementLabel` untuk arah stok: `Masuk/Keluar` berarti **Stock In/Stock Out**, berbeda dengan login/logout. Nilai filter `masuk`, `keluar`, `penyesuaian`, dan `retur` tetap sama.

Label pelanggan pada struk memakai `receiptCustomerLabel` (**Customer**, tunggal); menu pelanggan tetap menggunakan **Customers**. Jangan mengandalkan satu terjemahan kata pendek untuk semua konteks. Label gabungan diterjemahkan per bagian UI sebelum digabung, sementara nama, catatan, dan nominal diteruskan utuh.

Tes `pos_short_labels_test.dart` mencakup arah stok, fase pesanan, status koneksi, bukti pembayaran thermal, serta alur berbagi struk teks pada lebar 320 dp. Tujuan eksternal disimulasikan; tes tidak membuka aplikasi atau mengirim pesan.

Uji pergantian ID → EN → ID, penyimpanan setelah aplikasi dibuka ulang, layar sempit, pesan validasi, keranjang, dan nama produk yang kebetulan sama dengan teks tombol. Konten dari server serta halaman eksternal tetap mengikuti bahasa sumber masing-masing.
