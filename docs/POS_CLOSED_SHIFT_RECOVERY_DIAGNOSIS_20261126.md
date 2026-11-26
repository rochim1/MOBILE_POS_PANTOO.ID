# Diagnosis kebuntuan pembayaran dan shift asal — 26 November 2026

## Kesimpulan

Pembaruan implementasi berikutnya: jalur penyelesaian server/mobile/web sudah ditambahkan dan diuji. Lihat `docs/POS_CHECKOUT_RESOLUTION_FIX_20261126.md` untuk hasil, batas dan urutan deployment. Isi diagnosis berikut tetap menggambarkan kondisi sebelum perbaikan.

Ada celah alur operasional nyata: hasil pembayaran tidak pasti menyisakan bukti lokal; shift asal kemudian tidak lagi dapat digunakan; replay ditolak; bukti tetap mengunci seluruh kasir pada scope operator tersebut, termasuk ketika toko/shift aktif sudah berbeda. Layar hanya memberi satu tindakan replay sehingga tidak menyediakan penyelesaian untuk konflik yang tidak bisa pulih dengan retry.

Analisis ini tidak memperbaiki kode aplikasi, menghapus bukti, membuka/menutup shift produksi, memindahkan kas, atau membuat transaksi produksi. Berkas diagnostik hanya memakai transport tiruan atau replica set lokal sementara. Empat tes PASS berarti reproduksi dan kontrol terbukti, **bukan berarti kebuntuan telah diperbaiki**.

## Fakta kasus pengguna

- Pengguna mengonfirmasi memakai versi terbaru dan kemungkinan pernah menutup shift/berganti toko.
- Referensi screenshot: `762468b5-e354-45aa-8bc9-8d7f9d04158e`.
- Koneksi baca-saja ke database remote terkonfigurasi `tom_database` berhasil; koleksi transaksi memang ada. Pencarian referensi persis tanpa filter status menghasilkan **0 transaksi** pada saat pemeriksaan.
- Toko `Toko Bandung [Dummy]` pada instansi `6a856ce9517424ebab833ba9` aktif dan menggunakan `shared_register`. Ada shift terbaru berstatus **open**, ID `6b074e24c0565aed26c71ae8`, dan shift lebih lama berstatus closed.
- Ini belum mengidentifikasi `shift_id`, `toko_id`, nominal, metode dan waktu di bukti lokal HP. Header toko aktif tidak membuktikan toko asal bukti, karena panel pemulihan belum menampilkan konteks asal itu.
- Tidak ditemukannya transaksi pada database aplikasi bukan bukti bahwa uang belum diterima tunai/transfer di luar aplikasi. Tidak ada pemeriksaan mutasi bank atau webhook pada diagnosis ini.

## Rantai penyebab

1. `PosCheckoutRequestStore.begin` menyimpan input dan snapshot nota sebelum pengiriman. Input berisi UUID, toko dan shift asal.
2. Bila hasil belum dapat dipastikan, bukti tidak dihapus. Ini benar untuk mencegah pembayaran ganda.
3. `recoverPendingCheckout` mengirim kembali payload yang sama melalui `_deliverCheckout(... replay: true, recovery: true)`, bukan memeriksa status lewat operasi baca khusus terlebih dahulu.
4. Server mencari transaksi aktif dengan ID yang sama sebelum memvalidasi shift. Jika transaksi sudah tersimpan dan operator sah, invoice lama dapat dikembalikan meskipun shift tutup.
5. Jika belum ada transaksi aktif, server memeriksa shift persis sesuai payload: instansi, toko, mode/otorisasi dan status open. Shift lama yang closed/tidak cocok menimbulkan CONFLICT. Membuka shift baru tidak menggantikan ID shift pada payload lama.
6. Mobile sengaja hanya menghapus bukti pada penolakan pasti di pengiriman pertama: `if (!replay) await store.acknowledge(requestId)`. Penolakan replay tidak membuktikan pengiriman pertama tidak pernah tersimpan.
7. Scope bukti berisi endpoint, instansi, akun terminal dan operator, **tidak dibatasi toko atau shift aktif**. `begin` menolak keranjang/toko baru yang berbeda dari bukti lama.
8. `PosPage` langsung mengganti seluruh isi kasir dengan recovery panel selama ada bukti. Panel hanya menyediakan `onRecover`, tanpa keputusan final server atau jalur penyelesaian supervisor. Hasilnya penguncian aman terhadap duplikasi, tetapi tidak tuntas secara operasional.

