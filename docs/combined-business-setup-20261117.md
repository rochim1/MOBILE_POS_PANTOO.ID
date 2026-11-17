# Setup usaha terpadu — 17 November 2026

Menggantikan alur tiga langkah dalam `onboarding-operating-needs-20261117.md`.
Sumber journey: permintaan pengguna untuk menghilangkan Default Transaksi dan memilih profil bisnis saat membuat instansi.

## Alur yang diterapkan

1. Satu form pembuatan usaha: logo opsional, nama, nomor telepon, dan dropdown Profil usaha dengan label permanen. Profil awal Retail / Toko dapat diganti sebelum melanjutkan.
2. Setelah workspace dibuat, simpan pilihan profil lokal dengan scope instansi + akun. Pilihan tersimpan sebelum unggah logo; kegagalan logo tidak menghilangkannya.
3. Pengamanan PIN dan routing pusat tetap dipertahankan. Gate membaca pengaturan server, lalu otomatis menyelesaikan konfigurasi dari pilihan tadi. Tidak ada pertanyaan profil kedua ataupun halaman Default Transaksi / Validasi Inventory pada jalur sukses.
4. Load runtime, settings, dan katalog dilakukan paralel dengan batas waktu. Simpan menampilkan progres dan tidak dapat dikirim dua kali selama berlangsung.
5. Fitur dan tipe pemenuhan mengikuti katalog profil. Pajak, auto-print, channel dan level harga yang sudah tersimpan dipertahankan. Tracking wajib untuk inventory terkait tetap aktif.
6. Validasi inventory/pajak dan izin kelola tetap memblokir perubahan yang tidak valid. Penjelasan ditampilkan langsung, bukan sebagai langkah wizard tambahan. Pengaturan POS tetap menjadi tempat kustomisasi.
7. Jika simpan gagal, profil terpilih tetap tersedia untuk dicoba lagi. Jika server sudah menyatakan onboarding selesai setelah respons sebelumnya hilang, status server menang: pilihan pending dibersihkan tanpa mengulang update profil.
8. Instansi lama yang onboarding-nya belum selesai dan tidak punya pilihan pending mendapat satu form profil sederhana sebagai pemulihan. Tidak ada PageView, langkah fitur, maupun default transaksi.

Katalog sebelum instansi ada menggunakan tujuh profil bawaan; konfigurasi sesudah instansi dibuat dan pemulihan tetap memakai katalog server/cache. Profil tambahan backend diuji pada form pemulihan. Tidak menambah input GraphQL atau mengubah backend.

## Bukti TDD dan hasil

- RED `e2cba27`: 3 tes lolos, 19 gagal pada implementasi lama; dropdown profil belum ada pada pembuatan instansi, wizard transaksi masih ada, dan pilihan pending belum otomatis diterapkan.
- GREEN `91e1030`: 29 tes lolos setelah form digabung dan default otomatis diterapkan.
- RED tambahan `8d1f84b`: dua tes host completion menemukan spinner tetap aktif ketika host mengambil alih navigasi; tes pemulihan dan hak akses lainnya berjalan.
- GREEN `4d97a9b`: 60 tes lolos setelah status loading host diselesaikan.
- Refactor `486d19b`: perapian lint dan helper tes; suite yang sama diulang, `00:50 +60: All tests passed!`, exit 0.

Perintah verifikasi akhir (Flutter SDK lokal; TEMP/TMP diarahkan ke output di drive D):

```powershell
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/combined-business-setup-20261117-lcov.info test/pos_onboarding_profile_test.dart test/business_setup_page_test.dart test/pos_business_logo_flow_test.dart test/pos_setup_readiness_test.dart test/registration_flow_contract_test.dart test/setup_operational_labels_test.dart test/pos_localization_test.dart test/pos_translation_rescan_test.dart --reporter expanded
flutter analyze --no-pub lib/presentation/pages/login/business_setup_page.dart lib/presentation/pages/pos/pos_onboarding_page.dart lib/presentation/widgets/pos_business_profile_selector.dart test/business_setup_page_test.dart test/pos_onboarding_profile_test.dart test/pos_business_logo_flow_test.dart
git diff --check
```

