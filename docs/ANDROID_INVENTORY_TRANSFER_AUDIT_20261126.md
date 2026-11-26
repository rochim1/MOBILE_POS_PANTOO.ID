# Audit inventori dan transfer Pantoo POS Android

Tanggal: 26 November 2026 (Asia/Jakarta).

## Pembaruan implementasi

Temuan audit di bawah adalah **rekaman sebelum perbaikan**. Perbaikan Android sudah diterapkan untuk bukti permintaan persisten, pemulihan dengan ID yang sama, pengaman navigasi, pilihan biaya, pagination lokasi/rak, dan respons pencarian terlambat. Fixture COA pengujian server juga sudah diperbaiki: seluruh 132 regresi server kini PASS. Regresi Flutter final mencakup 1.389 skenario: 1.388 langsung PASS, satu timeout analisis label kemudian PASS saat diulang tersendiri. Tidak ada kegagalan yang dibiarkan tanpa tindak lanjut; raw log dan rincian rerun dicatat dalam laporan perbaikan.

Rincian perubahan, bukti RED/GREEN, hasil pengujian terbaru, dan batas pengujian perangkat ada di [laporan perbaikan](ANDROID_INVENTORY_TRANSFER_FIX_20261126.md). Jangan menganggap tes karakterisasi lama di folder `output/inventory-audit-20261126` sebagai hasil validasi kode terbaru.

## Kesimpulan

**Kesimpulan saat audit awal, sebelum perbaikan:** belum dapat dinyatakan seluruhnya aman/siap produksi. Proteksi saldo, transaksi atomik, otorisasi warehouse, batch/seri, dan variasi routing yang diuji berfungsi. Namun, ada empat temuan terkonfirmasi pada pemulihan dan UI transfer Android. Dua di antaranya dapat membuat dokumen atau penerimaan terulang jika respons pertama hilang dan pengguna membuka ulang form.

Ini audit, bukan implementasi perbaikan. Tidak ada kode operasional diubah, tidak ada APK/AAB dibuat, dan tidak ada perubahan data produksi. Berkas tambahan hanya laporan dan tes pembuktian.

## Lingkup dan batas pengujian

- Ditelusuri: stok, koreksi darurat, handoff opname per batch/multi-rak, stok awal, editor transfer, kirim langsung/transit, penerimaan sebagian, selisih kurang/rusak, persetujuan, pembatalan, biaya dan kaitannya dengan jurnal.
- Tes Flutter memakai widget/repository tiruan; ini **bukan pengujian GUI pada Android yang terpasang**.
- Tes server menjalankan resolver sebenarnya pada MongoDB replica set sementara lokal, bukan database produksi.
- ADB berhasil dijalankan, tetapi daftar perangkat kosong. Pengguna kemudian memilih **lanjut audit kode dahulu**. Tidak dilakukan boot, instalasi, penghapusan data, atau pengujian pada HP.
- Tidak mengaudit seluruh master inventori, seluruh alur pembelian/retur, printer, kamera barcode, maupun seluruh kombinasi akun/profil melalui GUI Android. Pengujian terkait yang tercantum di bawah tidak menggantikan matriks GUI tersebut.

## Temuan terkonfirmasi

### INV-A01 — P1: identitas pembuatan transfer hilang setelah form dibuka ulang

Sumber:

- `lib/presentation/pages/pos/pos_transfer_editor_page.dart:37`: nonce dibuat dari waktu saat state form dibentuk.
- `lib/presentation/pages/pos/pos_transfer_editor_page.dart:176`: request ID berasal dari nonce dan payload.
- `lib/presentation/pages/pos/pos_transfer_editor_page.dart:188`: kegagalan hanya memberi pesan untuk memeriksa daftar; tidak menyimpan intent pending secara persisten.
- Backend `graphql/inventory_transfer/inventory_transfer.resolvers.js:773`: deduplikasi berdasarkan request ID pembuat, bukan kemiripan isi transfer.

Reproduksi:

1. Buat transfer dan tekan simpan.
2. Server sudah menyimpan, tetapi respons tidak sampai.
3. Retry pada form yang sama memakai ID yang sama: aman.
4. Keluar/buka ulang form dengan isi identik: ID berubah.
5. Server menganggapnya transfer lain dan membuat dokumen kedua.

