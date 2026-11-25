# Audit operasional POS — 25 November 2026

## Keputusan dan ruang lingkup

Permintaan: memastikan alur/UI operasional, khususnya kasir, tidak buntu sebelum penjualan selesai. Audit dilakukan pada Flutter Android, Vue POS, dan server GraphQL yang tersedia di workspace. Temuan di bawah diperbaiki dengan reproducer RED, regresi, dan GUI terpilih. **Bukan pernyataan bahwa seluruh aplikasi bebas bug atau seluruh profil/perangkat telah mendapat persetujuan produksi.**

Penilaian sementara **78/100 — dapat dipilotkan dengan syarat, belum persetujuan peluncuran penuh**. Penghalang persetujuan penuh ialah bukti GUI crash/respons hilang di dua terminal, seluruh kombinasi profil/izin, hardware, dan rollback rilis aktual. Skor dibatasi karena CI/release deployment serta semua jalur kritis belum dibuktikan ulang E2E. Tidak ditemukan alasan untuk melewati PIN, scope toko, atau guard Finance demi melancarkan UI.

### Lingkungan bukti

- API QA terpisah: `http://127.0.0.1:18125/graphql`; web QA `http://localhost:5189`. Server pengguna 8080/5173 tidak diubah.
- Replica set lokal disposable, DB `operational_gui_20261125`, instansi sintetis `6b062bd96177a980ec9e37e7`. Semua mutasi GUI hanya di sini; tidak menulis database produksi atau mereset akun pengguna.
- Android `emulator-5556`, package `id.pantoo.pos.qa.service`, endpoint emulator `http://10.0.2.2:18125/graphql`. Login username/password dan PIN nyata, bukan injeksi sesi/token.
- APK **debug QA**, versi workspace tetap `1.0.21+22`; bukan APK/AAB rilis. Build awal305,2detik berhasil, hash `9AA5A76E0D5A5ACA721FBE13492BAE040B93667236C71412E6B91EAD13FB5120`. Build final setelah follow-up bahasa/pager50,3detik berhasil, hash `DDD1A96DF13B176C9E5F3DC9F655C0D4BE3FC56D2E352716B452536626C6F156`, dipasang dengan install-r tanpa clear data. Tidak mengubah signing, dependency, atau versi pengguna.
- Worktree sejak awal berisi perubahan pengguna. Perubahan BLoC milik audit dipisahkan dari diff pemuatan paralel pengguna; router/sidebar/admin/coverage/PIN/versi dan perubahan lain yang tidak terkait dipertahankan.

## Temuan yang diperbaiki

| Risiko awal | Perbaikan dan jaminan |
|---|---|
| Web: Escape/backdrop pada sukses meninggalkan cart yang sudah dibayar | Seluruh cara menutup hasil mengonsumsi cart satu kali; lock bertahan selama feedback. Share/refresh gagal bukan pembayaran gagal |
| Web: refresh katalog/shift menggantung setelah commit | Refresh dipisahkan dari keputusan transaksi; tidak mengantrekan ulang transaksi yang sudah commit |
| Web/mobile: identitas pelanggan atau pajak draft tertukar | Reset/restore mengikuti snapshot terpilih, termasuk ID pelanggan dan pajak nol; draft legacy tetap didukung |
| Web/mobile: hold mengosongkan cart sebelum storage berhasil | Tunggu penyimpanan durable, loader dan single-flight; gagal menyimpan mempertahankan cart |
| Web/mobile: buka draft menimpa cart yang masih berisi | Konfirmasi simpan dahulu; batal/gagal tidak membuang isi. Web memakai transaksi storage existing atomik; Android menunggu ACK save lalu restore |
| Web: respons hilang dan storage gagal dapat memicu transaksi ID baru | Proof sanitized disimpan di outbox existing sebelum request; kegagalan prewrite menghentikan mutation; recovery hanya ID/operator asli, tidak diputar ulang retry-all |
| Mobile: F4/tombol utama membuka pembayaran ketika sedang mengedit order | Simpan perubahan order terlebih dahulu, sebelum validasi meja untuk order baru. Tidak membuat penjualan/order kedua |
| Mobile: pembayaran order tempo menolak pelanggan yang sudah melekat / callback ganda | Gunakan pelanggan order yang sah, ID kosong/berbeda ditolak, single-flight sebelum await, keluar rute setelah sukses tanpa menghapus cart lain |
| Server: sale commit tetapi ACK order gagal, retry menimpa tender/pelanggan | Pulihkan snapshot sale canonical dan settlement Finance aktual, bukan payload retry; tunai/tempo/split dan partial/lunas diuji |
| Mobile: tempo tampil seolah lunas, nominal piutang Rp0 | Hasil menjelaskan belum lunas dan menunjukkan nilai piutang; label memakai tender respons server |
| Web: pesan pemulihan/pelanggan wajib campur bahasa | Katalog reviewed ID/EN dan runtime existing; tidak mengubah validasi atau nilai transaksi |
| Android: label/status detail layanan campur bahasa; pager overflow HP | Fallback/chip/durasi/status diterjemahkan sebelum interpolasi data. Pager label Flexible membungkus, bukan memotong; ID360/390 dan EN360 overflow59/29/2,3px direproduksi lalu diperbaiki |

