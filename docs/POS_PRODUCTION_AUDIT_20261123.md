# Audit POS: pembelian, stok, penjualan dan multibahasa

Tanggal: **23 November 2026**, Asia/Jakarta.

Pembaruan lanjutan: [GUI jasa/offline, bahasa dan overlap tombol Bayar](POS_FOLLOWUP_GUI_20261123.md). Penghambat syntax FAQ/generator yang dicatat di laporan awal ini sudah diperbaiki; gate final lanjutan1.004Flutter/408web dan compile972/0error. Status historis di bawah tidak dihapus dan tidak otomatis menjadi bukti seluruh matriks GUI lulus.

**Hasil: PASS untuk rantai prioritas yang diuji melalui GUI Android dan Chrome, ditambah tes otomatis di bawah. Ini bukan sertifikasi bahwa seluruh produk/profil/perangkat bebas bug.** Tidak ada transaksi, migrasi, reset akun atau deploy ke database produksi.

## Ringkasan akhir

| Pemeriksaan | Hasil aktual | Bukti |
| --- | --- | --- |
| Seluruh suite Flutter | **995/995 PASS**, exit0 | [Log](../output/production-audit-20261123/mobile-tests-complete.log) |
| Flutter analyze seluruh proyek | **No issues found**, exit0, 48 detik | [Log](../output/production-audit-20261123/mobile-analyze-complete.log) |
| Web POS/inventori/i18n terpilih | **401/401 PASS**, exit0 | [Log](../../front_end_template/docs/production-audit-20261123/web-tests-complete.log) |
| Backend kontrak klien/middleware/Finance | **44/44 PASS**, 0 skip/cancel | [Log](../../presensi_zera_BE/artifacts/pos-production-audit-20261123/contracts-final.log) |
| Backend integrasi replica set terisolasi | **146/146 PASS**, 0 skip/cancel | [Log](../../presensi_zera_BE/artifacts/pos-production-audit-20261123/critical-integration-final.log) |
| Audit ekstraksi terjemahan | 1.298 berkas, **0 teks hasil ekstraksi hilang dari katalog**; katalog web/server identik | [Audit](../../front_end_template/docs/production-audit-20261123/i18n-complete/audit.json) |
| Kompilasi transformasi terjemahan Vue | 971 komponen, **0 error baru**; satu error lama di FAQ backup non-POS | [Log](../../front_end_template/docs/production-audit-20261123/i18n-compile-complete.log) |
| Rekonsiliasi data GUI Android + web | **PASS**, stok, nilai persediaan, jurnal, request unik dan penutupan shift | [Hasil final](../../output/production-audit-20261123/inventory-verify.json) |

Hasil baseline: Flutter 972 PASS/19 FAIL, lalu 991 PASS setelah penyesuaian fixture/kontrak; web 391 PASS/2 FAIL. Kegagalan tes lama dipisahkan dari bug produk, bukan ditutup dengan menghapus tes. Angka akhir bertambah karena regresi baru. Coverage seluruh aplikasi tidak diukur ulang; jumlah tes lulus bukan persentase coverage.

## Lingkungan dan batas aman

- Mobile Flutter Android asli pada emulator5556, AVD di drive D; package QA terpisah `id.pantoo.pos.qa.service`. Update memakai install -r, **tanpa wipe data/sesi aplikasi**.
- APK debug QA final SHA256: `72cc3231a04bf321830ebcfee0146f950bca944227cd0a2e4d7c5fb198b7b566`. Ini bukan APK/AAB rilis.
- Chrome tersambung yang sudah tersedia; pembuat/admin dan approver memakai sesi browser terpisah. Tidak mengganti pengujian ini dengan browser Playwright baru.
- Vue5189 → API loopback18123. Android memakai endpoint QA18122 yang diarahkan ke18123. Server awal18122 tetap hidup sebagai pemilik MongoMemoryReplSet.
- Database disposable `service_intake_gui_20261122`, tenant `6b04242bfa25cacd45125b2c` / QA Layanan Adaptif2211. Helper menolak URI non-loopback atau nama tenant/database yang berbeda.
- Perubahan pengguna dan pekerjaan paralel pada bloc, shell/startup loader, kategori/grid, versi, label field, coverage, service worker dan katalog yang sudah kotor dipertahankan; tidak direset atau dijadikan perubahan milik audit ini.
- Tes final memeriksa **worktree aktif termasuk perubahan pengguna**, bukan menjanjikan hasil yang sama dari clean checkout HEAD tanpa perubahan tersebut.
- Data produk, supplier, nama toko/warehouse, angka uang dan kode API tidak diterjemahkan sebagai data.
- Modal awal shift fixture Rp100.000. Tidak mengubah konfigurasi toko/instansi produksi. Density emulator sementara320 untuk viewport360dp; **sudah dipulihkan ke480** (physical420, override480). Profil/fitur QA juga sudah dipulihkan ke jasa sesuai snapshot awal; verifier setelah pemulihan tetap PASS dan dokumen audit dipertahankan.

