# Kebijakan diskon kasir mobile dan web

Tanggal: 26 November 2026. Kebutuhan: kebijakan Hanya Promo tidak boleh tetap menawarkan diskon manual; pengguna meminta penerapan juga pada web.

## Temuan dan keputusan

- Dialog mobile hanya memeriksa izin `manage_settings`; panel web hanya memeriksa izin edit harga. Keduanya tidak memeriksa kebijakan diskon untuk menampilkan kolom manual.
- Pesanan tersimpan membawa persentase manual dan kebijakan lama. Memulihkannya dapat mengembalikan aturan yang berbeda dari pengaturan toko saat ini.
- Perhitungan/pratinjau/payload perlu memakai kebijakan aktif yang sama, bukan hanya menyembunyikan kolom input.

Kebijakan yang tersedia dari pengaturan POS menjadi acuan transaksi baru dan pesanan yang belum dibayar. Jika konfigurasi tidak tersedia, nilai kebijakan pada konteks transaksi dipakai sebagai fallback kompatibilitas. Hak admin tidak membuka kolom diskon manual pada mode Hanya Promo; untuk mengubah kebijakan, lakukan melalui Pengaturan POS, bukan mengganti aturan diam-diam dari dialog kasir.

| Kebijakan | Kolom manual | Kode promo |
|---|---|---|
| Hanya Promo | Tidak ditampilkan; nominal manual yang dihitung/dikirim nol | Ditampilkan, tetap perlu validasi promo |
| Manual Saja | Sesuai izin yang sudah berlaku | Tidak ditampilkan/dikirim; kode lama tidak boleh membuat pembayaran buntu |
| Manual + Promo / Diskon Terbaik | Sesuai izin yang sudah berlaku | Tetap tersedia; perhitungan mengikuti kebijakan masing-masing |

## Implementasi dan batas keamanan

- Mobile: dialog dan panel kasir mengikuti kebijakan; event diskon memeriksa izin dan rentang 0–100; kalkulasi mengabaikan nilai manual yang tidak diizinkan. Quote dengan kebijakan lama tidak menjadi dasar total/promo yang dianggap valid.
- Mobile: checkout, pembuatan pesanan/invoice dan penyimpanan/pemulihan pesanan menggunakan kebijakan aktif. Respons pratinjau lama tidak boleh menimpa konteks kebijakan baru.
- Web: kolom manual/promo disaring; nominal manual dihitung nol pada Hanya Promo; pratinjau, invoice/pesanan, checkout dan snapshot pesanan memakai pengaturan aktif. Pemulihan draf menetralkan manual lama pada Hanya Promo.
- Web: kode promo tersembunyi pada Manual Saja tidak menghalangi pembayaran atau pemulihan offline pesanan baru. Respons preview pada kebijakan sebelumnya diabaikan.
- Validasi promo online tetap berlaku. Tidak menganggap kode promo otomatis sah saat offline.
- Tidak mengubah transaksi yang telah diposting, jurnal, stok, kebijakan tersimpan di produksi, role atau konfigurasi lingkungan. Tidak menulis ulang bukti pembayaran/permintaan offline yang sudah disimpan untuk pemulihan idempoten.
- Backend tidak diubah. Perhitungan backend yang sudah ada mengabaikan nominal manual pada `promo_only`; pekerjaan ini menyelaraskan klien dan mencegah perpindahan kebijakan dari form/keranjang lama. Ini bukan perubahan desain otorisasi override pada API admin.

## Bukti TDD

| Tahap | Bukti | Hasil |
|---|---|---|
| Mobile RED | `test/pos_discount_policy_test.dart`, `output/discount-policy-20261126/red.log`, commit `924e191` | 7 reproduksi gagal: kalkulasi lama, event manual, pemulihan, kolom dialog/panel dan Manual Saja |
| Mobile GREEN | File baru + `pos_promo_apply_test.dart`, commit `0529666` | 36 PASS |
| Web RED | `tests/pos-discount-policy.test.mjs`, commit `9db08f64` | 5 reproduksi gagal: perhitungan, kolom manual, payload pratinjau dan pemulihan |
| Web GREEN | Policy + promo + durable held-order, commit `60219a96` | 27 PASS |
| Web RED lanjutan | `hidden-promo-red.log`, commit `a6f3b032` | Kode lama tersembunyi masih membuat `canPay` false; respons kebijakan lama sudah diabaikan |
| Web GREEN lanjutan | Commit `38935a5c`, `green-final.log` | 29 PASS |

Reproduksi web awal untuk pemulihan diperbaiki agar benar-benar memanggil indeks pesanan `0`; hasil RED yang valid tersimpan di `red-verified.log`. File log awal tetap disimpan sebagai riwayat, bukan dijadikan bukti keberhasilan.

## Regresi akhir

- **Mobile: 191/191 PASS**, sekitar 1 menit 18 detik, `output/discount-policy-20261126/mobile-regression.log`. Perintah `flutter test --no-pub --concurrency=2 --coverage --coverage-path output/discount-policy-20261126/coverage.info --reporter expanded` pada 14 berkas: policy, promo, cart units, checkout locks/request-store/recovery/recovery-flow/preparation, held-order flow/safety, pending-payment flow, offline safety/revocation, flexible service.
- Cakupan baris: `pos_state.dart` **166/185 (89,73%)**, dialog diskon **65/66 (98,48%)**. Panel info keseluruhan **90/347 (25,94%)** karena banyak builder legacy dan navigasi pelanggan tidak tercakup rangkaian terarah ini; bukan klaim cakupan seluruh UI.
- **Web: 468/468 PASS**, sekitar 21 detik. Seluruh `tests/pos-*.test.mjs` dijalankan dengan `node --test --test-concurrency=2`. Log `front_end_template/output/discount-policy-20261126/pos-regression.log`. Termasuk checkout, invoice/offline, pemulihan, held-order, jasa, otorisasi dan kompilasi template Vue.
- Analisis tujuh target mobile: **No issues found!**, `analyze-final.log`. Satu info lint pada tes telah dirapikan; bukan error aplikasi.
- `git diff --check` pada perubahan: bersih. Perubahan pengguna yang sudah ada pada `pos_bloc.dart` dipertahankan dan tidak dimasukkan ke commit perbaikan ini; hanya hunk terkait diskon yang di-stage.

## Belum dilakukan

Tidak membuat APK/AAB baru, build/deploy web, mengubah database produksi, atau melakukan GUI perangkat/browser pada pekerjaan ini. APK 1.0.26 (27) yang sebelumnya dibagikan belum memuat perubahan kebijakan diskon ini. Regresi di atas adalah pengujian otomatis, bukan bukti semua kemungkinan produksi telah diuji pada HP nyata.
