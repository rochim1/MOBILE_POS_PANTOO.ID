# Navbar POS kontekstual

20 November 2026. Tujuan: ikon hanya muncul ketika berguna pada halaman yang terlihat, tanpa menghilangkan pintu masuk fitur atau mengubah otorisasi backend.

| Aksi | Kapan tampil |
|---|---|
| Bantuan keyboard di navbar | Kasir, dengan izin `use_cashier`; ikon langsung pada layar lebar, overflow pada HP. F1 dan bantuan sidebar tetap tersedia. |
| Hubungkan layar pelanggan | Kasir dan izin kasir; tidak membangun listener/service display pada halaman yang tidak relevan. |
| Checklist/panduan di navbar | Hanya ketika panduan sedang terbuka, untuk menutupnya. Membuka panduan tetap tersedia di Lainnya dan sidebar layar besar. |
| Ganti tampilan | Kasir, katalog, riwayat, pesanan/meja, dan bagian stok inventori, sesuai izin. Tidak tampil pada PO, gudang, opname, transfer, stok terbuang atau retur pembelian. |
| Pesanan/riwayat dari kasir | Hanya jika tujuan tersedia menurut profil dan izin; tidak menawarkan halaman riwayat tanpa izin. |
| Notifikasi | Global saat tidak terkunci. |
| Kunci POS | Global saat penguncian POS diaktifkan dan aplikasi belum terkunci. |

Menu overflow HP tidak dibuat bila tidak mempunyai aksi yang relevan. Panduan dan halaman pembatas langganan tidak lagi mempertahankan kontrol kasir di belakangnya. Perubahan runtime/izin, status lock dan layanan langganan memicu evaluasi ulang. Bagian aktif inventori dilaporkan sesudah frame agar perubahan kategori tidak memicu `setState during build`.

## Pengujian dan bukti

Journey dan kriteria diturunkan dari permintaan pengguna. RED `cc95f6b`: kedua tes baru menginstansiasi kebijakan/widget yang belum ada, menghasilkan compile-time RED yang disengaja. GREEN `6236d4d`: 34 tes aturan/render lulus. Integrasi diterapkan pada shell dan callback bagian inventori.

Perintah regresi dari `mobile_POS_Pantoo`:

```text
flutter test test/pos_navbar_action_policy_test.dart test/pos_navbar_context_actions_test.dart test/pos_keyboard_navigation_test.dart test/pos_mobile_navigation_policy_test.dart test/pos_more_menu_visibility_test.dart --no-pub --concurrency=1 --coverage --reporter expanded
```

Hasil: **49/49 PASS**. Kebijakan diuji untuk seluruh indeks halaman 0–19, izin kosong/dicabut, mode stok/nonstok, antrian profil, guide overlay, pembatas body, PIN dinonaktifkan, serta aplikasi terkunci. Widget sesungguhnya diuji pada ukuran HP 320 dp dan layar besar, termasuk isi overflow, callback tombol, listener display yang tidak dibangun di halaman lain, dan tidak ada overflow/exception render.

Coverage baris executable file baru: `pos_navbar_action_policy.dart` **29/29 (100%)** dan `pos_navbar_context_actions.dart` **42/43 (97,7%)**. Bukan persentase coverage seluruh aplikasi. Log lokal: `D:/my node app/zera/output/navbar-*.log`.

Putaran final setelah integrasi sidebar dan perapian analyzer: perintah tes yang sama kembali menghasilkan **49/49 PASS**. `dart analyze lib/presentation/pages/pos` selesai exit 0, **No issues found!**, mencakup seluruh halaman POS beserta kebijakan dan widget baru. Tiga temuan gaya kurung blok pada pemeriksaan awal sudah diperbaiki; bukan ditandai selesai dengan warning tersisa. Pemeriksaan diff perubahan tugas juga PASS.

## Lingkup dan batas

Kompilasi diverifikasi melalui tes Flutter. Tidak mengubah data, skema query, izin backend, atau koneksi display/printer yang tersimpan. Perubahan hanya pada aplikasi Flutter POS (Android/tablet; Flutter web pengujian memakai kode yang sama), bukan navbar Vue admin. Tidak menjalankan transaksi produksi, GUI di emulator/perangkat, deploy, atau build APK/AAB baru. Target perangkat langsung belum diverifikasi dalam tugas ini.
