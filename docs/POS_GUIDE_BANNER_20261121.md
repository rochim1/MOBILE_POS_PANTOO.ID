# Banner panduan selebar konten

Permintaan terbaru mengganti tombol kuning kecil di kanan dengan banner biru penuh seperti pemberitahuan.

- Komponen bersama `PosFirstSaleGuide` memakai lebar penuh, latar biru muda `#E3F2FD`, teks/ikon biru gelap `#0D47A1`, dan konten rata kiri.
- Seluruh area banner tetap menjadi tombol buka panduan, tinggi sentuh minimal 44. Tidak mengubah eligibility, urutan, atau tindakan operasional.
- RED `38c50cb`: tes warna baru gagal terhadap style kuning lama. Tes juga memeriksa lebar tombol sama dengan lebar komponen.
- GREEN: `flutter test test/pos_first_sale_guide_test.dart test/pos_shift_guide_test.dart test/pos_quick_customer_open_test.dart --no-pub --concurrency=1 --reporter expanded`.
- Pengujian mencakup pembukaan ulang, target siap/tidak siap, layar pendek dan teks besar, panduan shift empat langkah, serta form pelanggan tanpa request konfigurasi ulang.
- Build yang sempat berjalan dihentikan tepat sasaran sebelum melanjutkan build agar artefak tidak memakai style lama.