Rincian/checkpoint: [mobile payment](POS_OPERATIONAL_MOBILE_ORDER_AUDIT_20261125.md), [web](../../front_end_template/docs/POS_OPERATIONAL_WEB_AUDIT_20261125.md), [server](../../presensi_zera_BE/docs/POS_OPERATIONAL_SERVER_AUDIT_20261125.md). Commit root: RED `3218625`, `89da0e8`, `9785fe9`, `ce308b3`; GREEN `67d91cf`, `968582e`. Commit subtugas dicatat dalam laporan masing-masing.

## Peta jalur klik dan penyelesaian

| Masuk dari | Keputusan | Akhir aman / pemulihan |
|---|---|---|
| Login → PIN | Server/PIN/cache scope pengguna tetap diverifikasi | Shift yang sudah aktif langsung digunakan; tidak memilih toko lagi pada GUI QA |
| Cart baru → Bayar | Pelanggan wajib sesuai profil, tender dan nominal valid | Sale terkonfirmasi → hasil → cart baru; printer bukan syarat selesai |
| Cart → jadikan pesanan | Bukan piutang Finance; konfirmasi maksud pengguna | Order belum dibayar tersimpan → daftar pesanan → pembayaran kemudian |
| Edit order → tombol utama/F4 | Simpan perubahan, jangan checkout cart baru | Order lama diperbarui; kegagalan tetap dapat dicoba ulang |
| Pesanan → bayar tempo | Pelanggan order sah, bukan cart lain | Satu sale tertaut, satu invoice Finance, saldo masih piutang; tidak menambah tunai |
| Hold → buka saat cart berisi | Batal atau simpan cart aktif terlebih dahulu | Pilihan lama terbuka, cart sebelumnya tetap draft; loader menunggu storage |
| Request commit → respons hilang | Status ambigu bukan penolakan pasti | Review/recovery request asli, jangan membuat transaksi baru atau menghapus bukti |
| Sukses → share/print/refresh gagal | Aksi turunan bukan transaksi baru | Hasil sale tetap sah dan pengguna dapat kembali menjual |

## Tes otomatis dan coverage terukur

| Gate | Bukti / status |
|---|---|
| Full Flutter | **1127/1127 PASS**, exit0,4menit1detik setelah seluruh source terakhir beku, concurrency2 dan timeout runner2menit; `output/operational-readiness-20261125/mobile-final-followup.log`. Gate awal final1120PASS tetap pada `mobile-final.log` |
| Full Flutter analyze | **No issues found**, exit0,97,1detik setelah follow-up; `mobile-analyze-final-followup.log`. Gate awal59,1detik juga bersih |
| Root critical |59PASS (bertumpang tindih full Flutter); `cashier-critical-final.log` |
| Follow-up Android order UI |21/21PASS pada empat suite; analyze empat berkas bersih127,1detik; commit706bc18/0811164 dan laporan mobile |
| Web POS | **397/397PASS**, exit0,22,67detik,0skip/cancel setelah follow-up label profil/workspace; laporan web dan `web-order-workspace-i18n-final-20261125.log` |
| i18n infrastructure web |41/41PASS; tidak sama dengan audit seluruh bahasa/seluruh sidebar |
| Server |148/148 integrasi dalam13suite,51/51 kontrak schema/auth/profile; laporan server memuat perintah/log |
| Verifier GUI |8/8unit guard/reconciliation PASS; snapshot database baca-saja konsisten, bukan mutasi koreksi saldo |

Run Flutter awal1078PASS/4FAIL disimpan pada `mobile-baseline.log`: satu syntax/label auditor timeout pada30detik saat RAM penuh dan tiga fixture hasil tempo masih membaca source pra-patch selama edit paralel. Gate final awal1120 kemudian **1127 setelah follow-up GUI**, keduanya exit0; tidak menghapus/skip assertion atau menurunkan guard bisnis. Dua warning style milik patch dibenahi sebelum full analyze final.

Cakupan targeted: helper held UI37/38baris (97,4%), model hold49/55 (89,1%), metode hold/restore BLoC120/127 (94,5%) pada lcov run41tes. Metode pembayaran pending86,4%, hasil pembayaran94%; patch recovery server17/17baris diff tercakup. Ini **bukan coverage80% seluruh aplikasi**; harness web method/VM tidak mengukur seluruh source Vue/outbox. Angka targeted tidak ditambahkan ke gate penuh sebagai tes unik.