Analyze akhir: `No issues found!`, exit 0. Whitespace bersih.

| Jaminan yang diuji | Target | Hasil |
|---|---|---|
| Profil dapat dipilih pada form usaha, semua label tetap terlihat pada lebar 360/1024 | business_setup_page_test.dart | PASS |
| Tujuh profil POS menerapkan fitur tanpa pertanyaan default transaksi; nilai pajak/channel/harga/auto-print dipertahankan | pos_onboarding_profile_test.dart | PASS |
| Profil tambahan backend dapat dipilih beserta default reservasinya | pos_onboarding_profile_test.dart | PASS |
| Tracking stok simple/centralized/advanced/custom aman, flag custom tidak terhapus | pos_onboarding_profile_test.dart | PASS |
| Pilihan dari pembuatan usaha otomatis disimpan; sukses menandai onboarding dan membersihkan pending | pos_onboarding_profile_test.dart | PASS |
| Respons simpan hilang lalu server sudah completed tidak mengulang/mengganti konfigurasi | pos_onboarding_profile_test.dart | PASS |
| Gagal load dapat dicoba lagi; profil tidak dikenal tidak otomatis disimpan | pos_onboarding_profile_test.dart | PASS |
| Kasir tanpa izin tidak dapat menyimpan; pajak negatif, >100 dan NaN diblokir; isu inventory tetap terlihat | pos_onboarding_profile_test.dart | PASS |
| Simpan tertunda menunjukkan progres dan mencegah submit kedua | pos_onboarding_profile_test.dart | PASS |
| Gagal logo tidak membuat workspace kedua pada retry; pilihan Restoran tetap tersimpan; lanjut tanpa logo masih mengunci PIN | pos_business_logo_flow_test.dart | PASS |
| Prasyarat operasional, routing registrasi, label gudang/outlet dan lokalisasi tidak regresi | lima target regresi lainnya di atas | PASS |

Coverage executable lines yang ditambah/berubah terhadap awal tugas: onboarding 151/161; business setup 14/15; selector 16/16. Total **181/192 = 94,3%**. Whole-file onboarding 225/270; business setup 116/130; selector 16/16. Bukan coverage seluruh aplikasi.

## Batas pengujian dan aktivasi

Pengujian ini adalah widget/unit dan kontrak sumber; repository server diganti fake untuk skenario update/response loss. Tes completion memakai callback host agar transisi selesai bisa diperiksa tanpa menjalankan seluruh shell kasir. Bukan E2E native Android atau pemutusan HTTP sungguhan. Tidak menulis database produksi, tidak deploy, tidak build APK/AAB, dan tidak mengubah versi pubspec milik pengguna. Untuk melihat perubahan di aplikasi berjalan perlu restart sumber terbaru atau APK berikutnya.

## Evaluasi hasil

Accuracy 4/5: 60 tes dan analyze bersih, tetapi tidak ada bukti GUI Android native. Completeness 4/5: form, profil, default dan pemulihan teruji; jaringan/database nyata pada jalur baru belum diuji. Clarity 4/5: alur baru dan fallback lama dibedakan, tanpa klaim satu transaksi database atomik. Actionability 4/5: kode siap dipakai dari sumber, APK belum dibuat. Conciseness 4/5: wizard lama dihapus dan selector dipakai bersama, laporan tetap lebih rinci daripada balasan pengguna. Rata-rata 4,0/5; tidak ada isu kritis yang ditemukan. Peningkatan berikutnya yang paling bernilai adalah smoke test registrasi → PIN → kasir pada Android setelah build berikutnya. Layak diserahkan dengan batasan yang dinyatakan.
