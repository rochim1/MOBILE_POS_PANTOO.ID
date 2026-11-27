# Utang & Piutang — penyelarasan UI dengan Inventori

Tanggal: 27 November 2026.

## Cakupan

Halaman **Utang & Piutang pada aplikasi Flutter POS**, termasuk tampilan HP/tablet, daftar, detail, pencatatan manual dan formulir pembayaran. Halaman Vue web serta aturan server/Finance tidak diubah pada pekerjaan ini.

## Perubahan tampilan

| Sebelum | Sesudah |
| --- | --- |
| Kategori memakai chip, berbeda dari Inventori | Memakai komponen kategori Inventori: sidebar 230 px pada ruang ≥760 px, dropdown pada HP |
| Ringkasan memakai kartu setinggi minimal 180 px | Kartu ringkas minimal 92 px; jumlah dan sisa tagihan lebih cepat dibaca |
| Pencarian tersembunyi bersama filter HP | Pencarian utama selalu tersedia; filter tambahan dibuka melalui tombol sejajar pilihan jenis tagihan |
| Isi kartu terutama pihak/referensi dan nominal | Pihak, referensi, sisa, nilai dokumen, jatuh tempo dan status ditampilkan bersama; overdue diberi penanda merah |
| Penjelasan Finance panjang di bagian atas | Penjelasan tetap tersedia melalui tombol informasi, tidak terus mengambil ruang daftar |
| Semua notifikasi terlihat sama | Informasi, sukses, kesalahan dan bukti belum terkonfirmasi dibedakan warna serta ikon |
| Detail menggunakan label teknis “Pembayaran pada Cutoff” | “Sudah dibayar” untuk utang dan “Sudah diterima” untuk piutang |
| Riwayat kosong selalu mengatakan belum ada pembayaran | Jika saldo sudah memiliki pembayaran, tampilkan bahwa rincian bukti belum tersedia; tidak menyatakan pembayaran belum pernah ada |
| Form tidak mempunyai bahasa visual yang konsisten | Bidang berbingkai putih, label selalu terlihat, jarak 16 px, tombol teal minimal 48 px, batas lebar sheet 720 px dan tombol tutup eksplisit |
| Label nominal/metode pembayaran generik | Dibedakan menjadi jumlah penerimaan/pembayaran, metode pembayaran dan kas pembayaran sesuai konteks |
| Kembali ke daftar memakai label “Detail” | Label jelas “Kembali ke daftar” |

Material yang benar dipakai pada filter agar efek interaksi ListTile tidak tertutup warna latar. Navigasi halaman daftar dapat membungkus pada HP dengan teks besar agar tidak meluap. Pesan kesalahan detail mengembalikan kontrol daftar, bukan meninggalkan halaman tanpa navigasi.

## Pengaman yang dipertahankan

- Tidak mengubah endpoint, repository, payload, akun jurnal, saldo, perhitungan pembayaran maupun kontrak server.
- Kategori dan tombol pencatatan/pembayaran tetap mengikuti izin server.
- Pengiriman tidak boleh dilakukan tanpa konfirmasi formulir.
- Bukti dengan respons belum terkonfirmasi tetap terlihat dan dapat diulang memakai request ID, jumlah, referensi dan tujuan semula.
- Identitas hasil pembayaran tetap diperiksa; respons dokumen/jenis yang berbeda tidak menghapus bukti lokal.
- Navigasi/filter dan aksi lain dinonaktifkan saat pengiriman pembayaran berlangsung.
- Penerimaan/pembayaran tetap dijelaskan sebagai pencatatan Finance, bukan penjualan baru atau perubahan kas laci shift.
- Safe area dan ruang keyboard dipertahankan; tombol simpan diuji tetap dapat dijangkau di atas keyboard serta area navigasi sistem.

## Pengujian

**49 tes PASS, 0 gagal** pada empat berkas:

```powershell
flutter test --no-pub test/pos_trade_workspace_test.dart test/pos_trade_form_spacing_test.dart test/pos_trade_repository_test.dart test/pos_trade_inventory_theme_test.dart
```

Di sesi ini perintah Flutter dipanggil melalui Dart/snapshot SDK yang sama agar tidak tertahan launcher.

- Tiga paket regresi lama: **27 PASS** — formulir entry/saldo awal/pembayaran, jarak bidang, hak akses, pembayaran sebagian, konfirmasi, koreksi penolakan, retry respons hilang, identitas ACK, dan kompatibilitas bukti POS lama.
- Paket UI baru: **22 PASS** — 16 kombinasi lebar 320/390/768/1280 px × bahasa ID/EN × skala teks 1,0/1,4; kategori/filter/pencarian; reset empty state; gagal memuat detail tanpa buntu; detail → pembayaran → tutup → kembali daftar; kategori sesuai izin; tombol simpan dengan keyboard 300 px dan inset navigasi 24 px.
- Pemeriksaan Flutter untuk empat berkas perubahan/tes: **No issues found**.
- Pemeriksaan whitespace: lulus.

Tes filter lama disesuaikan dengan perilaku baru yang disengaja: pencarian selalu tampak, sedangkan opsi tambahan termasuk lunas tetap dapat ditutup. Bukti pembayaran/pengujian mutasi tidak dilonggarkan.

## Pratinjau yang diperiksa

Tujuh tangkapan layar widget dengan font Roboto dan Material Icons di `output/trade-inventory-ui-20261127`:

- `overview-390-id.png`, `overview-390-en.png`
- `overview-1280-id.png`, `overview-1280-en.png`
- `detail-390-id.png`
- `payment-390-id.png`
- `empty-390-id.png`

Daftar, detail, dan formulir pembayaran diperiksa secara visual. Data pada gambar adalah fixture lokal QA, bukan saldo produksi.

## Batas verifikasi

Ini adalah pengujian widget dan repository dengan data uji lokal; bukan sesi GUI baru pada emulator/HP terhubung ke backend. Tidak ada transaksi produksi dibuat. Tidak ada build APK/AAB atau deploy pada pekerjaan ini. Perubahan tersedia di kode dan memerlukan restart/reload aplikasi pengembangan atau build baru untuk distribusi Android.

## Evaluasi hasil

| Aspek | Nilai | Bukti dan batas |
| --- | --- | --- |
| Ketepatan | 4/5 | 49 tes dan analyzer lulus; belum diulang pada HP fisik dengan API langsung |
| Kelengkapan | 4/5 | Daftar/detail/form dan ukuran responsif tercakup; perubahan hanya untuk workspace Flutter sesuai halaman yang diperiksa |
| Kejelasan | 4/5 | Label, status, penjelasan saldo/riwayat dan tombol kembali diperjelas; kenyamanan operasional tetap perlu umpan balik pengguna |
| Kesiapan penggunaan | 4/5 | Kode dan tes siap ditinjau; aplikasi distribusi belum dibangun ulang |
| Keringkasan | 4/5 | Ringkasan lebih pendek dan bantuan tidak memenuhi layar; komponen visual dipisah, sedangkan halaman stateful lama masih cukup panjang |

Rata-rata 4,0/5. Tidak ada isu kritis yang diketahui dari pengujian terpilih. Tindak lanjut utama adalah smoke test perangkat setelah aplikasi terbaru dijalankan. Penilaian membedakan pengujian otomatis yang sudah terbukti dari uji perangkat yang belum dilakukan.
