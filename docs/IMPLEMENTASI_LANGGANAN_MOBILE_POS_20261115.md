# Implementasi langganan Pantoo POS mobile

Tanggal: 15 November 2026. Versi Android terbaru 1.0.17+18.

## Perilaku aplikasi

Perpanjangan dan pembayaran tetap melalui https://app.pantoo.id/hrms/billing di browser eksternal. Tidak ada checkout, unggah bukti bayar, token login pada URL, atau aktivasi paket berdasarkan hasil redirect di mobile. Pemilik tetap mengikuti autentikasi dan verifikasi pembayaran web admin yang sudah ada.

Mobile memeriksa status saat sesi login dipulihkan, saat kembali ke foreground (termasuk kembali dari browser), berkala lima menit selama foreground, dan sebelum mutasi ketika pemeriksaan terakhir sudah lebih dari satu menit. Permintaan pemeriksaan bersamaan digabung. PIN operator tetap merupakan pemeriksaan tersendiri; kembali dari browser tidak mem-bypass kunci otomatis kasir.

- Aktif: kasir berjalan normal. Pengingat tampil dalam tujuh hari sebelum berakhir.
- Paket berbayar melewati tanggal akhir: maksimal tiga hari operasional, kemudian baca saja sampai akhir masa tenggang total (default tujuh hari). Nilai grace=0 dihormati. Perhitungan active/expired seragam, menggunakan batas waktu server yang tegas tanpa menunggu cron.
- Trial habis: tidak mendapat tambahan masa penjualan; baca saja sampai batas pemulihan, lalu dibatasi.
- Suspended: langsung dibatasi, tanpa masa penjualan tambahan.
- Baca saja: kasir/form penjualan dibatasi, riwayat dan laporan tetap sesuai hak akses. Semua mutasi bisnis juga dibatasi server.
- Akses berakhir: halaman langganan menutupi operasional. Pemilik dapat membuka web admin; kasir non-pemilik hanya mendapat instruksi menghubungi pemilik dan pemeriksaan ulang.
- Penutupan shift yang sudah ada dan pemeriksaan antrean tersedia melalui jalur pemulihan. PIN, hak pengguna, tenant, dan kepemilikan shift tetap diperiksa; shift baru dan perubahan kas tidak dibebaskan.
- Setelah status server aktif: entitlement, daftar toko, shift dan katalog diperiksa ulang tanpa mengosongkan draft. Shift yang sudah ditutup tidak dipakai kembali untuk checkout.
- Struk pembayaran yang sudah diterima server tetap dapat dilihat walaupun langganan kemudian habis.

Tambahan menu Langganan berada di Lainnya/Akun. Layar pelanggan tidak menerima informasi billing; saat dibatasi dikirim state idle.

## Offline, draft, dan sesi

Status terakhir disimpan di secure storage dengan scope endpoint, tenant, akun terminal, dan operator. Izin offline dibatasi maksimal 24 jam oleh server dan tidak melewati batas operasional paket. Waktu cache Android memakai pasangan boot count dan elapsedRealtime yang mencakup deep sleep, bukan selisih jam kalender. Restart proses dalam boot yang sama boleh memakai sisa izin; reboot perangkat, jam monotonik tidak tersedia/mundur, snapshot lama tanpa penanda boot, atau cache habis memerlukan verifikasi online. Cache yang ditolak dihapus. Stopwatch hanya membantu pembaruan UI di antara pembacaan waktu monotonik; sebelum penulisan offline, mutasi, dan saat kembali ke foreground, waktu tepercaya diperiksa ulang. Snapshot yang rusak, tidak lengkap, berbeda scope, atau habis tidak memberi izin penjualan baru.

Ini merupakan cache akses terbatas, bukan token replay yang membolehkan transaksi melewati pembatasan server. Server tidak menerima penjualan baru saat akses sudah dibatasi hanya karena transaksi mengirim tanggal lama. Antrean transaksi yang ditolak karena langganan tetap pending, dengan ID asli dan alasan menunggu aktivasi. Setelah aktif, sinkronisasi dapat dilanjutkan secara idempoten. Tidak ada pengecualian penjualan pada API kedaluwarsa berdasarkan waktu perangkat.

Draft aktif dipertahankan selama transisi layar langganan; perilaku penyimpanan draft saat aplikasi ditutup atau pengguna logout tetap mengikuti mekanisme POS yang sudah ada. Antrean unresolved tidak dihapus. Status langganan dibedakan dari sesi login kedaluwarsa. Ditemukan dan diperbaiki race pemulihan sesi lama yang sebelumnya bisa membuka setup bisnis setelah logout.