Perintah utama, dari project masing-masing:

```powershell
flutter test --no-pub --concurrency=2 --timeout 2m
flutter analyze --no-pub
$webPosTests = @(Get-ChildItem tests -Filter 'pos*.test.mjs' | ForEach-Object { $_.FullName })
node --test --test-concurrency=1 $webPosTests tests/preserve-pos-recovery.test.mjs
```

Integrasi replica set dan query contract memakai perintah lengkap dalam laporan server. TDD memakai fake/deferred transport pada widget/handler; integrasi server memakai resolver/Mongo nyata. GUI di bawah memakai UI, HTTP, PIN, dan server/DB nyata; pembayaran eksternal serta printer fisik tidak disimulasikan sebagai perangkat lulus.

## GUI Android dan web — bukti baru, bukan riwayat

| Kasus | Hasil yang diamati |
|---|---|
| Login web dan Android | Keduanya berhasil lewat autentikasi dan PIN; shift fixture dipakai otomatis |
| Web tunai Rp5.000 | `INV-20261125-0001`; satu sale, laci105.000, jurnal Dr kas/Cr penjualan5.000 |
| Tutup sukses web dengan Escape | Cart0 dan tombol bayar nonaktif; tidak mengulang mutation |
| Web tempo Rp5.000 | `INV-20261125-0002`; hasil credit invoice issued, piutang5.000, laci tetap105.000 |
| Android hold A → cart kedua2unit → buka A | Konfirmasi Save and open; cart A1unit pulih, cart kedua menjadi satu draft. Pelanggan belum diverifikasi pada saat hold awal; preservation pelanggan dibuktikan widget, bukan diklaim GUI ini |
| Android draft pulih → tunai Rp5.000 → Completed | `INV-20261125-0003`; cart kembali kosong, printer tidak tersambung tidak menghalangi; laci110.000 |
| Android tempo Rp5.000 → Completed | `INV-20261125-0004`; tulisan belum lunas dan tagihan5.000, tombol selesai dapat dijangkau dengan scroll pada layar360dp |
| Web held Continue → jadikan pesanan | `ORD-20261125-0001`; belum_bayar, belum ada sale atau jurnal tambahan sebelum pembayaran |
| Order web dibuka di Android → bayar tempo | Pelanggan QA otomatis melekat, tidak diminta ulang; `INV-20261125-0005` tertaut order, piutang Finance baru5.000, laci tidak berubah |
| Web barang tracked → tunai Rp100 | `INV-20261125-0006`; stok master dan lokasi40→39, nilai400→390, jurnal HPP10 serta penjualan100 seimbang pada cabang toko |
| Web offline → tunai5.000 → online → reload | UI menyatakan Saved on this device, belum di server. Snapshot saat offline tetap6sale. Sesudah online otomatis menjadi7sale, queue0/review0/clean; reload tidak menambah sale lagi |
| Copy pelanggan wajib web EN | Pesan profil/invoice dan tombol Select Customer benar-benar EN setelah fix; batal tidak mengirim transaksi |

Follow-up copy: sidebar profil kini memakai terjemahan runtime, bukan raw title; title/status/action/fulfillment/durasi workspace order memakai kode dan SLA asli dengan label ID/EN. Gate final web397tes mencakup template SSR, handler aktual, source util tidak diubah, dan katalog. **GUI web sesudah patch lulus**: options Accepted/In Progress/Ready for Pickup/Handed over/Completed/Canceled, kartu Store Pickup/Handover20min dan catatan invoice tempo sesuai. Kelulusan GUI tersebut terpisah dari compile/SSR.

Snapshot baca-saja `../../output/operational-gui-20261125/verify-*.json` memeriksa ID unik, hubungan order/sale/invoice, jumlah, laci, stok perlokasi, akun/cabang dan keseimbangan jurnal. Snapshot `verify-web-stock-sale-2026-11-25T01-23-42-488Z.json` lulus expected6sale. Snapshot final sesudah offline/sync/reload `verify-web-offline-sync-final-2026-11-25T01-28-43-332Z.json` lulus expected: **7sale total30.100, tunai15.100, tiga invoice outstanding15.000, opening100.000→laci115.100, delapan jurnal posted seimbang** (7pendapatan+1HPP), satu order tertaut. Barang tracked master/lokasi40→39 dan nilai400→390, pengurangan satu unit/HPP10 sesuai penjualan; enam penjualan lainnya adalah jasa.