## Detail penting yang tidak boleh disalahartikan

- Pesan “Shift asal transaksi offline ...” dipakai untuk semua checkout yang membawa `shift_id` tidak cocok. `resolveKasirShiftSnapshot` tidak mensyaratkan flag offline sebelum mengeluarkan pesan itu. Kata offline pada error **tidak membuktikan perangkat sebelumnya benar-benar offline**.
- Pesan menggabungkan beberapa penyebab: shift tutup/tidak ditemukan, toko asal tidak cocok, mode shift berbeda, atau kepemilikan per kasir tidak cocok. Tidak boleh memastikan satu penyebab hanya dari kalimat ini.
- Dalam laci bersama, akun pembuka bukan pembatas kepemilikan operasional. Toko yang diperiksa menggunakan laci bersama; menyalahkan perbedaan akun pembuka tanpa memeriksa ID/mode adalah diagnosis yang tidak cukup.
- Saat ini sudah ada guard mobile `_assertNoUnconfirmedShiftCheckout` sebelum/sesudah await antrean lokal; ia memeriksa bukti semua PIN pada terminal yang sama. Jadi bukan benar bahwa Android sama sekali tidak memeriksa bukti sebelum menutup shift.
- Guard tersebut tidak dapat mengetahui bukti lokal HP lain. Web juga hanya melihat antrean browser sendiri dan menampilkan peringatan perangkat lain. Server ClosePOSKasirShift memeriksa hak akses dan perubahan saldo/count, tetapi belum memiliki status persisten per request pembayaran yang mencakup bukti lokal semua terminal.
- Sesi offline murni tidak dapat memberitahu server secara realtime. Perlindungan lintas terminal harus memiliki aturan konflik/rekonsiliasi, bukan berasumsi server bisa melihat semua antrean offline.

## Bukti pengujian terisolasi

| Target | Skenario aktual | Hasil |
|---|---|---|
| Repository mobile | Respons pertama hilang, replay dua kali menerima CONFLICT shift tutup; semua request tetap UUID/toko/shift lama; mencoba pembayaran toko/shift lain tidak mengirim request baru | Reproduksi terbukti |
| Repository mobile | CONFLICT diterima langsung pada pengiriman pertama, bukan replay; bukti terlepas dan percobaan baru mendapat UUID berbeda | Kontrol terbukti |
| Resolver + DB lokal | Transaksi benar-benar tersimpan, shift ditutup, replay ID sama mengembalikan transaksi/invoice semula; stok, kas, jurnal tidak ganda | Kontrol terbukti |
| Resolver + DB lokal | Belum ada transaksi, shift lama ditutup, shift baru dibuka; dua replay dengan shift lama tetap ditolak dan tidak mencatat transaksi/jurnal atau mengubah stok; transaksi berbeda dengan shift baru berhasil | Reproduksi terbukti |

Mobile **2 PASS**, server **2 PASS**. Jangan melabeli flow penyelesaian konflik sebagai PASS berdasarkan tes ini: aplikasi saat ini justru terbukti tetap buntu pada kasus reproduksi.

Perintah yang dijalankan:

```text
flutter test --no-pub output/shift-recovery-analysis-20261126/closed_shift_diagnostic_test.dart --reporter expanded
node --test output/shift-recovery-analysis-20261126/closed_shift_diagnostic.integration.cjs
```

Log mobile dan server masing-masing ada pada folder `output/shift-recovery-analysis-20261126` di proyek terkait. Server memakai MongoMemoryReplSet baru, tidak menggunakan DB_CONNECT. Pemeriksaan remote dilakukan terpisah dengan MongoClient native, find/listCollections saja agar tidak memicu auto-index/auto-create model.

## Temuan terkait web