Pembuktian: tes widget menggunakan halaman asli menghasilkan dua ID untuk input yang identik setelah remount. Tes integrasi resolver sebenarnya menerima ID yang berbeda sebagai dua dokumen dan menduplikasi hanya ID yang sama.

Dampak: draft/dokumen transfer ganda. **Menyimpan saja belum memindahkan stok**; stok berisiko terkirim dua kali jika kedua dokumen kemudian diproses. Kesamaan isi tidak boleh dijadikan satu-satunya dasar deduplikasi karena dua transfer sah memang bisa identik.

Rekomendasi: simpan intent dan ID stabil sebelum request; pertahankan saat hasil belum pasti meskipun form/aplikasi ditutup; konfirmasi berdasarkan identitas tersebut sebelum membuat intent baru. Scope harus mencakup endpoint, instansi, aktor dan jenis operasi.

### INV-A02 — P1: penerimaan sebagian dapat diulang setelah hasil pertama tidak terkonfirmasi

Sumber:

- `lib/presentation/pages/pos/pos_transfer_operation_page.dart:201`: ID penerimaan mencakup `doc['updatedAt']`.
- `lib/presentation/pages/pos/pos_transfer_operation_page.dart:255`: setelah gagal hanya muncul pesan untuk memuat ulang; payload/ID pending tidak disimpan persisten.
- Backend `graphql/inventory_transfer/inventory_transfer.resolvers.js:1209`: deduplikasi penerimaan berdasarkan `request_id`.

Reproduksi yang dibuktikan:

1. Transfer 5 unit; penerimaan fisik 1 unit dikirim.
2. Server mencatat 1 unit, respons hilang.
3. Pengguna membuka ulang form; revisi dokumen kini berubah.
4. Jika pengguna mengulang input 1 unit dengan mengira percobaan pertama gagal, ID baru terbentuk.
5. Server sah menerima permintaan baru terhadap sisa transfer: jumlah diterima menjadi 2 unit, padahal dalam skenario ini fisik hanya datang sekali.

Tes widget menunjukkan ID berubah untuk payload penerimaan sama setelah reload. Tes integrasi nyata membuktikan: ID lama diulang tetap 1 unit, ID baru untuk input sama menjadi 2 unit. Ini bukan pembuktian server salah menghitung; server tidak dapat membedakan intent baru dari retry ketika klien mengganti identitasnya.

Batas proteksi yang sudah benar: server tetap menolak jumlah melebihi sisa. Tidak ditemukan saldo negatif dari skenario ini. Penerimaan penuh atau seri unik dapat tertahan oleh status/identitas barang, tetapi **barang biasa dengan penerimaan sebagian masih berisiko**.

Rekomendasi: simpan bukti penerimaan pending beserta ID/payload sebelum kirim. Saat dibuka ulang, cocokkan dengan riwayat penerimaan berdasarkan ID, lalu tampilkan hasil yang telah tercatat. Jangan menyuruh pengguna menginput ulang sebelum intent sebelumnya terselesaikan. Pola serupa perlu diterapkan pada laporan selisih karena ID laporan juga menggunakan revisi dokumen; jalur laporan belum direproduksi khusus pada audit ini.

### INV-A03 — P2: tombol kembali dapat menutup form saat penyimpanan masih berjalan

Sumber: `lib/presentation/pages/pos/pos_transfer_editor_page.dart:447` membentuk `Scaffold` tanpa guard navigasi. `AbsorbPointer` hanya melindungi isi form, bukan tombol kembali Android atau tombol kembali AppBar.

Pembuktian: widget editor didorong ke route baru, simpan ditahan dengan request yang belum selesai, lalu dikirim event kembali sistem. Route berhasil tertutup sementara request tetap berjalan. Saat respons datang, state sudah tidak mounted sehingga hasil tidak ditampilkan.

Dampak: pengguna kehilangan konteks dan dapat memicu INV-A01. Tidak direproduksi crash pada tes ini.

Rekomendasi: cegah keluar selama request berjalan atau simpan intent yang dapat dipulihkan dan tampilkan konfirmasi keluar. Setelah timeout, sediakan pemeriksaan status yang jelas; jangan membuat pengunci tanpa jalan penyelesaian.

### INV-A04 — P2: opsi biaya yang ditawarkan Android ditolak server

Sumber:

