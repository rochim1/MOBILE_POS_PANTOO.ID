# Panduan awal berbentuk pop-up dengan sorotan area

Tanggal: 21 November 2026. Permintaan: ganti instruksi produk pertama dan
langkah berikutnya dengan pop-up yang memfokuskan area terkait di POS mobile.

## Perubahan

- Banner instruksi penjualan pertama diganti panduan kontekstual dengan latar
  diredupkan, bingkai sorotan, dan kartu penjelasan dekat kontrol yang dituju.
- Produk pertama menyorot Tambah Produk dan dapat membuka form beserta panduan
  form yang sudah tersedia.
- Stok awal menyorot pemilihan barang, lokasi, jumlah dan simpan. Field yang
  belum dirender tidak dijadikan sorotan pengganti; setelah memilih barang,
  pengguna dapat membuka ulang panduan untuk field tambahan.
- Buka kas menyorot toko dan kontrol pembukaan shift; kasir menyorot pencarian.
  Profil jasa tetap memakai aturan readiness yang sama dan melewati stok awal
  bila tidak dibutuhkan.
- Panduan dapat ditutup/dilewati dan dibuka lagi melalui “Panduan langkah ini”.
  Dilihat/dilewati tidak berarti persiapan operasional sudah selesai.
- Kemunculan otomatis dicatat per endpoint/instansi/akun/operator dan langkah.
  Tenant baru setelah reset mendapat panduan baru. Pengguna lama, snapshot
  offline, PIN terkunci, dan halaman yang tidak sesuai tidak mendapat pop-up ini.
- Panduan menunggu target tersedia dan tidak tampil di atas route modal atau
  keyboard aktif. Saat eligibility berubah, hanya route panduan miliknya yang
  ditutup; tidak melakukan pop pada route lain.
- Layout pop-up bersama diperbaiki: tombol memakai Wrap, tinggi dibatasi ruang
  layar yang tersedia, isi dapat digulir. Ini juga memperbaiki panduan setup
  manual lain yang memakai komponen sorotan yang sama.

Panduan tidak menjalankan simpan stok, membuka shift, atau pembayaran otomatis.
Guard bisnis, permission dan API tidak diubah. Tidak ada penulisan database,
reset akun tambahan, perubahan Vue, atau build APK pada pekerjaan ini.

## Bukti tes

Sepuluh tes widget/kontrak khusus lulus, mencakup:

1. Pop-up pertama, sorotan nyata, lewati, dan buka ulang.
2. Langkah serta identitas berbeda mendapat panduan masing-masing.
3. Disabled/legacy/offline/locked tidak menampilkan pop-up maupun launcher.
4. Eligibility dicabut menutup panduan tanpa error render target lama.
5. Target belum tersedia tidak menghasilkan sorotan acak atau menghalangi halaman.
6. Shell memakai komponen panduan baru, bukan banner lama.
7. Ukuran HP 320×480 dengan skala teks 1,5: tidak overflow, kartu tetap di layar,
   tombol tutup dapat dijangkau.
8. Hanya field yang sudah mounted masuk ke urutan sorotan.
9. Berikutnya/Kembali memindahkan sorotan ke kontrol nyata yang sesuai.
10. Ketuk area produk menutup panduan dan memanggil handler satu kali.

Rangkaian regresi pada perintah di bawah: **68 tes lulus, 0 gagal**.
Setelah itu dua skenario navigasi/ketukan di atas ditambahkan; seleksi fokus
diulang dan **10 tes lulus** (70 tes berbeda secara total, bukan 78 karena
delapan tes fokus sudah termasuk dalam rangkaian 68).

Cakupan komponen baru `pos_first_sale_guide.dart`: **81/81 baris (100%)** pada
run regresi. Komponen tur lama mencakup fungsi tambahan yang tidak seluruhnya
diuji ulang; angka ini bukan coverage seluruh aplikasi.

Analisis enam file produksi/tes yang disentuh: **No issues found**.

Checkpoint pada branch mobile aktif:

- `bcf404c` RED: komponen belum ada → `10dcb78` GREEN: enam tes lulus.
- `b568b5c` RED: overflow kanan pada HP/teks besar → `05ec12b` GREEN: tujuh tes lulus.
- `2857e2a` RED: field belum tampil masih dimasukkan → `2aa2523` GREEN: delapan tes lulus.

Perintah regresi:

```powershell
flutter test test/pos_first_sale_guide_test.dart test/pos_first_sale_flow_test.dart test/pos_opening_stock_page_test.dart test/pos_opening_stock_repository_test.dart test/pos_opening_stock_draft_test.dart test/pos_optional_setup_test.dart test/pos_cashier_shift_sync_test.dart test/pin_lock_responsive_test.dart test/pos_cashier_tour_contract_test.dart test/setup_operational_labels_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-google-access-20261120/guide-coverage.info' --reporter expanded
```

Bukti berada di `D:/my node app/zera/output/pos-google-access-20261120/guide-*`.
`guide-final.log` menyimpan run 68 tes, `guide-focus-final.log` menyimpan 10 tes
fokus terakhir; coverage disimpan terpisah dari data coverage pengguna.
Run awal mengungkap pembacaan target yang sudah inactive saat panduan dicabut;
guard route ditambahkan dan tesnya lulus. Fixture HP memakai ukuran view dan
device-pixel-ratio nyata, bukan hanya batas layout test.

## Batas verifikasi

Tes memakai Flutter widget runner, bukan GUI APK terpasang di emulator/HP.
APK sebelumnya belum memuat panduan ini. Belum diuji ulang melalui akun Google
atau server produksi; pekerjaan ini hanya mengubah presentasi panduan mobile.
