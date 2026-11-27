# Visibilitas field saat keyboard terbuka — POS mobile

Tanggal: 27 November 2026.

## Hasil

Penanganan keyboard dipasang di tingkat aplikasi Flutter POS, di atas Navigator, sehingga berlaku juga pada halaman yang didorong, dialog, dan bottom sheet. Field yang tertutup otomatis digulir, sedangkan field yang sudah terlihat tidak dipaksa pindah posisi. Modal form berukuran tetap mempertahankan batas luarnya; area gulir di dalamnya yang disesuaikan.

**116 pengujian lulus:** 115 dalam regresi gabungan 16 berkas, ditambah satu pengujian dialog intrinsik setelahnya. Analisis 7 berkas terkait: **No issues found**. Tidak ada build, deploy, atau perubahan database dalam tugas ini. **AAB 1.0.28 (29) yang dibuat sebelumnya belum memuat perbaikan ini.**

## Audit dan penyebab

Pemindaian sumber menemukan 61 berkas presentasi dengan 265 deklarasi `TextField`/`TextFormField` (jumlah deklarasi sumber, bukan jumlah field dinamis yang muncul di aplikasi). Area yang ditelusuri mencakup autentikasi/PIN, profil/pengaturan, kasir/pembayaran, katalog, pelanggan, pembelian/penerimaan, stok/opname, transfer, retur, utang-piutang, layanan, dan pengaturan cetak.

- Beberapa layar sengaja memakai `resizeToAvoidBottomInset: false` agar layout kasir dan modal tidak mengecil.
- Banyak form telah menambahkan padding keyboard, tetapi viewport masih menganggap area yang tertutup sebagai area terlihat. Padding sendiri belum menjamin fokus otomatis terlihat.
- Sebaliknya, menambahkan seluruh tinggi keyboard pada semua halaman dapat menggandakan inset pada Scaffold yang sudah melakukan resize.
- Tidak ditemukan penggantian `ScrollConfiguration` atau `scrollBehavior` lokal pada sumber aplikasi yang melewati konfigurasi bersama ini.

## Implementasi

`lib/presentation/widgets/pos_keyboard_visibility.dart` menyediakan dua bagian bersama:

1. `PosKeyboardScrollBehavior`: hanya area gulir vertikal yang memuat input aktif yang menyediakan ruang untuk bagian viewport yang benar-benar tertutup keyboard. Scaffold yang sudah berakhir di atas keyboard tidak diberi inset kedua. Gulir horizontal, gulir internal teks, dan daftar di belakang route aktif tidak ikut diubah. Penanda lingkup mencegah inset bertumpuk pada scrollable bersarang.
2. `PosKeyboardVisibility`: mengamati fokus dan ukuran keyboard, menunggu perubahan layout selesai, lalu memeriksa posisi input terhadap keyboard serta batas viewport. Hanya input yang belum terlihat yang diminta bergulir. Posisi fokus, isi controller, validasi, dan pemanggilan simpan tidak diubah.

Keduanya dipasang di `lib/app.dart`; bukan disalin ke setiap field. Listener dan timer dibersihkan ketika widget dilepas. Tidak ada polling atau request jaringan tambahan saat mengetik.

Untuk catatan multiline yang lebih tinggi daripada ruang tersedia, seluruh kotak tidak mungkin tampil sekaligus: baris/caret yang sedang diketik dipertahankan di atas keyboard dengan margin yang menyesuaikan ruang tersisa. Form tidak dipaksa bergantian menggulir ke atas/bawah kotak.

Dialog form besar memakai komponen stabil yang sudah ada. Dialog kecil standar tetap mengikuti pengukuran/penempatan native Flutter dan tidak mengalami kegagalan pengukuran akibat penanganan global ini.