## Perubahan utama

Backend: utils/subscriptionAccess.js, graphql/instansi/instansi.typedef.js, graphql/instansi/instansi.resolvers.js. Endpoint GetSubscriptionStatus menambah effective_state, server_now, expires_at, operational_until, read_only_until, offline_valid_until.

Mobile: service/model/link subscription terpusat, boundary dan halaman langganan, integrasi login/lifecycle, menu, guard mutasi, guard antrean offline, pemuatan ulang konteks toko/shift, serta pemulihan sesi yang terlambat.

Tidak ada perubahan harga paket, invoice billing, webhook, gateway, atau otorisasi pembayaran web admin. Perubahan source lain yang sudah ada di workspace dipertahankan.

## Validasi

65 pengujian backend lulus: batas akses langganan, trial, status, pemulihan, keamanan pricing/billing dan kepemilikan shift/operator. 72 pengujian Flutter lulus: state/cache, tenant/operator, jam mundur, foreground resume, URL billing tanpa token, draft, struk, antrean SQLite dengan ID tetap, sesi login, PIN dan pembayaran mobile.

Analisis lib dan pengujian terkait bersih. Pengujian emulator memakai QA release pada ponsel virtual 360 × 800, data tenant baru dan Mongo replica set sementara. Aktivasi ulang disimulasikan secara terkendali pada tenant uji, bukan pembayaran uang sungguhan di web produksi. URL browser tujuan diperiksa; pembayaran/webhook billing divalidasi melalui pengujian backend existing.

Emulator berhasil menguji login/PIN, pengingat masa tenggang, laporan baca saja, pemulihan pemilik dan non-pemilik, penutupan shift saat habis, pemulihan draft, checkout tunai Rp1.000, struk yang tetap terlihat setelah expiry, serta antrean yang menonaktifkan sinkronisasi dan retry saat habis. Setelah aktivasi server dan kembali ke aplikasi, PIN tetap diminta sesuai kebijakan kunci; kasir pulih dengan stok hasil penjualan 49. Verifikasi database menunjukkan satu penjualan, satu jurnal seimbang Rp1.000, dan transaksi terhubung ke shift baru. Log Flutter/AndroidRuntime pada pemeriksaan akhir kosong.

APK produksi berhasil dibangun dan tanda tangan v2 terverifikasi. Identitas paket id.pantoo.pos, versi 1.0.16, kode 17. Registrasi plugin produksi dan SharedPreferences tersedia; plugin integration test tidak ikut. Artefak: output/pantoo-pos-subscription-1.0.16/Pantoo-POS-1.0.16+17.apk. SHA-256: 0bdc5373dda6e1977ac5f7da1658ffc845ff933d1557c7213f70c1603158ed5c.

Hasil emulator dan pemeriksaan APK akhir dicatat di output/pantoo-subscription-android-20261115 dan folder APK rilis. Belum diuji pada HP fisik.

## Urutan rilis

1. Rilis perubahan backend terlebih dahulu. Field status baru dan pengecualian pemulihan harus sudah tersedia sebelum APK baru didistribusikan. Tidak diperlukan migrasi koleksi untuk field respons tambahan ini.
2. Verifikasi GetSubscriptionStatus dengan akun pemilik dan kasir pada staging/deployment tujuan; pastikan batas waktu dan akses sesuai kebijakan bisnis.
3. Distribusikan APK terbaru 1.0.17+18 setelah verifikasi server. Jangan mendistribusikan APK QA kepada pengguna produksi.
4. Pantau error SUBSCRIPTION_REQUIRED, sesi dan antrean yang menunggu; jangan menghapus antrean sebagai langkah pemulihan.

Backend dan aplikasi belum dideploy ke produksi oleh pengerjaan ini.


## Penguatan keamanan sebelum rilis

Dua temuan audit ditangani di backend pada 15 November 2026:

- UpdateInstansi tidak lagi menerima pergantian atau pengosongan owner_id melalui profil, termasuk oleh admin. Form lama boleh mengirim kembali owner yang sama; field itu dibuang sebelum penyimpanan agar tidak menimpa perubahan kepemilikan bersamaan. Transfer kepemilikan harus memakai alur terpisah yang memiliki otorisasi khusus; alur tersebut tidak ditambahkan dalam perubahan ini.
- Konflik CAPACITY_RECONCILIATION/POS_CAPACITY hanya melonggarkan pemeriksaan kapasitas untuk jalur pemulihan yang sudah ada. Permintaan tetap melewati pemeriksaan langganan. Akses baca dan perubahan data pada tenant kedaluwarsa tidak dipulihkan oleh konflik kapasitas. PIN, billing, dan penutupan shift tetap tersedia sesuai hak akses.

