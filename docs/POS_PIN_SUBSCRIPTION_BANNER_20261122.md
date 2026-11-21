# Banner langganan pada PIN — 22 November 2026

## Permintaan dan batas perubahan

Sembunyikan banner langganan pada layar PIN, tetapi tetap periksa akses di belakang layar dan pertahankan perlindungan langganan. User journey diturunkan langsung dari permintaan ini, tanpa perubahan aturan bisnis atau server.

`PosSubscriptionBoundary` mendengarkan status `AppLockCubit`. Banner dan penyesuaian padding atas hanya ditampilkan bila PIN tidak terkunci. Ketika PIN dibuka, banner yang masih relevan kembali tampil; bila dikunci lagi, banner disembunyikan kembali.

Tidak ada perubahan pada `PosSubscriptionService`, deadline server, cache identitas, izin offline, mutation guard, overlay pembatasan akses, atau pengecualian struk transaksi yang sudah diterima server. Tidak ada early-return melewati perlindungan hanya karena PIN terkunci.

## Bukti pengujian

- RED `f77d955`: tes widget mereproduksi teks “Last known subscription status” dan “Read-only mode” tetap terlihat di PIN.
- GREEN `7008efc`: tiga skenario awal lulus setelah perubahan presentasi minimal.
- Tes lanjutan mencakup batas offline 24 jam serta pembaruan saat aplikasi kembali ke foreground.

| Jaminan | Bukti | Hasil |
| --- | --- | --- |
| PIN asli tampil penuh tanpa banner/detail langganan | `pos_subscription_pin_banner_test.dart` | PASS |
| Polling lima menit dan refresh saat resume tetap bekerja saat banner tersembunyi | tes widget dengan service asli dan sumber respons simulasi | PASS |
| Banner kembali setelah unlock dan hilang saat relock | tes widget reaktif | PASS |
| Status billing-only tetap memblokir penjualan online/offline dan interaksi workspace | guard mutation, offline guard, serta overlay | PASS |
| Mode read-only tetap menolak penjualan dan tidak berubah menjadi full | guard dan banner setelah unlock | PASS |
| Menyembunyikan banner tidak memperpanjang grant offline yang sudah kedaluwarsa | jam tepercaya dimajukan 25 jam | PASS |
| Verifikasi PIN dan tutup shift tetap merupakan aksi pemulihan yang diizinkan | guard mutation | PASS |
| Status tidak diketahui, cache rusak/beda operator, perubahan jam perangkat dan receipt tetap aman | regresi service/subscription yang sudah ada | PASS |

Perintah yang dijalankan:

```text
flutter test test/pos_subscription_pin_banner_test.dart test/pos_subscription_test.dart test/auth_subscription_preparation_test.dart test/pos_subscription_access_refresh_test.dart test/pin_lock_responsive_test.dart --no-pub --concurrency=1 --coverage --coverage-path=../output/pos-pin-subscription-coverage-20261122.info --reporter expanded
```

Hasil: **44 tes PASS**, tidak ada tes dilewati. Log: `../output/pos-pin-subscription-regression-20261122.log`.

Cakupan seluruh baris executable yang berubah pada kondisi banner/padding dan selector status PIN: **100%**. Cakupan service akses yang tidak diubah: 172/215 (80%). Seluruh file boundary: 131/198 (66,2%); bagian pemulihan operasional lama yang tidak disentuh belum seluruhnya tercakup oleh suite terarah ini. Angka tersebut bukan klaim pengujian seluruh aplikasi.

Analisis terarah: `dart analyze lib/presentation/widgets/pos_subscription_boundary.dart test/pos_subscription_pin_banner_test.dart`.

## Batas verifikasi

Pengujian widget memakai layar PIN dan service langganan asli, tetapi respons server, secure storage dan clock disimulasikan. Tidak mengakses database produksi, menguji HP fisik, atau membangun ulang APK/AAB. Artefak 21 November yang sudah diberikan sebelumnya belum memuat perubahan ini.
