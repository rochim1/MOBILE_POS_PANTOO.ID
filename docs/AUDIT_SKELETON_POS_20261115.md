# Pemeriksaan skeleton Pantoo POS — 15 November 2026

Perubahan terbaru masih di source, belum dibangun menjadi APK baru. APK 1.0.17+18 yang sudah tersedia dibuat sebelum perubahan pada audit skeleton lanjutan ini.

## Halaman yang diperbaiki pada pemeriksaan lanjutan

| Halaman | Perubahan |
|---|---|
| Riwayat transaksi | Kartu atau tabel sesuai pilihan tampilan; ordersRefreshing mengikuti request sebenarnya, menggantikan jeda tetap 500 ms. Data/draft tidak dikosongkan. Respons dari operator lama diabaikan. |
| Promo | Header kode/status, nilai diskon, metadata dan area aksi sesuai kartu promo; menggantikan kartu generik pendek. |
| Retur penjualan | Header/status, invoice asal dan nilai retur, serta area aksi. |
| Antrean offline | Referensi/status, waktu dan metadata, serta area aksi; padding mengikuti mobile. Pembatasan sinkronisasi langganan tetap berlaku. |
| Notifikasi | Daftar sliver dengan avatar, judul, isi dan waktu; header/filter tetap terlihat. |
| DP pembelian | Kartu nomor/nominal, supplier, status dan aksi di dalam scroll halaman. |
| Utang-piutang manual | Memisahkan loading daftar (filter, dua statistik, kartu dokumen) dan detail (ringkasan, riwayat, pembayaran). Indikator pengiriman pembayaran tetap berbeda dari loading data. |
| Piutang invoice POS | Daftar dan detail mengikuti susunan konten; menggantikan empat balok polos. |
| Pembelian langsung | Skeleton form dengan enam field dan area dokumen, menggantikan spinner satu layar. |
| Retur pembelian | Skeleton daftar saat memuat dan detail ringkasan saat pertama dibuka. Overlay proses simpan/persetujuan tetap dipertahankan. |
| Pembayaran hutang PO | Memuat kartu bukti invoice, ringkasan tagihan, lalu field pembayaran sesuai urutan konten. |
| Editor inventori/pembelian | Loading lookup mengikuti form, dengan jumlah kelompok field mengikuti tampilan pembelian mobile. |
| Pengaturan | Sidebar/dropdown kategori tetap terlihat; konten memakai skeleton field, tanpa item stok atau tab kasir. |
| Outlet | Menampilkan skeleton tile saat data dimuat, tanpa memperlihatkan keadaan kosong sementara. |
| Pesanan pada meja | Memakai skeleton tiket pesanan, menggantikan placeholder daftar umum. |

## Pemeriksaan sebelumnya

Kasir, katalog produk, pengelolaan meja, mutasi stok, penerimaan/selisih mutasi, serta laporan telah diperbaiki sebelumnya. Uji layout kasir dan konten tersebut dijalankan kembali pada pemeriksaan ini. Skeleton pembelian/receiving dan stok yang sudah mengikuti susunan kartu/formnya ditinjau dan dipertahankan. Indikator pada tombol simpan, pembayaran, pairing printer, dan pengiriman data bukan skeleton pemuatan halaman; indikator aksi itu tetap dipertahankan.

## Validasi

108 tes lulus: pos_record_skeleton_layout_test, pos_orders_refresh_test, pos_trade_workspace_test, pos_bloc_no_shift_test, pos_subscription_access_refresh_test, pos_cashier_skeleton_layout_test, pos_content_skeleton_layout_test. Layout diperiksa pada lebar 280/320/360/800/1280 sesuai suite dan skala teks hingga 1.6, termasuk konten embedded dan sliver. Tes refresh menunggu request lebih dari 500 ms, menangani kegagalan dan menolak respons operator lama. Analisis seluruh lib dan tes baru bersih. Log tersedia di output/pantoo-skeleton-remaining-tests.log dan output/pantoo-skeleton-remaining-analyze.log.

Tidak ada build/deployment APK atau pengujian native/HP fisik baru pada perubahan skeleton lanjutan ini. Tidak menyatakan seluruh variasi data atau seluruh layar dialog sudah diuji secara visual.