## Bug produk yang ditemukan dan diperbaiki

| Temuan | Perbaikan | Pembuktian |
| --- | --- | --- |
| **P0: empat field lifecycle PO belum memakai auth middleware**, sehingga pengguna sah mendapat “Anda belum terautentikasi” ketika mencatat pengiriman | Daftarkan BulkDeleteInventoryPurchase, MarkInventoryPurchaseSentToSupplier, RecordSupplierPurchaseAcknowledgement, CloseInventoryPurchaseWithVariance sebagai private Authorized; permission dan tenant guard tetap | Registry test semua field Query/Mutation purchase menolak request tanpa bukti sebelum resolver; 8 gate PASS. GUI catat pengiriman sesudah patch berhasil. Tidak mengklaim GUI bulk-delete diuji |
| **P0: editor inventori Android berhenti pada skeleton** setelah lookup | Route Navigator/dialog meneruskan PosBloc yang sama dari shell, bukan membuat identitas/policy permisif baru | Widget test route asli membuktikan identitas sama dan tidak ikut disposed saat pop; GUI PO termuat dan berhasil disimpan |
| **P0: 1 box12unit masih berharga Rp3.000** di PO Android | Harga per satuan terpilih dikonversi sesuai faktor, menjaga harga manual per unit dasar ketika satuan diganti lagi; key field harga mengikuti satuan | Widget editor nyata: box Rp36.000, edit Rp36.012 → unit Rp3.001. GUI box Rp36.000 → PO → GRN12unit; HPP dasar tetap Rp3.000 |
| Dropdown termin/acuan jatuh tempo meluber di layar ringkas | Dropdown menyesuaikan lebar tersedia | Widget editor400px tanpa RenderFlex exception; GUI360dp dapat lanjut |
| **P1: timeline PO “Invalid date” / tahap selesai ditulis “Belum”** | Parse epoch string detik/ms serta ISO valid; tanggal invalid tampil “-”; done tanpa timestamp tampil “Selesai” | 3 tes targeted PASS; detail PO web tidak lagi menampilkan Invalid date |
| **P1: jasa tanpa stok dihitung sebagai stok habis/rendah**, termasuk filter semua lokasi | Statistik mengabaikan produk tanpa pelacakan; label “Tidak dilacak”; filter status memakai API stock-aware juga tanpa filter lokasi | Tes service/deposit/tracked item PASS; GUI EN menampilkan4 “Not tracked”,0 stock-out dan filter Out of Stock0baris |
| **P1: salinan EN tidak lengkap** pada panduan, konfirmasi PO, hasil pembayaran, tarif jasa dan rekonsiliasi kas | ARB/bridge mobile serta47 sumber web ID→EN yang ditinjau; potongan dinamis diterjemahkan sebelum digabung, bukan menerjemahkan nama supplier atau enum | Tes bahasa/placeholder, widget konfirmasi PO serta10metode bayar; GUI EN Android/web hasil bayar Cash; label Opening cash/Actual sesuai |
| **P1: hasil pembayaran mobile menampilkan kode TUNAI/E_WALLET** | Peta label tampilan/share struk saja, nilai paymentMethod untuk API tetap |11tes success/nominal/non-blocking PASS; invoice0004 pada APK final menampilkan Cash |

