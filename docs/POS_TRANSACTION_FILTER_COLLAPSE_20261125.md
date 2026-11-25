# Filter transaksi HP — 25 November 2026

Permintaan: pencarian invoice, status, periode, dan kasir menghabiskan ruang daftar transaksi pada HP; jadikan panel yang dapat dibuka/tutup melalui tombol.

## Hasil

- Lebar area halaman <760dp: empat field tertutup saat awal, tombol Filter dengan chevron dan target sentuh minimal48dp. Badge menunjukkan jumlah filter aktif.
- Lebar≥760dp: filter tetap terlihat seperti sebelumnya, kategori/sidebar dan data transaksi tidak diubah.
- Tutup panel tidak mereset query/pilihan; controller pencarian dipertahankan dan dilepas saat halaman ditutup. Keyboard kehilangan fokus saat collapse.
- Panel terbuka dapat digulir pada layar pendek/teks besar; tinggi dibatasi agar daftar tetap mempunyai ruang.
- Expand/collapse hanya state UI lokal, tidak memanggil refresh API, tidak mengubah invoice, pembayaran, permission, pagination, atau hasil filter.
- Label memakai terjemahan Filter yang sudah ada; tidak menambahkan sumber terjemahan baru.

## TDD dan bukti

Source: `lib/presentation/pages/pos/pos_order_page.dart`; test: `test/pos_transaction_filter_collapse_test.dart`.

- RED `452393e`: **4kontrol desktop PASS/8FAIL**, karena mode HP belum memiliki toggle dan filter tidak dapat disembunyikan. Test nyata terkompilasi/dijalankan, bukan kegagalan dependency.
- GREEN `92f4bc4`: **12/12PASS**. Satu assertion fixture search diperjelas karena teks invoice tampil di EditableText dan kartu sekaligus; sesudah collapse tetap harus tepat satu hasil. Assertion pemfilteran/persistensi tidak dihapus.
- Regresi enam suite: **77/77PASS**, exit0,13detik, `output/operational-readiness-20261125/transaction-filter-regression.log`.
- Dua berkas terkait: `dart analyze --fatal-infos` **No issues found**, exit0, `transaction-filter-analyze.log`.
- `git diff --check` bersih. Perubahan pengguna pada BLoC, shell, versi, coverage dan tes lain tidak di-stage/reset.

```text
flutter test --no-pub --concurrency=2 --coverage --coverage-path=output/operational-readiness-20261125/transaction-filter-final-lcov.info test/pos_transaction_filter_collapse_test.dart test/pos_order_detail_date_test.dart test/receipt_share_contract_test.dart test/pos_category_navigation_test.dart test/pos_orders_refresh_test.dart test/pos_record_skeleton_layout_test.dart
dart analyze --fatal-infos lib/presentation/pages/pos/pos_order_page.dart test/pos_transaction_filter_collapse_test.dart
```

| Jaminan | Bukti widget |
|---|---|
| Default HP tertutup, kartu pertama tidak terdorong filter; desktop tetap terbuka |360×568/390×844/760×800/1280×900 × ID/EN |
| Query tetap berlaku saat ditutup/dibuka dan tidak menambah RefreshOrders | Pencarian INV-B, hasil INV-A hilang, badge1, controller tetap INV-B, init refresh tetap1 |
| Status/kasir/periode persisten dan badge benar |Batal+QA B+Hari Ini, collapse→reopen, badge3 |
| Panel pendek/teks besar dapat digulir tanpa overflow |360×420, skala teks1,4, field kasir dapat dijangkau |
| Resize tidak menghapus query/keadaan collapse HP |390→1280→390, query tetap, desktop terbuka dan HP kembali tertutup |

Coverage scope toolbar/panel **52/52baris (100%)** dari lcov lokal, bukan persentase seluruh halaman besar yang juga berisi print/receipt/payment. Regresi mencakup kategori, refresh, struk, tanggal dan skeleton. Tidak ada tes dihapus/skip.

## Batas dan handoff

Pengujian adalah widget/renderer Flutter nyata dengan BLoC fixture, bukan GUI APK pada HP pengguna atau transaksi backend nyata. Tidak melakukan build APK/AAB, hot restart proses pengguna, deployment, atau mutasi data. **APK1.0.22+23 sebelumnya belum memuat perubahan ini maupun patch pemulihan pembayaran sesudah build tersebut.** Untuk distribusi Android diperlukan build baru; di sesi pengembangan gunakan hot restart agar perubahan tampil.

Evaluasi: akurasi4/5 (runtime77 dan analyze, belum visual perangkat), kelengkapan4/5 (toggle/persistensi/responsif tertutup, build di luar permintaan), kejelasan5/5, tindak lanjut4/5 (source siap tetapi aplikasi terpasang perlu diperbarui), keringkasan4/5 (detail di dokumen, final ringkas). Rata-rata4,2/5. Prioritas berikutnya: tampilkan perubahan pada build/sesi Android terbaru; tidak mengklaim APK lama sudah berubah. Self-check: hasil sesuai permintaan ruang daftar yang lebih lega tanpa mengubah filter bisnis. Tidak ada isu kritis pada perubahan teruji; serahkan source dengan batas pemasangan yang jelas.