- `lib/presentation/pages/pos/pos_transfer_editor_page.dart:807`: opsi `landed_cost`, label “Tambahkan ke nilai persediaan”, tetap tersedia.
- Backend `graphql/inventory_transfer/inventory_transfer.resolvers.js:759`: mode tersebut ditolak dengan pesan “Alokasi biaya transfer ke HPP per barang belum tersedia. Gunakan mode Beban.” Proteksi juga ada pada submit/kirim.

Pembuktian integrasi: input transfer dengan mode tersebut ditolak sebelum dokumen atau stok berubah.

Dampak: pengguna mengikuti opsi UI yang tersedia tetapi tidak dapat menyelesaikannya. Ini ketidaksesuaian kapabilitas UI–server, bukan kegagalan jurnal yang boleh diabaikan.

Rekomendasi: untuk kemampuan server saat ini, tampilkan hanya mode beban atau tandai opsi belum tersedia tanpa dapat dipilih. Jika landed cost hendak diaktifkan, implementasi akuntansi dan preview dampaknya harus selesai dahulu.

## Risiko skala/konkurensi yang perlu diuji lanjut

Temuan berikut berasal dari pembacaan kode, **belum direproduksi lewat GUI**:

- `lib/data/graphql/pos_stock_queries.dart:19`: pilihan lokasi stok hanya meminta 200 warehouse tanpa pagination lanjutan; `:95` juga membatasi detail saldo lokasi ke 200. Perusahaan dengan lebih banyak lokasi/rak dapat kehilangan sebagian pilihan. Berbeda dengan repository transfer yang sudah melakukan loop halaman warehouse.
- `lib/presentation/pages/pos/pos_inventory_page.dart:589`: pemuatan daftar dokumen tidak memiliki penanda versi request seperti `PosStockBloc`. Respons pencarian/filter lama berpotensi menimpa hasil request yang lebih baru. Uji dua respons dengan urutan selesai terbalik diperlukan.

## Hasil uji otomatis

### Flutter — regresi yang sudah tersedia

**63/63 PASS**, tanpa build APK:

```text
flutter test --no-pub --concurrency=2
  test/pos_transfer_parity_test.dart
  test/pos_transfer_editor_test.dart
  test/pos_transfer_operation_test.dart
  test/pos_stock_pagination_test.dart
  test/pos_stock_location_contract_test.dart
  test/pos_stock_model_test.dart
  test/pos_inventory_action_policy_test.dart
  test/pos_opname_parity_test.dart
  test/pos_opname_stock_handoff_test.dart
  test/pos_opening_stock_repository_test.dart
  test/pos_opening_stock_page_test.dart
  test/pos_inventory_route_context_test.dart
```

Antara lain membuktikan: pemilihan barang/batch terpagina, validasi jumlah dan konversi, serial tidak rangkap, batch tidak asing, sisa penerimaan dikurangi laporan pending, cegah klik simpan ganda selama request aktif, status stale tidak dapat membuka penerimaan selesai, koreksi per batch diarahkan ke opname, nol tetap nol, dan stok awal mempertahankan intent saat respons tidak pasti.

### Server — regresi yang sudah tersedia

Dua kelompok menjalankan **132 skenario unik: 129 PASS, 3 FAIL**.

Kelompok pertama: 69 skenario, 66 PASS/3 FAIL:

```text
inventory_transfer_p0.integration.test.js
inventory_transfer_receiving_audit.integration.test.js
inventory_transfer_receipt_resolution.integration.test.js
inventory_transfer_profile.contract.test.js
inventory_transfer_routing_filters.integration.test.js
inventory_opname_multirack.integration.test.js
manual_stock_atomic.test.js
```

Kelompok kedua: 63 skenario regresi tambahan, seluruhnya PASS:

```text
inventory_transfer_dynamic_rules.integration.test.js
inventory_transfer_three_flows.integration.test.js
inventory_transfer_optional_approval.integration.test.js
inventory_transfer_payment.integration.test.js
inventory_transfer_stock_allocation.test.js
inventory_transfer_batch_plan.test.js
```

Run kelompok kedua juga memuat lima tes audit versi awal sehingga output run tersebut adalah 68/68; lima tes audit itu tidak dihitung lagi dalam angka 132 regresi unik.

Yang teruji antara lain:

- Saldo terakhir diperebutkan dua pengiriman: hanya satu yang berhasil.
- Retry kirim/terima dengan ID sama tidak memindahkan stok dua kali.
- Transfer langsung, transit, persetujuan manual/otomatis, display dan lintas cabang.
- Routing historis tetap mengikuti snapshot setelah pengaturan profil berubah.
- Penerimaan kurang/lebih, saldo transit kurang, dan pembatalan sebagian.
- Batch dengan nomor sama tetapi kedaluwarsa berbeda dan seri aktual tetap terpisah.
- Pelapor tidak memutuskan laporannya sendiri; izin scrap terpisah untuk kehilangan.
- Barang rusak menuju karantina; kehilangan memakai biaya aktual dan jurnal yang sesuai.
- Akses tenant/warehouse dan periode terkunci tidak dapat dilewati.
- Opname multi-rak, batch/nol, reservasi berubah setelah snapshot, dan posting bersamaan.

### Penjelasan tiga kegagalan tes lama

Ketiganya berada di `tests/manual_stock_atomic.test.js`:

1. Koreksi manual normal.
2. Injeksi kegagalan audit jurnal.
3. Dimensi cabang/proyek pada koreksi.

Fixture file itu tidak membuat COA. Pemeriksaan Finance terbaru menolak akun `1100` yang belum ada, sehingga tes berhenti sebelum mencapai perilaku yang ingin diuji. **Tidak disimpulkan sebagai kehilangan stok/jurnal atau bug produksi yang telah terbukti.** Fixture lama tetap perlu diperbarui; audit ini tidak mengubahnya.

Tes audit tambahan menggunakan `ensureDefaultCoa` seperti onboarding: koreksi 10 menjadi 12 berhasil dan jurnal debit/kredit masing-masing 200. Tanpa COA, koreksi ditolak dan seluruh saldo/history tetap semula. Setelah COA tersedia, injeksi kegagalan audit jurnal juga mengembalikan saldo serta jurnal secara atomik. Pengujian dimensi enam field pada fixture lama belum diulang dengan seed COA yang diperbaiki.

### Tes pembuktian temuan — bukan PASS kesiapan fitur

- `output/inventory-audit-20261126/audit_characterization_test.dart`: **3/3 reproduksi terkonfirmasi** pada widget Flutter asli: create setelah reopen, navigasi kembali saat pending, dan penerimaan sebagian setelah reopen. Server tiruan digunakan untuk menahan/menghilangkan respons.
- `presensi_zera_BE/output/inventory-audit-20261126/audit.integration.test.js`: **6/6 pemeriksaan audit sesuai ekspektasi**, terdiri dari tiga pemeriksaan koreksi/rollback dan tiga pembuktian gap create, penerimaan, serta landed cost terhadap resolver dan database uji nyata.

Tes bertanda `AUDIT GAP` sengaja mengharapkan perilaku bermasalah saat ini agar bukti dapat direproduksi. Hijau pada tes pembuktian **tidak berarti celah sudah diperbaiki**.

### Analisis statis

`flutter analyze --no-pub` pada delapan target inventori/transfer (termasuk folder bloc stok): **No issues found**, 32,3 detik. Ini tidak membuktikan kebenaran alur bisnis.

Pada shutdown beberapa replica set sementara, runner mengeluarkan log `ECONNRESET`; tidak menambah kegagalan assertion. Hasil exit code run pertama tetap gagal karena tiga tes fixture COA di atas, bukan dinyatakan seluruhnya PASS.

## Urutan perbaikan yang disarankan

1. Intent persisten dan pemulihan per operasi untuk create transfer, penerimaan, lalu laporan selisih. Gunakan kembali ID yang sama sampai hasil final terkonfirmasi.
2. Lindungi navigasi saat request aktif; berikan status dan jalur penyelesaian setelah timeout.
3. Selaraskan opsi biaya Android dengan kemampuan server.
4. Perbarui fixture koreksi stok sesuai prasyarat Finance, tambah tes respons terbalik dan pagination lokasi/rak.
5. Ulangi GUI Android versi terbaru: normal, airplane mode/timeout setelah server commit, tutup/buka aplikasi, dua akun gudang, penerimaan bertahap, batch/seri, batal, biaya dan opname.

Pengaman pemulihan sebaiknya membatasi **intent transfer yang belum pasti**, bukan ikut mengunci seluruh kasir/penjualan. Jangan menghapus bukti pending hanya karena dianggap data lama.