Checkpoint utama: backend RED `c031cbdb` → fix `d8150b46`; web tanggal `6e7e6cc6` → `898bfa14`; Android route `8cd6b38` → `1b36608`; konversi `cc41b38` → `1e21036`; label pembayaran `6e94c9a` → `d147659`. Log RED dan GREEN disimpan dalam folder bukti masing-masing repositori.

## GUI end-to-end: tindakan nyata

Semua dokumen berikut dibuat lewat layar klien, bukan disisipkan langsung oleh verifier.

| Tahap | Hasil |
| --- | --- |
| Login Android + PIN | PASS: username/password, gerbang PIN123456; update APK tetap meminta PIN. Tidak melewati verifikasi |
| Shift aktif saat masuk kasir | PASS: toko/shift aktif langsung dipakai, tidak memilih toko ulang |
| Web PO0001 | PASS: draft2unit × Rp3.000, submit, approver berbeda menyetujui; stok tetap40 sebelum penerimaan |
| Web catat pengiriman | PASS sesudah fix middleware; kanal cetak hanya catatan internal QA, tidak mengirim email/WhatsApp atau mencetak fisik |
| Web penerimaan sebagian | PASS: GRN0001 menerima1dari2unit; stok41, satu jurnal penerimaan |
| Web checkout0001 dan0002 | PASS: masing-masing1unit × Rp5.000, tunai uang pas; invoice sukses, tidak tertahan printer; stok39 |
| Android PO0002 | PASS: pilih barang QA-STOCK, satuan box12; harga Rp36.000. Draft → submit → approver web menyetujui, stok belum bertambah |
| Android penerimaan box | PASS: GRN0002,1box =12unit, stok51. Biaya aktual opsional ditawarkan terpisah, dipilih Later karena tanpa ongkir |
| Android lanjut PO parsial web | PASS: tersisa1unit, bukan2; GRN0003 menerima1unit. Kedua PO completed; web menampilkan12/12 dan2/2 |
| Android checkout0003 | PASS:2unit, total Rp10.000, uang pas, kembalian0; stok50 |
| APK final + checkout0004 | PASS: sesi dipulihkan melalui PIN,1unit Rp5.000, hasil EN “Cash”, selesai tanpa printer; stok49 |
| Android tutup shift | PASS: expected125.000, aktual125.000; peringatan cek perangkat offline ditinjau, shift closed. Web history menunjukkan nilai sama, selisih0 |
| Web stok setelah refresh | PASS: QA-STOCK49; tidak ada overflow horizontal halaman pada pemeriksaan375/768/1280/1440px untuk layar stok. Ini bukan audit visual seluruh halaman |

Invoice lengkap `INV-20261123-0001` s.d. `0004`; PO `PO-20261123-0001` dan `0002`; GRN `GRN-20261123-0001` s.d. `0003`.

### Rekonsiliasi final yang diasert oleh verifier

- Stok: **40 awal +14 diterima −5 terjual =49unit**.
- SOURCE tetap20, DEST29; jumlah saldo lokasi = stok master49.
- Nilai persediaan49 × Rp3.000 = **Rp147.000**. Kemasan tidak menggandakan atau mengurangi HPP.
- 2PO selesai,3GRN,4penjualan; nomor dokumen dan client_transaction_id unik.
- Setiap baris PO qty_received_base sama dengan penjumlahan GRN terkait dan tidak melebihi qty_ordered_base.
- 3jurnal penerimaan +4jurnal penjualan +4jurnal HPP = **11jurnal**, semua debit=credit; satu jurnal tiap jenis/sumber, tidak dobel.
- Tunai penjualan **Rp25.000**. Modal awalRp100.000 + kas masukpenjualanRp25.000 = expected/aktual **Rp125.000**, cash_difference0, total_transaksi4, shift closed.
- Saat shift open, closing_cash_expected menyimpan pergerakan saja; ketika close server menambahkan modal awal. Perbedaan raw field bukan bug; GUI dan hasil close dibuktikan sesuai.
- Helper `scripts/qa_urgent_inventory_20261123.cjs verify` exit0. Verifier hanya membaca data GUI; mode prepare sebelumnya dibatasi sebelum ada GRN/penjualan agar tidak mereset valuasi yang sudah berjalan.

