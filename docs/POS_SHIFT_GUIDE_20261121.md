# Perbaikan panduan shift kasir

21 November 2026. Permintaan: panduan shift hanya 1/1, perlu dilengkapi.

Penyebab: target pilihan toko muncul sebelum lookup shift selesai. Panduan
pertama menyaring target yang belum mounted, sehingga tombol buka shift dan
form kas hilang dari daftar sebelum sempat dimuat.

Perbaikan:

1. Periksa toko dan kasir.
2. Isi kas awal (nol diperbolehkan sesuai kebijakan; bukan omzet).
3. Catatan buka shift (opsional).
4. Periksa isian, tutup panduan, buka shift secara eksplisit dan tunggu hasil.

Cash dan catatan punya target widget tersendiri, bukan sorotan seluruh form.
Panduan otomatis menunggu keempat target siap (retry dibatasi 36 detik), jadi
jumlah tetap 1/4–4/4. Panduan dari menu setup memakai daftar yang sama dan
menunggu form siap maksimal 30 detik; jika tidak tersedia, menampilkan pesan,
bukan menyorot area kosong. Navigasi keluar/PIN terkunci menghentikan alurnya.

Status dilihat khusus langkah kas diperbarui ke cash-v2 agar pengguna baru yang
sempat melihat panduan tidak lengkap bisa memperoleh versi lengkap. Tidak ada
reset akun, perubahan aturan izin/kas, atau mutation bisnis baru.

## Bukti

- RED `36bf4f1`: API readiness/empat target belum tersedia.
- GREEN `3b47ac1`: 12 tes panduan lulus, termasuk form datang setelah dua detik.
- `52b492b`: integrasi form shift nyata dan panduan menu; **34 tes lulus**.
- Form nyata diuji pada 360×800; empat tahap dapat dilanjutkan dan scroll ke
  field sebenarnya tanpa error. Menyelesaikan panduan tidak membuka shift.
- Definisi panduan baru tercakup **10/10 baris (100%)**; bukan coverage seluruh app.
- Analisis tujuh file terkait: **No issues found**. Guard mounted eksplisit
  ditambahkan sebelum penggunaan context setelah menunggu form; 34 tes diulang
  dan tetap lulus.

```powershell
flutter test test/pos_shift_guide_test.dart test/pos_first_sale_guide_test.dart test/pos_cashier_shift_sync_test.dart test/pos_shift_cash_test.dart --no-pub --concurrency=1 --coverage --coverage-path='../output/pos-google-access-20261120/shift-guide-coverage.info' --reporter expanded
```

Log: `D:/my node app/zera/output/pos-google-access-20261120/shift-guide-*`.
Ini widget/integration tests Flutter, bukan APK yang dipasang di HP. Tidak ada
build APK/AAB, pengujian GUI native, atau perubahan database pada pekerjaan ini.