Web sudah memiliki “Selesaikan manual” dengan alasan lokal, sedangkan panel mobile belum memiliki padanannya. `resolvePOSOutboxEntry` dapat menandai bukti belum pasti sebagai reviewed/manually_reconciled tanpa keputusan final dari server. Itu bukan jaminan bahwa request lama tidak bisa datang/tersimpan kemudian. Menyalin tombol ini mentah-mentah ke mobile bukan solusi yang cukup aman; penyelesaian perlu otorisasi dan putusan server yang mencegah late commit/duplikasi.

## Perbaikan yang direkomendasikan — belum diimplementasikan

### P0 — Putusan pemulihan yang dapat dipercaya

1. Endpoint status/resolusi per ID pembayaran dengan scope instansi/operator, tidak bergantung toko yang sedang dipilih atau syarat shift asal masih open.
2. Status persisten server membedakan processing, committed, rejected/cancelled dan needs_review. Lookup saja yang mengembalikan not_found **belum cukup** untuk membuka kunci jika request pertama masih berjalan.
3. Putusan tidak tercatat harus atomik dengan idempotency/posting admission dan memiliki tombstone/terminal decision agar request lama yang terlambat tidak dapat mencatat transaksi setelah kasir memulai pengganti.
4. Jika committed: ambil invoice lama dan lepaskan bukti lokal setelah identitas cocok. Jika benar-benar tidak tercatat dan uang belum diterima: tutup bukti dengan audit trail dan pulihkan keranjang tanpa diam-diam memindahkan konteks toko. Jika uang sudah diterima: minta rekonsiliasi supervisor, bukan menghapus bukti atau mencatat dua pembayaran.

### P0 — Jalan penyelesaian mobile dan web setara

- Pisahkan “Periksa status” dari tindakan replay. Konflik terminal tidak diperlakukan sebagai kegagalan jaringan yang harus dicoba berulang.
- Tampilkan keputusan server dan tindakan sesuai hasil: buka nota lama, kembali ke keranjang setelah pembatalan terkonfirmasi, atau minta rekonsiliasi supervisor.
- Pertahankan PIN, hak akses, operator asal dan data bukti; jangan menukar shift/toko di payload lama, mengaktifkan transaksi di luar shift, menghapus preferences, atau membuka kembali shift lama otomatis.

### P1 — Pencegahan dan keterbacaan

- Koordinasikan penutupan shift dengan request server yang sedang diproses; pertahankan guard lokal semua PIN dan penanganan terminal lain/offline.
- Panel harus menampilkan toko/shift asal, waktu, kasir, nominal dan metode. Pisahkan error shift tutup, toko/mode tidak cocok dan akses operator.
- Uji sampai ada akhir bisnis yang benar: tidak tercatat + uang belum diterima, sudah diterima tunai/transfer, transaksi committed respons hilang, perubahan toko/operator, penutupan lintas terminal, request terlambat dan pembatalan bersamaan. Menguji bahwa bukti “tetap tersimpan” belum membuktikan operasional dapat dilanjutkan.

## Batas dan evaluasi

Tidak membaca penyimpanan HP pengguna atau log request pertama; ID shift asal tepat dan penyebab respons pertama belum diketahui. Tidak menguji GUI di HP pada tugas analisis ini. Perubahan sebelumnya memperkuat pencegahan duplikasi dan informasi error, tetapi belum menutup jalur penyelesaian konflik permanen ini.

Evaluasi: akurasi 4/5 (sumber, DB baca-saja dan reproduksi nyata; payload HP belum tersedia); kelengkapan 4/5 (akar alur dan kontrol pembanding diperiksa; peristiwa pertama belum dapat dipastikan); kejelasan 4/5 (fakta/dugaan dan reproduksi/perbaikan dibedakan); dapat ditindaklanjuti 4/5 (prioritas dan syarat keselamatan konkret; implementasi membutuhkan tugas berikutnya); keringkasan 4/5 (rincian ada di dokumen, ringkasan pengguna terpisah). Rata-rata 4,0/5. Perbaikan lanjutan paling bernilai: status/resolusi server dan payload asal dari HP; tidak ada izin untuk menghapus bukti atau mengubah transaksi produksi melalui permintaan analisis ini. Self-check: diagnosis menjelaskan stopper tanpa mengklaim sudah memperbaikinya.