Bukti gambar: [konversi box](../../output/production-audit-20261123/android-po-box-converted.png), [pembayaran APK final](../../output/production-audit-20261123/android-sale-success-final.png), [riwayat shift Android](../../output/production-audit-20261123/android-shift-history-final.png). [Observasi DOM web final](../../output/production-audit-20261123/web-gui-final.json) menyimpan stok49 dan riwayat expected/actual125k, selisih0. Browser screenshot ke file ditolak batas plugin; bukti web berasal dari snapshot/DOM teramati dan hasil database, bukan klaim screenshot yang tidak tersimpan.

## Multibahasa dan hasil audit

- 47 sumber web ditinjau untuk ID/EN: detail pekerjaan/laundry, validasi baris PO/batch, notifikasi sinkronisasi, kegagalan printer, popup berhasil/credit/offline, status stok dan istilah rekonsiliasi kas.
- Mobile: panduan opsional, Stok Awal, tombol/summary konfirmasi PO, label hasil bayar dan share struk mengikuti bahasa. Tes memastikan nama “Pemasok Uji”/“Gudang Uji” tidak diubah.
- 27.758 entry katalog web/server identik, termasuk47 reviewed entries. Penggabungan memakai serializer/hash proyek, mempertahankan entry pengguna dan nilai non-string; tidak memperkenalkan mesin lokalisasi kedua.
- Audit ekstraksi0missing **bukan bukti seluruh salinan UI sempurna**. Masih ada838 kandidat heuristik di luar ekstraksi (termasuk log, query, data dan modul lain) yang memerlukan penilaian konteks, bukan diterjemahkan membabi buta.
- Generator full-catalog masih menemui error lama `src/pages/website/faq/faq-backup.vue`: await dalam fungsi non-async. Komponen ini bukan jalur POS. Tidak dihapus, tidak di-skip baru, dan **build seluruh aplikasi tidak diklaim PASS**. Perubahan terjemahan POS sendiri lolos kompilasi971komponen, tanpa error baru.

## Matriks bukti dan pekerjaan yang belum diklaim PASS

| ID required point | Status | Level / purpose | Batas bukti |
| --- | --- | --- | --- |
| TEST-POS-URGENT-SCHEMA-2311 | covered | contract / rule protection |44tes termasuk dokumen mobile/web dan daftar auth purchase. Bukan GUI semua mutation destruktif |
| TEST-POS-URGENT-MODAL-2311 | covered scoped | unit, integration / regression protection | Race modal/opname/transfer dan route editor; tidak semua modal seluruh produk |
| TEST-POS-URGENT-DISPLAY-2311 | covered automated | unit / regression protection | HTML/template bootstrap; bukan pengujian dua layar fisik |
| TEST-POS-URGENT-CATALOG-2311 | covered automated | unit, integration / rule protection | Fixture service_intake_mode melengkapi respons nyata; scope/cache offline tetap diperiksa |
| TEST-POS-URGENT-PURCHASE-2311 | covered | integration, E2E / critical path | PO→approval berbeda→parsial/penuh→unit/box→stok/jurnal via GUI kedua klien |
| TEST-POS-URGENT-SALE-2311 | covered | integration, E2E / critical path | Checkout tunai, request unik, kas/jurnal/HPP, tutup shift. Piutang/refund terbukti integrasi, bukan GUI baru di audit ini |
| TEST-POS-URGENT-OFFLINE-2311 | covered automated | unit, integration / specialized protection | Cache/scope/revocation/retry/shift tests; tidak mengklaim live offline multikasir lewat GUI pada run ini |
| TEST-POS-URGENT-I18N-2311 | covered scoped | unit, integration, E2E / regression protection | ID/EN kritis, placeholder dan tampilan yang diamati; bukan semua27ribu entry |
| TEST-POS-URGENT-GUI-2311 | covered scoped | E2E / critical path | Retail/simple di Android + web, transaksi nyata pada replica lokal |
| TEST-POS-URGENT-PROFILE-GUI-2311 | unverified | E2E / specialized protection |7profil POS ×3inventori lolos integrasi; **bukan21kombinasi GUI baru** |
| TEST-POS-URGENT-OFFLINE-GUI-2311 | unverified | E2E / specialized protection | Dua perangkat offline bersamaan, kehilangan respons, restart/perangkat mati dalam alur baru |
| TEST-POS-URGENT-HARDWARE-2311 | unverified | E2E / specialized protection | Printer thermal Bluetooth/USB/Wi-Fi fisik, Google OAuth asli dan perangkat pelanggan tidak diuji ulang |
| TEST-POS-URGENT-FULLBUILD-2311 | unverified | smoke / regression protection | Full generator/build web terhalang error lama FAQ backup non-POS |

