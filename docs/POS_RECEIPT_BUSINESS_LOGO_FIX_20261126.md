# Logo profil usaha pada struk — 26 November 2026

## Permintaan dan temuan

Logo yang disimpan di Pengaturan POS → Profil Usaha harus tampil pada struk selama pilihan `Tampilkan Logo` aktif.

Server sudah menyimpan logo profil dan mengembalikannya melalui `GetPOSReceiptData.instansi.logo`; tidak diperlukan migrasi atau perubahan database. Dua gap mobile ditemukan:

1. Mode cepat Bluetooth hanya mengirim teks sehingga logo tidak ikut.
2. Cache struk tidak diperbarui ketika profil usaha disimpan dan belum dibatasi sesi.

## Perbaikan

- Simpan profil usaha memperbarui nama, telepon, alamat, dan logo di cache struk, termasuk penghapusan logo secara eksplisit.
- Cache dan permintaan struk dipisahkan menurut endpoint/instansi/akun/operator. Respons lambat yang dimulai sebelum penyimpanan profil tidak menimpa logo baru.
- Cache hanya menjadi fallback kegagalan koneksi, bukan penolakan izin server.
- Renderer PDF dan cetak cepat menggunakan pengunduh logo bersama: menghormati `show_logo`, batas file 5 MB, batas dimensi 16 juta piksel, waktu tunggu 5 detik, dan cache memori maksimum 16 URL. Unduhan gagal tidak disimpan sehingga dapat dicoba lagi pada cetak berikutnya.
- Bluetooth mode cepat menambahkan logo monokrom terpusat, maksimum 272×128 dot (sekitar 34×16 mm pada 203 dpi), dalam **satu pengiriman yang sama** dengan teks struk. Bagian transparan dipadukan dengan putih agar tidak menjadi kotak hitam.
- Logo rusak/kosong/terlalu besar tidak menggagalkan teks nota. Tidak ada retry otomatis setelah data dikirim ke printer.
- PDF, PNG yang berasal dari PDF, dan cetak ulang yang menggunakan renderer bersama tetap menggunakan logo yang sama. Tidak mengubah stok, jurnal, nilai pembayaran, atau transaksi.

## Bukti TDD dan pengujian

Journey diturunkan dari permintaan pengguna, tanpa dokumen rencana tambahan.

- RED `6001c53`: tes baru merujuk jalur yang belum tersedia (`onSaved`, `updateCompany`, `logoBytes`); kompilasi gagal pada ketiga kontrak tersebut. Ini compile-time RED, bukan klaim reproduksi GUI perangkat.
- GREEN `04164f5`: lima tes inti lulus setelah implementasi. Fixture tes dilengkapi cache GraphQL yang menerima respons parsial, pendaftaran plugin Bluetooth, dan pencocokan sintaks objek gambar PDF.
- Regresi akhir: **55 PASS**, 7 berkas tes, 13 detik, exit 0.
- Analisis 7 berkas: **No issues found**, exit 0.
- Cakupan baris executable yang berubah terhadap `6001c53`: **79/91 = 86,81%**. Bukan cakupan seluruh aplikasi. Registrasi dependensi belum dieksekusi oleh tes terisolasi (0/9); callback penyimpanan ke cache diuji melalui integrasi repository.

| Jaminan | Tes/bukti | Hasil |
|---|---|---|
| Logo diganti/dihapus langsung memperbarui struk, template tetap terjaga | `pos_receipt_logo_test.dart` | PASS |
| Cache tidak membawa logo ke akun/instansi berbeda | `pos_receipt_logo_test.dart` | PASS |
| Respons lama tidak menimpa logo yang baru disimpan | `pos_receipt_logo_test.dart` | PASS |
| Fallback offline sesi sama, bukan untuk FORBIDDEN | `pos_receipt_logo_test.dart` | PASS |
| Pengaturan show-logo tersimpan tanpa menghapus logo usaha | `pos_receipt_logo_test.dart` | PASS |
| PDF benar-benar memiliki objek gambar saat logo aktif, tidak saat dimatikan | `pos_receipt_logo_test.dart` | PASS |
| Satu pengiriman Bluetooth berisi raster logo dan total teks | Mock kanal plugin, batas ukuran raster diperiksa | PASS |
| Logo kosong/rusak/oversize tetap menghasilkan teks nota | Tiga variasi fixture byte | PASS |
| Piksel transparan tidak menjadi bidang hitam | Fixture gambar transparan, byte raster diperiksa | PASS |
| Tombol Cetak Struk di halaman pembayaran mengirim logo dan invoice | Widget UI + repository + pengunduh HTTP + kanal printer tiruan | PASS |
| Ukuran nota 58/80 mm, label, uang, dan halaman sukses tetap aman | Enam berkas regresi terkait | PASS |

Perintah yang dijalankan dari root mobile:

```powershell
flutter test --no-pub --coverage --coverage-path=output/operational-readiness-20261125/receipt-logo-lcov-final-20261126.info test/pos_receipt_logo_test.dart test/pos_receipt_layout_test.dart test/pos_receipt_printer_density_test.dart test/pos_business_profile_repository_test.dart test/pos_success_print_nonblocking_test.dart test/receipt_share_contract_test.dart test/pos_short_labels_test.dart --reporter expanded
dart analyze --fatal-infos lib/domain/repositories/pos_business_profile_repository.dart lib/domain/repositories/pos_receipt_repository.dart lib/injections.dart lib/core/receipt/pos_receipt_document_builder.dart lib/core/receipt/pos_receipt_print_service.dart lib/presentation/pages/pos/pos_success_page.dart test/pos_receipt_logo_test.dart
```

Log:

- `output/operational-readiness-20261125/receipt-logo-final-20261126.log`
- `output/operational-readiness-20261125/receipt-logo-analyze-final-20261126.log`
- `output/operational-readiness-20261125/receipt-logo-lcov-final-20261126.info`

Percobaan regresi pertama 54 PASS/1 FAIL karena variabel platform Android pada harness tes belum dipulihkan sebelum pemeriksaan invariant Flutter. Diperbaiki pada harness; assertion logo dan invoice dipertahankan, hasil akhir 55 PASS.

## Batas verifikasi

- Tidak build APK/AAB dan tidak mengubah aplikasi Play Store.
- Tidak mencetak pada printer fisik atau menguji GUI emulator. Kanal printer ditiru; kompatibilitas dan kontras logo pada printer/kertas nyata perlu pemeriksaan setelah pemasangan versi baru.
- Tidak menulis data produksi dan tidak mengubah frontend Vue.
- Cache logo hanya memori. Setelah aplikasi benar-benar ditutup, logo perlu diunduh lagi; saat tidak tersedia, teks nota tetap bisa dicetak.

## Evaluasi hasil

Rata-rata 4,0/5: akurasi 4 (55 tes lulus; printer fisik belum diuji), kelengkapan 4 (profil → cache → PDF/Bluetooth termasuk kegagalan; belum rilis paket), kejelasan 4 (batas simulasi dicatat), keterpakaian 4 (kode siap diuji perangkat setelah build), keringkasan 4 (laporan rinci terpisah dari ringkasan pengguna). Perbaikan lanjutan bernilai tertinggi: cetak fisik 58/80 mm setelah build baru. Pengguna semestinya dapat menyetujui penilaian ini karena tidak mengklaim pembaruan Play Store atau hasil perangkat yang belum dijalankan.
