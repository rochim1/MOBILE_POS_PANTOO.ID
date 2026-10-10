# Catatan Rilis 1.0.3 (Build 4)

Tanggal rilis: 10 Oktober 2026

## Pembelian dan pembayaran PO

- Pembayaran hutang PO dapat dicatat dari mobile setelah syarat penerimaan barang terpenuhi. Metode yang tersedia mengikuti pencatatan keuangan: transfer bank, tunai, giro, dan cek.
- Status pembayaran dan sisa hutang tampil di kartu PO mobile. Pengguna yang memiliki akses ke hutang dapat melihat riwayat pembayaran.
- Mobile menyembunyikan aksi bayar untuk hutang yang lunas atau dibatalkan. Pembatalan dan koreksi pembayaran dilakukan dari Finance web.
- Di Finance web, pembayaran yang salah dapat dibatalkan dengan alasan. Sistem menyimpan riwayat awal, mencatat jurnal pembalik, memulihkan saldo hutang dan termin, serta memungkinkan pembayaran yang benar dicatat kembali.
- Detail PO Inventory menampilkan status pembayaran, jumlah yang telah dibayar, dan sisa hutang bagi pengguna dengan izin melihat hutang.
- Status dan tanggal pembayaran termin diperbarui setelah pembayaran dibatalkan.

## Catatan akses

- Pencatatan dan pembatalan pembayaran di Finance memerlukan izin `payables:update` atau `payables:approve`.
- Mobile mengikuti izin melihat hutang dan mencatat pembayaran yang diberikan kepada pengguna.

## Artefak Android

- Flavor: production
- Versi: 1.0.3 (version code 4)
- Berkas: `build/app/outputs/bundle/productionRelease/app-production-release.aab`