Rujukan perilaku framework: [viewInsets menunjukkan batas keyboard](https://api.flutter.dev/flutter/widgets/MediaQueryData/viewInsets.html), [TextField memakai scrollPadding saat meminta agar fokus terlihat](https://api.flutter.dev/flutter/material/TextField/scrollPadding.html), dan [Scrollable.ensureVisible menangani scrollable leluhur](https://api.flutter.dev/flutter/widgets/Scrollable/ensureVisible.html).

## Temuan tambahan yang diperbaiki

| Temuan | Perbaikan / bukti |
|---|---|
| Pilihan pelanggan meluap pada HP 320 px dengan teks 140%. | Dropdown dibuat mengikuti lebar tersedia. |
| Aksi bawah form pelanggan dapat berdempetan/meluap. | Baris aksi memakai Wrap agar dapat berpindah baris. |
| Caret catatan QR masih tertutup 8 px saat ruang gulir sangat pendek. | Margin caret adaptif; pengujian koordinat caret sekarang lulus. |
| Implementasi awal bentrok dengan ukuran intrinsik AlertDialog tunai/catatan. | Pengukuran viewport tidak lagi memakai LayoutBuilder di jalur intrinsik; regresi pembayaran dan tes dialog native lulus. |

## Pengujian baru

### `test/pos_keyboard_visibility_test.dart` — 15 skenario

- Halaman overlay: field bawah terlihat tanpa menggeser header.
- Field atas yang sudah terlihat tidak mengubah posisi/offset.
- Dialog dan sheet tetap berukuran sama di portrait serta landscape (4 variasi).
- Scaffold resize tidak mendapat inset dua kali.
- Pindah fokus dengan keyboard sudah terbuka, perubahan tinggi keyboard, dan menutup keyboard.
- Gulir bersarang vertikal/horizontal tidak menggandakan inset.
- Catatan multiline panjang: caret terlihat dan isi tetap utuh.
- Route/modal aktif tidak mengubah daftar di belakangnya.
- Draggable sheet mempertahankan extent-nya.
- Rotasi layar saat mengetik mempertahankan teks dan mengukur ulang viewport.
- AlertDialog intrinsik tidak menyisakan ruang keyboard kedua setelah berpindah.
- Menutup halaman saat animasi keyboard tidak meninggalkan callback yang mengakses widget terlepas.

### `test/pos_keyboard_forms_integration_test.dart` — 11 skenario

- Form pelanggan kasir, detail layanan, dan pengaturan cetak QR yang sebenarnya pada 320×640 dengan teks 140%, 390×844, serta landscape 844×480 (9 variasi).
- Catatan barang pada editor transfer: bisa disentuh, fokus, tetap terlihat, isi tetap utuh, dan tidak mengirim penyimpanan.
- Jumlah fisik pada editor opname multi-rak: bisa disentuh/fokus di atas keyboard, menerima nol, dan tidak mengirim penyimpanan.

Semua memakai repositori fixture/fake; tidak ada request mutasi produksi. Ukuran keyboard disimulasikan melalui metrik Flutter dan posisi field/caret diperiksa, bukan hanya keberadaan widget.

## Regresi gabungan

115 PASS / 0 FAIL pada satu eksekusi:

```text
test/pos_keyboard_visibility_test.dart
test/pos_keyboard_forms_integration_test.dart
test/pos_keyboard_stable_dialog_test.dart
test/pos_keyboard_stable_sheet_test.dart
test/pos_cart_dialog_lifecycle_test.dart
test/pos_system_safe_area_test.dart
test/pos_shell_back_navigation_test.dart
test/pos_payment_mobile_layout_test.dart
test/pos_service_intake_fields_test.dart
test/pos_transfer_editor_test.dart
test/pos_opening_stock_page_test.dart
test/pos_opname_parity_test.dart
test/pos_catalog_form_initialization_test.dart
test/pos_quick_customer_open_test.dart
test/pos_customer_form_validation_test.dart
test/pos_business_logo_flow_test.dart
```

Sesudah eksekusi tersebut, satu tes tambahan `intrinsic AlertDialog does not retain a second keyboard reserve after moving` juga PASS. Tidak ada perubahan implementasi setelah regresi gabungan; tes tambahan menutup bukti inset native dialog.

Harness pembayaran dan stok awal kini mengaktifkan konfigurasi keyboard global yang sama dengan aplikasi. Regresi mencakup nominal tunai minimum, submit/loading pembayaran, split payment, pembatalan catatan, perlindungan simpan ganda stok awal, pemulihan posting, transfer, opname multi-rak, katalog, validasi pelanggan, pengaturan logo, safe area, dan navigasi kembali.

Analisis bersih pada `lib/app.dart`, komponen keyboard bersama, quick customer dialog, dan empat berkas tes yang berubah. Pemeriksaan whitespace diff juga lulus.

## Batas bukti dan penerapan berikutnya

- Belum diuji melalui keyboard fisik/OEM pada HP Android atau emulator dalam tugas ini. Pengujian ini adalah widget/integrasi komponen Flutter, bukan seluruh GUI produksi dari 265 deklarasi field.
- Keyboard mengambang/split yang tidak melaporkan area tertutup melalui inset tidak dapat dipetakan secara andal dari inset layar saja.
- Form baru harus tetap menyediakan scrollable untuk konten panjang; jangan menonaktifkan dekorasi scroll bersama pada seluruh form tanpa pengganti penanganan keyboard.
- Tidak ada perubahan API, stok, jurnal, idempotensi, PIN, atau permission. Perlindungan bisnis tetap berjalan pada alur yang sudah ada.
- Perlu build ulang APK/AAB untuk memasukkan perbaikan ini ke aplikasi terpasang. Paket rilis lama tidak ditimpa.

## Evaluasi hasil

Ringkasan: perbaikan global dan regresi komponen selesai; pembuktian keyboard perangkat nyata masih menjadi tindak lanjut. Nilai keseluruhan 4,0/5; tidak ada isu kritis tersisa pada tes akhir.

| Aspek | Nilai | Bukti dan peningkatan |
|---|---|---|
| Ketepatan | 4/5 | 116 tes lulus dan analyzer bersih; perlu pembuktian keyboard OEM nyata. |
| Kelengkapan | 4/5 | Penanganan terpasang di root dan 61 berkas input dipindai; bukan GUI menyeluruh setiap variasi field. |
| Kejelasan | 4/5 | Perilaku input biasa vs multiline dan batas pengujian dicatat; screenshot perangkat akan melengkapi bukti posisi. |
| Keterpakaian | 4/5 | Sumber dan tes siap digunakan; aplikasi terpasang memerlukan build baru. |
| Keringkasan | 4/5 | Satu penanganan bersama menggantikan patch per-field; pengujian geometri menambah kode tetapi menangkap gap nyata. |

Prioritas tindak lanjut: smoke test QA Android dengan Gboard/keyboard bawaan pada pelanggan, nominal tunai, detail layanan, dan baris terakhir opname/transfer setelah build baru. Pengguna dapat menilai dari bukti tes serta batas perangkat/paket yang dinyatakan, bukan diasumsikan semua keyboard produksi sudah dicoba.