Network emulation hanya pada tab QA; setelah kasus offline, di-reset online. Tidak memutus API/Android/user browser lain. Ini membuktikan satu checkout tunai offline normal, **bukan** commit server lalu respons hilang/crash, atau race dua kasir offline.

Screenshot Android: `output/operational-readiness-20261125/android-cash-success.png`, `android-credit-success.png`, `android-order-tempo.png`. Browser diperiksa lewat snapshot DOM/aksesibilitas; penyimpanan screenshot file ditolak konektor sehingga tidak diklaim memiliki file screenshot web. Kasir web771×667 tidak overflow horizontal. Error uji interaksi karena sidebar responsif tertutup, UID berubah setelah modal/HMR, dan keyboard Android menutupi pilihan dipisahkan dari kegagalan transaksi; data dicek sebelum mencoba lagi.

Verifikasi APK **final** setelah install-r/PIN: chip **All1**, pager berada dalam viewport360dp, scroll kartu menampilkan tombol Manage services utuh48dp dan membuka detail. Detail tampil **QA customer · No table**, **27 minutes**, **Status: Accepted** dan notice invoice dilunasi melalui Finance; nama produk/customer dan nominal tetap. Screenshot `android-orders-final.png` dan `android-order-detail-final.png`. Tombol bayar ulang tidak ditawarkan pada order yang sudah menjadi piutang. Tidak membuat penjualan tambahan ketika meninjau detail. Web order390×844 juga tanpa overflow dokumen horizontal. Density emulator untuk uji360dp dikembalikan ke override semula480; ukuran override720×1280 tidak diubah. Emulasi jaringan browser dipulihkan online, viewport dikembalikan771×667. Data/sesi/draft QA tetap, bukan clear data.

## Gate produksi yang belum selesai

1. **GUI crash/reload dan respons hilang nyata** di browser/Android, termasuk kehabisan storage sesudah server commit; tes handler/repository telah PASS tetapi bukan bukti perangkat rusak nyata.
2. **Matriks GUI seluruh7profil POS×3profil inventory**, pembelian/penerimaan/transfer/opname/retur, izin dicabut offline, dua akun/laci bersama dan race tutup shift. Gate server mencakup matriks dan invariant; tidak ditulis sebagai21kombinasi GUI PASS.
3. **Printer Bluetooth/USB/QZ, customer display dan dua HP fisik**. Khusus tempo, kontrak layar pelanggan lama masih memakai `payment_success`; perlu membuktikan tampilan pelanggan tidak menyiratkan lunas.
4. **Release/deployment/observability**: CI aktual, APK/AAB release/signature, replica set deployment, COA toko/cabang lama, backup/restore dan rollback staging aktual. Tidak ada deployment/migrasi pada audit ini.
5. **Bahasa non-ID/EN dan halaman di luar alur yang disentuh** belum mendapat audit visual global. Satu tes legacy sidebar admin uppercase gagal terhadap perubahan pengguna yang telah ada; tidak diubah diam-diam demi label gate hijau.

Jangan menutup gate di atas hanya berdasarkan jumlah tes. Prioritas berikutnya: GUI pemulihan commit→respons hilang→restart→request asal dengan rekonsiliasi laci/jurnal, lalu dua akun offline dan matriks inventory.

## Rilis dan pemulihan perubahan

Patch tidak membutuhkan migrasi schema/index atau penulisan ulang jurnal. Rilis terkontrol server lalu klien yang kompatibel; simpan paket sebelumnya, backup database, dan bandingkan sale/order/request/invoice serta kas sebelum/sesudah. Bila perlu rollback, rilis ulang paket sebelumnya atau revert **commit scoped audit setelah review**, bukan reset worktree pengguna. Rollback kode tidak membatalkan transaksi finansial yang sah dan dapat mengembalikan risiko lama; jangan membuat transaksi kedua untuk mengatasi ACK hilang. Rollback staging aktual belum dilaksanakan.

## Evaluasi bukti

Akurasi4/5: hasil gate dan snapshot asli ditautkan, tetapi coverage global tidak diukur. Kelengkapan3/5: perbaikan kritis dan beberapa GUI selesai, namun permintaan seluruh flow siap produksi masih memiliki lima gate di atas. Kejelasan4/5: peta jalur/hasil uang dipisahkan, laporan panjang untuk jejak audit. Tindak lanjut4/5: patch, reproducer dan perintah tersedia; penerimaan perangkat/deployment masih diperlukan. Keringkasan4/5: final pengguna dibuat singkat, detail historis disimpan di laporan. Rata-rata3,8/5. Self-check: pengguna layak menerima perbaikan teruji, bukan jaminan universal. Perbaikan tertinggi untuk kelengkapan ialah membuktikan crash/dua terminal dan matriks profil pada rilis yang benar-benar akan dipasang.
