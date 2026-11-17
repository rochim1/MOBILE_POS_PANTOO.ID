# Label permanen pada setup usaha dan operasional POS

Tanggal:17 November2026. Sumber kebutuhan: permintaan pengguna di chat ini, “setup business profile dan seterusnya juga tambahkan label pada setiap field”.

## Hasil

Label form tetap terlihat ketika kosong, terisi, fokus, ataupun ditinggalkan. Placeholder tetap dipakai untuk contoh, bukan menggantikan nama field. Override dibatasi pada51 dekorasi input di alur setup:

| Form | Dekorasi diperbaiki |
|---|---:|
| Profil usaha: nama dan nomor telepon | 2 |
| Default transaksi: pajak | 1 |
| Warehouse termasuk tipe dan outlet terkait | 6 |
| Outlet termasuk lokasi dan mode shift | 6 |
| Katalog: tambah/edit, kategori, informasi produk dan stok/satuan | 29 |
| Buka/tutup shift dan formulir pergerakan kas | 6 |
| Modal awal pada panel pembukaan shift | 1 |

Label tiga dropdown default transaksi sudah berupa judul di atas field; dipertahankan tanpa label ganda. Label PIN sudah memakai `always` sebelumnya dan tidak diubah. Tema global yang memakai `never`, kolom pencarian, filter katalog dan tabel tidak diubah. Nama field tetap memakai penerjemahan yang sudah ada.

Tes layar360px juga menemukan overflow147px dan99px pada dropdown onboarding. Perbaikan `isExpanded` serta batas satu baris/ellipsis menjaga nilai pilihan dalam lebar field. Tidak ada perubahan payload, validasi, izin, transaksi, data produksi atau versi aplikasi dalam pekerjaan label ini. Tidak build APK/AAB.

## Journeys dan jaminan

Sebagai pengguna baru, saya dapat mengenali setiap nilai yang saya ketik selama profil usaha dan setup operasional tanpa menebak dari placeholder yang menghilang.

| Jaminan | Bukti executable | Jenis / hasil |
|---|---|---|
| Nama/telepon usaha berlabel saat kosong dan setelah diisi/blur pada360px dan1024px; validasi nomor tetap berlaku | `test/business_setup_page_test.dart` memakai `AppTheme.light()` dan merged `InputDecorator` | widget integration;3/3PASS |
| Channel/pemenuhan/level harga tetap berjudul, pajak tetap berlabel setelah edit; tidak overflow pada360px | `test/pos_onboarding_profile_test.dart` dengan tema nyata; skenario profil dan payload tersimpan juga tetap diuji | widget integration/unit;4/4PASS |
| Enam field warehouse dan enam field outlet dalam bottom sheet mempertahankan label setelah mengetik/blur | `test/setup_operational_labels_test.dart`, halaman/modal nyata dengan repositori fixture | widget integration;2/2PASS |
| PIN, kesiapan setup, pembukaan kasir, kontrak outlet, konflik shift dan redirect login tetap diperiksa | Rangkaian lebih luas pada log regresi |53PASS,1FAIL lama; lihat batas di bawah |

## RED → GREEN

- Checkpoint `a858dfc`: sebelum source diubah, dua ukuran profil usaha gagal `expected always, actual never`; wizard pajak gagal label dan menampakkan overflow dropdown. Target berhasil dikompilasi dan dieksekusi, exit1.
- Checkpoint `60f77d3`: modal warehouse/outlet masing-masing gagal pada `Nama warehouse *` / `Nama outlet`, `expected always, actual never`, exit1. Tidak menggunakan pencocokan source sebagai pembuktian label.
- Perbaikan `393f496`: rerun tiga file yang sama, **9/9PASS**, exit0 (`output/setup-field-labels-20261117/green.log`). Dalam rerun yang lebih luas setelah perapian, sembilan tes ini juga tetap PASS.
- Pemeriksaan ketujuh file source dan tiga file tes yang diubah: **No issues found, exit0**, `output/setup-field-labels-20261117/analyze.log`.

Commands dari root mobile (SDK Flutter lokal):

```powershell
flutter test --no-pub --concurrency=1 test/business_setup_page_test.dart test/pos_onboarding_profile_test.dart test/setup_operational_labels_test.dart --reporter expanded
flutter test --no-pub --concurrency=1 --coverage --coverage-path=output/setup-field-labels-20261117/lcov.info test/business_setup_page_test.dart test/pos_onboarding_profile_test.dart test/setup_operational_labels_test.dart test/pin_lock_responsive_test.dart test/pos_setup_readiness_test.dart test/pos_cashier_setup_entry_test.dart test/pos_outlet_crud_contract_test.dart test/pos_shift_outlet_recovery_test.dart test/pos_catalog_tablet_grid_test.dart test/google_redirect_regression_test.dart --reporter expanded
dart analyze lib/presentation/pages/login/business_setup_page.dart lib/presentation/pages/pos/pos_onboarding_page.dart lib/presentation/pages/pos/pos_warehouse_page.dart lib/presentation/pages/pos/pos_outlet_page.dart lib/presentation/pages/pos/pos_product_page.dart lib/presentation/pages/pos/widgets/pos_active_shift_tab.dart lib/presentation/pages/pos/widgets/shift_management_panel.dart test/business_setup_page_test.dart test/pos_onboarding_profile_test.dart test/setup_operational_labels_test.dart
```

## Coverage dan batas bukti

LCOV rangkaian luas tersimpan di `output/setup-field-labels-20261117/lcov.info`; changed executable terhadap checkpoint RED: **11/11 (100%)**. Nilai enum konstan `FloatingLabelBehavior.always` sendiri tidak mendapat record executable terpisah; angka tersebut **bukan** bukti51 field diuji lewat GUI, bukan coverage seluruh tujuh file, dan bukan E2E perangkat Android.

Sembilan tes label terfokus PASS. Rangkaian luas berakhir **53PASS,1FAIL, exit1**, log `output/setup-field-labels-20261117/regression.log`. Satu kegagalan berasal dari assertion source lama pada `test/pos_catalog_tablet_grid_test.dart`: mencari teks `if (!widget.isGridView || isMobile)`. Teks itu sudah tidak ada pada `git show 60f77d3:lib/presentation/pages/pos/pos_product_page.dart` sebelum perubahan ini dan juga tidak ada sesudahnya; diff file hanya menambahkan29 override label. Tes skeleton tablet di file yang sama tetap PASS. Assertion lama tidak dihapus/dilemahkan atau ditandai PASS; penyelarasan tes dengan kebijakan grid terbaru merupakan tindak lanjut terpisah.

Form katalog bercabang dan form shift telah diberi override yang sama, tetapi belum seluruh varian produk, pergerakan kas dan penutupan shift dibuka melalui GUI pada pekerjaan ini. Android native/source terbaru dan APK rilis belum diuji/dibangun. Data akun yang dibersihkan pada permintaan sebelumnya tidak disentuh lagi.

Tinjauan akhir: accuracy5/5 (hasil gagal tetap dicatat), completeness4/5 (semua input setup yang ditemukan diperbaiki, varian GUI katalog/shift belum lengkap), clarity4/5 (label tidak menggantikan placeholder, laporan teknis terpisah), actionability4/5 (perlu hot restart/build untuk memuat source baru), conciseness4/5 (ringkasan pengguna dipisahkan dari bukti). Rata-rata4,2/5; tindak lanjut utama adalah uji native dan peninjauan assertion grid lama, bukan mengklaim seluruh regresi PASS.