Pengujian regresi tambahan mencakup JWT staf dengan klaim admin palsu, pengosongan/pergantian pemilik, pemilik/admin yang memakai API profil, form lama dengan owner sama, hak billing staf yang tetap ditolak, kedua jenis konflik kapasitas untuk pemilik/staf dan kondisi aktif/baca-saja/habis, serta query GraphQL beralias dengan konflik kontrak terjadwal sungguhan. Tes reproduksi sebelum perbaikan menunjukkan tiga kegagalan; setelah perbaikan seluruh 70 tes backend terkait lulus (0 gagal), termasuk lima tes integrasi penguatan keamanan. Log: output/pantoo-subscription-security-regression.log.

Perubahan ini berada di backend; APK 1.0.16+17 tidak perlu dibangun ulang untuk dua perbaikan ini. Backend yang dirilis harus mencakup penguatan keamanan tersebut. Belum ada deployment produksi.


## Penutupan tiga temuan audit lanjutan

Versi mobile 1.0.17+18 dan source backend lokal menutup tiga reproduksi audit:

1. GetOneInstansi memvalidasi scope tenant terautentikasi sebelum membaca database; akses lintas tenant hanya untuk admin pusat terverifikasi. password_sender, server_fcm, dan midtrans_server_key hanya dikembalikan untuk pemilik pada tenantnya atau admin pusat. Resolver field Instansi juga membatasi field tersebut agar jalur respons lain tidak membocorkannya. Staf tidak dapat menimpa kredensial; nilai kosong/null dari form profil yang disensor tidak menghapus konfigurasi tersimpan. Pemilik/admin tetap dapat mengelola konfigurasi mereka.
2. CreatePOSOrderPublic memeriksa status tenant dan akses jual di resolver, sebelum rate limiter, expiry cleanup, nomor order, reservasi stok, meja, atau pekerjaan dapur. Pemeriksaan tidak bergantung pada token opsional. Paket aktif dan masa tenggang jual tetap dapat memesan; trial habis, baca-saja, expired, suspended, tenant hilang/nonaktif ditolak. Idempotensi saat aktif dan tracking order yang sudah ada tetap diuji.
3. Cache offline Android kini terikat pada BOOT_COUNT dan SystemClock.elapsedRealtime melalui MethodChannel. Mengubah tanggal dan restart proses tidak mengembalikan sisa masa izin. Reboot memerlukan online, termasuk bila tanggal perangkat dibuat sama dengan tanggal snapshot. Cache lama tanpa stamp tepercaya tidak digunakan. Antrean dan draft tidak dihapus. Tanpa dukungan waktu platform, proses baru perlu online dan penulisan offline tidak diizinkan tanpa stamp yang valid. Ini tidak menjanjikan perlindungan terhadap OS/root yang telah dimodifikasi.

Validasi: 81 tes backend terkait lulus, termasuk 11 tes baru profil/pesanan publik. 111 tes Flutter terkait lulus; tes langganan ditambah satu kasus migrasi cache lama kemudian lulus kembali (16 tes pada berkas tersebut). Analisis lib dan tes terkait bersih. Tes perubahan jam/reboot/deep sleep menggunakan clock terkontrol; pengujian native build memastikan kode Kotlin dan channel disertakan. Belum dilakukan pengujian fitur ini pada HP fisik. Tidak ada kredensial nyata atau pembayaran sungguhan dalam pengujian.

APK 1.0.17+18 diperlukan untuk perbaikan cache offline dan mencakup perbaikan skeleton terbaru. APK 1.0.16+17 tidak memuat perbaikan clock baru dan jangan dianggap artefak rilis terbaru. Rilis backend yang sudah diperbaiki terlebih dahulu, verifikasi akun pemilik/kasir pada staging, kemudian distribusikan APK baru. Belum ada deployment produksi; pemeriksaan ini bukan klaim seluruh sistem bebas celah.


Artefak remediasi: output/pantoo-pos-security-1.0.17/Pantoo-POS-1.0.17+18.apk. Build production release selesai, identitas id.pantoo.pos versi 1.0.17 kode 18 dan tanda tangan v2 terverifikasi. Pemeriksaan DEX menemukan GeneratedPluginRegistrant, SharedPreferencesPlugin, channel subscription_clock, boot_count dan elapsedRealtime; IntegrationTestPlugin tidak disertakan. Detail hash, log tes, dan batas pengujian ada pada verification.json di folder yang sama.