Integrasi146mencakup7profil POS×3inventori, pemisahan operator/approver/receiver, transfer dan retur supplier, rollback ketika COA hilang, checkout/shift/operator, tarif fleksibel, workspace pesanan, piutang, refund laci, landed cost dan penerimaan. Bukti otomatis tidak dipromosikan menjadi GUI/hardware PASS.

## Perintah ulang dan lokasi tes

Dari root mobile:

```powershell
flutter test --no-pub --concurrency=1 --timeout=2m --reporter=expanded
flutter analyze --no-pub
flutter test --no-pub test/pos_inventory_route_context_test.dart test/pos_urgent_copy_test.dart test/pos_purchase_amount_test.dart test/pos_success_print_nonblocking_test.dart
```

Dari root Vue (kelompok401tes):

```powershell
$qaFiles = Get-ChildItem tests -File | Where-Object {
  $_.Name -match '^(pos-|purchase-|inventory-|ui-i18n|ui-translation|app-language|sidebar-i18n)' -and $_.Name -match '\.test\.(mjs|cjs|js)$'
} | ForEach-Object FullName
node --test --test-concurrency=1 $qaFiles
node scripts/audit-ui-translation.mjs docs/production-audit-20261123/i18n-complete
node scripts/verify-ui-translation.mjs
```

Dari root backend, runtime MongoDB tes memakai binary cache7.0.14 dan replica set sementara, tidak URI produksi. Kelompok44kontrak: direct_purchase_authmiddleware.contract, finance_authmiddleware.coverage, inventory_mobile_graphql.contract, inventory_purchase_authmiddleware.contract, inventory_purchase_receiving.contract, inventory_transfer_flow.contract, inventory_transfer_profile.contract, inventory_transfer_transaction.contract, pos_graphql.contract, pos_web_graphql_audit, purchase_cost_graphql.contract (semuanya tests/*.test.js).

Kelompok146: inventory_opname_multirack.integration, inventory_purchase_authmiddleware.contract, inventory_transfer_three_flows.integration, pos_checkout_optimization.integration, pos_flexible_service_pricing.integration, pos_order_workspace.integration, pos_priority_inventory_roles.integration, pos_profile_inventory_e2e.integration, pos_purchase_supplier_quick, pos_receivables.integration, pos_return_cash_drawer.integration, pos_shift_operator_scope.integration, purchase_landed_cost_finance.integration, purchase_lifecycle_advance.contract, purchase_return_replica_transaction, receiving_replica_transaction (tests/*.test.js), dijalankan `node --test --test-concurrency=1` dengan daftar berkas tersebut. Tes integrasi menggunakan DB buatan sendiri dan memverifikasi transaksi asli, bukan mock Mongo.

Penyesuaian fixture lama: seed COA default pada test receiving/opname/landedcost/profile; tes opname negatif tanpa COA tetap mengharuskan rollback. Fixture offline katalog ditambah service_intake_mode; test source mengikuti format kontrak/route yang berlaku; uji modal memakai race version saat ini, bootstrap display memuat copy nyata. Tidak menghapus tes, tidak melonggarkan guard PIN, permission, tenant, refund, stok atau jurnal.

## Kesimpulan

Rantai prioritas pembelian stok sampai penjualan tunai dan penutupan shift **PASS dalam cakupan di atas**. Tidak ada blocker yang masih terbuka pada skenario GUI tersebut. Langkah sebelum rilis luas: perbaiki generator full-catalog yang terhalang FAQ backup di pekerjaan modul terkait, lanjutkan matriks GUI profil/offline multikasir dan perangkat fisik yang masih unverified. Tidak ada build release/deploy atau data produksi yang diubah.
