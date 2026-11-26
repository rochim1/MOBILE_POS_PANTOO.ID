import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @promoValidating.
  ///
  /// In id, this message translates to:
  /// **'Memverifikasi kode promo…'**
  String get promoValidating;

  /// No description provided for @exitAppTitle.
  ///
  /// In id, this message translates to:
  /// **'Keluar dari aplikasi?'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In id, this message translates to:
  /// **'Perubahan yang belum disimpan bisa hilang. Menutup aplikasi tidak menutup shift kasir atau mengeluarkan akun Anda.'**
  String get exitAppMessage;

  /// No description provided for @exitAppConfirm.
  ///
  /// In id, this message translates to:
  /// **'Keluar aplikasi'**
  String get exitAppConfirm;

  /// No description provided for @exitAppFailed.
  ///
  /// In id, this message translates to:
  /// **'Aplikasi belum dapat ditutup. Silakan coba lagi.'**
  String get exitAppFailed;

  /// No description provided for @pendingCreditRecorded.
  ///
  /// In id, this message translates to:
  /// **'Pesanan dicatat sebagai piutang. Pelunasan dapat dilanjutkan dari Piutang Pelanggan.'**
  String get pendingCreditRecorded;

  /// No description provided for @creditSaleRecorded.
  ///
  /// In id, this message translates to:
  /// **'Penjualan tempo dicatat'**
  String get creditSaleRecorded;

  /// No description provided for @creditSalePending.
  ///
  /// In id, this message translates to:
  /// **'Belum lunas. Tagihan tersimpan sebagai piutang pelanggan.'**
  String get creditSalePending;

  /// No description provided for @heldCartRestoreConfirm.
  ///
  /// In id, this message translates to:
  /// **'Simpan keranjang saat ini sebelum membuka pesanan tersimpan? Barang dan pelanggan saat ini tidak akan hilang.'**
  String get heldCartRestoreConfirm;

  /// No description provided for @heldCartSaveAndOpen.
  ///
  /// In id, this message translates to:
  /// **'Simpan dan buka'**
  String get heldCartSaveAndOpen;

  /// No description provided for @heldCartNotEmpty.
  ///
  /// In id, this message translates to:
  /// **'Simpan atau kosongkan keranjang saat ini sebelum membuka pesanan tersimpan.'**
  String get heldCartNotEmpty;

  /// No description provided for @heldCartOtherStore.
  ///
  /// In id, this message translates to:
  /// **'Pesanan tersimpan berasal dari toko lain. Buka toko asal untuk melanjutkan.'**
  String get heldCartOtherStore;

  /// No description provided for @heldCartRestoreFailed.
  ///
  /// In id, this message translates to:
  /// **'Pesanan tersimpan belum dapat dibuka. Keranjang tetap aman; coba lagi.'**
  String get heldCartRestoreFailed;

  /// No description provided for @cashierActionFailed.
  ///
  /// In id, this message translates to:
  /// **'Proses belum berhasil'**
  String get cashierActionFailed;

  /// No description provided for @personalProfileInvalidPhoto.
  ///
  /// In id, this message translates to:
  /// **'Foto tidak valid'**
  String get personalProfileInvalidPhoto;

  /// No description provided for @personalProfileInvalidPhotoContent.
  ///
  /// In id, this message translates to:
  /// **'Isi file foto bukan gambar yang valid'**
  String get personalProfileInvalidPhotoContent;

  /// No description provided for @personalProfileInvalidPhotoPath.
  ///
  /// In id, this message translates to:
  /// **'Lokasi foto tidak valid'**
  String get personalProfileInvalidPhotoPath;

  /// No description provided for @personalProfileUploadError.
  ///
  /// In id, this message translates to:
  /// **'Unggah foto gagal'**
  String get personalProfileUploadError;

  /// No description provided for @personalProfileTitle.
  ///
  /// In id, this message translates to:
  /// **'Profil kasir aktif'**
  String get personalProfileTitle;

  /// No description provided for @personalProfileScope.
  ///
  /// In id, this message translates to:
  /// **'Data pribadi kasir yang sudah diverifikasi dengan PIN. Hak akses, outlet, dan PIN tidak berubah.'**
  String get personalProfileScope;

  /// No description provided for @personalProfileCached.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan data terakhir. Sambungkan internet untuk mengubah profil.'**
  String get personalProfileCached;

  /// No description provided for @personalProfilePhotoChange.
  ///
  /// In id, this message translates to:
  /// **'Ubah foto profil'**
  String get personalProfilePhotoChange;

  /// No description provided for @personalProfilePhotoRemove.
  ///
  /// In id, this message translates to:
  /// **'Hapus foto'**
  String get personalProfilePhotoRemove;

  /// No description provided for @personalProfilePhotoFormats.
  ///
  /// In id, this message translates to:
  /// **'JPG, PNG, atau WebP. Maksimal 5 MB.'**
  String get personalProfilePhotoFormats;

  /// No description provided for @personalProfileIdentityReadOnly.
  ///
  /// In id, this message translates to:
  /// **'Identitas login hanya dapat diubah melalui pengaturan keamanan akun.'**
  String get personalProfileIdentityReadOnly;

  /// No description provided for @personalProfileSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan profil'**
  String get personalProfileSave;

  /// No description provided for @personalProfileSaved.
  ///
  /// In id, this message translates to:
  /// **'Profil berhasil diperbarui'**
  String get personalProfileSaved;

  /// No description provided for @personalProfileUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Profil belum dapat dimuat'**
  String get personalProfileUnavailable;

  /// No description provided for @personalProfilePickFailed.
  ///
  /// In id, this message translates to:
  /// **'Foto belum dapat dipilih. Silakan coba lagi.'**
  String get personalProfilePickFailed;

  /// No description provided for @personalProfileEmptyPhoto.
  ///
  /// In id, this message translates to:
  /// **'File foto kosong'**
  String get personalProfileEmptyPhoto;

  /// No description provided for @personalProfilePhotoSize.
  ///
  /// In id, this message translates to:
  /// **'Ukuran foto maksimal 5 MB'**
  String get personalProfilePhotoSize;

  /// No description provided for @personalProfilePhotoType.
  ///
  /// In id, this message translates to:
  /// **'Foto harus JPG, PNG, atau WebP'**
  String get personalProfilePhotoType;

  /// No description provided for @personalProfileInvalidInput.
  ///
  /// In id, this message translates to:
  /// **'Nama, nomor telepon, atau alamat tidak valid'**
  String get personalProfileInvalidInput;

  /// No description provided for @personalProfilePhotoConflict.
  ///
  /// In id, this message translates to:
  /// **'Pilih unggah atau hapus foto, bukan keduanya'**
  String get personalProfilePhotoConflict;

  /// No description provided for @personalProfileUploadFailed.
  ///
  /// In id, this message translates to:
  /// **'Foto belum berhasil diunggah. Periksa koneksi lalu coba lagi.'**
  String get personalProfileUploadFailed;

  /// No description provided for @personalProfileServerFailed.
  ///
  /// In id, this message translates to:
  /// **'Profil belum berhasil disimpan atau dimuat. Silakan coba lagi.'**
  String get personalProfileServerFailed;

  /// No description provided for @personalProfileVersionConflict.
  ///
  /// In id, this message translates to:
  /// **'Profil berubah. Muat ulang sebelum menyimpan.'**
  String get personalProfileVersionConflict;

  /// No description provided for @personalProfileReload.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang profil'**
  String get personalProfileReload;

  /// No description provided for @personalProfileInvalidSession.
  ///
  /// In id, this message translates to:
  /// **'Sesi kasir tidak valid'**
  String get personalProfileInvalidSession;

  /// No description provided for @personalProfileNoSession.
  ///
  /// In id, this message translates to:
  /// **'Sesi kasir tidak tersedia'**
  String get personalProfileNoSession;

  /// No description provided for @personalProfileNotFound.
  ///
  /// In id, this message translates to:
  /// **'Profil kasir tidak ditemukan'**
  String get personalProfileNotFound;

  /// No description provided for @personalProfileServerValidation.
  ///
  /// In id, this message translates to:
  /// **'Nama, nomor telepon, alamat, atau pilihan foto tidak valid'**
  String get personalProfileServerValidation;

  /// No description provided for @setupAutomaticContextHelp.
  ///
  /// In id, this message translates to:
  /// **'Toko dan lokasi stok awal dibuat otomatis. Setelah ini cukup tambahkan produk atau layanan. Pengaturan lain bisa menyusul.'**
  String get setupAutomaticContextHelp;

  /// No description provided for @setupBusinessLogo.
  ///
  /// In id, this message translates to:
  /// **'Logo usaha'**
  String get setupBusinessLogo;

  /// No description provided for @setupChooseBusinessLogo.
  ///
  /// In id, this message translates to:
  /// **'Pilih logo usaha'**
  String get setupChooseBusinessLogo;

  /// No description provided for @setupBusinessLogoFormats.
  ///
  /// In id, this message translates to:
  /// **'Opsional · JPG, PNG, WebP · maksimal 5 MB'**
  String get setupBusinessLogoFormats;

  /// No description provided for @setupRemainingRequiredSteps.
  ///
  /// In id, this message translates to:
  /// **'Lengkapi langkah wajib yang belum selesai.'**
  String get setupRemainingRequiredSteps;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nBatch {arg1}'**
  String pos3f03891fda02(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nBiaya aktual: {arg1}'**
  String pos79a590570387(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nJurnal asal belum terkonfirmasi'**
  String get posc0a010e50551;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nJurnal asal gagal: {arg1}'**
  String pos0c9675bd9841(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nJurnal pembatalan belum terkonfirmasi'**
  String get pos879ea9b51bd7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nJurnal pembatalan gagal: {arg1}'**
  String pos8cff67795cb5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\nOleh {arg1}'**
  String posa350f080167b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'   Catatan: {arg1}'**
  String pos661046b05cc9(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'   dan   '**
  String get pos5ce2b951d32d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'   {arg1} {arg2} x {arg3}'**
  String pos1234901f1561(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'  •  {arg1}'**
  String posde5e5ed2b7ae(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' (HTTP {arg1})'**
  String pos94fb179f2344(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' · Batch {arg1}'**
  String posc9744dc328f8(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' · Deposit {arg1} ({arg2})'**
  String pos9bf490502e78(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' · SJ {arg1}'**
  String posb34c43522da4(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' · {arg1}'**
  String posc5d767f22ec6(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' · {arg1} hari'**
  String pos97ed94c3c5d4(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' • Batch {arg1}'**
  String pos7b27157c8a92(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' • estimasi kapasitas {arg1} {arg2}'**
  String posf5cb1d63d91e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' • tertua {arg1}'**
  String posd1ebf6ed0dad(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' • {arg1}'**
  String posd672f388af0f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **' • {arg1} perlu ditinjau'**
  String posb7e0b518ea55(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'(Maks {arg1})'**
  String pos4f22066d96ef(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'08xxxxxxxxxx'**
  String get poscff2156d208d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'1 x {arg1}'**
  String pos732cde583b07(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'1 {arg1} = {arg2} {arg3}'**
  String pos87d507a0208a(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'1. Cari pembelian'**
  String get pos37bddcbf7945;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'1. Pembelian sumber'**
  String get pos7f7b7b3be96c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'10 Laporan Teratas'**
  String get pos0e33a2321322;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'2 x {arg1}'**
  String pos178f405d8376(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'2. Lokasi dan barang'**
  String get posa88673e1998a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'3. Alasan dan penyelesaian'**
  String get posda2461dc4c65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'30 Hari'**
  String get pos5e3c05aa8fbd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'30 Hari Terakhir'**
  String get pos50bbea57f4d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'7 Hari'**
  String get pos921b024be4b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'7 Hari Terakhir'**
  String get pos0127a34dfd2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'7 hari terakhir'**
  String get pos1dc3ae18814b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'90 Hari'**
  String get pos19d8d271d250;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'90 Hari Terakhir'**
  String get pos92727baf6571;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'< 1 menit'**
  String get poscd4a252704cd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'@ Rp {arg1}'**
  String pos5e6481728b57(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'AKSI TRANSAKSI'**
  String get pos5273abffc139;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ASET & KENDARAAN'**
  String get pos331ac1a57f89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ada bukti belum terkonfirmasi, termasuk jika invoice sudah lunas. Jangan menerima uang dua kali.'**
  String get pos966864740106;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ada bukti belum terkonfirmasi. Data dikunci; kirim ulang bukti yang sama untuk memeriksa hasil tanpa pembayaran ganda.'**
  String get pos36b7fb4f9a18;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ada catatan pesanan'**
  String get pos883a34a40b54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ada item yang sedang dibuat. PIN supervisor diperlukan.'**
  String get pos7fb591c94502;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ada ongkir atau biaya aktual?'**
  String get pos606436971add;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutan'**
  String get pos4d064726954a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ajukan'**
  String get pos86d441c226b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ajukan DP'**
  String get pos87fff599644e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ajukan laporan selisih'**
  String get pos3bca9769e24e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ajukan pembayaran DP'**
  String get pose735cbe9effc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ajukan retur?'**
  String get pos92f75e2f1650;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akhiri operasional'**
  String get posd3dd70b0a951;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksen Pantoo'**
  String get pos62d21681eda3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akses Aman'**
  String get pose0c6ee4c156d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akses Kasir'**
  String get pos44defb18e533;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akses manajemen meja ditolak'**
  String get posef38073448c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akses seluruh riwayat penjualan'**
  String get pos218c9c023e46;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akses stok tidak tersedia'**
  String get posde1781be836c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akses tidak tersedia'**
  String get pos6aa3a3956cf0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi'**
  String get pos60ad46d8cab9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi dokumen'**
  String get pos0a4f2e3013a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi ini mengubah saldo stok dan dapat membuat jurnal otomatis. Pastikan rincian barang sudah benar.'**
  String get posf50f867d9136;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi inventori tidak didukung: {arg1}/{arg2}'**
  String posca97584f1ff6(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi lainnya'**
  String get pose3f2d8d7197d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi penerimaan'**
  String get posd94c0defdd67;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi retur'**
  String get pos8ecb75f58601;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi tidak tersedia untuk hak akses atau status transfer terbaru.'**
  String get posaae7d1621479;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi transaksi'**
  String get pos14c9ff04273c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aksi transfer tidak dikenal'**
  String get pos843e4fd9a436;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktif'**
  String get pos89f29d42adb5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktif setelah status diubah menjadi Member'**
  String get posd11f4d838612;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktif untuk cetak struk kasir'**
  String get pos7a87cdf85a9f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Kitchen Flow pada Pengaturan POS terlebih dahulu.'**
  String get pos523105d6e126;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan Kunci POS'**
  String get pos377c77dbfc01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan di POS'**
  String get pos7336fe1bc5d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan fitur Meja / Ruangan melalui Pengaturan POS terlebih dahulu.'**
  String get posb4e26befba24;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan hanya fitur yang digunakan usaha Anda.'**
  String get pos507d126a7d6c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan lokasi penjualan'**
  String get pos2e61131b1e2f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan minimal satu toko agar meja dapat dikelola.'**
  String get posdfae3bd5850b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan opsi ini agar warehouse dapat dihubungkan ke toko POS.'**
  String get pos2df503f82de0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan toko dan pastikan profil POS yang benar digunakan oleh kasir.'**
  String get pos3825003df1e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktifkan untuk penjualan'**
  String get pos078d204bd918;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aktivitas Penjualan Harian'**
  String get pos5ba3752e3e30;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get posffcd7fbae331;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun beban'**
  String get pos08af61f4a87c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun belum berhasil dibuat.'**
  String get pos1cea339be731;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun ini belum memiliki akses inventori.'**
  String get pos1f9c9c7c8f9e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun ini belum memiliki izin melihat dashboard POS.'**
  String get pos02081f30a5e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun ini tidak memiliki izin melihat antrean pesanan.'**
  String get pos98007921829c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun ini tidak memiliki izin mengirim persetujuan.'**
  String get pos3491bbe6c880;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun kas Finance'**
  String get pose7a4c1367031;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun login'**
  String get pos940234a21581;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akun login belum memiliki PIN. Buat PIN untuk melanjutkan.'**
  String get posc94022120917;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Akuntansi Aset'**
  String get posdc1e2531a28c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat'**
  String get pos85b6ed5c3bd2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat *'**
  String get pos604bea5dda58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat Wi-Fi lokal tidak ditemukan. Sambungkan ponsel POS ke Wi-Fi atau nyalakan hotspot.'**
  String get posd1736799e06d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat gudang *'**
  String get pose23909414216;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat gudang bisa disesuaikan untuk pengiriman ini.'**
  String get pos50e596236aee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat lengkap pelanggan'**
  String get posb9fa659409c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat manual'**
  String get pos24463a1bf4d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat pengiriman'**
  String get pos6a93711c9632;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat pengiriman *'**
  String get pos5b86b934d842;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alamat: {arg1}'**
  String pos7e9ed032cc32(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan'**
  String get pos3faa833b08be;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan / catatan (wajib)'**
  String get posdfef2f134ef6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan Retur'**
  String get pos64f19d7d9668;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan barang terbuang'**
  String get posfd4eb9d469a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan disposal'**
  String get poscebf83ae7585;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan koreksi *'**
  String get pos915f1d3d6a09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan minimal 3 karakter'**
  String get posa1a64b6405f4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan minimal 3 karakter diperlukan saat terdapat selisih.'**
  String get posbabdc64fb956;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan minimal 3 karakter.'**
  String get posc99ab02e61b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan pembatalan'**
  String get posb759c899d5b0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan pembatalan *'**
  String get pos8dc82593c03b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan pembatalan wajib diisi'**
  String get posa0299a19d99f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan penghapusan'**
  String get pos6368528ded87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan penjualan'**
  String get pos5c2144140b4b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan penolakan'**
  String get pos1a3a88c34341;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan penolakan: {arg1}'**
  String pos61cebd1cf6b2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan penutupan dan sisa barang'**
  String get pos9d0ca86850d6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan penutupan minimal 8 karakter.'**
  String get pos2850a479c8f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan perubahan paksa'**
  String get pos102e192f9886;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan retur'**
  String get pos348e3ad43c94;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan selisih'**
  String get pos876421b7949e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan selisih (wajib)'**
  String get posbe448d5c839b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan selisih wajib diisi.'**
  String get posa17b7918dd15;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan selisih: {arg1}'**
  String posae638041fd8e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan tidak dicatat'**
  String get pos629480d7c6e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alasan: {arg1}'**
  String posb8a08ba6e258(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alokasi biaya'**
  String get pos0ef3120e77a1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alokasi otomatis'**
  String get pos934f80f88a89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alokasi otomatis saat dikirim'**
  String get posf2acdb6020d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alt+1 Dashboard · Alt+2 Kasir · Alt+3 Katalog'**
  String get posdbed1333c6ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alt+4 Pesanan & Meja · Alt+5 Inventori · Alt+6 Riwayat'**
  String get pos014cbca5ba87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alur & rincian transfer'**
  String get pos0a18583acc03;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alur historis belum tercatat; periksa status dan penerimaan.'**
  String get pos6aa18e2874e9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Alur persiapan'**
  String get pos74a8585178e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ambil di toko'**
  String get posf4d4a3a1d79f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Anda belum memiliki shift aktif di toko ini. Silakan masukkan uang modal awal untuk membuka shift.'**
  String get posa83f9555276d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Anda tidak memiliki akses Pesanan Aktif & Meja.'**
  String get poscfdd6e8fddd5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Anda tidak memiliki izin melihat pesanan aktif.'**
  String get posa7b14c35cb1f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Android menggunakan printer Bluetooth thermal yang dipilih di atas. Printer sistem/Wi‑Fi tidak digunakan untuk struk kasir.'**
  String get pos57fdd883599c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antarmuka yang user-friendly'**
  String get pos93f2585ace2e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antre produksi'**
  String get pos4163bd8e4931;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antrean Transaksi Offline'**
  String get pos642626eb2451;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antrean belum berhasil dimuat'**
  String get pos0e7c34e9ca53;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antrean pesanan / ambil nanti'**
  String get pos8656e7da87ba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antrean transaksi kosong'**
  String get posa48b31818805;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antrean transaksi offline tidak dapat diperiksa. Data yang tersimpan di perangkat akan disinkronkan setelah akun ini login kembali. Yakin ingin keluar?'**
  String get pos58dc6962b034;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Antrian produksi dapur'**
  String get posa29ec9f55015;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin keluar dari aplikasi?'**
  String get posf7e5b5267754;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menghapus \"{arg1}\"?'**
  String posc2901f09b11d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menghapus produk \"{arg1}\"?'**
  String pos4a7f70cd767e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Apakah Anda yakin ingin menghapus promo \"{arg1}\" ({arg2})?'**
  String posf8ddd141364d(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aplikasi Kasir Online'**
  String get pos838dc4e298c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aplikasi tujuan tidak tersedia. Struk disalin.'**
  String get posc5fdea1d176c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persetujuan'**
  String get pos8cc047ac17d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Approved'**
  String get pos41b81eb8db1b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Approved via Mobile POS'**
  String get posae94d90f653a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Arahkan barcode ke dalam bingkai'**
  String get pos05bd1eee56b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Arahkan kamera HP Anda ke QR Code untuk melihat menu'**
  String get posd36df8019474;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Arahkan kamera ke kode produk'**
  String get pos0c52685ae7e2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Area / Zona'**
  String get posbf8a40c438d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Area display'**
  String get poscc51a04a8901;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Asal transaksi; tidak menentukan cara pesanan dipenuhi'**
  String get pos220120e6e34b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Asal: {arg1}\nTujuan: {arg2}'**
  String pos57cdcf19a10a(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aset Tetap'**
  String get pos718d646d607a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Asuransi'**
  String get pos29082e6724b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atau ketik barcode / SKU'**
  String get posa514b2860c91;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur PIN'**
  String get pos092d50eb5a8a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur Widget Dashboard'**
  String get pos2037b252d5e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur diskon manual dan kode promo'**
  String get pos385f6a96ab79;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur jenis order, meja, channel penjualan, pelanggan, dan level harga.'**
  String get pos62274222e3e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur konteks penjualan'**
  String get pos8a4dc30ba939;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur lokasi display'**
  String get posaa3d8657bd92;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur lokasi penerimaan default pada profil Inventory Simple sebelum menerima PO.'**
  String get posa1b06c99576a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur pelanggan wajib, pajak, biaya, pembulatan, dan aturan penjualan sesuai kebutuhan usaha.'**
  String get pose993a43f1493;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur ulang'**
  String get pos23a638fc122e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur ulang filter'**
  String get posa77c960334e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Atur widget dashboard'**
  String get pos6f7c8f3b4837;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aturan Kombinasi Diskon'**
  String get pos436b1c573119;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Aturan saat dikirim'**
  String get posceee0f5d9b4c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'BANTUAN'**
  String get pos7cf89ee76e92;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'BUKTI PENCATATAN PEMBAYARAN'**
  String get poseaf71d6b1c79;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Backend memvalidasi izin scrap dan akun.'**
  String get posdda079aaa57c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Backup database plaintext masih tersedia. Pemulihan manual diperlukan.'**
  String get pose4a1e6e1f820;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bagikan'**
  String get posafec631300bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bagikan Struk'**
  String get pos10cfbdcd57a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bagikan sebagai PDF'**
  String get pos9abbb72a14c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bagikan sebagai PNG'**
  String get pos140852a655fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bagikan struk melalui'**
  String get pose56f546cb66e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bagikan struk {arg1}'**
  String pos720eb19e66de(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bahan Baku'**
  String get poseda849fb70be;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Baik'**
  String get pos04f5b5ce0518;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang'**
  String get pos91f651c54514;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang / kode'**
  String get pos8063497da7c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang Dagangan'**
  String get pos950214d9b446;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang Dalam Proses'**
  String get pos77ea2d0a96a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang PO'**
  String get pos006fca52153a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang berserial'**
  String get pos35437e6347ba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang dalam keranjang akan dihapus dari keranjang, bukan dari stok. Setelah itu toko dan shift diperiksa kembali.'**
  String get pos938de32b04cc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang diretur'**
  String get pos689b25ff156e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang diterima'**
  String get pos9d3aa1c12691;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang hilang'**
  String get pos30351205ff4a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang rusak'**
  String get posda515f4d210f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang stok tidak tersedia pada katalog PO. Pilih barang secara manual.'**
  String get pos3d78f1b4c031;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang sudah ada di daftar disposal'**
  String get posf4efcb605d73;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang sudah ada. Ubah jumlah pada daftar.'**
  String get pos91a68e9bf513;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang tidak ditemukan'**
  String get pos1900451e3409;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barang tidak termasuk snapshot opname.'**
  String get pos024cd8937b2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barcode'**
  String get pos8e54dc5331b0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barcode tidak ditemukan di lokasi sumber'**
  String get pos68699a00fc9d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barcode tidak ditemukan pada penerimaan PO di lokasi ini'**
  String get pos18f08eeb773c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barcode {arg1} tidak ditemukan'**
  String pos6385c5b0e840(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Barcode · {arg1}'**
  String pos49b67ac0c655(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Baris 3'**
  String get poscbff89c30c54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Baris 4'**
  String get poseee53cdc7cd8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Baru'**
  String get pos5356cfdd73c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Baru ({arg1})'**
  String pos0c1674e894ea(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Baru saja'**
  String get posaac8eb7439e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get pos1433539c3b8f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batal Beli'**
  String get pos3432aed9b1cd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan'**
  String get posdbe47c83d4ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan Penerimaan'**
  String get pos5b90d4ccc074;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan item'**
  String get posa82ba1a88e58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan pembayaran'**
  String get pos7f1262289c0d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan pembayaran?'**
  String get pos7b849f4abad8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan pesanan'**
  String get posa4babe595ba6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan pesanan?'**
  String get pos4a4299234e5f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batalkan {arg1}?'**
  String pos345a2afe9fe7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batas Pemakaian'**
  String get pos0059ce715aa6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batas dengan toleransi {arg1}%: {arg2} {arg3}'**
  String poscd4516ba1708(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batas per pelanggan (pilih pelanggan saat memakai promo)'**
  String get posaf8c680677bd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch'**
  String get pos8bf1ef5668b1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch & Kadaluarsa'**
  String get pos518025a13256;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch sumber *'**
  String get pos007c04bae657;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch {arg1}'**
  String pos6f9650674671(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch {arg1} · {arg2}'**
  String posf45b61e66113(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch {arg1} · {arg2} · {arg3}'**
  String posa2f8e389c7e3(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch {arg1} • {arg2} {arg3} • {arg4}'**
  String pos08ea63214a56(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch, kedaluwarsa & keterangan'**
  String get posb189a6911737;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Batch: {arg1} · {arg2}'**
  String pos19c47f48a246(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bawa Pulang'**
  String get posa74cc32718e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bawa pulang'**
  String get pos9fffab284d64;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar'**
  String get pos6290c54f33d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar Invoice'**
  String get pos2d38facc4bc6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar Sekarang'**
  String get pos83553f81803a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar dahulu'**
  String get pos7f4c8305af51;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar layanan'**
  String get pos410df9b15672;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar pesanan'**
  String get posdf6097e391d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar: TUNAI'**
  String get pos28ee50878525;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bayar: {arg1}'**
  String posc5a29ff60a03(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bea cukai'**
  String get posa8059b4336f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bea masuk'**
  String get pos7293acd977ab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Beban langsung'**
  String get posd3eb55d8cbba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum'**
  String get pos81939e0e20a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum Bayar'**
  String get pos6e4dada04531;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada Pembelian Langsung.'**
  String get posb986d9ad990c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada Vendor Bill'**
  String get pos598513b20333;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada aktivitas penjualan'**
  String get posdb8e78b6ec5a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada akun kas/bank aktif. Siapkan di Finance terlebih dahulu.'**
  String get pos899ee8cadfc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada barang di Purchase Order'**
  String get pos5c9d5645a0d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada barang dipilih'**
  String get poscb8c5ab29822;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada barang terbuang'**
  String get pos46c0b148c7ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada capability'**
  String get pos15c81191fdf8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada data pembayaran'**
  String get pos7279f5c9e547;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada data penjualan'**
  String get posd22960cd0836;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada data produk'**
  String get pos651b68f6fe3a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada data transaksi void yang tersedia pada laporan.'**
  String get pos6f9c9a1f794d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada karyawan POS yang memiliki PIN.'**
  String get pos3308e06280d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada lokasi penerimaan aktif. Siapkan gudang sebelum membuat PO.'**
  String get posa926cc08c2fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja'**
  String get posf6da7e042e93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada meja aktif pada toko ini. Tambahkan meja dari Pesanan Aktif & Meja.'**
  String get posacd2f4b89b2a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada notifikasi'**
  String get pos5658d501e419;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada notifikasi baru'**
  String get pos73d8486b74a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada pembayaran pada periode ini'**
  String get pos94c914fad3b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada penerimaan barang'**
  String get pos8ca874c0e3a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada pengguna yang dapat dikelola PIN-nya'**
  String get pos57884a94b3d4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada penilaian pelanggan yang tercatat pada transaksi POS.'**
  String get pos3274d92c93e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada pergerakan stok pada toko ini'**
  String get pos6f932a5dc6bf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada permintaan DP.'**
  String get pose9fb26380266;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan'**
  String get posb0797ccd020a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada pesanan aktif di meja ini'**
  String get posa8504016d97d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada printer sistem yang terdeteksi. Periksa koneksi dan driver printer, lalu muat ulang.'**
  String get pos3fb98935fea6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada produk terjual pada periode ini'**
  String get pos68bd5cb61e21;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada promo'**
  String get posb6d4aa9799f7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada retur'**
  String get pos8a142384fc87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada retur ke supplier'**
  String get pos7433ec2c06fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada riwayat shift'**
  String get posfe11ad31ef77;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada saldo lokasi. Tambahkan melalui penerimaan, mutasi, atau Stock Opname.'**
  String get posfa31b1ef910c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada toko aktif'**
  String get posf2005c65e96b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi'**
  String get posa2fdf4433bf7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi deposit yang tercatat pada periode ini.'**
  String get pos9c542f99f553;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada transaksi kasir pada periode ini'**
  String get pos2a03d2d18522;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada tren penjualan'**
  String get pos084bf3032b4b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada warehouse'**
  String get pos92414ac02d75;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada warehouse aktif dengan capability Lokasi Penjualan. Aktifkan melalui Inventori > Warehouse & Lokasi.'**
  String get poscc03af637140;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ada warehouse yang diaktifkan untuk penerimaan pembelian.'**
  String get pos2512eb5b68b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum dibayar'**
  String get posf22109b83333;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum dikategorikan'**
  String get pos18f1630f1efa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum dikirim'**
  String get posb4c54491b1bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum dinilai'**
  String get pos14cc6d46510e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum dirinci'**
  String get pos6b18a18f0c5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ditautkan'**
  String get pos7e04d8c095fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum ditentukan'**
  String get pos1efe06a0e688;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum diterima'**
  String get posb90b37ff1647;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum lunas'**
  String get pos349d5df8e0b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Belum punya akun?'**
  String get posddb343c7e461;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bengkel'**
  String get pos9cb490a9372c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bentuk penjualan'**
  String get pos6bba8482fe7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bentuk penjualan *'**
  String get pos8c8cbf07fdcd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Beralih ke {arg1}... (Mock)'**
  String posde300b92dea3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Beranda'**
  String get pos014665dae415;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Berat (kg)'**
  String get posdbed99defc36;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Berat/jumlah harus sama dengan jumlah layanan di keranjang ({arg1}).'**
  String pos7c7180cb6f69(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Berdasarkan jumlah'**
  String get posae7d0610525b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Berdasarkan nilai'**
  String get posf2c55794b1c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Berikutnya'**
  String get pos1b4ac3d41520;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Besar'**
  String get pos0370e213f855;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya PO lama'**
  String get pos2f5b87dba6e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya aktual berhasil diterapkan ke nilai barang'**
  String get posbfe9ecf615b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya aktual {arg1}'**
  String pose8182cdba6ee(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya harus Rupiah bulat, nol atau positif.'**
  String get pos08816e7b0295;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya tambahan'**
  String get pos8f7fb601cfa7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya tambahan mengikuti alur PO lama.'**
  String get pos63b631fe67be;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya transfer Rp{arg1} · {arg2} / {arg3}'**
  String pos4ba07f7ac271(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Biaya, rekening & dimensi (opsional)'**
  String get posb607afe9f747;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bisa memakai pecahan, contoh 3,5 kg'**
  String get posbab48ae66a12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Blokir Sepenuhnya'**
  String get poscd9c695d49e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bluetooth tidak dapat diakses. Aktifkan Bluetooth dan izinkan perangkat terdekat.'**
  String get pos19e493c97a63;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Boleh kurang dari sisa untuk pengiriman parsial'**
  String get pose88f4040c3d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Boleh memakai nomor penanggung jawab sementara.'**
  String get posa0715d3a79a0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Browser tidak dapat membaca data gambar'**
  String get posa22c854942d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buang / kurangi stok'**
  String get posb1fa64be5914;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buang stok'**
  String get pos61ee66a29d62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat Opname'**
  String get pos8dae890b08ab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat PIN'**
  String get pos360cc15b6ba7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat PIN Akun Ini'**
  String get posca32f5206a2e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat PIN Kasir'**
  String get posd80023a69926;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat PIN aman'**
  String get posd111042dd9cb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat PO'**
  String get pos8614fc0335e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat PO untuk stok ini'**
  String get pos97fa09336bab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat Pesanan'**
  String get pos66b53af504dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat Pesanan / Ambil Nanti'**
  String get posb3e593a0ffd0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat Profil & Lanjutkan'**
  String get pos821ca8d7294b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat Promo'**
  String get pos1fa1f01587d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat akun dan lanjutkan'**
  String get posa73f9c464f90;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat dan aktifkan toko sebelum membuka tampilan dapur.'**
  String get posc7c1e1b2a335;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat lokasi operasional'**
  String get pos8205f5d23cde;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat lokasi penjualan aktif untuk dihubungkan ke toko POS.'**
  String get pos368caa939994;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat lokasi stok pertama agar outlet dan inventori dapat digunakan.'**
  String get pos61cd75a720e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat opname baru'**
  String get pos420196e519d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat pesanan / ambil nanti?'**
  String get pos184157557fa8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat pesanan ke supplier, lalu terima barang saat tiba. Stok belum bertambah saat PO dibuat.'**
  String get posaa415fd24064;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat promo atau voucher untuk meningkatkan penjualan dan loyalitas pelanggan.'**
  String get pose26137a4b826;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat tautan pairing'**
  String get pos26932da5bd8c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat toko POS'**
  String get pos139ad9e341d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat toko POS dan hubungkan dengan lokasi stok.'**
  String get posf1425150ed0d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat warehouse/lokasi dan pastikan dapat digunakan untuk stok.'**
  String get pos7ec5aa8a6bf8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buat, reset, atau buka kunci PIN karyawan kasir.'**
  String get posfd17909d918f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka'**
  String get posa82a3cd50dd4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka Pesanan Aktif'**
  String get posb3ddf2f52880;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka Shift'**
  String get pos796c94ee5e36;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka Shift Kasir'**
  String get pos498ce68c0dd1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka Shift Sekarang'**
  String get posab916481634f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka Stock Opname'**
  String get pos56ea24057566;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka aturan stok dan satuan'**
  String get posf1e83734c2af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka dan pantau shift'**
  String get posafea24434657;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka detail produk dan pastikan jumlah serta hierarki lokasinya sudah sesuai.'**
  String get pos5444c6986d9e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka kasir'**
  String get posf4921f9ec211;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka kunci operator'**
  String get pos066fc659b3bc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka pengelolaan PIN operator'**
  String get pos16d7a562dfd4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka shift'**
  String get pos6cd0bf95632e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka shift kasir sebelum membuat pesanan.'**
  String get posffcd01906370;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka shift kasir untuk melihat dashboard toko ini.'**
  String get posea8b17847200;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka shift kasir untuk menampilkan meja toko aktif.'**
  String get pos4c23101b3098;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka shift pada toko yang akan dikelola agar meja tidak tercampur antar toko.'**
  String get pose9f8df76cc9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka shift sebelum memilih meja.'**
  String get pos3825c8e27ca2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Buka tautan ini pada tablet/monitor pelanggan. Layar tersebut hanya menampilkan keranjang dan total, tanpa akses akun POS.'**
  String get pos878b88da5fcb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti Pembayaran'**
  String get posb519abaf52ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti belum terkirim. Periksa koneksi lalu coba lagi.'**
  String get pose588dc62fcf1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti draft gagal disimpan. Retur belum dikirim.'**
  String get pos07deb6efb37c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti draft retur lokal tidak terbaca. Jangan buat pengganti; minta pemeriksaan administrator.'**
  String get posc7897ff29a9c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti draft tidak dapat disimpan. Retur belum dikirim.'**
  String get pos0c3d913e5dc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti ini hanya menjadi submission. Mobile tidak membuat utang atau Vendor Bill.'**
  String get posf57d2184db0f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti kehilangan: {arg1}'**
  String pos685b57405ff1(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti nota'**
  String get posd271b7b998ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti nota sudah diunggah'**
  String get pos1833807f3c7e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti pembayaran yang dibatalkan tidak dapat dicetak.'**
  String get pos660052e375fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti pencatatan pembayaran dapat dibuka kembali dari riwayat pembayaran.'**
  String get pos1b7df73ea919;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti penerimaan lokal tidak terbaca. Jangan membuat pembayaran baru; minta pemeriksaan administrator.'**
  String get pos4ff6b8dd30f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti penerimaan tidak dapat disimpan. Pembayaran belum dikirim.'**
  String get pos84cc7cca3edd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Bukti terkirim. Finance akan memverifikasi sebelum membuat Vendor Bill.'**
  String get pos7b2f27bd5996;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang / Gudang'**
  String get pos98a45dc13ac8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang / Outlet'**
  String get posc5db540e520b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang / lokasi stok *'**
  String get pos1d4c0a709c37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang Bandung'**
  String get posc3913ea774d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang Surabaya'**
  String get pos9f4b06552ad9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang pembayar'**
  String get pos0cd34cfb1a1c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang pembayar: {arg1}'**
  String pos424b98aa8546(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang penanggung jawab'**
  String get pose8081560055d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang penerimaan *'**
  String get pos5023a9f946b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cabang: {arg1}'**
  String pos58c6df885eda(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cacat Produksi'**
  String get posd4a5652ee638;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cacat produksi'**
  String get pos1d3d9dc32e81;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cache toko belum diperbarui; mode shift offline mungkin belum siap.'**
  String get posdc0885b7a416;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cakupan offline: penjualan tunai dan penyimpanan pesanan kasir. Pesanan baru masuk meja/dapur setelah sinkronisasi; pembayaran elektronik, shift, pelanggan, dan perubahan inventori wajib online.'**
  String get pos8c9333b49aed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Campuran'**
  String get posa0516ee1776c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Capability operasional'**
  String get pos6c003b6e23a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cara menyambungkan'**
  String get pos40d8fcea97ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cara persiapan *'**
  String get pos08df45881eeb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari'**
  String get pos3f2275d79afb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari GRN, PO, atau supplier'**
  String get pos5d4d90a9f276;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari Invoice'**
  String get posa0f36a05b9b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari No. Retur / Invoice...'**
  String get pos851a9739e744;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari PO atau pemasok'**
  String get pos28320e410ffc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari PO yang akan diterima'**
  String get pos19e0d7731f54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari SKU atau nama produk...'**
  String get posbaa59be41455;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari atau scan produk'**
  String get pos9bdd15bae8f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari atau tambah supplier'**
  String get posc9786ac32af9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari bahan atau komponen'**
  String get pos509357cda333;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari barang'**
  String get posad0a8d45adbe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari invoice atau pelanggan...'**
  String get pos0a84e049b97b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari kategori'**
  String get pos880381e34e30;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari kode atau nama promo...'**
  String get pos7d5dad6647f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari meja'**
  String get pos6128892a6425;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari meja...'**
  String get pos4c2ea53bb4b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari menu'**
  String get pos16a4a1d8fed2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau kode produk'**
  String get posa01a225919b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau kode toko...'**
  String get posa4c02a6d9615;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau nomor telepon...'**
  String get pos00d1db3d643f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau telepon...'**
  String get pos031c855ae1be;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama atau username…'**
  String get pos8ed9d8f649ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama, kode atau barcode'**
  String get posd1772193eff8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama, kode, SKU, atau barcode...'**
  String get pos4792ca61c79a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nama, kode, atau telepon'**
  String get pos8c45e1cf3dda;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor / barang terbuang'**
  String get pos3f6b1fb10707;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor / lokasi mutasi'**
  String get posa999e7406679;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor PO atau pemasok'**
  String get pos7bfa890763c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor faktur / supplier'**
  String get pos480e34d203d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor opname'**
  String get pos01abd969d17f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor order atau pelanggan…'**
  String get pos45893b182246;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari nomor retur / supplier'**
  String get pos2c7ddda93ab8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari order / pelanggan'**
  String get posbbf757a632b7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari pelanggan'**
  String get pos0e369e2675c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari pelanggan / nomor invoice'**
  String get pos6a7ae838b897;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari produk...'**
  String get pos2b52cbef4d75;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari referensi'**
  String get pos8ec5c4f82650;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari semua kategori'**
  String get pos44491bc7acef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari toko atau kasir...'**
  String get pose53a0b916aed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cari warehouse'**
  String get pos214f0a2c34f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat Respons Supplier'**
  String get posde86a77fb4f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat biaya'**
  String get posb0f56a08deaa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat modal awal'**
  String get pos242aa2e706b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat modal awal sebelum bertransaksi'**
  String get posccb283cfadfa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat ongkir/biaya aktual'**
  String get pos20ffe2dcf59d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat pembayaran'**
  String get pos3a9e2b952f34;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catat penerimaan'**
  String get pos4be7f0b2d102;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan'**
  String get pos9f09aefd0dd4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get pos4d40bd22aea8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Bawah 1'**
  String get pos59ff732632a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Bawah 2'**
  String get pos3611e7728d8f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Bawah 3'**
  String get pos207ab68e27c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Buka Shift'**
  String get poscab450e481c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan PO'**
  String get pos750a62716d04;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Posisi'**
  String get pos284f0ee8e92f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Tambahan'**
  String get posaab3e9bd88a0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan Tutup Shift'**
  String get pos5018e0878c03;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan barang'**
  String get posf6b887f49700;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan barang (opsional)'**
  String get posa6ea551f47a7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan ini menjadi jejak acknowledgement supplier.'**
  String get pos7bc0abb662e7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan item'**
  String get pos9d266dc2187e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan keputusan (wajib)'**
  String get pos429f76d8ac4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan keputusan wajib diisi.'**
  String get pos4c0503349b16;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan penerimaan (opsional)'**
  String get pos7f28ea292f1e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan rekonsiliasi wajib 5–500 karakter, sertakan hasil pemeriksaan invoice dan uang.'**
  String get posf93a11f8dc1f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan respons supplier'**
  String get pos7e4eb72f29cd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan stok terbuang tidak tersedia'**
  String get pos179a4b68771a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan tambahan (opsional)'**
  String get pos4b4077f266dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan termin'**
  String get posa79789981a31;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan transaksi'**
  String get posf1f2ec007def;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan transfer'**
  String get pos9fdeae550e61;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan umum'**
  String get pos678064362122;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan untuk Finance'**
  String get pos61d31d182c5a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan ✓'**
  String get pose7a3c1fea4d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan/alasan barang'**
  String get pos850320f14d8a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan: {arg1}'**
  String posb0bf84cc5839(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Catatan: {arg1}\n'**
  String pos9715ac503203(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cek'**
  String get pos3de4a8034ba3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cepat (teks ESC/POS)'**
  String get pos72e4a5528b85;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cepat memakai teks ESC/POS dan tetap mengikuti field template. Pilih Presisi jika logo dan tampilan PDF harus sama persis dengan preview.'**
  String get pos6832a5cc9dec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak'**
  String get pose96378dc0a9d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak A4 (dialog perangkat)'**
  String get posbf3948a9c7d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak PO (A4)'**
  String get posc9fe212abb29;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak PO A4'**
  String get pose75740ca1028;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak QR'**
  String get pos4bd5367ef2a1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak QR semua meja'**
  String get pos6eeefc32fd54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak Struk'**
  String get posdb282005fdde;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak Struk Otomatis'**
  String get pos5e15d47f8805;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak label'**
  String get pos0436e2610a39;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak label barcode'**
  String get pos81c5b456162a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak langsung tanpa dialog sistem'**
  String get posb85a4c291fc6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak memakai printer terminal yang dipilih di Pengaturan Printer. Bluetooth thermal memakai kertas 58/80 mm; pratinjau PDF dapat dibagikan untuk cetak label A4.'**
  String get posb839576681e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak struk otomatis'**
  String get posa49225d73292;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel'**
  String get pos879f0b1bef59;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel Penjualan'**
  String get posec9fa27f5363;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel Penjualan Aktif'**
  String get pos2732c93ec01e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel Penjualan Default'**
  String get pos5378450ff38c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel mencatat asal transaksi; level harga menentukan daftar harga produk.'**
  String get pos215f81053c80;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel pengiriman'**
  String get pos99f4e83b5182;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel penjualan'**
  String get pos117aaa80c629;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel, level harga, pajak dan promo'**
  String get pos8e3b14cc8ee8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel, tipe pemenuhan, dan level harga disimpan sebagai konteks terpisah.'**
  String get pos1ac8ccbface8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel: Retail'**
  String get posd005afbbf88c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Channel: {arg1}'**
  String pos49724ddf398a(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Check-in'**
  String get pos48431e7fc690;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Checklist kesiapan'**
  String get posb03be9c4890a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Checklist kesiapan POS'**
  String get posac0aa5686aed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ciutkan menjadi ikon'**
  String get pos5eab5c3809a5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Client transaction ID wajib tersedia'**
  String get pos30def46f381e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba Jurnal Lagi'**
  String get pos91fc1531e59b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get pos4d65e8901484;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba hubungkan Google'**
  String get pos00108ed7c185;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get pos3a4d28a11e41;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba lagi dalam {arg1} detik'**
  String poseb9c086c8b8f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba status lain atau atur ulang filter.'**
  String get pos883a2e7b41b7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba ulang'**
  String get pos9b1482c4ef2e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Coba ulang yang ditolak'**
  String get pos03569164e0e5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cocok untuk arsip dan cetak ulang'**
  String get pos2fafd764d3d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get pos1798b3ba42ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh struk diunduh. Buka PDF untuk mencetak.'**
  String get pos3134925510af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh struk gagal disiapkan. Coba lagi tanpa logo atau periksa koneksi.'**
  String get pos4890f7931178;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh struk gagal diunduh'**
  String get pos3293fef167a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: 081234567890'**
  String get pos51308b6e8b02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: 1 dus = 12 pcs. Faktor selalu terhadap satuan dasar.'**
  String get pos898e357d0aec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: 10'**
  String get pos7bcecbcde1fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: Budi Santoso'**
  String get pos5c50a1fbf422;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: DP sesuai proforma supplier'**
  String get pos22201d029e0f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: HEMAT10'**
  String get pos1b776cdb429d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: Meja 1'**
  String get poscccac117a03d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: Minuman'**
  String get pose6223f9ee6fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: Pesanan Pak Budi'**
  String get pos7d0ed2ed463c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: Toko Pantoo Jaya atau Koperasi Maju'**
  String get posaafc591a1c5c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: dekat taman'**
  String get pos62144a2a8f91;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: jumlah atau lokasi penerimaan keliru'**
  String get pos9bca286a77ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: mitra khusus'**
  String get pos53a0336ceb4c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: opname bulanan atau audit gudang'**
  String get pose7c61a629b5a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Contoh: pesanan tanpa sambal, referensi pembayaran…'**
  String get posa7ec0efc73fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perusahaan'**
  String get posa83ed75221e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ctrl+Delete kosongkan keranjang · F1 tampilkan bantuan'**
  String get pos2c25fce5caf7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cucian pelanggan'**
  String get posb308c80ddcd3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get pos081ae3fdc403;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'DIBATALKAN - BUKAN BUKTI PEMBAYARAN AKTIF'**
  String get pos484aa1f13bf0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'DIBATALKAN · {arg1}{arg2}{arg3}'**
  String pose9eafafbbdc8(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'DIBAYAR'**
  String get pos2473c371f29e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'DRAFT - BELUM DISETUJUI - BUKAN PESANAN RESMI'**
  String get pos18a93cadfbd4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar & Mulai Trial'**
  String get pos52e887b1d178;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar PO gagal dimuat: {arg1}'**
  String pos5ffbf6ce4162(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar POS Mobile'**
  String get pos20848bfc13d4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar alasan koreksi belum tersedia'**
  String get pos5aa835a174a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar barang'**
  String get pos48db80a52a7a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar barang dikosongkan agar stok dan batch tidak memakai lokasi lama.'**
  String get pos1b213e639868;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar harga yang diterapkan pada produk'**
  String get pos0bbd7d660e6e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar invoice belum dapat dimuat'**
  String get pos0917fb0c311a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar kasir belum dapat dimuat. Periksa koneksi lalu coba lagi.'**
  String get pos16d4c9851bf6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar kasir telah diperbarui. Pilih kasir dan masukkan PIN kembali.'**
  String get posa6544b4fc7b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar kasir tidak sesuai dengan sesi saat ini. Keluar dari akun, lalu login kembali; transaksi offline yang belum dikirim tetap tersimpan.'**
  String get pos11964f8c8c3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar meja kosong'**
  String get pos6078827d658d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar pelanggan gagal dimuat. Coba lagi.'**
  String get posb00b95f31134;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar retur belum termuat'**
  String get pos0aad90265c2d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar sekarang'**
  String get pos18b852d98827;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daftar toko POS tidak tersedia'**
  String get posa0be338d3aa0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dalam perjalanan'**
  String get pos490ed470f481;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dapur'**
  String get pos1a3a18c173e2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dapur toko'**
  String get posc400c1a3475c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dari tanggal'**
  String get pos30b35bf928d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dasar jatuh tempo'**
  String get posdf17dcc0a2bf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dashboard'**
  String get posd87f47b47e4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dashboard Inventory'**
  String get posc107e17f81a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dashboard gagal dimuat. Periksa layanan server, lalu coba lagi.'**
  String get pos03f3b45fc439;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dashboard offline belum tersedia. Hubungkan internet sekali untuk menyiapkan data pada perangkat ini.'**
  String get posf965d3a8b69e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data Finance online. Penerimaan ke akun kas/bank terpilih, bukan penjualan baru atau uang laci shift.'**
  String get pos43c834aa1dbb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data Kendaraan'**
  String get pos38e41ab8e289;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data Mitra'**
  String get pos089bf95c1718;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data Pelanggan'**
  String get pos45f311257113;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data bahan/produk belum lengkap. Muat katalog saat online terlebih dahulu.'**
  String get pos5a8f96fbe340;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data belum dapat ditampilkan'**
  String get posc1d6daf21f74;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data berhasil dimuat ulang'**
  String get posee6a41d358ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data dashboard POS tidak tersedia'**
  String get posb7df95de52ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data inventori mengikuti akses gudang akun kasir.'**
  String get posf01e8a6fdf1f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data kasir belum siap'**
  String get pos60f60e2a769d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data kendaraan'**
  String get pos9c9139adbf85;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data langsung dari transaksi POS'**
  String get posb0dfaf79e365;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data master produk akan disinkronisasi ke server pusat. Konflik SKU/Barcode akan diselesaikan oleh server.'**
  String get pose84f77699217;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data pelacakan wajib'**
  String get pos394acb774655;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data pembayaran tidak lengkap'**
  String get pos84689d8e8228;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data pengaturan tidak ditemukan'**
  String get posa9ef081bfe11;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data pesanan belum dapat dipastikan kosong. Periksa koneksi, lalu muat ulang.'**
  String get pos64ff917593dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data terakhir disimpan {arg1}/{arg2} {arg3}:{arg4}'**
  String pos184f17ad7f06(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data terakhir yang tersimpan di perangkat'**
  String get pos8c7c7c39b297;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data tersimpan aman di server'**
  String get posa4bf79e3f75d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data tersimpan · {arg1} · Belum real-time'**
  String pos644f622b51e8(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data tidak ditemukan'**
  String get posa7d5538e2c7d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data toko atau meja tidak valid untuk QR.'**
  String get posd836206df077;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data toko dan shift belum dapat diperiksa. Periksa koneksi atau PIN, lalu coba lagi.'**
  String get posfc74494f5df2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Data transaksi stok, batch, dan kedaluwarsa dicatat saat penerimaan.'**
  String get pos8399f1eec253;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Daur ulang'**
  String get pos48451e69e7b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Default Catatan'**
  String get posdf8831116b32;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Default transaksi'**
  String get pos90f1fcb90983;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Demi keamanan, gunakan kombinasi huruf dan angka pada kata sandi baru Anda.'**
  String get poscf2f05740bfc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dengan melanjutkan, Anda menyetujui\n'**
  String get posd080689508ec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Deposit diminta'**
  String get pos51aafce040a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Deposit lama (tanpa stok)'**
  String get pos16e8e04bae02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Depresiasi'**
  String get posa076971a19ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Deskripsi'**
  String get pos7e9fd192194a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Deskripsi biaya'**
  String get posee86ab5a4ec8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Deskripsi pembelian'**
  String get pos396817a916ba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Deskripsi produk'**
  String get posf7d2ea1a9af1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail'**
  String get pos7c9a7c0610c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail & aksi'**
  String get pos484c446bce76;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail Pesanan'**
  String get pos7186342ca1c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail Retur'**
  String get pos40da1155cb2b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail Transaksi'**
  String get pos6c9f7d072fb1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail alasan / kronologi'**
  String get posf2ddf7714819;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail cucian'**
  String get posde32af10ad9a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail layanan'**
  String get posdfe99ad316f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail reservasi'**
  String get posa715d7fff607;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail tambahan'**
  String get posd8a42a009a66;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Detail {arg1} #{arg2}'**
  String pos849b319bd7c1(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dev: Custom Endpoint'**
  String get pos516a8ee6d983;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Di tablet atau monitor pelanggan, pindai QR atau buka tautan yang disalin. Tidak perlu login.'**
  String get posb751386df8ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diajukan'**
  String get pos2c509d533219;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan'**
  String get pos1ed2b478dc44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibatalkan pada'**
  String get posd3581c34b5fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibayar'**
  String get pos42b86f7c1b0f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibayar sebagian'**
  String get pos86a0bc70a8c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibayar {arg1} · Dialokasikan {arg2} · Saldo {arg3}'**
  String pos39807fd70afd(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibuat'**
  String get pos5264ac49ed12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibuat ({arg1})'**
  String pos74663425a1fa(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibuat oleh'**
  String get pos1216355f2efb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibuat otomatis oleh server'**
  String get posd1778edc3905;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibuka {arg1}'**
  String pos8e461e69d307(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dibukukan'**
  String get posc2f087b83545;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dicatat oleh'**
  String get pose70ef903e04d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dicatat oleh pembeli; bukan kuitansi supplier.'**
  String get pos710d22161734;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dicatat pada'**
  String get pos467c0f809a3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dicuci'**
  String get poscdce89cf2c57;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Didaur ulang'**
  String get pos6deabc07d983;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Digunakan untuk estimasi margin'**
  String get pos8b8e792d8b25;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dihapus melalui Mobile POS'**
  String get pos892f01466fd8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dihitung otomatis dari penerimaan barang (AVCO)'**
  String get pos67c05c254660;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikemas'**
  String get posb3b82d71d5ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikeringkan'**
  String get pos2f26e1050cf3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikerjakan'**
  String get pos2418f99b37f4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikirim'**
  String get pos9e1e4a8b51eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikirim ke supplier'**
  String get pos5aa9a930457b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikirim {arg1} {arg2} · Diterima {arg3} · Diselesaikan {arg4}'**
  String pos2edf59b130d4(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikonfirmasi'**
  String get pos0f258d986494;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dikreditkan'**
  String get pos75c1a67be0f1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dilayani Oleh'**
  String get pos54ae749efb6f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dine-in dan manajemen meja'**
  String get pos29397b29d260;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dipakai bersama oleh katalog inventaris dan kasir.'**
  String get pos6ec1160db69e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diperbarui'**
  String get pos9d77dbd733a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dipesan {arg1} pukul {arg2} · {arg3}'**
  String pos2885c22e700d(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dipesan {arg1} · Sudah diterima {arg2} · Sisa {arg3} {arg4}'**
  String posfc674fc6d98d(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dipilih'**
  String get posf78fe3459de0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diposting'**
  String get posd8bd5a6d277c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diproses'**
  String get pos54dfaef699d6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diproses di dapur / stasiun'**
  String get pos484fed959e5e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Disajikan'**
  String get pos6a5efb2d31a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diserahkan'**
  String get pos0335d447d92f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Disetrika'**
  String get posb61a3838102a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Disetujui'**
  String get pos8c5b40927348;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Disiapkan'**
  String get pos4d4cb33ec4b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon'**
  String get pos6cc10ed56760;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon    -{arg1}'**
  String posd20c0326fffe(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon & Promo'**
  String get pos8c61328fd3e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon (%)'**
  String get poscd5ad8d1f6c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon Manual (%)'**
  String get posf749315970d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon Terbaik: Manual atau Promo'**
  String get pos43861a053a64;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon dan catatan (opsional)'**
  String get pos39e0acf540f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon harus antara 0–100%'**
  String get pos35dedebc6b07;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon item'**
  String get pos0b805daf00e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon manual'**
  String get posd3e06f55da3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon manual (%)'**
  String get pos71057d4cb43f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon manual (otorisasi)'**
  String get pos5d822d3c8b42;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon nominal'**
  String get posd048abbdcd5a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon terbaik'**
  String get pos2e6eaa0f8139;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon, pajak, atau biaya pembelian tidak valid'**
  String get pos70f216c8f1f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon, pajak, dan biaya'**
  String get pos64f51620d22a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon: -{arg1}\n'**
  String pos6757573250bc(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diskon: {arg1}'**
  String pos79b4aaf15d61(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Disortir'**
  String get posbb04a084fc91;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima'**
  String get pos64643bb547ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima    {arg1}'**
  String pos6cbe2ba54793(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima sebagian'**
  String get pos6e35efb55623;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima sekarang'**
  String get pos1ff41d5332d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima sekarang ({arg1})'**
  String pos4c2897c3151f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima supplier'**
  String get pos64ddb219a2b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diterima {arg1} • Diselesaikan {arg2} • Sisa {arg3}'**
  String pos17d47a833e6d(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ditimbang'**
  String get pos610ce5495340;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ditolak'**
  String get posc4397f065ad2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ditolak supplier'**
  String get pos514476987e3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ditolak: {arg1}'**
  String pos6565140ed733(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ditutup'**
  String get pos0e97e7214c08;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ditutup dengan selisih'**
  String get pos9044ca83add5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Diurutkan berdasarkan omzet'**
  String get pos8fc67d6bb35b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen akan dihapus dan tidak dapat dipulihkan.'**
  String get pos3e65f4ff63bc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen akan dihapus dan tidak dapat dipulihkan. Tuliskan alasan untuk jejak audit.'**
  String get pos30f862ef282a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen berhasil diperbarui'**
  String get pos6624aad87bd7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen ini dibuat oleh pihak pembeli dan bukan tanda terima yang diterbitkan supplier.'**
  String get pos4f085c6005eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen ini dicetak dari sistem pada {arg1}.'**
  String posa8f1911e24f6(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen pesanan pembelian inventory'**
  String get pos537a9dacad2a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dokumen resmi perlu koneksi untuk memverifikasi status terbaru. Sambungkan internet lalu coba lagi; data lama tidak dicetak otomatis.'**
  String get pose8d8d0eb1f7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dompet Digital'**
  String get pos4f1621cbaa3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draf'**
  String get pos73021deac09e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft'**
  String get pos23d33e22acfc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft berhasil dibuat'**
  String get pos53c84f0fb661;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft biaya tersimpan, tetapi belum diterapkan: {arg1}. Periksa di Inventory > Landed Cost.'**
  String posf4aa85a645e9(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft disimpan lokal; belum mengubah stok/kas.'**
  String get pos75a4016a3b31;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft retur berhasil disimpan'**
  String get pos7e42bb752260;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft tersimpan, tetapi gagal dikirim: {arg1}'**
  String pos32665db570e5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Draft {arg1} akan dihapus dan tidak dapat diproses.'**
  String pos8b42dadfb112(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Dudukkan tamu'**
  String get posb6e666f86c46;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Durasi'**
  String get posb7d4c20c85fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Durasi kunci otomatis harus 1–120 menit.'**
  String get pos1987a1e42ffd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Durasi terlama'**
  String get pos2f6682a1a18d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'E-Wallet'**
  String get pos85c05bd848b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit'**
  String get pos5301648dcf6b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit Meja'**
  String get posffe1b372fccb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit Outlet'**
  String get pose0ba251e59ec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit Pelanggan'**
  String get pos3112917853d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit Produk'**
  String get pos919aa11d43a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit Promo'**
  String get pos17bab1a67eb5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Edit Warehouse'**
  String get pos7d401a7f62c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get pos84add5b29527;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email (opsional)'**
  String get poscd9cfacc4a41;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email aktivasi berhasil dikirim'**
  String get pos2f1cfd6ea0cb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email aktivasi gagal dikirim'**
  String get pos3521ad2ebf75;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email atau nomor WhatsApp'**
  String get pos785e71efc024;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email atau username belum tersedia.'**
  String get pos983304bee613;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email sudah digunakan'**
  String get pos87c3b4974191;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Email verifikasi telah dikirim ke {arg1}. Verifikasi akun terlebih dahulu, lalu masuk untuk menyiapkan POS Anda.'**
  String pos4502e01c7a52(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Endpoint tersimpan. Mohon restart aplikasi/hot restart.'**
  String get pos8f80d0fdc1ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Error'**
  String get pos7f2f6a15cf8d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi biaya'**
  String get posb6c2a17bc667;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi biaya harus dalam Rupiah bulat'**
  String get posa6a149dda389;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi biaya tidak menambah tagihan atau nilai stok. Catat biaya aktual saat penerimaan atau lewat landed cost.'**
  String get poseca61d4216c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi margin: Rp {arg1} ({arg2}%)'**
  String pos917facb520d6(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi tanggal tiba'**
  String get posbbb52a27a493;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi tanggal tiba tidak boleh sebelum tanggal kirim'**
  String get pos02f9dede92fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Estimasi waktu persiapan'**
  String get posa09085e4ea3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'F1 untuk melihat panduan'**
  String get posdc027a58c1d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'F6 keranjang · F7 diskon · F8 simpan pesanan'**
  String get pos74899f949819;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'F9 pesanan tersimpan · F10 pengaturan penjualan'**
  String get pos7bc8b50180e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Faktur'**
  String get pos738a4653220f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Faktur Penjualan ({arg1})'**
  String pos1d39c9ee7007(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Faktur pembelian tidak tersedia'**
  String get pos5a617e53a43f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fallback 60 detik'**
  String get pos79d8f3b388ed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Favorit'**
  String get pos39c0b929b750;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Favorit tersimpan lokal dan menunggu sinkronisasi'**
  String get pos420534b5d146;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'File gambar tidak dapat dibaca'**
  String get posdf99a62fb9ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter'**
  String get posd7decf1aa22b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter Produk'**
  String get posd3d9ec019f31;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter Retur Pembelian'**
  String get pos8aa1b56a68b1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter Stock Opname'**
  String get pos4d912020c34d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter Stok Terbuang'**
  String get posd502b23ad42f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter aktif: {arg1}'**
  String poscd472b2621dc(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter alasan dan tanggal'**
  String get posaeb609066ae3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter lokasi dan tanggal'**
  String get pos5c5d5d49ebb5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter pelanggan'**
  String get pos521018c8bcca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter pesanan aktif'**
  String get pos724fd6a109a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter produk'**
  String get pos261a4017ab53;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter retur'**
  String get pos9e8861c24689;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Filter status toko'**
  String get posedf803f6fc3b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Finance · Tagihan supplier'**
  String get posb3fe852fa673;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fisik batch {arg1} · {arg2}'**
  String pos73ff67cc0d8e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fisik tanpa batch'**
  String get posa6184c3c4b18;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fisik {arg1} · Pembukuan {arg2}'**
  String posb181ba4478da(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fisik {arg1} · dialokasikan {arg2}'**
  String posb3eb03dd1e68(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fitur belum diaktifkan oleh Finance tenant.'**
  String get pos869f6e70b024;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fitur ini sedang dalam tahap pengembangan.'**
  String get pos72e206b7fd90;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fitur meja nonaktif'**
  String get pos02370c9b6e7c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fitur operasional'**
  String get posd308a880c1df;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fitur pembelian lainnya'**
  String get posc307c71e021d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Footer Struk'**
  String get pos83fed4c2c818;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format email tidak valid'**
  String get pos6b03993ccb88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format foto harus JPG, PNG, atau WebP'**
  String get pos833cfc904919;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format foto invoice harus JPG, PNG, atau WebP'**
  String get pos637b919a6c4f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format proforma harus JPG, PNG, atau WebP'**
  String get posf46d7da48b61;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format respon tidak valid'**
  String get pos71e93c87c1b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format respon tidak valid dari server'**
  String get posdbb3a5ba3622;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format respons API tidak valid (HTTP {arg1}). Silakan coba lagi atau hubungi admin.'**
  String pos09d0570c7e41(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Format respons GraphQL tidak valid'**
  String get posa5fe855ddf3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Foto'**
  String get pos0f5e4f087245;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Foto invoice'**
  String get pos78db57fd7866;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Foto masuk antrean Finance dan tidak langsung membentuk utang.'**
  String get posf6bcc19ad31c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Foto produk'**
  String get posd65275950187;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'GRAND TOTAL'**
  String get pos1b983d2c1189;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gabungkan Diskon Manual + Promo'**
  String get posf901c08f43dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal'**
  String get pos224bc6b9119b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal keluar dengan aman. Coba lagi.'**
  String get posb4e2c379fc5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membagikan QR meja.'**
  String get pos1b40f959803b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat file struk. Silakan coba lagi.'**
  String get pos1b8cd2da2b3d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat kategori'**
  String get pos53291830aa2e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat meja baru'**
  String get posb252d4627327;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat produk'**
  String get pos92f937bb5794;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuat promo'**
  String get pos094efd6453e9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuka atau mencetak bukti pembayaran. Periksa printer dan coba lagi.'**
  String get posf0f32118ea7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuka gambar: {arg1}'**
  String posb4e271dca4dd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuka layanan print invoice'**
  String get posebe630c6382b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal membuka shift'**
  String get pos4ff7e02899e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memeriksa hasil kas masuk/keluar. Muat ulang sebelum mencoba lagi.'**
  String get pos803763bbee6d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memeriksa hasil tutup shift. Muat ulang sebelum mencoba lagi.'**
  String get posec9fe1b66848;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memindahkan pesanan. Coba lagi.'**
  String get posab8c52527c01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui outlet'**
  String get pos7c77c31da98c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memperbarui pelanggan'**
  String get posd30eedfe6de6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memproses dokumen. Muat ulang untuk memeriksa statusnya.'**
  String get posdf4880ac2cf1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat konversi satuan: {arg1}'**
  String pos1b53e9ce9719(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat riwayat transaksi'**
  String get pos3cbe80b3fcca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat riwayat transaksi. Tarik untuk mencoba lagi.'**
  String get pos3c846dece8ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat semua meja untuk dicetak.'**
  String get posaf44df03a0aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat shift kasir aktif'**
  String get pos511e4132f12f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal memuat transaksi berikutnya.'**
  String get pos1801846f09c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menambahkan outlet'**
  String get pos16483d7d4df7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menambahkan pelanggan'**
  String get posc3f3bd12f9f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal mengajukan retur'**
  String get pos4e6a0ac973aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus outlet'**
  String get posee01c4493ae8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus pelanggan'**
  String get pose3649adbbe7e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus promo'**
  String get pos495296b777e2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menghapus retur'**
  String get pos02af68ce1478;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal mengubah status promo'**
  String get pos1a21dc8ed086;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal mengupdate meja'**
  String get pose0a9a444a6ff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal mengupdate produk'**
  String get posc172b66da4d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal mengupdate promo'**
  String get pos46e82b0ae0c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menutup shift'**
  String get posee6c48daa9fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyetujui retur'**
  String get pos976fbff96b8d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyiapkan PO: {arg1}'**
  String posc2b7886b6824(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyiapkan QR semua meja.'**
  String get pos5df42ee84e41;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyiapkan cetak QR meja.'**
  String get pos2ee9ffe5a92d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyiapkan label.'**
  String get posc954d5ca3c3a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan atau mengambil data lokal'**
  String get posddb9aa8fd356;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan data'**
  String get pos4c687db5daf2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan pengaturan'**
  String get posd4aa54d3272d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gagal menyimpan petty cash'**
  String get pos0fef5416efb2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gambar CAPTCHA tidak dapat ditampilkan. Coba login kembali.'**
  String get pos23e2e47741e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ganti'**
  String get pos0dfd02112e86;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ganti PO'**
  String get pos58d72143f2f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ganti gambar'**
  String get posc032d55c32f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ganti lokasi'**
  String get posf6b4e4763c6f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ganti lokasi asal?'**
  String get pos37433a332509;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gedung'**
  String get posd7ec1542ac28;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gedung (opsional)'**
  String get poseea149a1c095;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gedung {arg1}'**
  String pos7fac25ce1b1f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gedung, ruangan & rak (opsional)'**
  String get pos62f72c81b717;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gedung, ruangan, dan rak bersifat opsional, tetapi membantu pelacakan saldo yang lebih presisi.'**
  String get pos236ae339131d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gedung: {arg1}'**
  String pos786a448f1a32(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gelap'**
  String get pos5920cc131a58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Generate ulang SKU dan barcode'**
  String get pos0bdb72ba702c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Geser card'**
  String get pos608b62493d5c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Geser kartu ke kanan untuk tahap berikutnya'**
  String get posb4b96ac14e22;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Geser tabel ke samping untuk mengisi kolom lainnya.'**
  String get posf13036b0f9c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Giro'**
  String get pos8a813f3e08f2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Google belum dapat dihubungkan. Silakan coba lagi.'**
  String get pos1b155396b4ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Google belum memberikan verifikasi akun. Silakan coba lagi.'**
  String get posb10adea98b92;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Google belum tersedia pada server ini.'**
  String get pose0a9270ba48f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Google belum tersedia. Anda tetap bisa masuk atau daftar dengan email.'**
  String get pos2f1334888329;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Grafik penjualan'**
  String get posece89223a27e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Grand total'**
  String get pos650fe991ac42;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'GraphQL Endpoint'**
  String get pos38849fb0615b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gudang cabang'**
  String get posd969fdbaeddf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gudang pusat'**
  String get pos8cc222a3287a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gudang toko'**
  String get posccc625ad01b5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tamu'**
  String get posface83ee3014;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan'**
  String get pos77a9bf43ee61;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan 4–6 digit angka yang mudah diingat operator tetapi tidak mudah ditebak.'**
  String get pos1324bb13a47e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan Riwayat untuk cetak ulang, melanjutkan invoice, atau retur.'**
  String get posd3ef9894d6f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan huruf, angka, titik, _ atau -'**
  String get pos0c4c95dc7004;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan jumlah'**
  String get pos2578dc120c2a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan kode'**
  String get pos68c6220bf962;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan komposisi stok / resep (BOM)'**
  String get pos06b348aec71c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan nomor aktif yang diawali 0 atau 62'**
  String get pos1344c75514e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan nomor telepon valid (8–15 digit)'**
  String get pos24457d2732a0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan pelanggan umum'**
  String get pos6da08cf9e00e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan pencarian, kategori, favorit, atau pemindai barcode.'**
  String get pos83eaa0de7240;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan penerimaan pembelian untuk barang datang atau stok awal/koreksi untuk saldo pembukaan.'**
  String get pos77b44b71db37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan penerimaan, retur, atau scrap dengan nomor seri yang jelas. Koreksi jumlah serial belum didukung pada opname.'**
  String get pos5b22a1493baf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan penerimaan/retur/scrap dengan nomor seri.'**
  String get pos5f9f4a96fb84;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gunakan produk stok, layanan, atau paket sesuai cara item dijual.'**
  String get pos18060473474f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'HPP komposisi Rp {arg1}{arg2}'**
  String posca170b43672a(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Habis'**
  String get pos1d846b91a00b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Habis Pakai'**
  String get pos59f7d7f90bfb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman berikutnya'**
  String get pos648e401ed6fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman legal tidak dapat dibuka.'**
  String get posb0fd7e079f01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman sebelumnya'**
  String get pos74d76fb1e7d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1}'**
  String pos4d0803eab0a2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} / {arg2}'**
  String pos61f7b0c13f15(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} dari {arg2}'**
  String posea3f79a3c91b(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} · {arg2} kategori'**
  String pos6a42159c5abb(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} · {arg2} komponen'**
  String pos189db84b3f7d(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} · {arg2} permintaan'**
  String posad518ced7c3d(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} · {arg2} pesanan'**
  String posd628bb3772f8(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} · {arg2} pilihan'**
  String posd56e0c97a9f6(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halaman {arg1} · {arg2} produk'**
  String posddeedb7fc620(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Halo, {arg1} 👋'**
  String pos49f816b08de3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penanganan'**
  String get pos6c94476426e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hanya Diskon Manual'**
  String get pose0174d444b53;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hanya Promo'**
  String get posdd40e443b7fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hanya lihat'**
  String get pos5bac0e78561a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hanya pengguna yang berwenang dan memiliki PIN yang dapat membuka sesi kasir.'**
  String get pos172bc678f03c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hanya untuk ongkir/biaya yang dibayar terpisah. Jika ongkir ada dalam invoice supplier yang sama dengan barang, catat lewat Vendor Bill di Finance web untuk satu GRN yang ditagih penuh; jangan catat di sini agar utang tidak ganda.'**
  String get pos4b7b05435e97;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hanya warehouse aktif dengan capability Lokasi Penjualan'**
  String get pose8f25ae79a1c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get pos9d053c98fde4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus Meja'**
  String get posd350eb5f85c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus Promo'**
  String get pos5711e2078686;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus barang'**
  String get pose817b0f4863b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus biaya'**
  String get pos8dc1f033132c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus draft retur?'**
  String get pos389385909a93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus foto'**
  String get pose6eff93e6a27;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus jadwal'**
  String get posde0e62337399;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus konversi'**
  String get pose78112cde662;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus metode'**
  String get pos04ec30ffeb21;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus outlet?'**
  String get posf73f077fe3c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus pelanggan?'**
  String get pos7878b0d8997e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus retur pembelian?'**
  String get posb51ee6066ff5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus tanggal'**
  String get posd42e339038ff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus warehouse?'**
  String get poscbed1954f6c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hapus {arg1} dari favorit'**
  String posb45b8e526f3f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga'**
  String get pos059e7656ec55;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Corporate'**
  String get pos728a37639a44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Distributor'**
  String get pos1ba6727611e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Eceran'**
  String get pos61d717e6a361;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Grosir'**
  String get posf0d242effb62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Jual'**
  String get pos7d9d78a74ccb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Member'**
  String get pos1cba3d99c4b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga Reseller'**
  String get pos08d741fe3e42;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga VIP'**
  String get pos1e1a56a7fdd2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga beli'**
  String get pos67af8b49dbf7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga beli / HPP'**
  String get pos47fd3ba771f7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga beli per satuan'**
  String get pos0f54f8223fa1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga jual'**
  String get pos6c49a243b754;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga jual *'**
  String get pose4d6b23f3352;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga pokok'**
  String get posfcc71c6d0fa8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Harga {arg1}'**
  String posba0f270a2974(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get posd300b7bcaae8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get pos2c6ad1441fa8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hasil belum terkonfirmasi. Periksa ulang status transfer sebelum mengulang.'**
  String get pos46d1bb285515;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hasil refund belum terkonfirmasi. Jangan keluarkan uang lagi. Periksa status retur saat koneksi tersedia.'**
  String get pos111ba08784da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hasil rekonsiliasi / nomor bukti'**
  String get posf32d12e478fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Header Struk'**
  String get pos1e17ce7f8720;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hilang'**
  String get pos71efaa642140;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hilang / kurang permanen'**
  String get posf96204859cd2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hilang/kurang'**
  String get pos9b43a9323e44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hitung dengan konversi'**
  String get posc35fb6745fcf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hitung per batch'**
  String get pos42045bba2963;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hitung stok'**
  String get posf0b4d6c6e6c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hitung stok di lokasi ini'**
  String get pos4a88241970e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hitung/koreksi per batch'**
  String get pos2c1369113bcd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hubungi admin untuk mendapatkan izin melihat stok toko.'**
  String get posac2ed926abe5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hubungi admin untuk mendapatkan izin mengelola meja.'**
  String get posbe42365b3845;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hubungkan Layar Pelanggan'**
  String get posc93991607418;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hubungkan layar pelanggan'**
  String get pos6988b7016ba0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hubungkan lokasi stok'**
  String get pos6883cf015f7e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hubungkan toko aktif ke lokasi penjualan terlebih dahulu.'**
  String get pos1da990c78361;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Hutang dibatalkan'**
  String get pos9537523da00d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ID PO tidak tersedia'**
  String get posf67b1a19f6eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ID pembayaran'**
  String get pos8bb0f77f5f25;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ID pesanan tidak tersedia'**
  String get pos24e0b20d63a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ID pesanan tidak valid'**
  String get posecc15f135718;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ID pesanan tidak valid. Muat ulang pesanan.'**
  String get pos6cef3759bcbb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ID tagihan tidak tersedia'**
  String get pos00e61a9042b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'INVOICE'**
  String get posfe1a6c8519c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas instansi atau pengguna tidak tersedia'**
  String get pos89ae2350ce7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas instansi, toko, atau pesanan offline belum tersedia'**
  String get pos8f15bdaa0369;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas kasir asal tidak tersedia. Transaksi perlu ditinjau admin.'**
  String get posdd1efa7c5f1f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas kendaraan pelanggan'**
  String get pos740dea0268ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas pembeli tidak dapat dimuat: {arg1}'**
  String pos67bae1d899bf(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas toko POS'**
  String get pos1bbd060dbfe8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Identitas/jumlah batch tidak sesuai sisa transfer.'**
  String get pos0b843309058d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ikuti kebijakan instansi'**
  String get posa2853109d1eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ikuti sorotan untuk menambah item, mengatur konteks order, lalu memeriksa total.'**
  String get posb5e55c9dbb49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Info'**
  String get pos4b631f698425;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi & lokasi opname'**
  String get posaa72b721e803;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi Produk'**
  String get pos39ed5e099637;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi Promo'**
  String get pos04ebcc29713d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi ini menjadi acuan Finance. Mengisi PO tidak membentuk hutang atau mencatat pembayaran.'**
  String get pos6a6754295abb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi pembelian'**
  String get pos2db5d5d597a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi penerimaan'**
  String get pos794d3faa5c0c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi produk'**
  String get pos92efbb82664b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Informasi transfer'**
  String get pos8d749d079e06;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Input hitung fisik'**
  String get pos3a187ec13ed4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Input satuan / kemasan'**
  String get pos7f53b7abb18f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Inspeksi'**
  String get posf53c87ea7127;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tak berwujud'**
  String get posc2804192832a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Internal kasir'**
  String get pos844739bd2099;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Internet'**
  String get pos66c06c11d179;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Inventori'**
  String get pos77b5136d4e8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice'**
  String get posf9f38818c406;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice Asal'**
  String get pos24b6f23a456c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice Belum Bayar'**
  String get pose61508685db4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice dibatalkan'**
  String get posdf484f04f890;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice gagal dibuat'**
  String get pos4900d09d9809;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice offline tersimpan. Belum bisa dibayar; cek Antrean & Sinkronisasi.'**
  String get pos95347c107273;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice server: {arg1}. Periksa nilai transaksi, harga, dan kas fisik sebelum menandai pemeriksaan selesai. Jangan kirim ulang sebagai transaksi baru.'**
  String pos498daa89ff78(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice sudah diterbitkan. Pelunasan melalui Piutang di Finance.'**
  String get posb65d7cb22df8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice supplier'**
  String get posab8d9d4d63c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice tersimpan · menunggu pembayaran'**
  String get posc5670e9d9652;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice tidak cocok'**
  String get pos0e45fc42efe8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice tidak ditemukan'**
  String get poscc106607c66b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice yang sudah diverifikasi Finance akan tampil di sini.'**
  String get pos8b0377d34af1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice {arg1}'**
  String pos3818e7b1db75(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice {arg1} berhasil dibayar'**
  String pos4def2db5b18e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice {arg1}. Pulihkan isian yang sudah dikirim sebelum membuat retur lain. Ini tidak mengajukan atau membayar refund.'**
  String pos3a368a74f5da(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Invoice: {arg1}'**
  String posee94ad7e244c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi Rak Display'**
  String get pos960c2dafc91f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi Rupiah bulat maksimal sisa tagihan, akun penerimaan dan nomor bukti.'**
  String get pos18372bff924d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi alamat pengiriman'**
  String get pos5b074a10c758;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi alasan minimal 10 karakter dan centang pernyataan pemahaman.'**
  String get pos4fd509646f1e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi alasan selisih {arg1} minimal 3 karakter'**
  String pos42d67456c6c0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi alasan selisih {arg1} minimal 3 karakter.'**
  String pos9fec2fcbc391(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi angka 1–100'**
  String get pos068dd112192d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi angka nol atau lebih'**
  String get pos7bf0a2ca4ee6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi barang yang benar-benar tiba. Sisa dan selisih pending tidak diterima otomatis.'**
  String get posa4d4a5b8ded1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi detail alasan disposal'**
  String get posaec5933834f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi identitas warehouse. Nama dan alamat wajib agar lokasi mudah dikenali.'**
  String get pose552d7de417f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah 0 sampai {arg1}'**
  String posd06dba4cee38(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah fisik yang valid'**
  String get pos3dab9217cedf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah kemasan nol atau lebih dan faktor konversi yang valid.'**
  String get pos3a193722be00;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah per kemasan. Sistem menghitung total dalam {arg1}.'**
  String pos87d6dcc5b9dd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi jumlah yang benar-benar tiba. Sisa tetap dalam perjalanan.'**
  String get pos46a82e97da42;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi minimal satu jumlah diterima'**
  String get pos86399e5bb71d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi minimal satu jumlah yang diproses.'**
  String get pos677c7a68dc45;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi minimal satu satuan.'**
  String get pos4b026df5b239;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi nama dan kode toko yang akan tampil pada transaksi dan struk.'**
  String get pos43dca23d4112;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi nama opsi terlebih dahulu.'**
  String get pos681bcce6a36e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi nama produk yang singkat dan mudah dikenali kasir.'**
  String get posb8492d02d692;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi nama toko dan identitas yang akan tampil pada transaksi serta struk.'**
  String get posb784b2892be6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi nama, kategori, satuan, harga, SKU/barcode, dan foto bila diperlukan.'**
  String get posfddd62cd0dea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi objek layanan atau keluhan, minimal salah satu.'**
  String get pos1aaeb76923cd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi rak display'**
  String get posf62435f24f32;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi satuan dasar'**
  String get pos694ca219260b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi seluruh sisa baris ini'**
  String get posed6b2fa03012;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi semua jumlah fisik dengan angka nol atau lebih.'**
  String get pos12a293d406a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi stok awal'**
  String get posb0dc8b63cbec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi stok awal setelah produk selesai dibuat.'**
  String get posd8a2ff97ecdc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Isi tanggal fisik dan pembukuan yang valid (YYYY-MM-DD).'**
  String get posf571768b6250;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Item'**
  String get posecdda59aea5e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Item Pembelian'**
  String get pos021cd2ea7514;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Item Produk Teratas'**
  String get posb94f9ded282d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Item dapat langsung diserahkan atau dikirim ke dapur/bar.'**
  String get pos5f3e283632e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Item dapur belum memiliki ID yang valid. Muat ulang pesanan.'**
  String get posea0309ed55f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Item layanan'**
  String get pos8fea91694ec2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izin'**
  String get pos9abf395c316a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izin Bluetooth ditolak permanen. Aktifkan Perangkat terdekat dari Pengaturan Aplikasi.'**
  String get pos0249c76f6e84;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izin persetujuan scrap tidak tersedia. Anda hanya dapat menolak; persetujuan dilakukan supervisor yang berwenang.'**
  String get pos29131337e7c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izinkan Kasir Edit Harga'**
  String get poscfadf68bfea9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izinkan Penjualan Tanpa Shift Aktif'**
  String get pos12d2cd6e66b7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izinkan Perangkat terdekat (Android 12+) atau Lokasi (Android 10/11) untuk mencari printer.'**
  String get posc873500afc78;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Izinkan dengan Otorisasi'**
  String get pose5ca412acd29;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'JPG, PNG, atau WebP • maksimal 5 MB'**
  String get pos6d9747726c3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal Termin Pembayaran'**
  String get pos630e28585a4f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal layanan wajib dipilih untuk reservasi.'**
  String get pos8bb5b1a09462;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal pelanggan'**
  String get pos8d8ce1f777c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal reservasi diperbarui'**
  String get pos64744b573d98;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal reservasi diperiksa sebelum pembayaran. Jika pembayaran dibatalkan, reservasi tetap tersedia di Pesanan Aktif untuk dilanjutkan.'**
  String get pos9059226e133b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal reservasi tidak dapat diproses'**
  String get pos85bf1ddd2dd3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal termin belum tersedia. Perbarui data PO atau hubungi admin sebelum mencatat pembayaran.'**
  String get pos88b9ef6a0784;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwal: {arg1}'**
  String posbfa60931a0a5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan ulang'**
  String get pos8257c2080610;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jadwalkan ulang reservasi'**
  String get pos2f4d174beca0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jam Pesan'**
  String get pos8402e5e930c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jangan ulangi refund sebelum status retur terkonfirmasi. {arg1}'**
  String pos4a5790de1739(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jangka waktu kredit tidak valid'**
  String get poscef3e9d96af0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jaringan perangkat tersedia. Server diperiksa saat transaksi.'**
  String get posaee3ad0696eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jasa'**
  String get pos873385d700da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jasa / Janji Temu'**
  String get pos8a49b0cab4ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo'**
  String get pos165b11818801;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo (hari)'**
  String get pos6b5c41c5f9d4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo mengikuti tanggal penerimaan. Penerimaan hanya mencatat stok dan GRNI; hutang terbentuk setelah invoice diposting Finance.'**
  String get posa2461e28f412;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo segera'**
  String get pos2305cc99bfbb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jatuh tempo: {arg1}'**
  String pos0c8620dab460(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jelaskan alasan sisa barang tidak akan diterima'**
  String get posc6b8aa8f3866;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis'**
  String get posfabb2b5c779a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis Nilai'**
  String get pos2e99133d9825;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis Pembayaran'**
  String get posa54013c11f44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis Pesanan'**
  String get pos653eb5e1517f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis Pesanan Default'**
  String get pos68d1bcb419e2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis biaya'**
  String get poscbcb5c510e6b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis diskon'**
  String get posb33a27088b2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis diskon item'**
  String get pos704467719529;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis operasi antrean tidak dikenal: {arg1}'**
  String pos60e3a1766a6e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis pesanan: Bawa Pulang'**
  String get posb1e87cb3d8dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis pesanan: {arg1}'**
  String pos351aef710752(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jenis selisih'**
  String get posb31bb29fd469;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jika dibayar terpisah, catat sekarang agar biaya masuk nilai barang. Estimasi di PO tidak otomatis dibebankan.'**
  String get posbb1ab312f123;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jika invoice fisik sudah diterima, kirim fotonya untuk diverifikasi Finance.'**
  String get pos1a3535f3f905;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jika kosong, server membuat barcode internal EAN-13.'**
  String get pos338c62110b22;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jika tautan tidak terbuka, periksa apakah kedua perangkat benar-benar satu jaringan dan fitur isolasi perangkat pada router tidak aktif.'**
  String get posd33f413944c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jl. Asia Afrika No. 10, Bandung'**
  String get posc0f585c44ba8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jl. Sudirman No. 1, Jakarta Pusat'**
  String get pos2668f5896214;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jl. Tunjungan No. 5, Surabaya'**
  String get posa946b3e9bada;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Judul (Baris 1)'**
  String get posaa99b2216b01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Judul Utama'**
  String get posafb0a31422e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Judul wajib diisi'**
  String get posdcb86663713e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah'**
  String get pos755c97873b6a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah (Rp)'**
  String get pose7150b7c11bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah ({arg1})'**
  String pos8109832b1b60(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah PO terbuka sudah memenuhi target stok.'**
  String get pos443be1dee7c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah barang harus positif.'**
  String get pos9d3ddbcdda58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah berhasil direcycle'**
  String get pos947f16e391d6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah diproses'**
  String get pos8aeb9aa96315;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah diterima diperbarui. Periksa batch dan lokasi sebelum simpan.'**
  String get pos51b76460b766;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah diterima tidak valid'**
  String get pos807ac846d704;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah fisik'**
  String get pos032f507eb0f4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah fisik batch tidak boleh negatif'**
  String get pos537a99d1024c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah harus 0 sampai {arg1} {arg2}.'**
  String posfd2ad4755705(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah harus nol atau positif dan tidak melebihi sisa tersedia.'**
  String get posb0fa83b331ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah hasil recycle {arg1} harus 0–{arg2}'**
  String posfb4a0df20901(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah hilang {arg1} melebihi saldo batch'**
  String pos2a8779efd3b6(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah item'**
  String get pos2493b57b023e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah label (1–50)'**
  String get posd9512d28962d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah label harus 1–50.'**
  String get posbafa7741b996;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah label thermal harus 1–8.'**
  String get pos990f037d4332;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah melebihi sisa hutang ({arg1}).'**
  String posda44a8c5e2db(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah melebihi sisa termin ({arg1}).'**
  String pos0933c14b6cfc(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah nomor seri unik harus sesuai jumlah barang.'**
  String get posca46c6d39fc4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah pembayaran *'**
  String get pos65f277f99e7e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah penerimaan (Rp)'**
  String get pose434144b33a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah per satuan / kemasan'**
  String get pose7dda6f78955;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah retur ({arg1})'**
  String pos981fefc1e33c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah saldo lokasi'**
  String get posf9ee5fc6a4d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah satuan harus nol atau positif.'**
  String get pos01ceffc734ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah tagihan mengikuti jumlah layanan di keranjang. Ketuk angka jumlah pada keranjang untuk mengubah berat/jumlah.'**
  String get poscab1f74c7c7e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah tamu'**
  String get pos0df65f44728b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah termin (2–12)'**
  String get posd629ec82f452;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah usulan mempertimbangkan stok dan PO terbuka. Periksa kembali kebutuhan, harga, dan supplier sebelum menyimpan PO.'**
  String get pos50ec82b77842;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah {arg1}'**
  String posfed87456b577(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah {arg1} diperbarui.'**
  String pos5b84c2d40d4c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah {arg1} harus lebih dari 0 dan maksimal {arg2} {arg3}'**
  String pos7ee454b3f2c2(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah {arg1} maksimal {arg2} {arg3}'**
  String pos0502434efde2(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jumlah {arg1} melebihi stok lokasi ({arg2} {arg3})'**
  String posad42a01ae2c6(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal belum selesai: {arg1}'**
  String posd73d69d726dc(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal belum terkonfirmasi. Gunakan Coba Jurnal Lagi.'**
  String get pos56f27547fcc3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal gagal diproses. Muat ulang untuk memeriksa statusnya.'**
  String get pos8adf9b478501;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal gagal: {arg1}'**
  String pos4c593ad5f42d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal pembatalan belum selesai: {arg1}'**
  String posa1928b385d2d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal pembatalan berhasil diperbarui'**
  String get posd932dbb48b4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal penerimaan berhasil diperbarui'**
  String get pos635ac7ca192e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal scrap berhasil diperbarui'**
  String get pos86f313ec201e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Jurnal: {arg1}{arg2}'**
  String pose627ba45da07(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'KATEGORI LAINNYA'**
  String get pos1c18b07a4c12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kadaluarsa'**
  String get pos6417dc96dd89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kandidat Mitra'**
  String get pos3fd661d8c272;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kapasitas'**
  String get pos9519ed0538ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kapasitas Kursi'**
  String get pos5337214524ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kapasitas: {arg1} Orang'**
  String pos50275ce55359(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kapasitas: {arg1} kursi{arg2}'**
  String posf4f1e83621da(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Karantina'**
  String get posdeaa3060dc73;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Karantina: {arg1}'**
  String pos9b789015b765(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kartu Debit'**
  String get pos6760171d6a3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kartu Kredit'**
  String get pos2800248d00b9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Karyawan'**
  String get posbb1ee7385e63;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Karyawan tidak ditemukan'**
  String get pos59cd57f7989b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas / bank pembayaran'**
  String get pos1749b0cd9a9a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Aktual'**
  String get pos4c2dbc3f372c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Awal'**
  String get pose9518d0bc9a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Awal (Rp)'**
  String get posa8fe0dd3179a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Expected'**
  String get pos8b3c8b8f3e44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Fisik Aktual (Saat Tutup)'**
  String get pos7796b33a3260;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Kasir'**
  String get pos3922fba5c102;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Keluar'**
  String get pos6a1707dcf187;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Keluar (Ambil Kas)'**
  String get pos2f0711c7a173;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Masuk'**
  String get posa44379c56411;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas Masuk (Tambah Modal)'**
  String get posf42c4fa8721b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas awal'**
  String get pos577ada5e540c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas masuk / keluar'**
  String get pos493f3c681020;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas seharusnya'**
  String get posaab29c0a1124;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kas {arg1} berhasil dicatat!'**
  String pos3e08d3d71a70(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir'**
  String get posfb5ff76f1668;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir & Keamanan'**
  String get posab572ef96179;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir ({arg1})'**
  String posf9195de99c01(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir Pantoo'**
  String get pos0d960b0b7ec9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir belum dapat dibuka. Periksa koneksi dan kesiapan toko, lalu coba lagi.'**
  String get pos63c8b4a4a776;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir boleh mengganti stasiun'**
  String get pos6da6c33d741b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir cepat, bisnis lebih tertata'**
  String get pos425d51c266d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir shift aktif'**
  String get pos77410ea1a888;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir siap menerima transaksi'**
  String get pos62c15db2412e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir tidak teridentifikasi'**
  String get pos068673dfb8b9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir: F2 cari produk · F3 scan barcode · F4 bayar/simpan meja'**
  String get pos2f7d5a68ea08;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir: Kasir Pantoo'**
  String get pos57a7f26fb08f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir: {arg1}'**
  String pos354df62f6aa3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kasir: {arg1}\n'**
  String pos5ca6d211882e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi Baru'**
  String get pos7d0ab1b98a4c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi Saat Ini'**
  String get pos696ebc0f2322;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kata sandi berhasil diubah'**
  String get posbbe72013807d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog'**
  String get pos788fce56160f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog POS'**
  String get pos1b8beb8b165e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog POS tidak tersedia'**
  String get pos6b0fbc1b4d51;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog Penjualan'**
  String get posce7dda4ae52e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog Penjualan · Produk bersumber dari Inventory. Detail master, HPP, satuan, batch, dan saldo lokasi dikelola melalui alur Inventory.'**
  String get posd8a0aafdf1ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog Produk'**
  String get pos9c558e070577;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog gagal dimuat ulang'**
  String get posb841391f4a09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog gagal dimuat. Coba lagi.'**
  String get pos65e32f2507ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog hanya-baca. Perubahan master produk dilakukan oleh admin Inventory.'**
  String get pos46c2553e8367;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog offline tidak cocok dengan lokasi stok toko. Sambungkan internet dan muat ulang katalog.'**
  String get pos5105028f0d55;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog penjualan'**
  String get posc7849a0f41eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog profil POS tidak valid'**
  String get posaa06cfa392d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog profil tidak tersedia'**
  String get pos7e7fbaa5b57a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Katalog tersimpan digunakan. Hubungkan kembali untuk memuat profil terbaru.'**
  String get posbd69dfa44442;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori'**
  String get posb7964404a785;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori Inventaris'**
  String get poscc7d382913a7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori Inventori'**
  String get pos61daf4364861;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori Laporan'**
  String get posd54d0c3d2dca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori Order'**
  String get pos8166ea178d93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori Pengaturan'**
  String get pos75fc71e6eb87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori barang'**
  String get pos72fa10ee02ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori berhasil ditambahkan'**
  String get posbca5b8164d65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori berikutnya'**
  String get posbb00a2fcf16f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori gagal dimuat. Periksa koneksi lalu coba lagi.'**
  String get pos4663bb157a02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori inventori'**
  String get pos0e3ff9e29811;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori laporan'**
  String get posa802a00dd246;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori notifikasi'**
  String get posb2bdc6965d8f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori order'**
  String get pos3301c65345b9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori pengaturan'**
  String get pose424eda02a56;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori sebelumnya'**
  String get pos01c76765186f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori tidak ditemukan'**
  String get pos15ceab423713;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kategori: {arg1}'**
  String pos93a6ccae326e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ke vendor'**
  String get pos01884787d5a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kebijakan Diskon'**
  String get pos0e79d4505659;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kebijakan Privasi'**
  String get posf1240b7c6e7e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kebutuhan operasional'**
  String get pose5e530d03013;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kecil'**
  String get pos23ec4523a9f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kedua perangkat memerlukan internet, tetapi tidak harus memakai Wi-Fi yang sama. Bluetooth tidak digunakan untuk layar pelanggan.'**
  String get pos63ae75ea44f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelebihan'**
  String get pos968a23422b65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola Bisnis'**
  String get posefa02b180cab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola PIN Operator'**
  String get pos04f02f2aee2d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola PIN karyawan dari Pengaturan POS tanpa mengunci sesi admin.'**
  String get pos003cad4427bd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola database pelanggan Anda'**
  String get pos09eacc17ec77;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola katalog'**
  String get pos0c42cb92c0d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola keamanan akun'**
  String get pose496817082e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola layanan'**
  String get pose40af8929b30;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola lokasi'**
  String get posf61f59975812;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola operasional dan pengaturan toko.'**
  String get pos42d050a1533e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola penerimaan PO'**
  String get pos95eb056f1c94;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola pre-order, persiapan barang dan pengambilan. Penjualan langsung tetap selesai di kasir.'**
  String get posc34d57ba5437;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola reservasi'**
  String get pos5bd9b7f94c75;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelola toko'**
  String get pos299582cec1e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kelompokkan produk'**
  String get posfc0b2e1dfece;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get posa421ce222c82;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keluar dari Aplikasi'**
  String get pos4d322b566d50;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keluar dari akun?'**
  String get posc0f5a7fa6764;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keluar layar penuh'**
  String get pos1bef008211b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keluhan / catatan layanan'**
  String get pos5687de1fa1c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keluhan: {arg1}'**
  String pos40b1639b7bb2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali'**
  String get posc43a6e25b712;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Keranjang'**
  String get pos024e89a11384;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali ke Login'**
  String get posa880cee60ee1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali ke daftar piutang'**
  String get pos7d9e6b1f7ba0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali ke login'**
  String get pos7ff9bb1beb64;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali ke pembelian'**
  String get pos13d986d7a714;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembali ke shift aktif'**
  String get pos04f4e113ab12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembalian'**
  String get pos5c9372f2f537;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembalian    {arg1}'**
  String pos9346d428aef7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembalian: {arg1}\n'**
  String posfbcfa461b741(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kembalikan ke Stok'**
  String get pos0b31187ca7ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kenali area kasir'**
  String get posa6e6096bad6e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kendaraan'**
  String get pos79e4ec31d635;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kendaraan: {arg1}'**
  String posd11b0955d522(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kepuasan Pelanggan'**
  String get posd0e69e9b51ec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keputusan selisih'**
  String get pos517f4907a428;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keputusan tersimpan'**
  String get pos58540729c325;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keputusan: {arg1}'**
  String pos735eff437800(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keranjang'**
  String get pos3ac7e2913ec0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keranjang ({arg1})'**
  String pos541eb83e5a0c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keranjang masih kosong'**
  String get posd10f06fb91f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kerugian bersih = jumlah disposal dikurangi hasil recycle'**
  String get pos98dfce1f2b6a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kesepakatan pembayaran'**
  String get pos5fa25d549304;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kesepakatan pembayaran dan prioritas'**
  String get pos5c7981a1e508;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketentuan Layanan'**
  String get pos802c6998ea71;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keterangan'**
  String get pos557f56ddb658;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keterangan (opsional)'**
  String get pos6d421a9a346a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keterangan *'**
  String get pos1d4731ce6f06;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Keterangan minimal 5 karakter'**
  String get pos6ed3ea76d4bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketersediaan server diperiksa saat sinkronisasi.'**
  String get pos828c4805f454;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketik enam karakter pada gambar'**
  String get posb4294193d174;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk Simpan jika pelanggan belum siap membayar. Order dapat dilanjutkan kembali.'**
  String get pos49ea8bd96b89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk Tambah Produk untuk membuka formulir dan mulai menyiapkan item yang akan dijual.'**
  String get posbdeb2bbb6da0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk Tambah Warehouse untuk membuka formulir lokasi penyimpanan pertama.'**
  String get pos1e30aa18f316;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk area yang disorot untuk melanjutkan'**
  String get posfcc4b15454eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk elemen yang disorot untuk melanjutkan.'**
  String get posc88fca67057b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk kolom ini untuk mencari nama, SKU, kode, atau memindai barcode.'**
  String get pos3888ca3dce59;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ketuk untuk memilih channel, level harga, pajak, jenis order, dan promo.'**
  String get pos3f4aada8fe7d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kiloan'**
  String get pos2c73aefd8a60;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim'**
  String get pos00d1624e7e8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim Persetujuan'**
  String get pose654910117ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim Ulang Email'**
  String get pos95ef9b85140e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim bukti invoice ke Finance'**
  String get pos5d44f805b296;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim bukti invoice lain'**
  String get pos7eb2078b7723;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim foto invoice'**
  String get posd437960909e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim ke'**
  String get pos0d9901a7c98b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim ke Supplier'**
  String get posae1729b56772;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim permintaan'**
  String get posdda037ae2d4c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim transfer'**
  String get posbbc1bdc9fe7f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang'**
  String get pos6bb160cfbf81;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang bukti yang sama'**
  String get pos90138adadcb4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim ulang transaksi?'**
  String get pos86399cce1679;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim untuk persetujuan?'**
  String get pos14453ee0a3de;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim → Transit → Terima di tujuan'**
  String get posf9fff542e06f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kirim: {arg1}'**
  String posc3ea0cd9a924(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kitchen flow'**
  String get pose11f122c5a6c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode'**
  String get pos3e25d43ab0d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode CAPTCHA'**
  String get pos24b32ed17d3a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode CAPTCHA enam karakter'**
  String get pos72e4ae972eb0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode Promo'**
  String get pos7e032c04b7e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode akun beban (opsional)'**
  String get pos546bf5e04d4a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode akun beban kehilangan'**
  String get pos682155107733;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode cocok dengan beberapa barang. Pilih manual.'**
  String get pose2234af7c2a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode cocok dengan beberapa produk. Pilih manual.'**
  String get pos88c20dbb60a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode dan jumlah label (1–50) wajib valid.'**
  String get posfce6e7d87c33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode harus 3–20 huruf atau angka tanpa spasi'**
  String get posdec99effb544;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode inventaris · {arg1}'**
  String pos844214a54fe7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode kosong atau tidak didukung Code 128.'**
  String get posd39725beed75;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode outlet'**
  String get pos997eb9526cf1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode pada label'**
  String get posbd37069ac452;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode produk tidak ditemukan.'**
  String get pose4280a94c63c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo'**
  String get pos3d00cf0d363b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo    {arg1}'**
  String pos5d8a179eb068(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo belum dapat diverifikasi. Invoice tidak disimpan offline.'**
  String get pos7cb199edf974;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo belum dapat diverifikasi. Transaksi tidak disimpan offline; sambungkan internet atau hapus promo.'**
  String get pos66fbf8f2a3ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo belum terverifikasi. Sambungkan internet atau hapus promo.'**
  String get pos93c1b1c32490;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo harus diverifikasi online sebelum invoice dibuat.'**
  String get pos40786c706bd8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode promo memerlukan validasi server. Sambungkan internet atau hapus promo sebelum membayar.'**
  String get pos49e5b7b133e9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode tidak ditemukan di lokasi opname ini.'**
  String get posbedb90d93b97;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode tidak ditemukan di lokasi sumber.'**
  String get pos0805d43c642d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kode warehouse'**
  String get pos2ee4a91cbabe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kolom Ditampilkan'**
  String get posb39d2ddfa76c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komisi'**
  String get pos32385ebb7c07;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komisi belum tercatat pada transaksi POS di periode ini.'**
  String get pos7df1a7e7cc8c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komponen'**
  String get pos0750e291bd60;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komponen gagal dimuat. Coba lagi.'**
  String get posc8e53a04fdf8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komponen stok tidak ditemukan.'**
  String get pos8f4c585200a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komposisi atau jumlah produk tidak valid.'**
  String get posb68777628996;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komposisi dikonsumsi'**
  String get pos20c2bca27f3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Komposisi stok wajib memiliki komponen dengan jumlah yang valid'**
  String get pos8c991cd95ebb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kondisi'**
  String get posb723bb628009;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kondisi stok'**
  String get posef072c920632;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kondisi/catatan'**
  String get pos76a219477066;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kondisi: {arg1}'**
  String pos3ef623db628c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi ke API terputus sebelum respons lengkap diterima.'**
  String get posfefe3b5e56fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi layar pelanggan terputus. Buat pairing baru untuk mencoba lagi.'**
  String get posde96ca46f337;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi melewati batas waktu. Muat ulang; bukti yang belum terkonfirmasi tetap tersimpan.'**
  String get posc9474dc76f88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi perangkat tersedia'**
  String get pos3c2bcc062ea3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi server terputus. Transaksi web belum disimpan; silakan coba kembali.'**
  String get posdb3205b1b23c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi terputus · mencoba ulang'**
  String get pos3444e1c1dff0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koneksi terputus. Menghubungkan ulang ({arg1}/3)…'**
  String pos2eda82c2246c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi POS belum dapat dimuat. Coba lagi.'**
  String get pos99c144670e54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi POS belum siap. Tarik untuk mencoba memuat ulang.'**
  String get pos49d77ea309d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi POS tidak dapat dimuat. Periksa koneksi lalu coba lagi.'**
  String get pos8ae2a0e3cf19;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi POS tidak tersedia'**
  String get pos09c5005bb9e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi operasional'**
  String get pos6d555e664b59;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi operasional sesuai'**
  String get pos823d61d3f0f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi sesi tidak tersedia. Coba lagi saat layanan pulih.'**
  String get pos8ee41d90bf64;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi'**
  String get pos67b7bd6433f2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Hapus'**
  String get pose170ace18250;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Kata Sandi Baru'**
  String get pos32e39568417f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Keluar'**
  String get pos4c8507e0ea2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi PIN tidak sama'**
  String get pos979b1c6d198e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi Tutup Shift'**
  String get pos746fbd90103e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi diterima pelanggan'**
  String get pos088961359018;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi kata sandi tidak cocok'**
  String get posbdb2300bdfd3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password'**
  String get pos8acb91d763c0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password akun login, lalu buat PIN kasir 4–6 digit.'**
  String get posf035413485d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi password tidak sama'**
  String get posda41260e3e35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi penerimaan'**
  String get pos81bad4d0ebdb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi sudah dikirim'**
  String get posd33e46cd3a38;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi sudah disajikan'**
  String get pos83544e6c3733;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi sudah diserahkan'**
  String get posfb7511dd7570;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi {arg1}'**
  String pos18a9e21cb58b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kontak atau catatan wajib diisi.'**
  String get posbd9d9eeacb9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kontak supplier tujuan'**
  String get pose196b46c270c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kontak tujuan supplier'**
  String get posa7603db4ad52;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konteks Transaksi & Harga'**
  String get pos4fa7254bb966;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konteks harga'**
  String get posc7c9c2251e9e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kontrol inventaris secara real-time'**
  String get posba1eb971cb88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi satuan'**
  String get pos1da5dc1946c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi satuan belum tersedia untuk transaksi offline.'**
  String get pos830c62a13eba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi satuan fisik'**
  String get pos07a366526b53;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi satuan harus unik dan bernilai lebih dari 0'**
  String get posd78e730c904e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi satuan tidak valid.'**
  String get poscfae9e972218;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi tersimpan: {arg1}'**
  String pos2befc83ee9ee(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Konversi: 1 {arg1} = {arg2} {arg3}'**
  String posa006c9daadf0(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koreksi'**
  String get posc59d948c6451;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koreksi Darurat'**
  String get posbc53e9e226ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koreksi darurat {arg1}'**
  String pos886f4075bfac(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koreksi saldo ini'**
  String get pos6130a29de57d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Koreksi stok'**
  String get pos63100c7697f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kosongkan'**
  String get pos899f41b5cc75;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kosongkan keranjang & periksa'**
  String get pos6114bc6f6206;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kosongkan keranjang?'**
  String get posd197177a4ce2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kosongkan seluruh keranjang'**
  String get pos7e23cb1f87fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kosongkan untuk nomor otomatis'**
  String get posd84cb32dc73b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kredit'**
  String get pos9e12621cc945;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kualitas Buruk'**
  String get posb6b8590ca28b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kunci Otomatis Setelah (menit)'**
  String get pos4e21022f6bb3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kunci PIN dinonaktifkan sesuai kebijakan POS.'**
  String get pos707a549e35fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kunci POS'**
  String get pos79508d5da62e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kunci Saat Aplikasi di Latar Belakang'**
  String get posd369c03ef692;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kunci layar lalu masuk kembali dengan operator dan PIN yang sudah dibuat.'**
  String get posfcafa7a594c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kurangi'**
  String get pos5589ac4ca19e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kustom'**
  String get pos0b769ce5980a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'LAPORAN'**
  String get pose7ef668236c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Label Barcode {arg1}'**
  String pos366edac1e231(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Label terkirim: {arg1}/{arg2}'**
  String pos58df45e9d2a1(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Label {arg1}'**
  String posd56f5ea7493b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lainnya'**
  String get pos844f8a723473;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lampiran proforma maksimal 10 MB'**
  String get pos55d1ade4d4df;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lampirkan proforma (opsional)'**
  String get pos13c41f4e7cde;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Landed Cost'**
  String get pos1416db327cbc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 1 dari 3 · Profil Usaha'**
  String get pos8aa2435c809f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 1 · Lokasi stok siap'**
  String get posdc6bcae9bf52;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 2 dari 4 · Fitur Operasional'**
  String get pos139e5c7d4542;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 2 · Toko POS aktif'**
  String get pos64db087956e5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 2 dari 3 · Default Transaksi'**
  String get pos553e7bc38201;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 3 · Katalog penjualan'**
  String get pos21ebb9cb6982;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 3 dari 3 · Validasi Inventory'**
  String get pos9bffdb32cde8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 6 · PIN operator kasir'**
  String get pos019fc97e4540;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah 6 · {arg1}'**
  String pos20c79e7542df(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah {arg1}'**
  String pos73c8c1400ddb(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langkah {arg1} · {arg2}'**
  String pos2c4c63238b07(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langsung'**
  String get pos429121b48c9c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langsung jadi / tanpa dapur'**
  String get pos18b46d7a8e8d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langsung kirim untuk persetujuan'**
  String get pos5f04d3d18b1e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Langsung selesai saat dikirim'**
  String get pos45fb05bf47a1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjut'**
  String get pos5636299a6637;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan'**
  String get pos5bcbc797a7ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan dengan Google'**
  String get posabf7ce4c1009;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan ke tab Stok & Satuan untuk menentukan satuan dasar dan aturan persediaan.'**
  String get pos9d5e28c99300;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan pembatalan'**
  String get posb318e3331d05;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan pembayaran'**
  String get pos85f2ed654282;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan setup'**
  String get posc9b2dead5600;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanjutkan shift tersebut, atau tutup setelah kas dan transaksi offline direkonsiliasi. Shift tidak ditutup otomatis.'**
  String get pose0b6de8be3dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lanskap'**
  String get posdc72f24826cc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lantai / Level'**
  String get posebfe5e0b4b99;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lantai 2'**
  String get pos90570335cffb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan'**
  String get pos4ea259b1329d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Kendaraan'**
  String get pos93c1f2ea2f12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Komisi'**
  String get pos96d3857baa1c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Lengkap'**
  String get pose945841afe4b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Penjualan'**
  String get posd1dcfd64446e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Pergerakan'**
  String get pos5738a26d9387;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Stok'**
  String get posa8b6fd8161a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan Void'**
  String get posf6944142501b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan diperbarui langsung dari transaksi POS.'**
  String get pos01faa16d9dd8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan selisih diajukan; menunggu reviewer terpisah'**
  String get pos687d9b37d5f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan sudah diputuskan. Muat ulang daftar.'**
  String get pos681e73127873;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporan tidak dapat dimuat'**
  String get pos36b2c0cff56a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporkan kurang/rusak'**
  String get pos53ad13d0b210;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laporkan selisih transfer'**
  String get pos0a96ed2b8247;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Laundry'**
  String get posf5c101a0c210;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layanan'**
  String get pos64aceffd3bed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layanan / jasa (tanpa stok)'**
  String get posb79eff83a8b7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layanan Cepat'**
  String get pos3696a417e271;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layanan cepat'**
  String get pos48ab7ebb7bb8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layanan kecantikan, reservasi, staf, dan produk perawatan'**
  String get pos416962365efd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layani pelanggan, pantau stok, dan kelola penjualan dari satu tempat.'**
  String get pos1b3d7b3d9d3f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar Pelanggan'**
  String get pos16cd7168e6ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar pelanggan'**
  String get pos8978d15ec397;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar pelanggan melalui Wi-Fi lokal hanya tersedia di aplikasi Android.'**
  String get pos2af1260728c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar pelanggan terhubung'**
  String get pos672d2762260b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar penuh'**
  String get pos4b2f7033dd09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar penuh belum dapat dibuka. Coba lagi dari browser perangkat ini.'**
  String get pos677be7603ea9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Layar terhubung'**
  String get posb68df8c1bbf2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lebar Kertas'**
  String get posb7a2f669650b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkap'**
  String get posfd1f28e18dec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi akun Pantoo'**
  String get posaa1ec1566c21;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi detail layanan sebelum melanjutkan.'**
  String get pos1cbe776efda3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi field wajib lalu simpan agar produk tersedia di kasir.'**
  String get pos6b493cb6bbf1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi hierarki lokasi'**
  String get pos1899cac656d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi informasi akun untuk melanjutkan.'**
  String get pos6fb687df48cb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi informasi jual'**
  String get pos0f2a6d363a37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi nomor telepon dan persetujuan untuk membuat akun.'**
  String get pos4c4a81c0a45c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi sebelum menyimpan'**
  String get pos5c72e643bc37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi supplier, deskripsi, nominal, sumber dana, dan akun beban.'**
  String get pos9494ee1e398a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lengkapi waktu yang valid dan jumlah tamu minimal 1.'**
  String get posdcd63112b43a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lepas printer Bluetooth'**
  String get pos60e7fbd2c6f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lepas voucher'**
  String get posa17fe7adeee7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lepas voucher dari pesanan?'**
  String get posfb406180b6c2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lepas voucher {arg1}'**
  String pos3c6acbdc6172(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Level Harga'**
  String get pos28f2742a5e35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Level Harga Aktif'**
  String get posd11d31a1fb97;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Level Harga Default'**
  String get pose4887ee2eec0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Level harga'**
  String get posf85112657fba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Level {arg1}'**
  String posb3c012f547d2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lewati'**
  String get pos8bd638497107;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat / Cetak QR meja'**
  String get pose75a6809ca54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat Detail'**
  String get posa8f9f7a09784;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat Semua'**
  String get pos2adf97615584;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat Tagihan Supplier'**
  String get pos9f38e2a2710a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat bukti'**
  String get pos1c9522defd65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat detail'**
  String get pos2557d2ec360e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat pesanan aktif'**
  String get pos7046318792e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lihat semua'**
  String get pos9527dd654568;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login Google belum berhasil. Coba lagi atau gunakan email dan password.'**
  String get posb63f1d0ba8de;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login Google belum berhasil. Periksa koneksi dan coba lagi.'**
  String get poscfe2976f2ac1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login Google belum berhasil. Silakan coba lagi.'**
  String get posfebd44020ff0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login Google terlalu lama. Periksa koneksi lalu coba lagi.'**
  String get pos78a1383b4dc9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login gagal.'**
  String get pos81fe77ec85c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login gagal. Coba lagi.'**
  String get pos5e8dd9952d58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Login sekarang dan rasakan kemudahannya'**
  String get pos4485b4994161;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Logout'**
  String get pose43d612e11f1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Logout akun'**
  String get pos34c87188d721;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi Transit'**
  String get pos273a69e49c76;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi asal dan tujuan harus berbeda.'**
  String get pos13f745d88bdc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi belum tercatat'**
  String get posd2f4fea361d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi cabang belum diatur'**
  String get posf8e78d9857e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi kejadian'**
  String get pos5cb6e8758fbd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi penerimaan berbeda dari tujuan stok yang tercatat pada PO'**
  String get posee8e873d108d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi penjualan'**
  String get pos83744b737263;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi penjualan / warehouse'**
  String get pos0c712232d2cf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi perpindahan'**
  String get posf513e88bc46a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi snapshot (terkunci)'**
  String get pos89306eb4ab8c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi stok'**
  String get pos5dedca68146c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi stok penerimaan PO *'**
  String get posdfca62413fe4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi stok siap'**
  String get pos25894be8623d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi stok tidak tercatat'**
  String get pos3abb25ef4211;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi stok toko belum tersimpan. Sambungkan internet untuk menyiapkan katalog offline.'**
  String get posa94470fe0694;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi stok {arg1}'**
  String pos2843f97128cf(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi sumber'**
  String get pos239846258153;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi tujuan'**
  String get pos5ccdecdb4fd8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi utama • belum dirinci ke gedung/ruangan/rak'**
  String get pos2e053f59095f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lokasi: {arg1}'**
  String pos86d285bf18f2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Lunas'**
  String get pose065b60384ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'MA'**
  String get pos83125cc87a7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'MANAJEMEN'**
  String get pos2162e65b6e55;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'MITRA'**
  String get pos83255691db80;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'MRO Supplies'**
  String get pos09dab143c57f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di Tempat'**
  String get posf2f24bd8b491;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di Tempat (Pilih Meja)'**
  String get pos91aa7317a575;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di Tempat (Tanpa Meja)'**
  String get pos23b1e38da612;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di Tempat (dengan meja)'**
  String get pos0b8d01beaa49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di Tempat (tanpa meja)'**
  String get posf560263f3112;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di tempat'**
  String get pos27711cc5f4a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di tempat · Tanpa meja'**
  String get pos1c37b48fea67;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Makan di tempat · tanpa meja'**
  String get pos2c1d80834aac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Maks. Diskon (Rp)'**
  String get pos13ad040ce070;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Maksimal 100 hasil. Ketik nama/kode untuk mempersempit pencarian.'**
  String get posee50303e2a5e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Maksimum tersisa {arg1}'**
  String pos27801602c212(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Manajemen'**
  String get pos1edebd1f9bf6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Manajemen Stok'**
  String get pos18928d792efc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Manajemen Terpadu'**
  String get posdc5278c51c2f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Manual'**
  String get pos4e836fdc2572;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Manual + Promo'**
  String get pose2d1385525c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Manual saja'**
  String get posa597b84b2833;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Marketplace'**
  String get pos983095c0ea49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get posf2dd30734a6a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masuk PIN kasir terlebih dahulu untuk menyimpan atau memulihkan retur.'**
  String get pos2a5d8a5edfc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masuk ke POS Mobile'**
  String get posa791716d343e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masuk sebagai Kasir'**
  String get pos5e8a419ae266;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan 4–6 digit angka khusus milik operator tersebut.'**
  String get pos51f157329714;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan No. Invoice...'**
  String get pos9130978b1b96;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN 4–6 digit karyawan'**
  String get posd729b5d8f153;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan PIN kasir sebelum memeriksa shift.'**
  String get pos7c3de4226e10;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan angka valid'**
  String get pos3f0e8b9c8b17;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan email yang valid'**
  String get pos8f3a1bf071bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan enam karakter CAPTCHA'**
  String get pos4de3692f58a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan harga yang dibayar pelanggan. Harga beli/HPP dapat dilengkapi untuk membaca margin.'**
  String get pos4ebfb06378c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan jumlah pembayaran yang valid.'**
  String get pos0a979f003a0b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan kas awal sesuai uang fisik di laci untuk memudahkan rekonsiliasi.'**
  String get pos2a9e22d410da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan kode voucher atau promo yang digunakan'**
  String get pos04f4fcb6b340;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan minimal 2 karakter'**
  String get posdb3a72dc94d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan nomor telepon 8–15 digit.'**
  String get pos7844ce0f93f7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan nomor tujuan'**
  String get pos59f2894d2bfa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan stok melalui alur yang tepat'**
  String get posfa444fe1d6d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Masukkan stok yang valid'**
  String get poscff23131c29d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Matching: {arg1} · Jatuh tempo: {arg2}\nOutstanding: {arg3}'**
  String pos17bfd9a177d7(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja'**
  String get pos7e149ab136a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja \"{arg1}\" berhasil diperbarui'**
  String posfa22ff918702(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja \"{arg1}\" berhasil ditambahkan'**
  String poscef4c604164c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja berhasil dihapus'**
  String get pos40cab72a9546;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja masih memiliki pesanan aktif dan tidak dapat dihapus.'**
  String get pos4ced6ce7acc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja tidak ditemukan'**
  String get posb9acaf793c8e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja {arg1}'**
  String pos29db2f117897(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja · {arg1}'**
  String posc617cc586a0c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meja, dapur, dan pesan antar'**
  String get pos305a15c9d811;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memastikan draft...'**
  String get pos2b24399b7752;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Member'**
  String get pos6853c98a6f43;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memeriksa PO terbuka untuk barang ini…'**
  String get posa8891bc0532c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memeriksa antrean offline...'**
  String get pos3347fa44e993;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memeriksa penerimaan...'**
  String get pos7835f13bdca6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memeriksa transfer terbaru...'**
  String get pos1a72fe1062a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memeriksa...'**
  String get pos2e34c1191665;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memeriksa…'**
  String get pos048ecc7562e7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memerlukan izin tambah supplier. Data pajak dan alamat dapat dilengkapi di web.'**
  String get pos15403184d9b0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memerlukan verifikasi online.'**
  String get posf4b4e9473648;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memindahkan pesanan'**
  String get pos5aa9f2c1320e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memindahkan pesanan dapur'**
  String get posd393b9b0ef8e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Meminta revisi'**
  String get pos4f8ed6e388f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mempersiapkan dashboard...'**
  String get posbed1b72018c1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memproses dan memperbarui retur...'**
  String get pos955ddd5b0913;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memproses transfer...'**
  String get pos6264e018ce66;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memproses...'**
  String get pos5f2061cbdf8f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memuat pengaturan struk… Anda tetap dapat melihat halaman ini.'**
  String get pos5dd5b804c0b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memuat transaksi...'**
  String get posdb6901fef6ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Memverifikasi akun ke Pantoo POS…'**
  String get pos900c6d4b2e5b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menampilkan panduan tata letak PDF'**
  String get posa301c88d72cd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mencatat penerimaan mutasi {arg1}...'**
  String posa71587490499(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mencetak struk...'**
  String get pose6d19189f617;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mencetak struk…'**
  String get pos2df640ba2491;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mencetak…'**
  String get posce247c3f955f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mendesak'**
  String get posc614b769dbbc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menentukan daftar harga produk pelanggan ini'**
  String get pos2225aa4fce9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menentukan harga produk untuk pelanggan ini'**
  String get posee48fb2e096b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mengajukan PO {arg1}...'**
  String posbffaaa8b679c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mengerti'**
  String get poscda80f09a6a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan ulang layar pelanggan…'**
  String get pos609df42fd4d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menghubungkan…'**
  String get pos787dc4aadf40;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mengirim...'**
  String get pose1010f9f4fe2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mengirim…'**
  String get pos00df34064d27;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mengulangi jurnal {arg1}...'**
  String pos7ff57871e031(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mengunggah...'**
  String get posbf0c0c2094f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menolak melepaskan barang agar dapat diproses ulang. Pelapor tidak boleh memutuskan laporannya sendiri.'**
  String get pos9f17fa169c88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menu'**
  String get pos57f5f5efbc59;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menu tidak ditemukan'**
  String get pos45718cc63b3f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu'**
  String get posbcc4a60693b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu dapur'**
  String get posb651ecbc1c60;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu kasir menambahkan produk.'**
  String get posf3057c1bd132;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu konfirmasi'**
  String get pos4c25b91d5275;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu penerimaan'**
  String get pos226af7add369;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu penyerahan'**
  String get pose3d4131eda62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu perangkat…'**
  String get pos709aa770adfc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu persetujuan'**
  String get pos8359f127193c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu pilihan akun Google…'**
  String get pos53a70fe7d7f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu proses'**
  String get pose398c2c079bf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu respons'**
  String get pos7acfde6c8cc9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu sinkronisasi server'**
  String get pos4775986a2641;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menunggu supplier'**
  String get pos2f330d8f1f39;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menyelesaikan pendaftaran…'**
  String get pos2e76b446b2a7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan Pantoo POS…'**
  String get pos833c65e9f213;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan login Google…'**
  String get pos090296b76c46;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan…'**
  String get pos36dd6d6b11f7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menyimpan...'**
  String get posf16f7f9512ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Menyimpan…'**
  String get pos92e2482fd49f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Merek'**
  String get pos2281e868fd1a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode'**
  String get pos5ac33f2c588b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran'**
  String get pos2a5040bd1051;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode Pembayaran Default'**
  String get posac8a50ffd071;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran'**
  String get pos53eb1a623ade;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode pembayaran: {arg1}'**
  String pos37949a5da433(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode penerimaan'**
  String get pos1e76e9e68291;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode untuk bagian yang sudah dibayar'**
  String get posfd53d4d680b7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode: {arg1}'**
  String posc1ee701a402d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Metode: {arg1} · Termin: {arg2}{arg3}'**
  String posb0b20c64aae6(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Min. Pembelian (Rp)'**
  String get pos2a72463de982;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Min. belanja {arg1}'**
  String pos2642c8d7b316(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minggu Ini'**
  String get posa4c67a20f600;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimal 10 karakter'**
  String get pos24e468e21005;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimal 2 metode, setiap jumlah harus lebih dari 0, dan total harus tepat.'**
  String get pos7218dad7779c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimal 5 karakter'**
  String get pos254f9747a60f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimal Transaksi Tunai (Rp)'**
  String get pos097715fd4c9e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimal transaksi tunai tidak boleh negatif.'**
  String get posbe17257a299d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimum'**
  String get pos5d398eef3ecc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimum transaksi tunai {arg1}. Pilih metode lain atau tambah transaksi.'**
  String pos9e159b1c2295(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minimum {arg1}'**
  String pos543e961a6128(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minta petugas yang memiliki akses membuat opname untuk lokasi ini.'**
  String get pos40adfaa035d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Minta revisi'**
  String get pos43b98f83f50d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mitra'**
  String get posf2505d4015d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mitra Non-Aktif'**
  String get pos8bb4ef5d9c6d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mobile POS Pantoo'**
  String get posd242e923b109;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mobile POS Pantoo (Dev)'**
  String get posab370d25ce9c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mobile POS Pantoo (Staging)'**
  String get pos163fa4235845;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mobile POS Payment'**
  String get pos2df17605c8ff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode Cetak Bluetooth'**
  String get pos70a4f89b86e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode debug PDF'**
  String get pos13c8ce146162;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode lihat saja. Izin Kelola Pengaturan POS diperlukan untuk menyimpan perubahan.'**
  String get pos4bc940c602c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode lihat saja. Perubahan memerlukan izin Kelola Pengaturan POS.'**
  String get pos5c174268db6c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode offline · Angka ini hanya perkiraan dari riwayat yang tersimpan di perangkat.'**
  String get pos910c6d384f34;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode shift kasir'**
  String get pose9e5220de240;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode shift toko belum tersimpan. Hubungkan internet dan muat ulang toko sekali sebelum melanjutkan offline.'**
  String get posd014b242f2da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mode snapshot shift belum tersedia. Verifikasi shift saat online terlebih dahulu.'**
  String get posff82cf4bada4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Model / tipe'**
  String get pos650e36cf76a5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Model layanan'**
  String get pos3cc6edc5685a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Model: {arg1}'**
  String posbdc2845195b0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mohon isi field yang wajib (Nama dan Harga)'**
  String get posc46febb3ad42;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mohon tunggu sebentar'**
  String get posc8e79b99f056;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat lagi ({arg1}/{arg2})'**
  String pos3bcc4a44a905(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat lebih banyak'**
  String get posf7a8990dc6a0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang'**
  String get pos139b85ada048;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang antrean'**
  String get pos86fa0b971ba4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang katalog'**
  String get posb272a8e4df9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang kategori'**
  String get posaa8e77425c74;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang printer'**
  String get pos1a640a1a1a7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang tagihan sebelum mencatat pembayaran lagi.'**
  String get posc143701b68e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang tagihan sebelum mencoba pembayaran lagi.'**
  String get posc6835bfee9cb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Muat ulang tagihan sebelum pembayaran berikutnya'**
  String get pos2bf3a79eb582;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mudah Digunakan'**
  String get pos9ec2d52493d6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai'**
  String get pos44164b908ecb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai Berjualan'**
  String get posb22588b3cc58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai Lebih Cepat'**
  String get pos6abcbebc3318;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai Sekarang'**
  String get pos7c4bd6c9b22d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai hitung barang ini'**
  String get pos48ab3b2f0e33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai panduan'**
  String get posc22730cb8b24;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai panduan kasir'**
  String get pos0093d2ea6be6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai proses'**
  String get pos1801629853aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai reservasi *'**
  String get posb90f6133997b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai shift kasir'**
  String get pos37304c670c37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mulai trial Pantoo Unlimited dan siapkan toko Anda dalam beberapa langkah.'**
  String get pos8062023c1687;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mutasi Stok'**
  String get posb949f55ba289;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mutasi stok berhasil disimpan'**
  String get pos154f8be699fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mutasi stok gagal diterima'**
  String get pos7f4d6bf4adad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Mutation GraphQL gagal'**
  String get pos00d20ca3cb52;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama'**
  String get pos79d12c107a32;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Kasir'**
  String get posb101d3947323;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Meja'**
  String get pos8e78fc4ac38b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Pelanggan'**
  String get pos4eccf1679992;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Produk'**
  String get pos67c56ac125b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Promo'**
  String get pos783aacf14a0e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Toko / Outlet'**
  String get pos50188da51884;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama Usaha/Organisasi'**
  String get posadaa66a604ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama atau kode barang'**
  String get posddc01a706e19;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama atau nomor telepon'**
  String get pos7cb67ac49563;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama dan alamat lokasi'**
  String get pos2cc7aa59412b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama dan alamat warehouse wajib diisi'**
  String get pos397e8d44d9fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama dan email menggunakan akun Google Anda. Tambahkan nomor telepon untuk melanjutkan.'**
  String get pos59e181097852;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama dan harga jual wajib diisi'**
  String get posbc94b959088f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama ini ditampilkan sebagai judul pesanan tersimpan.'**
  String get pos3b70768d4a70;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama instansi belum tersedia untuk bukti pembayaran'**
  String get pos8f4ec64c487b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama instansi belum tersedia untuk dokumen PO'**
  String get poseadc7dc709ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama kategori'**
  String get pos458b202df966;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama lengkap'**
  String get posc35873bafe84;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama maksimal 200 karakter'**
  String get pos715ed13a07ec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama meja'**
  String get pos99e0f9c80f34;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama meja wajib diisi'**
  String get pos7f62288a5370;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama minimal 3 karakter'**
  String get pose22f47c2bafa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama outlet'**
  String get posc031fef2c068;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan'**
  String get pos21cafc4df8c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan wajib diisi'**
  String get poscf7ab6193fcb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama pesanan'**
  String get pos8de772a9999c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama produk *'**
  String get posa19b14d84330;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama supplier *'**
  String get posfb1952bd2dd8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama supplier minimal 2 karakter'**
  String get pos8477380609e5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama usaha atau organisasi minimal 3 karakter'**
  String get pos32fe40c439ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama wajib diisi'**
  String get pos488b5904e23a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama warehouse *'**
  String get pos4a8e2d02dfb4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama, kode, atau barcode'**
  String get pos471299409740;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nama, kode, dan lokasi penjualan wajib diisi'**
  String get posb3b972e0dfc0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nanti'**
  String get posb96e0062842d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Navigasi: Tab / Shift+Tab untuk berpindah, Enter atau Spasi untuk memilih.'**
  String get pos34a5d7a1b7ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Net 30'**
  String get pos66a1e43c0a09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Net 45'**
  String get posed50c264b6f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Net 60'**
  String get posd964ac944cda;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Net 90'**
  String get pos10b28cd6b026;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nilai Diskon (%)'**
  String get pos85fa51601fca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nilai Diskon (Rp)'**
  String get pos2a1731d0a48c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nilai Retur (neto)'**
  String get pos86f56874ed7a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nilai Stok'**
  String get pos7e2564a5f6c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nilai baru sama dengan saldo saat ini'**
  String get pos81751335f5f1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nilai diskon wajib diisi'**
  String get posf723f99a2d34;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No PO: {arg1}'**
  String posec83af4cb31d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No Transaksi'**
  String get posecd4d34e4587;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No.'**
  String get posb8b9f1367ad6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No. Order'**
  String get pose0a60dd8f90d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No. polisi / ID unit'**
  String get pos299fec51b2e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No: INV-20260909-001'**
  String get posd6e29beb91fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'No: {arg1}'**
  String posded34ba7cec1(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal'**
  String get pos1795d163388f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal (maks. Rp{arg1})'**
  String pos75918812dfbd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal DP'**
  String get pos2125c9c5afc2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal Tetap (Rp)'**
  String get pos590738f070c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal aktual (Rp)'**
  String get pos08d381cde90d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal biaya (Rp)'**
  String get pos967052976a85;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal biaya harus Rupiah bulat positif'**
  String get pos7c122c58a738;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nominal harus lebih dari nol dan tidak melebihi {arg1}.'**
  String pos7596519ab293(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor Invoice'**
  String get pos0cfda8058a7d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor PO'**
  String get pos1b3f5700a70c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor PO / supplier'**
  String get pose625eaba682f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor Telepon Usaha/Organisasi'**
  String get pos9ec5ed9753e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor WhatsApp'**
  String get pos9aea5ac737a1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor batch (opsional)'**
  String get pos893df9598db8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor batch *'**
  String get pose0d718d0a94b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor batch dan tanggal kedaluwarsa {arg1} harus diisi bersamaan'**
  String posfe43073929cf(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor batch dan tanggal kedaluwarsa {arg1} wajib diisi'**
  String poscc7d32a39de7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor bukti / referensi penerimaan'**
  String get posd60ca2aeac57;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor dokumen disalin'**
  String get pos53d8cfb1d872;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor invoice (opsional)'**
  String get posfb635bb270e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor invoice maksimal 120 karakter'**
  String get pos50cf5c6f8843;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor pesanan server: {arg1}. Periksa item, total, dan meja sebelum menandai pemeriksaan selesai. Jangan buat pesanan baru untuk menggantikannya.'**
  String pos810ac1454f9b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor referensi (opsional)'**
  String get posd4b1fb67c48e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor retur disalin'**
  String get pos9ff1720d219e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor seri barang tidak boleh dipakai di dua baris.'**
  String get posb75e90b2eb7a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor seri tidak termasuk transfer.'**
  String get pos924623adb22d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor seri yang dikirim (satu per baris)'**
  String get pos2a23699fd244;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor surat jalan (opsional)'**
  String get pos42ee73368f4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor telepon'**
  String get posf2df3517c26b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor telepon harus 8–15 digit'**
  String get posa61d7dc8457d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nomor telepon wajib diisi'**
  String get pos5be049bc5180;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Non Member'**
  String get posed25485938dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nonaktif'**
  String get pos609449ca31c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Nonstok'**
  String get pos1d31e323e7a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Normal'**
  String get pos45e118d0563e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Notifikasi'**
  String get pos624d215cd123;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Notifikasi gagal diperbarui'**
  String get pos76be91279516;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Notifikasi operasional'**
  String get pos3950c303ce3f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Objek layanan'**
  String get pos7d0d951cd306;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Objek/jenis kendaraan'**
  String get posb2d8d9f91c27;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Offline'**
  String get pose01fa717bacc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Offline · hanya katalog tersimpan, belum tentu lengkap'**
  String get pos451617e30393;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Oleh {arg1}{arg2}'**
  String posfd312a360b1e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Omzet'**
  String get pos4e970421d303;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ongkir'**
  String get pos63383c0e6b7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ongkos kirim'**
  String get pos06ac9575d123;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Online'**
  String get posc3e839df6084;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operasi antrean gagal. Muat ulang untuk memeriksa statusnya.'**
  String get pos31135b0c022b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operasi belum tersedia pada versi API yang sedang aktif.'**
  String get pos7c554fb93f2a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operasi gagal diproses'**
  String get posde3d00f8991f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operasi inventori gagal'**
  String get pos02eaee2e25a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operasional'**
  String get pos425f34356895;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator aktif: {arg1}'**
  String posf749a4f6a690(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator berubah selama pemeriksaan shift'**
  String get pos57fc2f64757a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator berubah. Muat ulang halaman retur.'**
  String get pos04116e2c9dd5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator berubah. Periksa shift kembali.'**
  String get pos6d7d771d7ac4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator berubah. Pulihkan menggunakan kasir asal.'**
  String get pos9844e85a16c2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator kasir'**
  String get pos10b91cdcb5b9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Operator kasir sudah terverifikasi.'**
  String get posb4caca3a4305;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opname sudah berubah status. Kembali dan muat ulang daftar.'**
  String get pos8f47d27a760e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opname tidak ditemukan.'**
  String get posd4c5cc9a4011;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opsi lain: pembayaran, diskon & biaya'**
  String get pos94953b7a3b93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opsi lanjutan pembelian'**
  String get posb0e96c170c53;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opsi pembayaran'**
  String get pos88b0caa86d35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opsional'**
  String get poscf048762964b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opsional untuk barang ini'**
  String get pos247219f1e8ec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Opsional, untuk membatasi kelebihan persediaan'**
  String get pos9868b6f7cd56;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get pos1d75774c0f96;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Order Online ({arg1})'**
  String pos46179ba2b7f3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Order layanan'**
  String get posafd54e4e8409;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Order tersimpan dapat dilanjutkan dari Daftar Order atau Riwayat.'**
  String get pos9f001a135526;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Orientasi'**
  String get pos3312abcca494;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Otorisasi & Lanjutkan'**
  String get pos39eae302d6a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Otorisasi Barang Kedaluwarsa'**
  String get pos451bde271c3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Otorisasi PIN supervisor memerlukan koneksi server. Sambungkan perangkat lalu ulangi transaksi.'**
  String get posb727f0a4d627;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Luar Ruangan'**
  String get posc28c999070af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet POS terkait'**
  String get posdcd76e2dcb71;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet Pusat Jakarta'**
  String get pos34e845713ad1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet berhasil dihapus'**
  String get posdbab7c41f127;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet berhasil disimpan'**
  String get pos2d5a92222852;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet shift aktif belum tersedia untuk penjualan. Minta supervisor memeriksa akses dan lokasi stok.'**
  String get posc8b97c065670;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet shift aktif tidak ada dalam daftar akses. Minta supervisor memeriksa akses outlet; jangan membuat shift pengganti.'**
  String get pos8d1ce322c4eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet tersimpan ({arg1})'**
  String posb3f4a442d275(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet tidak ditemukan'**
  String get pos48ed07b336e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Outlet: {arg1}'**
  String pos8c29bd885f11(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Override hanya berlaku untuk produk nonkonsumsi yang diizinkan pada master inventaris. Perangkat harus online dan supervisor wajib memberi PIN serta alasan audit.'**
  String get pos489422d10046;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PEMBATALAN DIPROSES'**
  String get pose5dc3f463927;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PEMBATALAN DIPROSES - BUKAN BUKTI PEMBAYARAN AKTIF'**
  String get posabafacd8728c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PEMBELI'**
  String get pos9df33ab5c1be;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PEMBELIAN'**
  String get posc0d021d95ace;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PENGATURAN'**
  String get pos4886f4978ab5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PERINGATAN: Barang kedaluwarsa dijual dengan otorisasi. Alasan: {arg1}'**
  String pos8005cfd2ce83(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN akun lain tetap dibuat atau direset oleh admin POS.'**
  String get pos0ad4164958bd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN baru'**
  String get posa401eb1a3917;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN baru (4–6 digit)'**
  String get posf646e7f70118;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN dapat dibuat sendiri untuk akun login atau dikelola oleh admin POS.'**
  String get pose836d8ff248d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN hanya dapat dibuat untuk akun login'**
  String get pos9e179dd946e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN harus 4–6 digit angka'**
  String get pos51ef2be0d90a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN karyawan belum dibuat. Hubungi admin POS.'**
  String get pos18e45faa12d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN kasir pembuat transaksi'**
  String get pos49d3706211c0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN keypad'**
  String get pos51801b9f543e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN offline belum tersedia di perangkat. Verifikasi operator saat online terlebih dahulu.'**
  String get posf0051b79abf9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN operator kasir'**
  String get posee711e78127c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN salah'**
  String get pos245897c8bf93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN supervisor'**
  String get pos0d84c7cb0ab3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN supervisor wajib diisi'**
  String get posee4f932a81c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN terkunci sementara. Coba lagi setelah {arg1}.'**
  String posc67d91cca2be(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PIN tidak valid'**
  String get posafb55c20b67a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO belum dapat diperbarui: {arg1}'**
  String pos696aa1b34ef8(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO belum disetujui dan belum dapat dicetak resmi.'**
  String get pos33d25940f1a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO halaman {arg1}'**
  String pos4a59442df598(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO sudah tidak dapat menerima barang. Periksa status terbaru sebelum membuat request baru.'**
  String get posa3c6a5810273;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO terbuka belum dapat diperiksa: {arg1}'**
  String pos62e8e1dd4504(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO tidak dapat menerima barang lagi setelah ditutup.'**
  String get pos1f963bbc11d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO tidak ditemukan'**
  String get pos1bdb95acfb37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PO: {arg1}'**
  String pos5c04fa38f710(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'POINT OF SALE'**
  String get pos302161171b37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'POS'**
  String get pos4abd3985ba80;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'POS & Inventori'**
  String get pos4c43bce2f75e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'POS / Retail'**
  String get pos7be1648ccde7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'POS Mobile ({arg1})'**
  String posa8e0e5d00653(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'POS siap digunakan'**
  String get pos2f59f12da563;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PPN (%)'**
  String get posea28acda10e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PPN ({arg1}%)'**
  String posc53479dd68b9(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'PURCHASE ORDER'**
  String get posf549f53f0f38;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pairing gagal.'**
  String get pos0ca6630f8da2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak'**
  String get pos7fe412d4db0e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak    {arg1}'**
  String pos62e104d5b8c0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak & Keuangan'**
  String get pos3b7cc0983555;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak (%)'**
  String get pos1c019b5a318e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak harus antara 0 dan 100 persen'**
  String get pos5a2e9c877bbb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak harus berada pada rentang 0–100%.'**
  String get pos681bd4010b93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pajak transaksi (%)'**
  String get pos495f9bff5a0e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Paket'**
  String get pos3c97ce060ce2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Paket / bundel (stok komponen)'**
  String get pos678240e33a4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Paket trial akan aktif otomatis setelah profil usaha berhasil dibuat.'**
  String get pos04611b81b2b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Paksa lanjutkan'**
  String get pos738c87593325;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Panduan interaktif akan menyorot pencarian produk, keranjang, pelanggan, dan tipe pemenuhan.'**
  String get posd427334c1222;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Panduan kasir sudah dijalankan dan POS siap digunakan.'**
  String get pos2643f0cd5bdd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Panduan transaksi kasir'**
  String get pos846f60a5b73d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pantau penjualan setiap saat'**
  String get pos03d6254f41fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pantau transaksi'**
  String get pos787caf16bfe3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pantoo'**
  String get pos6b5dafc69e0a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pantoo POS'**
  String get pos01b2e69d6fa9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Password'**
  String get pos8be3c943b160;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Password akun'**
  String get pos211e672794db;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Password minimal 8 karakter'**
  String get posaaf0a22fd3ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Password wajib diisi'**
  String get posdab355983303;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan POS dan Inventory sejalan'**
  String get poscbdd94221370;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan data retur sudah benar.'**
  String get pose4c906f412e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan harga, stok, promo, pelanggan, dan shift sudah diperbaiki. Server akan menghitung dan memvalidasi ulang transaksi ini.'**
  String get posbc5c68313a8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan lokasi penjualan aktif agar dapat dihubungkan ke toko POS.'**
  String get pos195cac54b1c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan pembayaran sudah diterima pada perangkat atau rekening merchant sebelum memproses transaksi. POS mencatat metode pembayaran dan tidak menjalankan payment gateway otomatis.'**
  String get posc1a3f392520f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan produk aktif dan ditampilkan pada katalog penjualan.'**
  String get pos336fac8d52c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan produk yang melacak stok memakai lokasi dan satuan yang konsisten.'**
  String get pos2eec238fa1ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan rincian dokumen sudah benar sebelum melanjutkan.'**
  String get pos7c54f7a9d9d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pastikan shift dibuka pada toko yang akan melayani transaksi hari ini.'**
  String get pos468d2133243d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Payload lokal'**
  String get posbcbef5a9f3fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pekerjaan Bengkel'**
  String get pos544b8efc9443;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pekerjaan berbasis layanan'**
  String get pos7a95c90c9044;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelajari cara menyimpan pesanan aktif serta melanjutkan ke pembayaran dan struk.'**
  String get pos5fc5f5280c54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get posaf0ab4433946;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan / Meja'**
  String get pos437a6e3cfda6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan POS tidak tersedia'**
  String get pos91cff7aeb01e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Transaksi'**
  String get pos3a5a53b1566e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Umum'**
  String get pose5141a6ccfac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan Wajib Dipilih'**
  String get posee9ef7297ddc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil dihapus'**
  String get pos4899fcfdc5f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil disimpan'**
  String get pos727d3a540546;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan berhasil ditambahkan'**
  String get pos6bf58e968c9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan tersimpan, tetapi ID pelanggan tidak diterima'**
  String get pos7643a04897af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan tidak ditemukan'**
  String get posb95f6d3181a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan umum'**
  String get pos4866ef8a31f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan umum dipilih'**
  String get pos467968fe0458;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan wajib dipilih untuk profil POS ini'**
  String get pos77bfd66f8168;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan wajib dipilih untuk tipe pemenuhan ini'**
  String get posec4690a862aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan: Pelanggan Umum'**
  String get posa0218cf87673;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan: {arg1}'**
  String pose8576d8afa6c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pelanggan: {arg1}\n'**
  String pos0a36262b25f5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pemakaian: {arg1}/{arg2}'**
  String pos5f2c9e5e92b4(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembatalan akan membalik perpindahan stok ke lokasi asal. Pastikan stok tujuan atau transit masih mencukupi.'**
  String get pos73b0a9bc9815;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembatalan pembayaran gagal'**
  String get pos3ac3498cb0dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembatalan sebelumnya belum selesai. Coba lagi untuk menyelesaikan jurnal pembalik.'**
  String get pos462ab9a7ce8e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran'**
  String get posf0874594eb78;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Berhasil'**
  String get posdeea40f5a356;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Gagal'**
  String get poseeca4a051f2b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran PO {arg1}'**
  String pos26eb6e9694bd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran Tidak Cukup'**
  String get poscfc71d335b86;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran berhasil!'**
  String get pos1a292ae60985;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran dibatalkan dan jurnal dibalik'**
  String get pos5158591538d6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran diterima server, tetapi bukti lokal belum dapat diperbarui. Muat ulang sebelum melanjutkan.'**
  String get posdff803622eaa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran hutang gagal disimpan'**
  String get pos71a0b91660a0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran ini'**
  String get posd1faba7b4922;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran invoice gagal diproses'**
  String get pos3d560d6087d4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran non-tunai harus diverifikasi oleh server. Pilih Tunai atau sambungkan perangkat ke internet.'**
  String get posa95cbe825211;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran tercatat'**
  String get posc21910623c68;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran tersedia setelah penerimaan pertama dicatat.'**
  String get pos9a469f02f486;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran tidak ditemukan'**
  String get pos36b10f4c63f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran {arg1} akan dibalik di jurnal dan dihitung kembali sebagai hutang.'**
  String pos47ced915a77a(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembayaran: {arg1}'**
  String pos0e93e26fcc3b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembeli'**
  String get pos40fb4ba95b58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembelian'**
  String get posa266463e5684;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembelian & Penerimaan'**
  String get pos7f58b58ae05a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembelian Langsung'**
  String get pos1349bbfde1db;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembuatan PIN tidak tersedia'**
  String get posa6ecfd4c4da6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pembulatan Harga'**
  String get pos348bbc8d9acb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pemenuhan profil POS tidak valid'**
  String get pos987bddc13363;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pemesan meminta menjadi pelanggan dengan nomor {arg1}. Konfirmasi lalu pilih profil yang ada atau tambah pelanggan baru.'**
  String pose6d93ee48cd5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penanggung jawab layanan'**
  String get pos169ead46c156;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penanggung jawab: {arg1} · Proyek: {arg2}'**
  String posa21c3b378169(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pencetakan PO dibatalkan atau gagal.'**
  String get poscb23b0c42cec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pencetakan dibatalkan atau gagal.'**
  String get posc5bfc8ed9319;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pencetakan label dibatalkan.'**
  String get pos5e19b1a72a86;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pendaftaran Berhasil'**
  String get posa500f2871bbc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pendapatan Hari Ini'**
  String get pos44d976b9e0fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pendapatan {arg1}'**
  String pos14401dca7861(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penempatan aktual harus berada di gudang tujuan transfer.'**
  String get pos7efe502de734;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan'**
  String get posbd870ab7ab13;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan Barang'**
  String get pos750232066a15;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan Tunai'**
  String get pos7509362285bd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan barang'**
  String get pos8b1fc3d1fa70;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan berhasil dibatalkan'**
  String get pos59dc4a661597;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan dari supplier'**
  String get pos47db2ea96b3d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan mutasi gagal. Muat ulang untuk memeriksa statusnya.'**
  String get pos9ad658342acf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan parsial didukung. Isi hanya jumlah yang datang sekarang; sisanya tetap dapat diterima pada penerimaan berikutnya.'**
  String get pos8ed81389e32e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan parsial yang sudah dicatat'**
  String get pos72c698870099;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan pembelian berhasil dicatat'**
  String get pose0963221e1a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan sebagian berhasil dicatat'**
  String get posa609bf18a1d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan sebelumnya sudah tercatat; request tidak dikirim ulang.'**
  String get pos04bc1b7c365e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan tercatat di Finance. Stok tidak berubah.'**
  String get posb6c6364e3add;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan tercatat; sisa tetap dalam perjalanan'**
  String get pos05f9c28311c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penerimaan, proses cucian, pickup, dan delivery'**
  String get pos2b4ff2a4ed85;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengantaran'**
  String get pos9adf173776ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get pos3fcdc1c4886d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Cetak'**
  String get posc2a1a7bc8f01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Cetak QR'**
  String get posa6e412670477;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Cetak QR Code'**
  String get pos4abb25f8759e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Kendaraan'**
  String get pos8e7869583112;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan PIN berhasil'**
  String get posad02c326569e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan PIN gagal diproses'**
  String get posf78996a42a51;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan POS'**
  String get pose448f6706003;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Printer'**
  String get pos5fc77a1fa51e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan Struk'**
  String get pos7bbfda48ddc4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan berhasil disimpan'**
  String get posff057d419bee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan berlaku sebagai default operasional POS.'**
  String get pos1d50f6761638;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan disimpan ke database dan digunakan bersama POS Admin serta Inventory.'**
  String get pos041be20d76d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan pelanggan belum dapat dimuat. Coba lagi saat koneksi tersedia.'**
  String get posb51af5a191e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan pelanggan gagal dimuat. Coba lagi.'**
  String get pos003d670b7cbd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan struk berhasil disimpan'**
  String get posb06ae32ef97e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengaturan struk gagal dimuat'**
  String get posafd542ed86f2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengguna'**
  String get posc720f7612f49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengguna tidak ditemukan pada instansi ini'**
  String get pos87594ba2bb9c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengiriman'**
  String get posf5064fda288a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengiriman dari outlet'**
  String get posd330ba42196d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pengiriman menuju transit: stok tujuan baru bertambah setelah penerimaan.'**
  String get pos20dd92d09621;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penjualan'**
  String get posf577b29c51a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penjualan Barang Kedaluwarsa'**
  String get pos3b91e2010d2b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penjualan Deposit'**
  String get pos1cbe1294fd2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penjualan Hari Ini'**
  String get pos063da5c806a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penjualan tanpa shift diizinkan oleh kebijakan POS.'**
  String get pos188eb84be3dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penjualan {arg1} Terakhir'**
  String pos063e03843503(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyelesaian'**
  String get posd7fc0ffb0ed7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyelesaian selisih'**
  String get pos50b47d38dfab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyelesaian: {arg1}'**
  String pos57915034b172(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyerahan'**
  String get pos6be6f1877afe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyimpanan PIN tidak tersedia. Verifikasi online diperlukan.'**
  String get pos636321469856;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyimpanan browser menolak data pesanan'**
  String get pos74a586d6b8f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Penyimpanan request ditolak perangkat'**
  String get pos3887933a52b5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perangkat lain yang masih offline tidak dapat dideteksi. Pastikan semua kasir pada shift ini telah sinkron dan kas fisik telah dicocokkan.'**
  String get pos6e9a2f805880;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perangkat offline. Penjualan tunai disimpan lokal dan menunggu sinkronisasi.'**
  String get pos851e8c6bca8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perangkat sedang offline'**
  String get pos4e197bd5a06d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perangkat sedang offline. Operator belum memiliki cache PIN lokal; sambungkan internet sekali untuk verifikasi awal.'**
  String get posb8a45c361d38;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perangkat sedang offline. Sesi yang pernah login akan dibuka otomatis; login pertama atau setelah logout memerlukan internet.'**
  String get posb2bf5d7b9022;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perbaiki Retur Pembelian'**
  String get pos3a5ec7f46fc1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perbarui informasi dokumen dan hasil penghitungan stok.'**
  String get posc1fa4d0e39e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perbarui status'**
  String get pos11163811c0bd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Percobaan sinkron: {arg1}'**
  String pos7d60a10a7702(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Percobaan: {arg1}'**
  String pos919294430196(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Performa Kasir'**
  String get pos15fde549f970;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa'**
  String get posd1c4bf867dc6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa & putuskan selisih'**
  String get pose4f82cb96e1d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa Lagi'**
  String get pos5cba9de4623c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa Riwayat'**
  String get posb40a738a07a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa dulu'**
  String get pos909e2d8b157e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa harga'**
  String get pos888b973df441;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa jumlah, harga beli, dan diskon setiap barang'**
  String get pos7495cad8f33b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa kembali'**
  String get pos0334dacff8fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa kembali shift'**
  String get pos3c5de457478d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa lebih dulu apakah invoice sudah tercatat di server. Pastikan uang yang diterima telah dikembalikan atau direkonsiliasi. Jejak transaksi tetap disimpan pada perangkat.'**
  String get posd3742633c646;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa lebih dulu apakah pesanan sudah tercatat di server. Jika belum, pesanan lokal dapat diselesaikan setelah pelanggan diberi tahu. Jejaknya tetap tersimpan pada perangkat.'**
  String get pos7a9db5794ed8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa pengaturan'**
  String get pos0fefa3ec8de5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa perangkat kasir lain'**
  String get pose54d897562ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa profil transaksi'**
  String get pos6b9246966cac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa status toko'**
  String get posde9c5e3dcdb6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa toko aktif dan buka shift kasir sebelum membuat pesanan.'**
  String get pos7b21414952b5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periksa transaksi server'**
  String get pos51c207011a12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Peringatan stok minimum'**
  String get pos78659c9a6100;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Periode'**
  String get pos85e181b57a56;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perkiraan kebutuhan dana'**
  String get pos7559a88f2a3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perlakuan biaya'**
  String get pos7af907a24b5b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perlu akses Stock Opname'**
  String get poscc925cc7522e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perlu disiapkan'**
  String get pos1c9ed065a9c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perlu ditinjau'**
  String get pos67c4b57f25d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perlu persetujuan'**
  String get pos166e0b446d19;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perlu tindakan saya'**
  String get pos39154964c2c8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perluas {arg1}'**
  String posa67275acc90a(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan DP'**
  String get pos21b92e2945e7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan DP gagal disimpan'**
  String get posa2f3b4d3283e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan DP terkirim. Menunggu approval dan pembayaran Finance.'**
  String get pos1bb95bff678f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan ini tidak mengeluarkan uang. Finance tetap harus menyetujui dan membayar secara terpisah.'**
  String get pos87c742af3515;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan profil pelanggan'**
  String get pos3b6a51e586af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan terakhir belum dikonfirmasi. Data jumlah dan lokasi yang tersimpan akan dikirim ulang; perubahan form saat ini tidak ikut dikirim.'**
  String get posb41fc25c6a52;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan tersimpan. Menunggu approval; kas belum berkurang.'**
  String get posa5a4b853cf69;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Permintaan uang muka supplier'**
  String get pos871d16a76eb4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persen'**
  String get posde08bb634a50;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persentase (%)'**
  String get pos3778aa59db1d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persetujuan diperlukan untuk membuat akun.'**
  String get pos5fc71f538952;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persetujuan kehilangan membutuhkan izin persetujuan scrap. Anda dapat menolak laporan.'**
  String get pos61ff1cf7478e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persetujuan {arg1} • aturan terkunci setelah diajukan'**
  String posb11d7ad2d4ac(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Persetujuan {arg1}/{arg2}'**
  String pos3b0f37c81a64(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pribadi'**
  String get pos40f073237966;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pertumbuhan Omzet'**
  String get posf506ccdb8e76;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pertumbuhan Transaksi'**
  String get pos62d1855e8263;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perubahan dibatalkan.'**
  String get posa20d6217eda2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perubahan pesanan tidak dapat diproses'**
  String get pos059e6f7883d7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perubahan tercatat sebagai override transaksi'**
  String get pos412dd953969a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesan Antar'**
  String get pos2d4162712448;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesan antar'**
  String get posdbefd5b08844;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesan dari {arg1} di {arg2}: {arg3}'**
  String pos0bff6b4c25ac(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesan ke supplier'**
  String get pos371a2a377534;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesan ulang'**
  String get pose88ee63879a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan'**
  String get posaf947234cc1b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan & Meja'**
  String get posd0658219f7c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan Aktif'**
  String get posa496c99bbf7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan Aktif & Meja'**
  String get pos41b6ba1b6db4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan Baru'**
  String get pos773636fad145;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan Laundry'**
  String get pos0a2e2a094314;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan Layanan'**
  String get pose6e1e3329ff4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan Meja {arg1}'**
  String posf86f87a78d52(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan QR diproses setelah bayar di kasir'**
  String get pos0a35cb3e503b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan akan dicatat pada meja {arg1}. Meja ditandai terisi dan tagihan dapat dilanjutkan dari Pesanan Aktif & Meja.'**
  String pos3b458bf929ac(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan aktif'**
  String get posb2b2fef5a283;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan belum dapat disimpan di perangkat'**
  String get posd2999deece68;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan berhasil diperbarui'**
  String get pos8e28bf2b73d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan dengan produk “Kirim ke dapur” akan tampil di sini. Produk langsung jadi tidak masuk antrean.'**
  String get posa9c01eb5f898;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan dibatalkan'**
  String get posa27a48a65cba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan disimpan sementara'**
  String get pos1591c15f679c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan lama tetap memakai snapshot-nya. Profil baru berlaku untuk transaksi berikutnya. Periksa kembali fitur meja, layanan, pelanggan, dan tipe pemenuhan.'**
  String get posdf79967b4ba9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan meja {arg1} berhasil disimpan.'**
  String pos6fe4c911e4d5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan offline tersimpan. Belum masuk meja/dapur; cek Antrean & Sinkronisasi.'**
  String get pos53fd557c7923;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan operasional disimpan untuk disiapkan dan dibayar kemudian. Bukan invoice piutang Finance. Buka dari Pesanan atau Riwayat Transaksi; untuk keranjang sementara gunakan Simpan pesanan.'**
  String get pos93e538d96629;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan sudah masuk server'**
  String get posac7404519b39;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan terbaru'**
  String get pos74ecaa1b9f86;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan terlama'**
  String get posebe8c57f5cb4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan tersimpan'**
  String get pos352c6cc8bd8e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan tidak dapat dibatalkan'**
  String get pos03ecfa106dbe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan yang selesai tersedia di Riwayat Transaksi.'**
  String get pos4a7b1648aafd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan {arg1}'**
  String pose27a8b678805(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan {arg1} belum dibayar. Stok yang dipesan akan dilepas.'**
  String posbe4e656f20d1(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan {arg1} berhasil diperbarui.'**
  String posc8b050cf8ef3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan {arg1} tersedia di Pesanan dan Riwayat Transaksi.'**
  String posf970ac5a216e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pesanan {arg1} tersimpan di meja {arg2}.'**
  String posbf7cbf6e7df0(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Peta Meja'**
  String get posedaf7adb17af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih'**
  String get pose137919915b5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih Item Diretur:'**
  String get pos4961e3a50c3b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih Kasir'**
  String get posb587a0f7dba2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih PO dan lokasi stok terlebih dahulu'**
  String get pos52def59984f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih PO dengan sisa kesepakatan DP'**
  String get pos099ac28689df;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih Pelanggan'**
  String get pos320d17578301;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih WhatsApp atau aplikasi lain'**
  String get posfdd613a427ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih alasan koreksi'**
  String get posbd006c5b464a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih barang'**
  String get pos4ad6b1404620;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih barang dan saldo lokasi yang valid.'**
  String get pos709fdf8ae6e9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih barang dari stok lokasi untuk mulai mengisi tabel.'**
  String get pos5dfffa7a1318;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih baris PO'**
  String get pos65516be18338;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih batch'**
  String get posfa0626bb42ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih batch transfer'**
  String get pos24f3a034b35c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih batch {arg1}'**
  String pos9518606db839(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih cabang hingga rak yang benar agar stok awal tercatat di lokasi fisiknya.'**
  String get pos0f6c6fedcedf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih cabang penerimaan sebelum scan.'**
  String get poscb0fcc1c4066;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih foto'**
  String get pos77888323ec06;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih fungsi utama lokasi, misalnya gudang toko atau gudang pusat.'**
  String get pos80f5a8d955cf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih gambar'**
  String get pos06b8038867a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih gudang'**
  String get pos4638e00a2067;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih informasi yang paling penting untuk operasional {arg1}.'**
  String pos28da64abd533(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih invoice dan item'**
  String get posf86f4256c556;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih jadwal layanan'**
  String get posd5df0db008e7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih jenis produk'**
  String get pos6be9415d49a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih karyawan'**
  String get posf5c237c88c94;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih karyawan terlebih dahulu'**
  String get pos60a99b71af5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih karyawan yang akan menggunakan kasir POS.'**
  String get posc71c04e0152f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori'**
  String get pos5322c62fbfeb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih kategori agar pencarian dan penyaringan katalog lebih cepat. Kategori baru dapat ditambahkan dari tombol +.'**
  String get pos18bc245517d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih komponen paket'**
  String get posea08738178f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih komponen stok *'**
  String get pos35dd55e65eb1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih konteks order'**
  String get posf59f9e84c6a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi asal dahulu'**
  String get pos0896a043009e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi asal dan tujuan.'**
  String get pos39c964d26616;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi dan isi jumlah penerimaan'**
  String get pos77845316790e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi isi rak'**
  String get pos47dd0da5a204;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi karantina untuk barang rusak.'**
  String get posaa5cbc57913b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi saldo'**
  String get pos907d106c0c78;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi stok penerimaan PO'**
  String get poseea7cef26cbc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi sumber'**
  String get pos21084f943554;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi toko untuk memuat katalog'**
  String get posac33e5d3b94e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi tujuan yang berbeda'**
  String get pos806e3503c247;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih lokasi yang akan dihitung. Saldo akan dipotret otomatis.'**
  String get pos08be59662c42;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih meja dari menu tipe pemenuhan terlebih dahulu.'**
  String get pos3f55fbdf2353;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih meja terlebih dahulu dari halaman kasir.'**
  String get pos06ec9d461857;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih meja untuk pesanan'**
  String get pose626124c671a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih metode bayar, split payment, catatan, dan invoice bila diperlukan.'**
  String get pos8c28e3c0f8c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih minimal 1 item untuk diretur'**
  String get pos4a9eb2ac0a2e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih minimal satu barang dan masukkan jumlah retur'**
  String get pos4ef6120aadb2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih nomor seri aktual, satu seri per unit, dari sisa transfer.'**
  String get pos33883a3bf54e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih operator'**
  String get posd840f8f1ce4b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih operator dan buat/masukkan PIN kasir.'**
  String get posdd3bb4425063;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih operator dan isi PIN 4–6 digit angka'**
  String get pos683fb000ce5c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih operator dan masukkan PIN untuk melanjutkan'**
  String get pos83d9841efcfb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih operator kasir'**
  String get pos3f02d5042e1b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan'**
  String get pos83ac49b96164;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan terlebih dahulu untuk penjualan tempo.'**
  String get pose0ea931f61de;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih pelanggan untuk poin, promo, dan riwayat pembelian'**
  String get pos70585fecd75e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih pembelian dan lokasi retur'**
  String get pos7a5d67b6c307;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih periode dashboard'**
  String get posf3e599685a4f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih printer Bluetooth di Pengaturan Printer terlebih dahulu.'**
  String get pos72c35021a5ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih printer di Pengaturan Printer Terminal.'**
  String get pos7cd2a2d08d87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih profil usaha'**
  String get pos97d0edd1cd6f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih rak yang sedang dihitung'**
  String get pos5da93a6249f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih rekening bank untuk transfer.'**
  String get pos5a6498c8f0a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih rekening pembayaran biaya transfer.'**
  String get pos5b05aca5d8d4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih saldo lokasi *'**
  String get posf0a1bc36d652;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih saldo lokasi fisik yang benar. Koreksi hanya untuk salah input teknis atau migrasi; hasil hitung fisik diproses melalui Stock Opname.'**
  String get pos089a0f4fc2f2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih satuan dasar'**
  String get pos148cad088f6c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih satuan terkecil tempat stok disimpan, misalnya pcs, porsi, atau botol. Konversi kemasan dapat ditambahkan di bawahnya.'**
  String get posf8c1cdf075c0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih stasiun produksi untuk item ini'**
  String get posb19d2b4f4201;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih sumber stok'**
  String get pos99f1f5366c28;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih supplier'**
  String get pos97a1701e1552;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih supplier untuk melanjutkan'**
  String get posac0270f821d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal'**
  String get pos69774aafa14f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih tanggal & waktu'**
  String get pos417e732e9cfc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih termin yang akan dibayar.'**
  String get posd3fd7fe483f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih tipe warehouse'**
  String get pos918a38df1fbe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih toko kasir'**
  String get pos0822b1ae9504;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih toko operasional'**
  String get pos69d036b4ed5e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih toko untuk memuat antrean dapur'**
  String get pos43a2717b8f48;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih toko, masukkan modal awal, lalu buka shift.'**
  String get pos2ae8df888b0e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih warehouse berstatus lokasi penjualan sebagai sumber stok toko.'**
  String get pos551888c64850;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih warehouse/lokasi penjualan aktif sebagai sumber stok toko.'**
  String get pos5de4f71b3421;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pilih {arg1}'**
  String pos42aa2abf5ad3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pisah Bayar'**
  String get pos34ada2e93f20;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Piutang & Pelunasan'**
  String get posa3fd3d4be631;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Piutang berkurang {arg1} · Refund {arg2} · Saldo kredit {arg3}'**
  String pos1d6fd1683a30(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Piutang hanya tersedia bagi operator yang memiliki izin Finance.'**
  String get posed3d014a4485;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Piutang · kelola di Finance'**
  String get posa76456858256;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'\'Placeholder kasir: {{nama_kasir}}  (alias: {{kasir}}). Contoh: Dilayani oleh {{nama_kasir}}\''**
  String get posa1539fde74fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ponsel POS dan layar pelanggan harus berada pada Wi-Fi/hotspot pribadi yang sama. Mode ini tidak memerlukan internet; biarkan aplikasi POS tetap terbuka. Hindari Wi-Fi publik.'**
  String get posb51c5e7468f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Portal'**
  String get posb55223c7bdc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Potongan tambahan antara 0–100%'**
  String get posa1670bdfd674;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Potret'**
  String get posec2630527c8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pratinjau / Bagikan'**
  String get posaefb2c722166;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pratinjau PO'**
  String get pos8fb4d431e5f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pratinjau label'**
  String get posa0517112362a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Prefix Invoice'**
  String get posbf8e8e197f4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Prefix invoice harus 1–10 karakter huruf atau angka.'**
  String get pos85d88da6d103;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Presisi (PDF + logo)'**
  String get posdd8c6beb8f62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Preview Struk'**
  String get pos4bc8972ab9b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Preview diperbarui langsung mengikuti pengaturan di sebelah kiri.'**
  String get pos280ef1d0199d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Preview harga tidak tersedia'**
  String get posb9e296f62897;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Cetak Invoice'**
  String get pos4c6aae8435a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Print Struk'**
  String get pos8603bde055dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer Bluetooth berhasil dipilih'**
  String get posf161eb61452f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer Bluetooth kasir disimpan pada perangkat ini untuk struk dan label thermal. PO dan bukti pembayaran A4 memilih printer melalui dialog cetak perangkat saat dicetak.'**
  String get posd1c6d22c93dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer Bluetooth menolak data struk'**
  String get pos591a9e65d14b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer Bluetooth thermal'**
  String get pos7daf17b7f7b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer Bluetooth tidak merespons. Periksa koneksi printer.'**
  String get pos649513b7074a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer Terminal Ini'**
  String get posefc8c22a5026;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer dapat dipilih dari menu Pengaturan Printer'**
  String get posaf57377b32ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer default terminal'**
  String get posac376db4a4bc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer menolak sebagian label.'**
  String get posa30a2081e4f7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer terlalu lama merespons. Periksa koneksi lalu coba lagi.'**
  String get pos8b336c0163c2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer terminal tersimpan tidak tersedia. Pilih ulang printer di Pengaturan Printer.'**
  String get posd7e27376368f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer tidak merespons. Periksa koneksi atau driver printer.'**
  String get posd0c9b622f84f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Printer tidak merespons. Periksa koneksi printer.'**
  String get pos51920b6b7ae9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Prioritas'**
  String get pos51cb5d20e6cb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Privasi dan keamanan terjamin'**
  String get pos13da982ef4aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk'**
  String get pos869eb84eb3dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Contoh A'**
  String get pos1138b2d9becd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Contoh B'**
  String get posdda7c4cb3ebf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Kedaluwarsa'**
  String get pos8f9d458d26c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Layanan'**
  String get pose1afb631b23e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Paket'**
  String get pos0da22a551588;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Terjual'**
  String get pos1e32a5808bac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk Terlaris'**
  String get posa357bd367628;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk baru dibuat dengan stok 0. Saldo awal atau perubahan stok dicatat melalui menu Stok Toko agar lokasi dan riwayat stok tetap valid.'**
  String get pos06fb51535ff5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk belum memiliki kode untuk label.'**
  String get posb6483575f031;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk belum memiliki saldo pada warehouse ini. Tambahkan melalui penerimaan atau mutasi terlebih dahulu; opname memerlukan saldo lokasi yang tercatat.'**
  String get posf640370cc858;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk belum tersimpan untuk transaksi offline.'**
  String get pos2a2a10ed9820;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk berhasil dibuat'**
  String get posccb7fe69cbf8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk berhasil dihapus'**
  String get posde1096477c33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk berhasil diubah'**
  String get pos09706678ca5b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk berikutnya'**
  String get posc7bb9c341c76;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk fisik (stok sendiri)'**
  String get posec2438d3dbfa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk ini dilacak per batch. Koreksi stok dilakukan melalui Stock Opname agar batch dan kedaluwarsa tetap konsisten.'**
  String get posbb232b1b62e4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk ini tidak ada pada sisa PO.'**
  String get posaa41b88f9177;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk ini tidak menggunakan saldo stok.'**
  String get pos54eb2930473e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk sebelumnya'**
  String get poscb5467abcdfe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk terlaris'**
  String get pos0bc283dc5c7a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk tidak dikembalikan oleh server'**
  String get pos0026bfce12f2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Produk, barcode, dan stok toko'**
  String get posd71d5f161e97;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil Bisnis POS'**
  String get pos543bbb66f3f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil Inventory'**
  String get pos5d63d006cbcf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil Inventory Simple hanya menerima stok pada lokasi default'**
  String get pos4b8a8b28136c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil POS duplikat'**
  String get pos7674f2e0ef8c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil POS ini tidak melacak stok. Aktifkan Tracking Stok melalui Pengaturan POS jika produk perlu dikurangi saat transaksi.'**
  String get pos9e0fb3d65a6f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil POS tidak valid'**
  String get posdd3f53ab7f71;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil Pengguna'**
  String get pos22cb048be681;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil atau tipe pemenuhan ini mewajibkan pelanggan.'**
  String get pos6480b1d46dcd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil bisnis atau Tracking Stok tidak dapat diubah'**
  String get posb03276b31a5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil ini menjadi workspace utama untuk toko atau organisasi, produk, kasir, laporan, dan trial Pantoo Anda.'**
  String get posb25c367c89a2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil inventory dan aturan stok POS sudah konsisten.'**
  String get posb154f59af7cf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil inventory: {arg1}. Stok, pembelian, opname, mutasi, barang terbuang, dan retur tersedia sesuai izin akun.'**
  String pos647182c03196(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil masih digunakan operasional'**
  String get pose713185ec3fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil usaha'**
  String get pos87960d620984;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Profil usaha gagal dibuat'**
  String get posab57b24264e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Fitur operasional mengikuti profil usaha. Sesuaikan nanti di Pengaturan POS → Transaksi & Penjualan.'**
  String get pos741cc223e0db;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proforma terlampir · hanya bukti pendukung, bukan Vendor Bill'**
  String get pos0c14cf63b0e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proforma: {arg1}'**
  String pos7dfa2cce27c1(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo'**
  String get pose0f4f87da3de;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo    -{arg1}'**
  String pos5f0e590eb67a(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo \"{arg1}\" berhasil dibuat'**
  String pos33d2c3ae1407(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo \"{arg1}\" berhasil diupdate'**
  String posf923a5377f98(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo \"{arg1}\" berhasil {arg2}'**
  String pos2a3d9ec5d50a(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo & Diskon'**
  String get pos6222e034ade4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo & Voucher'**
  String get posbf5882aa45e5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo belum memenuhi ketentuan'**
  String get pos11b0997ad729;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo berhasil dihapus'**
  String get pos236d5e96ed6f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo berhasil diterapkan'**
  String get pos12ea083e3644;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo saja'**
  String get pos891fa7bb20d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Promo, diskon, pajak, dan biaya diringkas sebelum pembayaran.'**
  String get pos58df4233fa45;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses'**
  String get pos2023525f33bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses Bayar'**
  String get pos04f0bc1ae070;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses Pembayaran'**
  String get pos5628f88ed746;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses Pembayaran Invoice'**
  String get pos5d7671ae674d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses Retur'**
  String get pos16b3eaa5db4f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses Stok'**
  String get pos842b4aa99f70;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses layanan'**
  String get poscafa9231b673;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses pembayaran'**
  String get pos3058d0885078;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses pembayaran tanpa hambatan'**
  String get posbd31d165b7b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses retur?'**
  String get pos974113ed5333;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proses ulang'**
  String get pos06f4807d49e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Proyek'**
  String get pos1c9c05321ac4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pulihkan bukti draft retur yang belum terkonfirmasi terlebih dahulu.'**
  String get pos4dc41ac187b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pulihkan bukti {arg1}'**
  String posc4171a22051c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pulihkan draft retur'**
  String get posb03c898f4c0d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Purchase Order'**
  String get pos3c45b957fdc8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Purchase Order terpilih'**
  String get pos9ac7b79547ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Putuskan'**
  String get pos3b45046321f9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'QR Meja Pantoo POS'**
  String get pos16dcfba0340a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'QR ini permanen. Pantau pesanan Web Order sebelum staf mulai menyiapkannya.'**
  String get pose4e6da0b48b9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'QR meja {arg1}'**
  String pos133f8123ec8d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'QR {arg1}'**
  String pos8c5a30764897(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'QRIS'**
  String get posa8d6682e6a6a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Qty'**
  String get pos1e5ff9e500c2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Qty Asal: {arg1} {arg2}'**
  String posbc47f5da0ae0(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Qty Retur'**
  String get pose7b155797eb0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Kontrol Kualitas'**
  String get pos8f6e9ad919a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rak'**
  String get posf89332db8409;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rak (opsional)'**
  String get posd796fab4ace6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rak {arg1}'**
  String posad54407447b0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rak: {arg1}'**
  String pos1af981c59b08(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rata-rata / Transaksi'**
  String get pos482902c46d65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rata-rata Order'**
  String get pos36db4b26bf84;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Real-time'**
  String get poscc63552558f8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Recycle sebagian'**
  String get pos6243755d7b5b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Recycle {arg1} • '**
  String posc4042d7f65c7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi'**
  String get pos3166201d7baf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi / tiket (opsional)'**
  String get posc65dccdd3292;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi PO tidak tersedia. Muat ulang daftar.'**
  String get pos76d2d1517764;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi gagal dimuat. Coba lagi.'**
  String get pos94751b2cc725;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi pembayaran (opsional)'**
  String get pos5f95d9a50b17;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi transfer'**
  String get posaffaa9974a71;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi untuk Finance; tidak membentuk utang atau pembayaran.'**
  String get pos7de25f0023d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi: {arg1}'**
  String pos96b044b6e7c2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Referensi: {arg1}\n'**
  String posea21c3d7a950(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perbarui'**
  String get pos56e3badc4e6c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Refund dan pergerakan stok akan dijalankan sesuai detail retur.'**
  String get pos7d773b881b3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Refund tunai'**
  String get pos15b8b44ee8cf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Register bersama'**
  String get posf993cffba741;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Register bersama: satu laci per toko untuk akun yang memiliki akses. Per operator: rekonsiliasi tiap PIN terpisah.'**
  String get posb97465b4316b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekening'**
  String get pos60c4ba76c7de;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekening bank'**
  String get pos280fa8bb05b9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekening bank *'**
  String get posd1bc54bee535;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekening bank tidak dapat dimuat. Pembayaran tunai atau giro tetap tersedia.'**
  String get pos79a9b4e67d92;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekening pembayaran biaya'**
  String get pos036967f2c2dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekening: {arg1}'**
  String posd88b4d30bc43(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rekonsiliasi kas lalu tutup shift setelah pekerjaan selesai.'**
  String get pos8c9039befce5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rencana saat ini'**
  String get pos12cc792f0fdc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rencana saja; pembayaran dilakukan Finance'**
  String get posb97f4712bde6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rentang waktu atau jumlah tamu tidak valid'**
  String get pos0611cb3543b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reorder Alert & HPP'**
  String get pos4062aae419d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Request API gagal (HTTP {arg1}) tanpa pesan kesalahan.'**
  String pos72f4ddb26760(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Request belum dikirim karena gagal disimpan di perangkat: {arg1}'**
  String posbcd5593f5bcc(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Request gagal (HTTP {arg1})'**
  String pos849ad4d3801b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Request lama memakai lokasi yang ditolak profil Simple. Isi ulang jumlah penerimaan pada lokasi default.'**
  String get posd50df1e81ef3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Request penerimaan sebelumnya di perangkat tidak dapat dibaca. Penerimaan baru diblokir untuk mencegah stok ganda. Periksa riwayat GRN dan hubungi admin inventori.'**
  String get pos519c54ce138a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Request penerimaan sebelumnya tidak dapat dibaca. Periksa riwayat GRN dan hubungi admin sebelum menerima ulang.'**
  String get pos25d0e3d3a07d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reseller'**
  String get posa259ac911046;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Resep/paket belum tersedia untuk transaksi offline. Sambungkan ke server.'**
  String get posb45dd3aea462;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reservasi'**
  String get pos9cc2cf871dfe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reservasi & Layanan'**
  String get pos69d163afa2ee;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reservasi dan layanan pelanggan'**
  String get posa077a8f388a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reservasi · {arg1}'**
  String pos039cdeadaabb(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reset'**
  String get pos44c57abd888a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Reset sesuai profil'**
  String get pos0487356165fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons pengaturan PIN tidak valid'**
  String get posa843c895becf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons server: {arg1}'**
  String pos48c3ba336d52(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons supplier'**
  String get posc48f8c0f5f2d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons supplier dicatat'**
  String get pos9a536089f3ed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons terputus. Jangan menerima uang dua kali; gunakan Kirim ulang bukti yang sama.'**
  String get pos023feb541ab2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons transfer kosong. Muat ulang sebelum melanjutkan.'**
  String get posdd4c968c4616;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons upload bukti tidak valid'**
  String get pos64aa97a812fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Respons upload proforma tidak valid'**
  String get pos4a5c80fa526d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Restoran / Cafe'**
  String get pos5b52143dd801;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Restoran / Kafe'**
  String get pos812d0896ea60;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retail'**
  String get pos925dd33f9082;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retail / Toko'**
  String get pos5cfbc75b4208;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retry otomatis: {arg1}'**
  String posb17d3b472148(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur'**
  String get pos7a82f9e98c12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur Pembelian'**
  String get pos0e241374b8c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur Penjualan'**
  String get pos64bfb532598f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur akan disimpan sebagai draft'**
  String get pos8a44f03ed038;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur berhasil dihapus'**
  String get pos299b53317e1d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur dan refund penjualan yang diajukan akan tampil di halaman ini.'**
  String get poscb804c0ee887;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur dibuat dan dikirim untuk persetujuan'**
  String get posff9563c75acd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur diterima tetapi bukti lokal belum diperbarui. Pulihkan sebelum membuat retur lain.'**
  String get pos4a880b9a2380;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur ke Supplier'**
  String get pos2d5779ea48b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur mengurangi piutang terlebih dahulu. Hanya selisih yang sudah dibayar dikembalikan. Tunai memakai akun kas 1001; transfer akun bank 1002 di Finance.'**
  String get pos883e50798514;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur terkonfirmasi. Periksa status pada daftar; pengajuan dan refund tetap terpisah.'**
  String get pos999602d184e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur {arg1} akan menunggu persetujuan supervisor.'**
  String pos27df11542691(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Retur {arg1} akan siap diproses.'**
  String pos45799a85e9a2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rincian lokasi gagal dimuat: {arg1}'**
  String pos8e1dc55435c2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rincian saldo per lokasi'**
  String get pos17b252650858;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkas sidebar'**
  String get posbaaf73d00305;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkasan'**
  String get posd28feba12163;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkasan Penjualan'**
  String get pos26537d1df4a7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkasan belanja Anda'**
  String get posdd37fa0a60b0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkasan pembelian'**
  String get pos8076ee30b32a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkasan penjualan'**
  String get pos75e583d10204;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ringkasan performa POS untuk {arg1}.'**
  String pos29a28ea5e03e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat'**
  String get posbdeacd1760b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat GRN belum dapat diperbarui: {arg1}'**
  String pos065a9e21d49d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat Shift'**
  String get pos611fe79e900e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat Stok Shift Aktif'**
  String get pos5906e6282ccf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat Transaksi'**
  String get pos8806dc3915aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat pembayaran'**
  String get pos03d06fe851ed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat penerimaan'**
  String get posdf9bcb350501;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat penerimaan ({arg1})'**
  String pos78bff8e79d25(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat penerimaan gagal dimuat: {arg1}'**
  String pos44a6903141ee(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat persetujuan'**
  String get posa85af1e71e9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat pesanan belum tersimpan untuk mode offline.'**
  String get pos0fe8517ac3fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Riwayat status'**
  String get posb4a4bddfcda6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rp '**
  String get pos0aa338c39d33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rp 20.000'**
  String get posbebb06d5f701;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rp 50.000'**
  String get pos614dc907883d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rp {arg1}'**
  String pos70272f418def(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rp{arg1}'**
  String pos0435fa2b2918(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ruangan'**
  String get pos687b1a98c956;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ruangan (opsional)'**
  String get posa1c2ef9582aa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ruangan {arg1}'**
  String pos9a295c412a94(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ruangan: {arg1}'**
  String pos085e03d813e0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rusak'**
  String get posf1238819f6ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rusak (perlu karantina)'**
  String get pos97b4a8c1a3d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rusak Berat'**
  String get pos3fc271bd3070;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rusak Pengiriman'**
  String get pos848c71c6e7fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Rusak Ringan'**
  String get posf0dbf90859f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'SJ {arg1}'**
  String pos2d721657d7fb(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'SKU'**
  String get posd59192b9c8f2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'SKU internal'**
  String get pos0efd2187e8af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'SKU · {arg1}'**
  String pos19aa65c6a13e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'SKU: {arg1}'**
  String posee769816dc3e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'SKU: {arg1} • Stok {arg2}'**
  String posa8bae00d81f1(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'STATUS: {arg1}'**
  String pos31737f83ebbc(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'STOK & GUDANG'**
  String get posce2676cae242;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saat dibuat, sistem otomatis mengambil snapshot saldo terpilih. Isi hasil hitung fisik, konversi satuan, dan alasan selisih di form ini. Stok baru berubah setelah persetujuan dan posting.'**
  String get posab88dce84a40;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saat diterima'**
  String get pos19c0ad1a1458;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo Awal Persediaan'**
  String get pos55cd4b5b2584;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo Kredit Pelanggan'**
  String get pos34793d42070a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo belum berkurang saat draft dibuat. Stok dan jurnal kerugian baru diproses setelah dokumen disetujui.'**
  String get pos3e5e25a71723;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo lokasi barang terbuang tidak valid'**
  String get pos6d045c1e5f71;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo lokasi barang tidak tersedia'**
  String get pos62edee410efe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo lokasi saat ini: {arg1} {arg2}'**
  String poscb93757b9cc2(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo lokasi tidak ditemukan'**
  String get poscd7e20e32092;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo lokasi: {arg1} → {arg2}  •  Jumlah {arg3}'**
  String pos21462b1cd3e9(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saldo rak tidak boleh duplikat.'**
  String get pos50ead4249311;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Perkiraan Penjualan'**
  String get posc31885e11835;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Salin'**
  String get pos276d0542201d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Salin nomor'**
  String get pose4c5244bd1e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Salin tautan'**
  String get pos94eecb57710c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Salinan thermal - PDF memuat detail lengkap.'**
  String get pos44ca06cb5561;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Salon / Barbershop'**
  String get pos55a7650d7df1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sambungkan ponsel POS ke Wi-Fi atau nyalakan hotspot, lalu coba lagi.'**
  String get pos722663e06443;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sampai tanggal'**
  String get pos95b58818f0a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saran jumlah stok saat perlu melakukan pembelian'**
  String get pos2903a31e3470;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satu kasir untuk setiap peluang'**
  String get pos25153d5331af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satu laci per toko untuk akun yang memiliki akses; identitas kasir tetap tercatat.'**
  String get posea9f626a17a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satuan'**
  String get pos24726ff1ab88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satuan dasar'**
  String get posde491a7e311f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satuan dasar *'**
  String get pos1792eb514851;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satuan dasar wajib diisi'**
  String get posba7cb71c0df6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Satuan pembelian'**
  String get posdb925237c56a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saya memahami operasional aktif tidak ikut diubah.'**
  String get pos72d7c8475f29;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Saya menyetujui Kebijakan Privasi dan Ketentuan Layanan Pantoo.'**
  String get pos44e0630b4e02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pindai'**
  String get pos28cba55d2aad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan & Pesan'**
  String get pos682ac2614b67;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pindai Barcode'**
  String get pos0335022fe9ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pindai barcode'**
  String get pos5f5b67de90e9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan barcode barang'**
  String get posf017b1c0753e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan barcode barang PO'**
  String get pos6ebeb3af8b4f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan barcode dengan kamera'**
  String get posd4291e971b03;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan beruntun aktif · tutup halaman jika selesai'**
  String get pos1ae0ede21575;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan gagal. Coba lagi.'**
  String get pos75d2fe07b0b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan ulang kode terakhir'**
  String get pose7711dd9beac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scan/isi barcode kemasan atau kosongkan'**
  String get pos719bf1496bac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Scrap & Insiden'**
  String get pose9916d957f01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sebagian'**
  String get poseef74f939bac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sebagian data dashboard belum dapat dimuat. Tarik untuk mencoba lagi.'**
  String get posbd6d8425847c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sebagian dibayar'**
  String get pos92b05f3448b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sebelumnya'**
  String get posc9caf74cdab0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sedang'**
  String get posff9bb4f03176;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sedang Dibuat'**
  String get pos4b4720fe2684;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sedang membuat SKU...'**
  String get posf37c61ce775a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sedang membuat barcode...'**
  String get pos312e1053962d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sederhana'**
  String get posef457d1c5e7a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Segera'**
  String get posa253a166b7f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Segmen Pelanggan'**
  String get pos0c3c9b2741f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Segmen: Regular'**
  String get pos5d19f1d2f443;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Segmen: {arg1}'**
  String posf35e7016437f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selalu pilih melalui dialog sistem'**
  String get posfebb840871f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selanjutnya'**
  String get pos2587dceb3eff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selaraskan aturan stok'**
  String get pos148ec09c853e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selengkapnya'**
  String get pos84b4b08d288b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesai'**
  String get pos94388531abcf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesai diproses'**
  String get pos56103c7818ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesai produksi'**
  String get pos342b00b06c09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesai reservasi *'**
  String get posa62977f8f177;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan CAPTCHA untuk melanjutkan login'**
  String get posdf1b466c3bdb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan manual'**
  String get poseb491c27383d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan pesanan'**
  String get pos30e25467c147;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan secara berurutan agar stok, toko, kasir, dan shift tetap selaras.'**
  String get pos70bd8bc4dfc1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan setup POS'**
  String get pos4b18934a8a78;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan transaksi ditolak?'**
  String get posc097dcdfa01d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selesaikan tujuh langkah sebelumnya terlebih dahulu.'**
  String get pos52226b8e3996;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Selisih'**
  String get pos2a0ab753352f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Seluruh mutasi stok berhasil diterima'**
  String get pos50b9d8ad54f1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan opsi lanjutan'**
  String get pos40c34042d466;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan sidebar'**
  String get pos383ff5de869b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua'**
  String get pos42c76592cdc1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua ({arg1})'**
  String pos5ab6295dbc59(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Cabang'**
  String get pos6c4ed1239a1d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Inventaris'**
  String get pos89487a13ab68;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Kasir'**
  String get pos2aca9f32c447;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Kategori'**
  String get posd83b4ec645a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Level Harga'**
  String get pos61e3dd11f0d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Status'**
  String get pos38a8d3e5d5dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Stok'**
  String get posf9245e99ba9f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua Waktu'**
  String get pos4bc9b7e5061e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua aktif'**
  String get pos74fce2388fe0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua alasan'**
  String get pos9468c7c38a1f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua item dalam pesanan akan dihapus.'**
  String get posd6039e2c5ee0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua kapasitas'**
  String get posf6e4d87afd89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua kategori'**
  String get pos3ee43aaffaaf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua kebutuhan utama sudah tersedia. Anda dapat mulai melayani transaksi.'**
  String get posc0a87712b909;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua kolom harus diisi'**
  String get pos1fa2d4c18ea4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua lokasi'**
  String get posedfd39e720f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua penyelesaian'**
  String get pos975a6c8b7bc0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua prasyarat siap. Ikuti highlight interaktif di halaman kasir.'**
  String get posf6debe4a2e8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua stasiun'**
  String get pos438928a078ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua stok'**
  String get pos30de1da3b483;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua tanggal'**
  String get posc07ed2379764;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua tipe'**
  String get pos0c4dc379ee55;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Semua transaksi lokal sudah selesai diproses.'**
  String get pos850f969f05d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Serah'**
  String get posfff6c547a425;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Seri {arg1}'**
  String pos2520218913bd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Seri: {arg1}'**
  String pos78308eaba248(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Serial number *'**
  String get posbb6c59a46705;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Serial number {arg1} wajib diisi'**
  String pos4983e9639596(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server Google berubah. Tutup dan buka kembali aplikasi.'**
  String get pos418e05534d50;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server mengembalikan respons non-JSON (HTTP {arg1}).'**
  String pos440545e7a2a5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server sedang bermasalah (HTTP {arg1}). Silakan coba lagi.'**
  String posee023ea50beb(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak dapat dijangkau. Pembayaran non-tunai belum disimpan karena harus diverifikasi online.'**
  String get posb7a0c72c7641;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak memberikan refresh token mobile'**
  String get posb2e9666e3516;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak mengembalikan URL bukti'**
  String get posdd98b0b9b3e6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak mengembalikan URL foto'**
  String get pos641027584bdc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak mengembalikan URL proforma'**
  String get pos2a59e8486f16;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak mengembalikan data'**
  String get pos512b700c40d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Server tidak mengembalikan hasil transaksi'**
  String get pos2acd1683a552;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Service order, teknisi, kendaraan'**
  String get pos68f06b40165b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi POS berakhir. Login kembali untuk menghubungkan layar pelanggan.'**
  String get posf48e34c772d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi POS tidak tersedia. Login kembali terlebih dahulu.'**
  String get pos51fc8b31070d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi POS tidak valid. Login kembali untuk menghubungkan layar pelanggan.'**
  String get posa8e4eb047804;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi belum dapat diverifikasi. Coba lagi.'**
  String get pose56d33370578;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi kasir berubah. Muat ulang shift.'**
  String get pos8a53ace562dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi kasir berubah. Periksa shift kembali.'**
  String get posc901baf238d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi kasir dan akun akan ditutup. Anda perlu login kembali untuk menggunakan POS.'**
  String get pos580f12f5433c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi login dan cache PIN offline tidak ditemukan.'**
  String get pos637079847c6d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi login gagal disimpan dengan aman'**
  String get posdfd94253b50e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi login tidak ditemukan. Silakan login kembali.'**
  String get pos9b7df86957fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi opname sudah ditutup.'**
  String get posa6793d1e0c7c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi telah berakhir atau otentikasi gagal'**
  String get pos7d6be8c431ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sesi telah berakhir. Silakan login kembali.'**
  String get poscda725eb3c5e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Set API Endpoint'**
  String get posb00ae356192a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setelah aktif, transaksi dapat dimulai dan shift ditutup setelah rekonsiliasi.'**
  String get pos466e36cfa50d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setelah data wajib terisi, simpan. Status ringkasan akan diperbarui dari server.'**
  String get posbca98a902aa8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setelah keranjang terisi, ketuk Bayar untuk memilih metode pembayaran dan invoice.'**
  String get pos5b9e3f13a536;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setelah penerimaan'**
  String get pos671488b2d5fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setujui'**
  String get pos1f9ce43818de;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setujui Kebijakan Privasi dan Ketentuan Layanan untuk mendaftar.'**
  String get pos805a4ef3a05a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setujui laporan selisih'**
  String get posdbdcf1bd6a09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setujui retur?'**
  String get pos8362cf86c76f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setup POS belum selesai'**
  String get posf5015f6aba50;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Setup POS belum selesai. Simpan langkah ini, lalu kembali ke panduan.'**
  String get pos2116158c3784;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sewa Aset'**
  String get pos5c41c1f348dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift'**
  String get pos469d5b183fdc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift Aktif'**
  String get pos29ec3676a09b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift Kasir'**
  String get posa5e670d32c94;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift Kasir Bermasalah'**
  String get pos96e86a23186a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift aktif'**
  String get pos6da0ceec2e04;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift aktif berada di toko lain. Keranjang tidak dipindahkan. Kosongkan keranjang untuk menyelaraskan toko.'**
  String get pos7ffcb176cc14;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift aktif dan transaksi dapat dimulai.'**
  String get pos4bdb422b576b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift aktif ditemukan dan ditampilkan kembali.'**
  String get pos156f00c76795;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift aktif ditemukan. Lanjutkan shift tersebut atau kembali ke outlet shift aktif; tidak perlu membuka shift baru.'**
  String get pos08859689018b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift belum dapat diperiksa. Periksa koneksi atau PIN lalu coba lagi.'**
  String get pos2c99482a7981;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift belum dapat diperiksa. Periksa koneksi atau PIN, lalu coba lagi.'**
  String get pos98a50c991dd1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift belum dapat diperiksa. Periksa koneksi atau masuk ulang dengan PIN, lalu coba lagi. Jangan membuka shift pengganti.'**
  String get posde0df7c46cc9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift belum dapat ditutup karena masih ada transaksi offline'**
  String get posa33c718829d0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift berhasil dibuka'**
  String get pos894b97fdf33f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift berhasil dibuka!'**
  String get pos7e0e86e2d1ed;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift berhasil ditutup!'**
  String get pose097451c0eb3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift kasir belum dibuka'**
  String get pos4dbcb8467f91;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift kasir dibuka'**
  String get posc11258dd9252;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift masih aktif di {arg1}'**
  String posdabd37d4fec2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift per operator PIN'**
  String get pos7bb626d2ee62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift sedang berjalan'**
  String get pos073e31a3bd3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift tidak sesuai dengan sesi kasir. Hubungkan kembali untuk memeriksa shift.'**
  String get posa073778c7067;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift: {arg1}'**
  String pos98c99bd51ac2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shift: {arg1}\n'**
  String pos948945f10e42(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shortcut halaman hanya tersedia jika operator mempunyai izin. Saat mengetik di formulir, shortcut navigasi tidak dijalankan.'**
  String get posd21509bf517a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shortcut keyboard'**
  String get pos1c79423e4e80;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shortcut keyboard (F1)'**
  String get posb2be3c5f95c3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Shortcut keyboard Pantoo POS'**
  String get pos8151487829c2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap'**
  String get pos791fdbfcb8c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap ({arg1})'**
  String posd100bfb67f19(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap Diambil'**
  String get pose56826ba586f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap Diambil / Dikirim'**
  String get pos527ad1be2e11;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap Digunakan'**
  String get posec0a910a0f17;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap Dikirim'**
  String get pos6e739dd63407;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap Disajikan'**
  String get pos981dc927c290;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap diambil'**
  String get posa5cc9140a81a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siap diterima'**
  String get pos93edf0e21787;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siapkan Profil Usaha'**
  String get posf691f231a836;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Siapkan pesanan'**
  String get pos73b6f04c6ed8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Silakan masukkan pesanan dari pelanggan'**
  String get posc1f3fe0dd2fa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get pos87dd92d7407a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan & Kirim'**
  String get posc5d8fd5362b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan & Pilih'**
  String get posed3d4bd0e9e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan & Terapkan'**
  String get pos3511a0c6ae2e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan & pilih'**
  String get pose69db462d981;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Draft'**
  String get pos5591ae665d57;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Draft Retur'**
  String get posb37749958c1c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan PIN'**
  String get posd7e094de96dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan PIN operator'**
  String get pos6d1d8f98614f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan PIN. Setelah itu operator dapat dipilih pada layar akses kasir.'**
  String get pos6676a7fa663e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Pelanggan'**
  String get pos4d868b31685a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Penerimaan'**
  String get pos022708721646;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Pengaturan'**
  String get posfd004c61af49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Perubahan'**
  String get pos03f7dda53d04;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan Template Struk'**
  String get posf9048f3b57b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan atau bayar'**
  String get posf4f3de2168e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan belum terkonfirmasi. Gunakan Pulihkan draft retur; jangan buat pengganti.'**
  String get posf2b6ffa0fd34;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan dan validasi'**
  String get posf87e6c7fa4d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan draft'**
  String get pos56cc656e2401;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan draft retur belum terkonfirmasi'**
  String get pos0d21cf8aebc6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan draft retur masih berlangsung.'**
  String get pose01936b5dec8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan jika belum selesai'**
  String get posebe79e862972;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan ke Meja'**
  String get pos4b4ec71d0e25;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan ke katalog'**
  String get pos9410daa3e8ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan keputusan'**
  String get pos850a0cd2d599;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan mutasi'**
  String get poscbcb630b45b8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan order sementara'**
  String get poscb9079833a1c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan pembayaran'**
  String get posa24f4a17df98;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan perubahan lalu kembali ke ringkasan untuk melihat hasil pemeriksaan terbaru.'**
  String get posc2d472b10022;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan pesanan'**
  String get posa5e4d00c96cb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan pesanan ke meja?'**
  String get pos48677f83dedc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan pesanan saat ini'**
  String get pos45df8c04b3a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan produk'**
  String get pos569a88c42e99;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan reservasi & lanjut bayar?'**
  String get pos1bbe87b2d71e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan sementara untuk dilanjutkan nanti'**
  String get pos1835ae239c74;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan setelah identitas dan lokasi stok terisi.'**
  String get pos445b4fe65c10;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan toko aktif'**
  String get pos83b7d41ba189;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simpan warehouse'**
  String get posc74955195dfc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Simulasikan pesanan'**
  String get pos7462bf74293a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi Cloud'**
  String get posf4a8038902a9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi antrean selesai diperiksa'**
  String get posc370e2b4c2d9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sinkronisasi sebelumnya terputus'**
  String get pose4e548e9dd8b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sinkronkan sekarang'**
  String get posd71ed5288850;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa'**
  String get pos861b9e39506d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa PO berubah sejak request disimpan. Request lama tidak dikirim; periksa riwayat lalu buat penerimaan baru.'**
  String get posa8a45e527a31;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa PO: {arg1}'**
  String pos9475d97d7968(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa Tagihan'**
  String get posf10e195d9d38;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa hutang'**
  String get pos54260e5e875d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa tagihan'**
  String get posc0fd40e41b59;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa tagihan saat dokumen dibuat'**
  String get pos44b02638cf4e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa tersedia {arg1} {arg2}'**
  String posf7452c021e4b(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sisa {arg1}'**
  String posb83023605a49(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sistem lengkap dengan berbagai fitur andalan.'**
  String get posf4904a2aa306;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sistem menyimpan snapshot PO yang dikirim. Pengiriman melalui aplikasi eksternal tetap dilakukan dari channel tersebut.'**
  String get pose141f778c439;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sistem tetap membuat referensi internal.'**
  String get pos6b21da6c193d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sistem {arg1} {arg2}'**
  String pos6aba9ab9eb0a(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sistem {arg1}; dihitung terpisah.'**
  String posafb095f644ad(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sistem: {arg1} • Selisih: {arg2}'**
  String pos3f737224c118(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Situs web tidak dapat meminta izin untuk membaca daftar printer sistem. Buka contoh struk PDF, lalu pilih printer melalui dialog cetak browser.'**
  String get pos3d85cb55da89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Snapshot belum diterima lengkap. Kembali dan muat ulang daftar sebelum mencoba lagi.'**
  String get pos91adb24a8159;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Snapshot rak ambigu. Buat opname baru sebelum menghitung.'**
  String get posa0ebce5d1fff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Snapshot saat pembayaran'**
  String get pos2a3af98bc4a1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Snapshot saat pesanan disimpan'**
  String get posfb0bf8a35d12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Snapshot siap. Isi fisik, simpan, lalu submit untuk persetujuan. Stok belum berubah.'**
  String get pos23bd1710c9ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Solusi kasir modern untuk usaha Anda'**
  String get posed5bcef77ee0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Staff Kasir Aktif'**
  String get posdb07d07df1ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stasiun'**
  String get pos750b70e7921a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stasiun produksi *'**
  String get pos4c740831fad8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status'**
  String get posbae7d5be7082;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status PO berhasil diperbarui.'**
  String get pos260bc84885eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak'**
  String get posae2d57447d2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak Bluetooth tidak pasti. Periksa kertas printer sebelum mengulang. {arg1}'**
  String pos3ee0e530bdfb(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak belum pasti. Periksa kertas printer sebelum mencoba lagi.'**
  String get pose4b2dbd27139;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak tidak pasti pada printer terminal. Periksa hasil cetak sebelum mengulang. {arg1}'**
  String pos5e6e850d331f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak tidak pasti. Periksa hasil cetak sebelum mengulang. {arg1}'**
  String pos09b1e41db353(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak tidak pasti. Periksa kertas printer sebelum mencetak ulang.'**
  String get pos430beb670045;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status cetak tidak pasti. Printer tidak merespons tepat waktu; periksa hasil cetak sebelum mengulang.'**
  String get pos70828e6b73c6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status dokumen berhasil diperbarui'**
  String get pos1068901e5eab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status item layanan diperbarui'**
  String get posa993f0a3012e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status item layanan tidak dapat diproses'**
  String get posae0c83d34577;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status keanggotaan'**
  String get pos3d062ec9eebb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status koneksi perangkat belum diketahui.'**
  String get poseee4706eb33b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status kunci POS tidak tersedia'**
  String get pos318defda0303;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status lama tidak sesuai progres • masih bisa diterima'**
  String get pos965dd1f4ec17;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status layanan diperbarui'**
  String get pos803ffa3e7808;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status layanan tidak dapat diproses'**
  String get poscd787856b1ff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status pembayaran hanya dicatat oleh Finance.'**
  String get pos9e279437f53e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status pesanan'**
  String get pos81449d4aa3f4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status pesanan berhasil diubah'**
  String get pos67c6c3bc4519;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status pesanan tidak dapat diproses'**
  String get pos80c2b8011e85;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status reservasi diperbarui'**
  String get pos8e8818b099b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status reservasi tidak dapat diproses'**
  String get posccd2f79d3688;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status retur berhasil diperbarui'**
  String get pos2b855e28ddaa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status selesai'**
  String get pos18ba5c874c90;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status shift berasal dari data terakhir yang tersimpan. Transaksi offline tetap menunggu verifikasi server saat sinkronisasi.'**
  String get posc3aefe57a641;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status sinkronisasi server perlu diperiksa'**
  String get pos7ceb6266a330;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status sinkronisasi: {arg1}'**
  String pos09cf25171d0b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status stok'**
  String get pos9ab5b57e2ee0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status transfer berhasil diperbarui'**
  String get posa4a06d4f622c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status transfer berubah. Muat ulang daftar sebelum mengedit.'**
  String get pos8e92361ede90;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status: Offline'**
  String get pos2980c2cf8251;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status: Online'**
  String get pos989f71bddd67;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status: {arg1}'**
  String pos52fb707d5447(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Status: {arg1} · {arg2}'**
  String posd3f7af1f6d12(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stock Opname'**
  String get pose2b5665a464c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok'**
  String get pose3cf2afbdddd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok & Satuan'**
  String get pos1847b1f21884;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok (hanya baca)'**
  String get pos7fd8b3f8b4fb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Habis'**
  String get pos710ec3c4fe69;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Inventori'**
  String get pos2be0b0b1dbb3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Opname'**
  String get pos68e480371d62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Rendah'**
  String get pos42321abe7200;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Saat Ini'**
  String get posf98b1faeb0e2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Terbuang'**
  String get pos346dd6087ca1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Tersedia'**
  String get pos8c00059d75a7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok Tidak Cukup'**
  String get pos6221a27d5a5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok awal produk'**
  String get pos5d8949197719;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok awal produk sudah tersedia untuk mulai berjualan.'**
  String get pos5a32fa04b2af;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok berhasil disesuaikan'**
  String get pos21af179ea077;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok dan konsekuensi finansial akan diproses oleh server.'**
  String get pos1c03f3cf2a63;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok dapat digunakan oleh kasir outlet'**
  String get pos266e05dff2d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok dibalik; jurnal pembatalan perlu diperiksa.'**
  String get pos51b774badd39;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok dikembalikan, tetapi jurnal pembatalan gagal: {arg1}'**
  String posdf3a8d32e918(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok dilacak per nomor seri'**
  String get pos63e60a9d4a35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok diterima, tetapi jurnal biaya perlu dicoba ulang'**
  String get pos1c8a7e170526;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok fisik terbaru'**
  String get pos60af176a330a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok gagal diperbarui'**
  String get pos8544030a617e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok habis'**
  String get posc9cffe0a7181;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok lokal {arg1} tidak mencukupi. Periksa stok saat online.'**
  String pos882f6d381755(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok maksimum'**
  String get posaf3ec6b9dbd2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok maksimum tidak boleh di bawah stok minimum'**
  String get pos7a11751ba810;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok mengikuti transaksi dan lokasi'**
  String get pos4304912d8a8e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok menipis (1–10)'**
  String get pos52db5a21b33f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok minimum'**
  String get pose98220c91cd4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok opname tidak tersedia'**
  String get pos3d062b4adc05;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok selalu disimpan dalam satuan ini.'**
  String get posbc11dbfb3dda;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok sistem: {arg1}'**
  String posee3f877ea456(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok sudah dikembalikan, tetapi jurnal pembatalan perlu diperiksa: {arg1}'**
  String pos2de86e144e10(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok sudah diproses, tetapi jurnal biaya perlu diperiksa: {arg1}'**
  String pos39e38f288da4(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok sudah diproses, tetapi jurnal perlu diperiksa: {arg1}'**
  String pos01eebd959af3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok sudah diterima, tetapi jurnal perlu diperiksa: {arg1}'**
  String posa8ad9c0dfe6e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok tersedia'**
  String get posdaf83725281e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok tidak dilacak'**
  String get posb8b02b77a74b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok tidak ditemukan'**
  String get pos18f6d7a4344b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok {arg1}'**
  String pos0f3c48a06258(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok {arg1} habis'**
  String posfb314505e100(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok {arg1} tidak mencukupi'**
  String posda4c6efa512d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok {arg1} tidak mencukupi untuk satuan {arg2}'**
  String posb84bbc8a4359(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Stok/status diproses, tetapi jurnal biaya belum terkonfirmasi. Periksa rincian jurnal.'**
  String get pos9596e59f4d65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Struk belum dicetak karena printer belum dipilih. Transaksi tetap berhasil; cetak dapat dilakukan nanti.'**
  String get posef10e37e5405;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Struk transaksi {arg1} dari Pantoo POS.'**
  String pos1552d665f55b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Struk {arg1}'**
  String posb8805613da76(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Struk {arg1}\n{arg2}{arg3}{arg4}{arg5}{arg6}{arg7}\n{arg8}\n\nSubtotal: {arg9}\n{arg10}Total: {arg11}\nPembayaran: {arg12}\nDibayar: {arg13}\n{arg14}{arg15}Terima kasih.'**
  String pos4301300bea4d(
    String arg1,
    String arg2,
    String arg3,
    String arg4,
    String arg5,
    String arg6,
    String arg7,
    String arg8,
    String arg9,
    String arg10,
    String arg11,
    String arg12,
    String arg13,
    String arg14,
    String arg15,
  );

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sub Judul (Baris 2)'**
  String get pos7c355d6ded0e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sub-Judul'**
  String get pos3db67bab4761;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Submission invoice gagal disimpan'**
  String get pos496773411e93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Subtotal'**
  String get pos97f7359ed801;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Subtotal    {arg1}'**
  String poseb08b632f2d5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Subtotal  Rp {arg1}'**
  String pos7eef271ab44c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Subtotal retur'**
  String get posbc469e0842ff;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah ada PO terbuka'**
  String get posecee7d783116;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah dialokasikan'**
  String get posd2f1691a6064;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah dialokasikan/diselesaikan'**
  String get pos9081b592591b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah diambil'**
  String get pos8f5b2a4c8e87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah dibayar'**
  String get pos3c78f49c2760;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah dibayar Finance'**
  String get pos65547f8b0596;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah diperiksa'**
  String get pos485abda51c24;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sudah punya akun? '**
  String get pos59342aa97b3f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sukses!'**
  String get posc554a5971e09;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sumber dana'**
  String get pos4a35306efdc4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sumber mutasi'**
  String get pos7fe3f6a28b35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sumber mutasi stok'**
  String get posbd176eff4e37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sumber stok'**
  String get poscd35adb78547;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sumber stok tidak tercatat'**
  String get pos61c9cd215c5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Sumber transaksi yang tersedia di kasir.'**
  String get pos0feff31b55c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pemasok'**
  String get pos55edd462872a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Pemasok *'**
  String get pos396c65e60e58;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Supplier / Pengiriman'**
  String get poscb0f469f333b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Supplier PKP'**
  String get posf530daa061ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Supplier belum tersimpan'**
  String get posfad4b83e3b5c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Supplier tidak ditemukan'**
  String get pos2c04998514d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Supplier: {arg1}'**
  String pos31dc38aa1f0a(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Supplier: {arg1}\nCabang: {arg2}\nTotal: {arg3}\n\n'**
  String pose887e1053f93(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Susun alur operasional sendiri'**
  String get pos3ff56bafe041;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Syarat pembayaran'**
  String get pos5043e33cb064;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'TIPE PEMENUHAN'**
  String get pos5103f5b202bf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'TOTAL    {arg1}'**
  String posf584192c76e1(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tag kantong'**
  String get pos5a9710152fc9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tag: {arg1}'**
  String pos60cb53587d72(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tagihan'**
  String get pos40bbe135d3d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tagihan Supplier'**
  String get poscb40220c0a55;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tagihan ini bersifat baca-saja di workspace PO. Kelola pembayaran di Finance Web.'**
  String get pos92ccc2918c68;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tagihan sudah menjadi invoice. Pelunasan dicatat melalui Piutang di Finance.'**
  String get posb628d14b320c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tagihan untuk PO ini belum tersedia.'**
  String get pos553785145ba6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tagihan {arg1}'**
  String pos1a57bf89a651(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tahun Ini'**
  String get pos6ad5100db871;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Take Away'**
  String get pos68efe193b73e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah'**
  String get posa44eb3d1808f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Inventaris'**
  String get pos6c6f45d37def;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Kendaraan'**
  String get pos755cf8a9ca03;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Meja'**
  String get pos99ca62429533;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Meja Baru'**
  String get pos6e5442a4cfe5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Mitra'**
  String get pos019dd35046d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Mutasi Stok'**
  String get pos9a338a7e55c9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Outlet'**
  String get pos56c5bd1400ce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Pelanggan'**
  String get pos2e73c6e4a5c7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Produk'**
  String get pos23cd385042fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Promo'**
  String get pos4160fba23eb0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Promo Baru'**
  String get pos6482219b950b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Retur'**
  String get pos4e362518ed1c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah Warehouse'**
  String get pos7010b9522fd5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah atau hapus dari favorit'**
  String get pos44a863c60f91;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah barang'**
  String get posb3f10ee4007c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah barang transfer'**
  String get pos037fbc1dfe7d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah biaya'**
  String get pos498e8fb630b1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah estimasi'**
  String get posf38998f2d56f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah kategori'**
  String get posf1458c4deaa0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah kategori cepat'**
  String get pos96b75014ae96;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah lokasi stok'**
  String get pos29f1ec9a570b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah metode pembayaran'**
  String get pos0cd32f8dcafe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah pelanggan baru'**
  String get pos30483a1c75bb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah produk baru'**
  String get pos6031696a08e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah supplier cepat'**
  String get pos1b3001928c79;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah {arg1}'**
  String pos56c80ff62e6d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambah {arg1} ke keranjang'**
  String posee8ce59373ea(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan barang dan isi jumlah yang valid'**
  String get posaf4a6e6a61f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan cabang atau warehouse yang benar-benar menyimpan stok usaha.'**
  String get pos0e9808622c06;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan foto nota'**
  String get pos14ab770d31dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan ke nilai persediaan'**
  String get posf28de2fc76b0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan meja beserta kapasitas kursinya untuk mulai menerima order dine-in.'**
  String get posc0ef565f6c46;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan meja dari tab Peta & Pengaturan Meja agar order dine-in dapat diproses.'**
  String get pos0a20820582f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan minimal satu barang.'**
  String get posf9ed1378315b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan minimal satu produk, layanan, atau paket aktif.'**
  String get pos7c4d863b6e3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan outlet dan hubungkan ke lokasi inventory agar kasir dapat beroperasi.'**
  String get pos3f0c2dfed6fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tambahkan {arg1} ke favorit'**
  String pos954c7b7880aa(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilan Dapur'**
  String get posc471ab3cb8ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilan dapur belum aktif'**
  String get posfcf9d787a451;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan Logo Instansi'**
  String get posa9d494637756;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan Logo Toko'**
  String get pose9e2bf944744;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan sebagai grid'**
  String get pos80a8257d82b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan sebagai kartu'**
  String get poscef74203b616;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan sebagai list'**
  String get pos1ae84586da02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan sebagai tabel'**
  String get pos54109c62b2f0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tampilkan sidebar'**
  String get posf537d54d0add;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tandai dibaca'**
  String get pos77f0b190ab89;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tandai siap'**
  String get pos20c6fad9ebd2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tandai siap diambil'**
  String get pos5b62a882a596;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tandai siap dikirim'**
  String get pos97c6fd355f4c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tandai siap disajikan'**
  String get pos28b4cc7ba754;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tandai sudah disajikan'**
  String get posac8b880f0ed5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get pos807151f245bd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal & Waktu'**
  String get pos131138e3eed6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal Berakhir'**
  String get pos501be77e1c34;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal Mulai'**
  String get posbb48601d724d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal PO'**
  String get posdb24b06fb8ef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal PO: {arg1}'**
  String pos69d6ab263540(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal Pesan'**
  String get poscaeb6107474a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal fisik tidak boleh sebelum pengiriman {arg1}.'**
  String pos5415cb31728d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal invoice (YYYY-MM-DD)'**
  String get posebfbac7f1c35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal invoice harus tanggal kalender valid (YYYY-MM-DD)'**
  String get posff1b197f16ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal invoice supplier'**
  String get posd54b6df76995;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal jatuh tempo'**
  String get pos3d3a31237bf5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal kedaluwarsa (opsional)'**
  String get pos12e331f09cb3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal kedaluwarsa *'**
  String get posce03e667a236;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal kedaluwarsa {arg1} tidak boleh sebelum tanggal penerimaan'**
  String pos3d3dc9c404be(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal kedaluwarsa {arg1} tidak valid'**
  String posdb30b8965c81(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal kejadian'**
  String get pos08206fcf8a87;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal opname *'**
  String get pos0bcfc3c95d98;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembayaran'**
  String get pos045865863406;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembayaran *'**
  String get posee1938d41d9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembelian *'**
  String get pos30ded67f550b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembukuan'**
  String get posaf9ed8959b4d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembukuan biaya (YYYY-MM-DD)'**
  String get pos0e6d46526797;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembukuan mendahului perpindahan/penyelesaian sebelumnya ({arg1}).'**
  String pos67ec666ad538(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pembukuan tidak boleh sebelum penerimaan fisik.'**
  String get pose6a950933ff5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal penerimaan'**
  String get pos956df79c0998;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal penerimaan fisik'**
  String get pos2cb9669941f4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pengiriman'**
  String get pose76f1b421a66;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal pesanan'**
  String get posab8b37663768;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal retur'**
  String get posa1a64376f020;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal tetap'**
  String get pos6d63436f523e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal tidak boleh di masa depan.'**
  String get pos8732d88a75f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal transfer (YYYY-MM-DD)'**
  String get pos81c93eadaee7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal, surat jalan, gedung, ruangan, rak, dan catatan'**
  String get posc87c804724f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal: 09/09/2026 14:30'**
  String get pos12f948b60d02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanggal: {arg1}'**
  String pos54ec6781af4f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa Pembulatan'**
  String get posbc69375eb9f6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa batch'**
  String get pos20b8d29a2f68;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa detail'**
  String get pos39a8e7188576;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa kedaluwarsa'**
  String get pos4a57a4e8c738;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa kode'**
  String get pos455b1c47f174;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa meja'**
  String get pos6b15ca9b9ecd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa nomor telepon'**
  String get pos3c0eda1efc57;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa pelanggan'**
  String get pos14b38f55305d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tanpa persetujuan (sesuai izin)'**
  String get pose16378fd2ee7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tarik ke bawah untuk memuat ulang.'**
  String get posaecde974c63d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan Web Order tidak dapat dibuka.'**
  String get pos6044f3b894da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan bukti (opsional)'**
  String get posdea33388f0d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan bukti harus http/https yang valid.'**
  String get pos1c308860b4fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan layar pelanggan disalin'**
  String get pos0cdccef7be07;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan layar pelanggan tidak valid. Buat pairing baru di POS.'**
  String get pos2e43636edafe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan meja disalin.'**
  String get posa4167d79d806;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautan pairing sudah dibuat di bawah.'**
  String get pos14b38fc11a3b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tautkan gudang toko dan display ke outlet POS yang sama di Warehouse & Lokasi.'**
  String get pos00edd80ae2b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tekan “Buat tautan pairing” di bawah.'**
  String get pose62855ffc2cc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tekan “Putuskan” setelah kasir selesai atau sebelum berganti operator. Tautan akan dinonaktifkan.'**
  String get pos5c0323d8d3b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Teknisi / staf'**
  String get pos8b5144cc4869;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Teknisi / staf penanggung jawab'**
  String get posf3d9ea2fc63b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Teknisi / staf: {arg1}'**
  String pos4d67ce5fd380(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Telepon'**
  String get pos396dc0e2976f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Telepon (opsional)'**
  String get posece97dedc009;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tempo / Piutang'**
  String get pos0e7c0c9f4a88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tentukan cara promo dan diskon manual diterapkan'**
  String get pos8b492afb0f02;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tentukan harga jual'**
  String get pos827f2855ac2a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tentukan produk fisik atau paket agar aturan stok diterapkan dengan benar.'**
  String get pos81c9388d21a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terang'**
  String get pos3cb303bd2ec7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terapkan'**
  String get pos9ff8760b6d49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terapkan ({arg1})'**
  String posdd94a4d861f7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terapkan draft biaya'**
  String get pos77a4d402549f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terapkan kode setelah selesai diketik'**
  String get posd70b31cde451;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terbuka'**
  String get posd79b3f5531eb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terhubung'**
  String get posc6a1492ff72c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terhubung ke Outlet Utama'**
  String get pos123eb4b1f4a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terhubung · perubahan keranjang akan tampil otomatis.'**
  String get pos328534274450;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima'**
  String get posa40d8bc2696a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima Barang'**
  String get pos3c23586cca04;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima Mutasi'**
  String get pos9138ecd0cc2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima Mutasi Stok'**
  String get posa5a0eefe554a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima Semua'**
  String get pos918f7e4bada8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima Sisa'**
  String get pos13084f0060ba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima jumlah ini'**
  String get pos2a56109caa07;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima kasih telah berbelanja.'**
  String get pos85d56e26d84f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima kasih.'**
  String get pos5b2653468523;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima mutasi stok'**
  String get pos8bf051a528b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terima {arg1}'**
  String posfd9cce7e760d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terisi'**
  String get posa95fd00d6f74;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terisi dahulu'**
  String get posb80a611ada31;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan pada server'**
  String get posf2f8ad1a33a3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan pada server (GraphQL)'**
  String get pose38a09bee38f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan sistem'**
  String get posd53ab0343c76;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan tidak terduga'**
  String get posd851d69b35dc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terkirim'**
  String get pos9825574c27d3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terlalu banyak percobaan. PIN dikunci 15 menit.'**
  String get pose052ade153b0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Termasuk lunas / dikreditkan'**
  String get posa91276a45d32;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Termin'**
  String get pos11f75ee33253;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Termin pembayaran'**
  String get pos8bc422f90578;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Termin {arg1} · sisa {arg2}'**
  String posb4fffbba8098(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Termin {arg1}: {arg2} / {arg3}'**
  String pos513371e1f08c(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Termin: {arg1}'**
  String posaed34e9e9854(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Terpusat'**
  String get pos0fa74526920d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tersedia'**
  String get pos227ffef55dc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tersedia {arg1} {arg2}'**
  String pos355bebfd5205(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tersedia: {arg1} {arg2} • {arg3}'**
  String pos6551fa1c3fd7(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tervalidasi'**
  String get posa6c7a3f94cda;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tes cetak'**
  String get pos1df0537d9de5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tes cetak Bluetooth'**
  String get posba1ba5c3dedc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tes cetak gagal dibuka'**
  String get pos4e9e8afc4161;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tetap Buat PO'**
  String get pos7a5e10c3ec8f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak Layak'**
  String get pose28c8f9b6faa;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak Sesuai Pesanan'**
  String get pos02d9f6225cc9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada PO siap diterima pada halaman ini. Cari nomor PO/supplier atau buka halaman berikutnya.'**
  String get posd14b80e2cab6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada antrean dapur'**
  String get pos07937b27ef30;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada barang yang masih dapat diretur.'**
  String get pos25a5ed84de7b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada draft retur untuk dipulihkan.'**
  String get pos16b44b53e177;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada invoice POS sesuai pencarian. Pesanan belum dibayar bukan piutang Finance.'**
  String get pos3c61b2617f65;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada koneksi internet. Silakan periksa jaringan Anda.'**
  String get posf2c7cb131978;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada meja dengan kapasitas ini.'**
  String get pos23fdb360f8b3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada meja valid untuk dicetak.'**
  String get pos0ebce40e26fd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada mutasi yang perlu diterima'**
  String get pos0be0bfd5091d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan aktif'**
  String get poscd430fcd869c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada pesanan pada filter ini'**
  String get pos372c46a6aa3b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada produk ditemukan'**
  String get pos7cb0145c32a4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada produk yang cocok'**
  String get pos276765701c83;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada referensi sesuai pencarian.'**
  String get posb634c27cda07;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada rekening bank aktif. Pilih tunai atau giro, atau aktifkan rekening bank.'**
  String get pos08e988bdbdd9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada rincian barang'**
  String get posb988e0cefb12;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada sisa barang untuk diterima'**
  String get pos8ef1715375a7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada sisa bebas. Periksa laporan selisih yang masih menunggu keputusan.'**
  String get posd3507ee22ea4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada sisa bebas; tunggu keputusan laporan selisih.'**
  String get pos3b85b962d8dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi dengan status yang dipilih.'**
  String get posb9423ee93d01;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak ada transaksi penjualan yang menunggu.'**
  String get pos1e33bb47437a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak dapat menghubungkan layanan layar pelanggan.'**
  String get posfd5faee84f1b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak dilacak'**
  String get poseb6d895fe4e7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak dipilih'**
  String get posd44bf57a32ac;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak hadir'**
  String get pos8034781bbb27;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tidak memerlukan persiapan'**
  String get posebc30faa0fa1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tier member'**
  String get poseb71f28b76dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Timeline PO'**
  String get pos02a84571b7f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tindakan'**
  String get pos4c20e74480b6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tindakan stok'**
  String get pos3801023d0e64;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tingkatkan produktivitas bisnis Anda sekarang juga.'**
  String get posf74b2e01d304;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tinjau'**
  String get pos3c2875091e3c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tinjau & kirim ulang'**
  String get posf0aed10f9451;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tipe Pemenuhan'**
  String get posb666fefb0fb8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tipe kredit'**
  String get pos39695d6fab24;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tipe pelanggan'**
  String get pos5b2ea9d58638;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tipe pemenuhan'**
  String get posfc101b9f5bc8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tipe pemenuhan: {arg1}'**
  String pos0a10d64b8683(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tipe warehouse'**
  String get pos7539a5f64c2c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Titik pemesanan ulang'**
  String get pose187aa4cc6cf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Titik pemesanan ulang tidak boleh melebihi stok maksimum'**
  String get posd7ec691ffd26;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Token login tidak valid'**
  String get posf2de7d5013d2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko'**
  String get posba59de499bef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko Kasir'**
  String get posbf2a3a380ae5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko POS aktif'**
  String get posc4a098109244;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko Utama'**
  String get pos80f6d6639a16;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko aktif belum terhubung ke lokasi stok. Periksa toko dan shift kasir.'**
  String get pos881045d882c0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko aktif belum tersedia'**
  String get pos9cc793d53ed1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko aktif belum tersedia untuk menampilkan meja.'**
  String get pos8a1efe9dca0c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko aktif belum tersedia untuk transaksi'**
  String get pos3a3cb51969d1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko aktif belum tersedia.'**
  String get pos9ef09d22b518;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko aktif tidak ditemukan'**
  String get posedc717c12636;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko belum terhubung ke lokasi penjualan aktif'**
  String get pos4f103360274e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko belum tersedia'**
  String get posf7072aa80587;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko shift belum terhubung ke warehouse aktif'**
  String get pos41e84ba3fd33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko: Toko Utama'**
  String get pos49c6b2654fba;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Toko: {arg1}'**
  String pos25b5fa1d18b0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tolak'**
  String get pose2f73daf8ad0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tolak retur'**
  String get pos5b45c628dde2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tolak transaksi'**
  String get pos84c23558e454;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tolak transaksi lokal?'**
  String get pos661e54fd9138;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tombol aktif setelah semua kebutuhan wajib selesai. Langkah tanpa akses harus diselesaikan admin POS.'**
  String get pos5e462813f581;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total'**
  String get posb25928c69902;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total Invoice'**
  String get pos712ac5744241;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total Pembayaran'**
  String get pos0edbc4a83d06;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total Penjualan'**
  String get posabe6ac2824da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total Produk'**
  String get pos8396d2543918;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total Tagihan'**
  String get pos0fc983ed2d5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total Transaksi'**
  String get posa46b1987023b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total dihitung ke satuan dasar. Faktor berasal dari master barang.'**
  String get pos9cfd7ea58a5f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total faktur'**
  String get posdd4e80fe392d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total fisik: {arg1} {arg2}'**
  String posd6f7fd5de931(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total item'**
  String get pos0a574329b34f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total jumlah batch harus sama dengan jumlah diterima/dilaporkan.'**
  String get posc3719a52f6da;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total konversi satuan harus sama dengan jumlah barang.'**
  String get posd7fc4f1f38e0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total pembayaran aktif saat dokumen dibuat'**
  String get posd1325b552564;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total pesanan server berbeda dari estimasi perangkat. Periksa pesanan sebelum menerima pembayaran.'**
  String get pos387705b1005d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total retur'**
  String get posa010ebebdaa7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total server berbeda dari uang yang dicatat offline. Cocokkan invoice dan kas fisik.'**
  String get posbd97f3163d03;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total tagihan'**
  String get pos98939e557aaf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total tagihan PO'**
  String get posd7bf2cf67fad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total terbesar'**
  String get pos7d383dc5f80b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total {arg1} Produk'**
  String posbd45ba0ddb67(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total {arg1} · Dibayar {arg2}\nKredit {arg3} · Sisa {arg4}'**
  String pos708b9937b7f6(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total: Rp {arg1}'**
  String pos1b58713d0d0e(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Total: {arg1}'**
  String pos596318639b9f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tracking stok'**
  String get posb0e1aaa60268;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tracking stok POS wajib aktif untuk profil Inventory ini.'**
  String get posa30e42dfeca0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tracking stok nonaktif'**
  String get pos4c697c1208a6;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi'**
  String get pos05ad114b6398;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi & Penjualan'**
  String get pos5706aca66e97;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Anda telah selesai.'**
  String get posfd0591b93e49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Baru'**
  String get posf24c8324445b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Cepat'**
  String get posa89cb868f629;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Ditolak'**
  String get pos099aef52697a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Hari Ini'**
  String get pos7b6056658137;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Terakhir'**
  String get posb653b31b8eaf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi Tunai'**
  String get pos2e839e8b2d7d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi belum tersimpan di perangkat. Periksa ruang penyimpanan, lalu coba lagi.'**
  String get pos1580dc07676b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi dan invoice yang dibuat dari kasir akan tampil di halaman ini.'**
  String get pos631991be1f51;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi dengan otorisasi PIN supervisor harus diproses saat online'**
  String get poscaddb4f7b210;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi harus memilih pelanggan'**
  String get pos752ce2ad63e3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi sudah masuk server'**
  String get pos7dfa63215c99;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi telah berhasil diproses.'**
  String get pos6a2d684ff284;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi telah selesai diproses'**
  String get pos986d3ab97aef;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transaksi {arg1}'**
  String posb9fb0286e5f6(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer'**
  String get poscbb4cc49824b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer Bank'**
  String get pose275aadefb10;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer Stok'**
  String get posc0f0a2dc1a3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer bank'**
  String get pos3e1af964e646;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer langsung: stok tujuan bertambah dan dokumen selesai saat dikirim.'**
  String get pose257882eba93;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer selesai. Periksa rincian jurnal bila ada biaya.'**
  String get pos5ad1af2acc27;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer tidak ditemukan atau tidak dapat diakses.'**
  String get pos731b69a0bb45;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transfer tidak lagi dalam perjalanan. Kembali dan muat ulang.'**
  String get posa055a39bd588;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Transit: {arg1}'**
  String pos1a266eba7d88(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tren Penjualan'**
  String get pos004cad660b83;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tujuan / catatan opname'**
  String get pos060c7c7202e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tujuan / keterangan'**
  String get posdffe7a4163fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tujuan mutasi'**
  String get pos02ccf7770f37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tujuan mutasi stok'**
  String get pose69bebecddc7;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tujuan permintaan DP wajib diisi.'**
  String get pos0a78745dd62b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tujuan stok pada PO tidak tersedia untuk penerimaan. Periksa lokasi PO dan pengaturan inventori.'**
  String get posd0d530dc9610;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tulis manual'**
  String get pos81edf3c4ac59;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tunai'**
  String get posa95263a809a0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tunggu status “Layar terhubung”, lalu tambahkan produk ke keranjang untuk memastikan layar ikut berubah.'**
  String get posea87feb3a83f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup'**
  String get pos06cde76b08c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup & kosongkan meja'**
  String get posf25f39d6a1b4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup Shift'**
  String get pos198d04f3123b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup dengan Selisih'**
  String get pos1c6d3d899f61;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup konversi'**
  String get pos7e2c5bec7ea0;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup panduan'**
  String get pos065cf00b7076;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup pesanan & kosongkan meja'**
  String get pos7d5b3fcdabe8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup shift aktif sebelum memilih toko lain.'**
  String get pos90cfcd5e19e2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Tutup sidebar'**
  String get posb0fc2128a9e8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'URL Web Order pada build aplikasi tidak valid.'**
  String get posae7b61300bc2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'UTAMA'**
  String get pos54e4b285b105;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uang Modal Awal (Rp)'**
  String get pos370bbfc4c6f3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uang Pas'**
  String get pos8a15664747c4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uang diterima'**
  String get pos5d88fa8ca6f5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uang diterima kurang dari total tagihan'**
  String get posd277bd4a7f37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uang muka tidak boleh melebihi total PO'**
  String get pos66f0e8d0b410;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uang muka yang disepakati'**
  String get posc5ddad284953;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get pos0d4e86dd43ca;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah Kata Sandi'**
  String get posd43b81387c11;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah Mutasi Stok'**
  String get pos3d05b10abd07;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah Pesanan'**
  String get pos527c4c661da3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah harga satuan'**
  String get posda4b035f456f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah jumlah'**
  String get pos7f6115f597fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah kata pencarian atau tambahkan pelanggan baru.'**
  String get posa456981f7a35;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah melalui menu Stok Toko agar tercatat dalam riwayat.'**
  String get pos8613138ac9a1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ubah pencarian atau filter. Produk yang terhubung ke toko akan tampil di sini.'**
  String get pos32dbeededecf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uji tautan'**
  String get pos652095d719e1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Uji tautan sebelum menempel QR. Pesanan masuk ke daftar pesanan aktif dengan sumber Web Order.'**
  String get posa2a346200e44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ukuran Font Default'**
  String get posa8ae0ebfbce4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ukuran foto maksimal 5 MB'**
  String get pos83b7dea60a55;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ukuran label'**
  String get posea509388c129;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi Jurnal'**
  String get posd33b85a37b70;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi Jurnal Batal'**
  String get pos469ce4c9a28e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi Jurnal Pembatalan'**
  String get posc17999007f8f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi PIN'**
  String get pos5d6ca5be4503;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi Request'**
  String get pos43ccf0129156;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi panduan'**
  String get pos7c91c6ac823e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ulangi penerimaan sebelumnya?'**
  String get pos451eaa755c4a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Umum'**
  String get pos2dd33eb6ed9e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Unduh contoh struk'**
  String get posec5aab0a9179;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Unduh contoh struk PDF, buka file tersebut lalu cetak dari browser. Untuk printer Bluetooth thermal langsung, gunakan aplikasi Android.'**
  String get pos8abd3947a6b5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Unduhan contoh struk dibatalkan'**
  String get poscfb8fb243b03;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Unik per instansi dan dapat diisi manual bila diperlukan.'**
  String get pos06c6280b7765;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Untuk dapur'**
  String get pos485487d4970f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Untuk dapur: {arg1}'**
  String pos6c74f030d8e7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Untuk menu olahan atau layanan yang memakai bahan/suku cadang. Paket boleh berisi produk berbom atau paket lain; stok akhirnya dihitung dari komponen dasar. Master komponen dikelola melalui Inventory Web.'**
  String get pos073d6c9f55fe;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Untuk pembelian kecil yang langsung dibayar. Pengiriman PO, Vendor Bill, dan utang tidak dibuat.'**
  String get posde3e49bd421c;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Upload bukti gagal'**
  String get pos0693a068e967;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Upload gambar gagal'**
  String get pos8d10c2a32c62;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Upload gambar gagal (HTTP {arg1})'**
  String posb6b3d93e8479(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Upload gambar gagal: respons server bukan JSON (HTTP {arg1}).'**
  String pos5851f7728c66(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Upload proforma gagal'**
  String get pos6d1570c0ed5d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Urutkan'**
  String get pos9f3f4e0c0a0e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Username'**
  String get pos84c29015de33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Username dan password wajib diisi'**
  String get pos6d07eb268e23;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Username minimal 3 karakter'**
  String get pos3da4232cad38;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Username sudah digunakan'**
  String get pos45585ce95883;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Username supervisor'**
  String get posc07288f18f36;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Username wajib diisi'**
  String get pos84d4cc20900b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Usulan tambahan: {arg1} {arg2}.'**
  String pos50e3560c32e9(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Utama'**
  String get posde8e2428407a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Validasi Inventory'**
  String get pos2cf8b197f95e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi & kirim'**
  String get pos107f6ed46940;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi CAPTCHA'**
  String get pos48c0247cf3ea;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi PIN kasir asal saat online, lalu kirim ulang. Transaksi tetap tersimpan.'**
  String get pos8257b6733f00;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi PIN tidak tersedia'**
  String get pos8d47558d0279;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi akses'**
  String get pos5d2d9be54cec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi harus dilakukan saat server dapat dijangkau.'**
  String get posb5ddbecb5231;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi kasir & kirim ulang'**
  String get pos784445614b66;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi kasir asal'**
  String get pos975be95dacf4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi migrasi database gagal pada {arg1}'**
  String posd42481239233(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi operator tidak tersedia'**
  String get pose7a82ec760dd;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Verifikasi rincian saldo'**
  String get pos136300f9a6ad;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Virtual account'**
  String get posfdaebba5fc2b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Void'**
  String get pos207c7c00630b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Voucher dilepas. Total baru {arg1}. Tinjau sebelum bayar.'**
  String pos759eb33e6286(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Voucher tidak dapat dilepas dari order'**
  String get pos0364b523c94d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Voucher {arg1} akan dilepas. Total tagihan dihitung ulang oleh server dan perlu ditinjau sebelum pembayaran.'**
  String pos05d7f4d6cf47(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Wajib aktif untuk profil Inventory saat ini'**
  String get posa30d29c8e996;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi jika stok fisik berbeda'**
  String get pos76fed7f3609a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Wajib pelanggan'**
  String get pos25ef7a11e45f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Wajib untuk pemindahan stok gudang toko ↔ display.'**
  String get posdc4ec62efd33;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Waktu Buka'**
  String get pos3f286ad44bb9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Waktu Buka: {arg1}'**
  String pos13585ecae7e3(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Waktu Tutup'**
  String get pos020f9b28d77a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Waktu buka tidak tersedia'**
  String get pos94677c75fcb8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Waktu pesan'**
  String get posa427df535276;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Waktu: {arg1}'**
  String posee16580f1d1c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Walk-in'**
  String get pos801d866beb88;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Gudang'**
  String get pos298dff72dae2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse & Lokasi'**
  String get posc8d47c42e360;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse / Lokasi'**
  String get pos3a0176226d44;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse berhasil dihapus'**
  String get posfd070731ed26;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse berhasil disimpan'**
  String get pos21919b3b14a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse gagal dihapus'**
  String get pos7d0fb7463dbb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse gagal disimpan'**
  String get pos0fe60734a6b2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warehouse lainnya'**
  String get pos4fb835991e0f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Warna Tema'**
  String get posea1d1795b37d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Web Order saat ini hanya menerima pembayaran langsung di kasir; pembayaran online belum tersedia.'**
  String get pos7ec8ab3a21d5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'WhatsApp'**
  String get posb336fc558722;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'WhatsApp sebagai teks'**
  String get pos6348c32e9fc3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Wi-Fi lokal'**
  String get pos6ff911097025;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Wi-Fi lokal belum dapat dibuka. Periksa jaringan dan coba lagi.'**
  String get pos24f6e9a93620;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'YYYY-MM-DD · mengikuti periode pembukuan'**
  String get pos5754555ecb84;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'Ya, Terima Barang'**
  String get pos5976ced22c37;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'advanced'**
  String get pose62854369199;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'aktual {arg1}'**
  String posadd23ff79c19(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'alasan'**
  String get posa402cc68ed18;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'asal'**
  String get pos17a3c6b44960;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'atau dengan email'**
  String get pos0f35190a786a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'belum bayar'**
  String get pos0580e7127940;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'belum dibayar'**
  String get pos871d3d68cecb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'belum tercatat'**
  String get pos7809dc360252;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'belum terkonfirmasi'**
  String get pos1be297298b78;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'catatan'**
  String get pos5cb3a7b4ddf4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'dari'**
  String get pos70a7b0d23590;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'deskripsi'**
  String get posd7343a231e9b;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'diperlukan'**
  String get pos3afeff377f69;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'diterapkan'**
  String get pos9c018701d0bc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'draft menunggu validasi'**
  String get pos0f3c832976ae;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'kadaluarsa'**
  String get pos06a45e5495d8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'karantina'**
  String get pos0deab2a2cfaf;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'ke'**
  String get pos15d5e1d3b948;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'kedaluwarsa'**
  String get posce54c69ffee9;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'laundry'**
  String get posd34c12c7afd1;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'lokasi'**
  String get pos9c8096bb4cbc;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'lokasi terpilih'**
  String get pos572e26c8af54;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'lunas'**
  String get pos93fc709f3a3e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'masukkan PIN kembali'**
  String get pos646fd2f63975;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'metode'**
  String get pos6039de4af239;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'nama@email.com (opsional)'**
  String get pos6c570c44d115;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'nominal'**
  String get pos586d61286110;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'outlet lain'**
  String get pos13da303cf88e;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'pelanggan'**
  String get pos597a445e77ec;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'pelanggan umum'**
  String get posb5afb0866405;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'penerimaan'**
  String get pos9cd64c607065;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'pengguna tidak ditemukan atau status tidak aktif'**
  String get posa41af4fbe47d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'pesanan'**
  String get pos90ec6f7cafce;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'restoran'**
  String get posd26df9c6abb4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'selisih'**
  String get pos076a81586916;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'sesi pengguna atau instansi tidak valid'**
  String get posa3ac48246ec3;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'sesi sudah dicabut'**
  String get posb269cdf44c06;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'stok'**
  String get pose4ca2609b3c5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'sudah ditutup'**
  String get poscf9d3898c3c2;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'sudah kadaluarsa'**
  String get pos75eaedaa3415;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'sudah kedaluwarsa'**
  String get pos5be6b7bc380d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tanpa kedaluwarsa'**
  String get pos1a5cfe31e47d;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'telepon'**
  String get pos289ad2a10489;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tempo'**
  String get pos65e336e20c50;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'termin'**
  String get pos73185e3fd124;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tersimpan'**
  String get posbe1b2f30c1a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tidak diperlukan'**
  String get pos5a6b85302cab;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tidak ditemukan'**
  String get pos879feb73384a;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tidak valid'**
  String get pos7b1221e5f7a8;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tindakan'**
  String get pos12156b361980;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'toko'**
  String get pos67e6ea635235;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'transaksi'**
  String get pos6cf4f5f27a49;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'tujuan'**
  String get posf7eaba5d8bf4;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'uang diterima'**
  String get pos369f683b79e5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'unit'**
  String get pos0df9eea0bad5;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'user tidak ditemukan'**
  String get pos0992d001463f;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'user …{arg1}'**
  String pos4fb0953658c9(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'warehouse'**
  String get pos4a35c0647dfb;

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\n\nTransaksi otomatis dicatat atas kasir yang membuka shift aktif.'**
  String posf8d9cba5e651(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\nJatuh tempo: {arg2}'**
  String pos36e433c66faa(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\nJika hasil belum pasti, muat ulang dokumen sebelum mengulang.'**
  String pos4865be94ff66(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\nJika koneksi terputus, periksa daftar sebelum membuat transfer baru.'**
  String posb682cdaf8e17(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\nMuat ulang status sebelum mengulang jika koneksi terputus.'**
  String poseca045b64da0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\nSaldo tersedia {arg2} {arg3}'**
  String pos9a3af49b041e(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}\n{arg2} {arg3} × Rp {arg4}'**
  String posf7f7c59d6a0a(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} (default)'**
  String posb572718edb66(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} Data terakhir tetap ditampilkan.'**
  String pos05de1a67c3af(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} Draft tetap tersimpan dan belum mengubah stok/kas.'**
  String pos3c0064b85206(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} Hari'**
  String posf286f4675572(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} Periksa hasil fisik sebelum mencoba lagi.'**
  String posce59266da29b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} batch aktif'**
  String pos784f6f055869(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} batch tercatat'**
  String pos3a95104b1217(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} dari {arg2}'**
  String pos9074e3322f20(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} dari {arg2} baris sudah diproses • periksa sisa tiap barang'**
  String pos078a5eb9fa64(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} dari {arg2} langkah selesai'**
  String posf627ed309787(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} dihapus dari keranjang'**
  String pos8270fbc798d5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} dipilih'**
  String posa6d0a58ea7de(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} ditambahkan'**
  String pos2f1e6a806cc7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} ditambahkan ke keranjang'**
  String pos602c13c1eeea(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} diterima'**
  String pos5e64822cb742(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} hanya dapat dihapus jika belum dipakai outlet dan belum memiliki saldo inventaris.'**
  String posc9d3ba9c4543(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} hari'**
  String pos07ffbaeefbeb(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} hari tercatat'**
  String pos8d46fa4132ae(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} hari {arg2} jam'**
  String posc96f7e9303ef(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} hasil fisik'**
  String pos0b3c91d7acb1(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} item'**
  String pos89bd7b74615c(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} item · {arg2}'**
  String posf6026f00f33e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} item • {arg2}'**
  String posc7eeba1af189(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} jam'**
  String poscc814c436aaa(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} jam {arg2} menit'**
  String posa6aae0f32863(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} jenis barang'**
  String posd3db39ddbb57(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} jenis barang akan menambah stok di {arg2}.\n\n{arg3}\n\nPastikan jumlah, batch, dan lokasi sudah benar.'**
  String posb77962af8721(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} jenis barang tersisa · {arg2}'**
  String pos005ed817deab(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} jenis barang · {arg2}'**
  String pos77cc5f06183a(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} kerugian bersih'**
  String pos2b5b18eb7e33(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} kg · {arg2}'**
  String pos96c96d35cf4e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} komponen dipilih'**
  String posd8b7f9fcbdae(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} kursi'**
  String posc92e889b21e0(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} lokal #{arg2}'**
  String pos2e58e983605b(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} lokasi'**
  String poscd596d982fc7(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} masih memiliki {arg2} {arg3} dalam PO yang belum diterima. {arg4} Periksa PO yang ada sebelum membuat pesanan baru.'**
  String pos3ddbca1be993(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} menit'**
  String posc0c6484282fd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} mnt'**
  String pos1903b0face48(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} operator pada periode ini'**
  String posa8b15dbf49a2(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} pesanan tersimpan'**
  String posc1d0cd74f8ec(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} produk kosong atau mencapai batas pesan ulang.'**
  String poscda259d82b9a(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} produk/layanan siap dijual.'**
  String pos9511cddc9569(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} saldo lokasi • {arg2} jenis barang'**
  String pos7d4d5958fa9e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} stok sistem'**
  String posef655d18b036(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} sudah digunakan'**
  String pos4f29bd492330(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} tamu{arg2}'**
  String pos9e2b35272c32(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} terjual'**
  String pos67fdbcba215b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} tersedia'**
  String pose9a226455937(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} tidak tersedia'**
  String pos0137b35ee82f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} toko aktif terhubung ke lokasi penjualan.'**
  String pos1c13a6636001(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} total jumlah'**
  String pos30453377460d(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi'**
  String pos3badc0263682(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi belum selesai{arg2}{arg3}'**
  String posb9af015b5b3c(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi dipilih'**
  String posac37abdf6133(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi ditolak dimasukkan kembali ke antrean'**
  String pose215c398e32f(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi lokal belum selesai disinkronkan. Ketuk untuk melihat antrean dan konflik.'**
  String pos2b8d8622ab16(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi penjualan offline belum selesai. Data tetap tersimpan di perangkat, tetapi sinkronisasi tertunda sampai akun instansi ini login kembali.'**
  String pos452e3bc76740(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi penjualan offline belum selesai. Data tetap tersimpan di perangkat, tetapi tidak dapat disinkronkan sampai akun instansi ini login kembali.'**
  String pos509814bee562(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} transaksi · Rata-rata {arg2}'**
  String posc86080cde078(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} trx'**
  String pos971fbc291672(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} unit · {arg2}'**
  String pos256020cc43aa(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} wajib diisi dan maksimal 10 MB'**
  String pos83c794c3c247(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} warehouse/lokasi penjualan aktif tersedia.'**
  String pose02d08abae0b(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} {arg2} dari {arg3} label telah dikirim. Periksa hasil fisik sebelum mengulang; batch terakhir mungkin sudah tercetak.'**
  String pos5dfc7705f747(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} {arg2} tersedia'**
  String pos8e2e32f18621(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · Coba lagi'**
  String posb4fb1c3b1411(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · Stok {arg2}'**
  String pos0bdde42d626d(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · sisa {arg2} {arg3}'**
  String pos2f893bcc6344(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · {arg2} invoice'**
  String posd4d98a649594(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · {arg2} item'**
  String posdf24f5ec1143(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · {arg2} produk'**
  String posa6e5135e1c96(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} · {arg2}. Konfirmasi nomor, lalu pilih atau tambah pelanggan saat pembayaran.'**
  String pos6e9f8acab9e7(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} • Sistem {arg2} {arg3}'**
  String posd94b4f688664(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} • Stok {arg2}'**
  String pos41d9f9c2727c(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} • Stok {arg2} {arg3}'**
  String posd3e4f6b9f3d9(String arg1, String arg2, String arg3);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1} • {arg2} tersedia'**
  String posbc5439bf7220(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}% diterima'**
  String pos984dd212a7c5(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}. Data bukan pembaruan langsung.'**
  String pos69b46e44cb84(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}Dokumen akan disetujui untuk melanjutkan proses inventori.'**
  String pos5a750eacdedd(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}Dokumen akan ditolak dan harus diperbaiki sebelum diproses kembali.'**
  String pos4aff662939ed(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}PO akan diajukan ke alur approval. Periksa kembali nilai dan tujuan pembelian.'**
  String pos60620fd8af23(String arg1);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}j {arg2}m'**
  String pos3b16fedb59a0(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}{arg2}\n{arg3}Hilang {arg4}'**
  String posecae7016438c(String arg1, String arg2, String arg3, String arg4);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'{arg1}{arg2} selisih'**
  String posdf19d6c3808e(String arg1, String arg2);

  /// Reviewed Pantoo POS UI copy; do not use for user-generated data
  ///
  /// In id, this message translates to:
  /// **'• {arg1}: {arg2} {arg3} · HPP Rp {arg4}'**
  String pos04f490437f3e(String arg1, String arg2, String arg3, String arg4);

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Pelanggan'**
  String get receiptCustomerLabel;

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get stockMovementIn;

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Keluar'**
  String get stockMovementOut;

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Bahasa'**
  String get languageTitle;

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Ikuti perangkat'**
  String get languageSystem;

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Pilihan bahasa belum tersimpan. Coba lagi.'**
  String get languageSaveFailed;

  /// No description provided for @pushPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi perangkat dinonaktifkan. Aktifkan melalui pengaturan Android.'**
  String get pushPermissionDenied;

  /// No description provided for @pushConnectionError.
  ///
  /// In id, this message translates to:
  /// **'Notifikasi perangkat belum tersambung. Coba perbarui.'**
  String get pushConnectionError;

  /// Contextual stock, language, and authentication UI
  ///
  /// In id, this message translates to:
  /// **'Masuk'**
  String get signInAction;

  /// No description provided for @reportPreviousPeriod.
  ///
  /// In id, this message translates to:
  /// **'Dibanding periode sebelumnya'**
  String get reportPreviousPeriod;

  /// No description provided for @reportAverageTransaction.
  ///
  /// In id, this message translates to:
  /// **'Nilai rata-rata setiap transaksi'**
  String get reportAverageTransaction;

  /// No description provided for @reportTopProductQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah item pada daftar produk teratas'**
  String get reportTopProductQuantity;

  /// No description provided for @dashboardCatalogProducts.
  ///
  /// In id, this message translates to:
  /// **'Produk yang tersedia dalam katalog'**
  String get dashboardCatalogProducts;

  /// No description provided for @financialProfitLoss.
  ///
  /// In id, this message translates to:
  /// **'Laba Rugi'**
  String get financialProfitLoss;

  /// No description provided for @financialReportSubtitle.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan dan beban yang sudah dibukukan'**
  String get financialReportSubtitle;

  /// No description provided for @financialScope.
  ///
  /// In id, this message translates to:
  /// **'Seluruh usaha dalam instansi ini'**
  String get financialScope;

  /// No description provided for @financialScopeNote.
  ///
  /// In id, this message translates to:
  /// **'Gabungan semua toko/cabang. Bukan laporan toko yang sedang aktif.'**
  String get financialScopeNote;

  /// No description provided for @financialBasisNote.
  ///
  /// In id, this message translates to:
  /// **'Laporan memakai jurnal terposting. Biaya atau transaksi yang belum dicatat belum termasuk.'**
  String get financialBasisNote;

  /// No description provided for @financialCostNote.
  ///
  /// In id, this message translates to:
  /// **'HPP mengikuti biaya historis dalam jurnal, bukan harga beli katalog saat ini. Kelengkapan semua biaya usaha belum dapat dipastikan otomatis.'**
  String get financialCostNote;

  /// No description provided for @financialNetSales.
  ///
  /// In id, this message translates to:
  /// **'Penjualan Bersih'**
  String get financialNetSales;

  /// No description provided for @financialCogs.
  ///
  /// In id, this message translates to:
  /// **'Harga Pokok Penjualan'**
  String get financialCogs;

  /// No description provided for @financialGrossProfit.
  ///
  /// In id, this message translates to:
  /// **'Laba Kotor Tercatat'**
  String get financialGrossProfit;

  /// No description provided for @financialNetProfit.
  ///
  /// In id, this message translates to:
  /// **'Laba/Rugi Tercatat'**
  String get financialNetProfit;

  /// No description provided for @financialRecorded.
  ///
  /// In id, this message translates to:
  /// **'Sesuai jurnal terposting'**
  String get financialRecorded;

  /// No description provided for @financialUnavailable.
  ///
  /// In id, this message translates to:
  /// **'Belum dapat dihitung'**
  String get financialUnavailable;

  /// No description provided for @financialDetails.
  ///
  /// In id, this message translates to:
  /// **'Rincian per akun'**
  String get financialDetails;

  /// No description provided for @financialOperatingExpenses.
  ///
  /// In id, this message translates to:
  /// **'Biaya Operasional'**
  String get financialOperatingExpenses;

  /// No description provided for @financialOtherRevenue.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan Lain'**
  String get financialOtherRevenue;

  /// No description provided for @financialOtherExpenses.
  ///
  /// In id, this message translates to:
  /// **'Beban Lain'**
  String get financialOtherExpenses;

  /// No description provided for @financialUnclassifiedRevenue.
  ///
  /// In id, this message translates to:
  /// **'Pendapatan Belum Dipetakan'**
  String get financialUnclassifiedRevenue;

  /// No description provided for @financialUnclassifiedExpenses.
  ///
  /// In id, this message translates to:
  /// **'Beban Belum Dipetakan'**
  String get financialUnclassifiedExpenses;

  /// No description provided for @financialTotalRevenue.
  ///
  /// In id, this message translates to:
  /// **'Total Pendapatan Tercatat'**
  String get financialTotalRevenue;

  /// No description provided for @financialTotalExpenses.
  ///
  /// In id, this message translates to:
  /// **'Total Beban Tercatat'**
  String get financialTotalExpenses;

  /// No description provided for @financialReview.
  ///
  /// In id, this message translates to:
  /// **'Data perlu diperiksa'**
  String get financialReview;

  /// No description provided for @financialNoEntries.
  ///
  /// In id, this message translates to:
  /// **'Belum ada jurnal terposting pada periode ini.'**
  String get financialNoEntries;

  /// No description provided for @financialDenied.
  ///
  /// In id, this message translates to:
  /// **'Akses laporan keuangan belum tersedia'**
  String get financialDenied;

  /// No description provided for @financialDeniedNote.
  ///
  /// In id, this message translates to:
  /// **'Minta admin memberikan izin laporan Finance. Izin laporan penjualan tidak otomatis membuka laba rugi seluruh usaha.'**
  String get financialDeniedNote;

  /// No description provided for @financialFailed.
  ///
  /// In id, this message translates to:
  /// **'Laporan belum dapat dimuat'**
  String get financialFailed;

  /// No description provided for @financialFailedNote.
  ///
  /// In id, this message translates to:
  /// **'Periksa koneksi dan coba lagi. Data lama tidak ditampilkan sebagai laporan terbaru.'**
  String get financialFailedNote;

  /// No description provided for @financialRetry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get financialRetry;

  /// No description provided for @financialRefresh.
  ///
  /// In id, this message translates to:
  /// **'Perbarui laporan'**
  String get financialRefresh;

  /// No description provided for @financialPeriod.
  ///
  /// In id, this message translates to:
  /// **'Periode laporan'**
  String get financialPeriod;

  /// No description provided for @financialToday.
  ///
  /// In id, this message translates to:
  /// **'Hari ini'**
  String get financialToday;

  /// No description provided for @financialSevenDays.
  ///
  /// In id, this message translates to:
  /// **'7 hari terakhir'**
  String get financialSevenDays;

  /// No description provided for @financialThisMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan ini'**
  String get financialThisMonth;

  /// No description provided for @financialLastMonth.
  ///
  /// In id, this message translates to:
  /// **'Bulan lalu'**
  String get financialLastMonth;

  /// No description provided for @financialCustomPeriod.
  ///
  /// In id, this message translates to:
  /// **'Pilih rentang tanggal'**
  String get financialCustomPeriod;

  /// No description provided for @financialInvalidRange.
  ///
  /// In id, this message translates to:
  /// **'Pilih periode maksimal 366 hari dan tidak melewati hari ini.'**
  String get financialInvalidRange;

  /// No description provided for @financialUpdated.
  ///
  /// In id, this message translates to:
  /// **'Diperbarui'**
  String get financialUpdated;

  /// No description provided for @financialMissingMapping.
  ///
  /// In id, this message translates to:
  /// **'Ada akun yang belum dipetakan atau tidak ditemukan. Periksa klasifikasi akun di Finance.'**
  String get financialMissingMapping;

  /// No description provided for @financialMissingCogs.
  ///
  /// In id, this message translates to:
  /// **'Pemetaan akun HPP belum tersedia. HPP dan laba kotor belum dapat dipastikan.'**
  String get financialMissingCogs;

  /// No description provided for @financialUnpostedSales.
  ///
  /// In id, this message translates to:
  /// **'Transaksi POS belum dibukukan'**
  String get financialUnpostedSales;

  /// No description provided for @financialUnpostedReturns.
  ///
  /// In id, this message translates to:
  /// **'Retur POS belum dibukukan'**
  String get financialUnpostedReturns;

  /// No description provided for @financialDraftJournals.
  ///
  /// In id, this message translates to:
  /// **'Jurnal masih berupa draf'**
  String get financialDraftJournals;

  /// No description provided for @financialUnpostedCogs.
  ///
  /// In id, this message translates to:
  /// **'Transaksi dengan biaya historis belum memiliki jurnal HPP pada periode ini'**
  String get financialUnpostedCogs;

  /// No description provided for @financialHeaderPosting.
  ///
  /// In id, this message translates to:
  /// **'Ada pencatatan langsung pada akun kelompok. Periksa jurnal sumber.'**
  String get financialHeaderPosting;

  /// No description provided for @financialUnknownIssue.
  ///
  /// In id, this message translates to:
  /// **'Ada keterbatasan data yang perlu diperiksa di Finance.'**
  String get financialUnknownIssue;

  /// No description provided for @financialLedgerDenied.
  ///
  /// In id, this message translates to:
  /// **'Rincian jurnal memerlukan izin buku besar Finance.'**
  String get financialLedgerDenied;

  /// No description provided for @financialLedger.
  ///
  /// In id, this message translates to:
  /// **'Rincian jurnal'**
  String get financialLedger;

  /// No description provided for @financialPrevious.
  ///
  /// In id, this message translates to:
  /// **'Sebelumnya'**
  String get financialPrevious;

  /// No description provided for @financialNext.
  ///
  /// In id, this message translates to:
  /// **'Berikutnya'**
  String get financialNext;

  /// No description provided for @financialDebit.
  ///
  /// In id, this message translates to:
  /// **'Debit'**
  String get financialDebit;

  /// No description provided for @financialCredit.
  ///
  /// In id, this message translates to:
  /// **'Kredit'**
  String get financialCredit;

  /// No description provided for @financialCogsMismatch.
  ///
  /// In id, this message translates to:
  /// **'Nilai jurnal HPP berbeda dari biaya historis transaksi'**
  String get financialCogsMismatch;

  /// No description provided for @financialSessionChanged.
  ///
  /// In id, this message translates to:
  /// **'Sesi atau akses laporan berubah'**
  String get financialSessionChanged;

  /// No description provided for @financialSessionNote.
  ///
  /// In id, this message translates to:
  /// **'Muat ulang laporan dengan sesi yang aktif. Data dari sesi sebelumnya sudah dihapus.'**
  String get financialSessionNote;

  /// No description provided for @businessCashFlow.
  ///
  /// In id, this message translates to:
  /// **'Arus Kas'**
  String get businessCashFlow;

  /// No description provided for @businessAging.
  ///
  /// In id, this message translates to:
  /// **'Piutang & Utang'**
  String get businessAging;

  /// No description provided for @businessReceivables.
  ///
  /// In id, this message translates to:
  /// **'Piutang Pelanggan'**
  String get businessReceivables;

  /// No description provided for @businessPayables.
  ///
  /// In id, this message translates to:
  /// **'Utang Pemasok'**
  String get businessPayables;

  /// No description provided for @businessInventory.
  ///
  /// In id, this message translates to:
  /// **'Persediaan'**
  String get businessInventory;

  /// No description provided for @businessMovement.
  ///
  /// In id, this message translates to:
  /// **'Pergerakan Stok'**
  String get businessMovement;

  /// No description provided for @businessRestock.
  ///
  /// In id, this message translates to:
  /// **'Kebutuhan Restok'**
  String get businessRestock;

  /// No description provided for @businessCutoff.
  ///
  /// In id, this message translates to:
  /// **'Posisi per tanggal'**
  String get businessCutoff;

  /// No description provided for @businessRange.
  ///
  /// In id, this message translates to:
  /// **'Periode pergerakan'**
  String get businessRange;

  /// No description provided for @businessSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari nomor dokumen atau nama'**
  String get businessSearch;

  /// No description provided for @businessAllSources.
  ///
  /// In id, this message translates to:
  /// **'Seluruh sumber yang didukung'**
  String get businessAllSources;

  /// No description provided for @businessPosSources.
  ///
  /// In id, this message translates to:
  /// **'Hanya invoice POS'**
  String get businessPosSources;

  /// No description provided for @businessSources.
  ///
  /// In id, this message translates to:
  /// **'Sumber tagihan'**
  String get businessSources;

  /// No description provided for @businessOpeningCash.
  ///
  /// In id, this message translates to:
  /// **'Saldo Awal Kas'**
  String get businessOpeningCash;

  /// No description provided for @businessCashIn.
  ///
  /// In id, this message translates to:
  /// **'Uang Masuk'**
  String get businessCashIn;

  /// No description provided for @businessCashOut.
  ///
  /// In id, this message translates to:
  /// **'Uang Keluar'**
  String get businessCashOut;

  /// No description provided for @businessClosingCash.
  ///
  /// In id, this message translates to:
  /// **'Saldo Akhir Kas'**
  String get businessClosingCash;

  /// No description provided for @businessCashChange.
  ///
  /// In id, this message translates to:
  /// **'Perubahan Bersih Kas'**
  String get businessCashChange;

  /// No description provided for @businessOutstanding.
  ///
  /// In id, this message translates to:
  /// **'Sisa Tagihan'**
  String get businessOutstanding;

  /// No description provided for @businessOverdue.
  ///
  /// In id, this message translates to:
  /// **'Lewat Jatuh Tempo'**
  String get businessOverdue;

  /// No description provided for @businessNotDue.
  ///
  /// In id, this message translates to:
  /// **'Belum Jatuh Tempo'**
  String get businessNotDue;

  /// No description provided for @businessUnknownDue.
  ///
  /// In id, this message translates to:
  /// **'Jatuh Tempo Belum Diketahui'**
  String get businessUnknownDue;

  /// No description provided for @businessOpenDocuments.
  ///
  /// In id, this message translates to:
  /// **'Dokumen Terbuka'**
  String get businessOpenDocuments;

  /// No description provided for @businessExcludedDocuments.
  ///
  /// In id, this message translates to:
  /// **'Sumber Belum Didukung'**
  String get businessExcludedDocuments;

  /// No description provided for @businessStockValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai Persediaan'**
  String get businessStockValue;

  /// No description provided for @businessBookValue.
  ///
  /// In id, this message translates to:
  /// **'Saldo Jurnal Persediaan'**
  String get businessBookValue;

  /// No description provided for @businessDifference.
  ///
  /// In id, this message translates to:
  /// **'Selisih Nilai Stok'**
  String get businessDifference;

  /// No description provided for @businessProductsEvidence.
  ///
  /// In id, this message translates to:
  /// **'Produk dengan Bukti'**
  String get businessProductsEvidence;

  /// No description provided for @businessOpeningStockValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai Stok Awal'**
  String get businessOpeningStockValue;

  /// No description provided for @businessClosingStockValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai Stok Akhir'**
  String get businessClosingStockValue;

  /// No description provided for @businessStockValueChange.
  ///
  /// In id, this message translates to:
  /// **'Perubahan Nilai Stok'**
  String get businessStockValueChange;

  /// No description provided for @businessStockProducts.
  ///
  /// In id, this message translates to:
  /// **'Produk Stok'**
  String get businessStockProducts;

  /// No description provided for @businessLowStock.
  ///
  /// In id, this message translates to:
  /// **'Stok Rendah'**
  String get businessLowStock;

  /// No description provided for @businessOutOfStock.
  ///
  /// In id, this message translates to:
  /// **'Stok Habis'**
  String get businessOutOfStock;

  /// No description provided for @businessReorderProducts.
  ///
  /// In id, this message translates to:
  /// **'Perlu Restok'**
  String get businessReorderProducts;

  /// No description provided for @businessReference.
  ///
  /// In id, this message translates to:
  /// **'Referensi'**
  String get businessReference;

  /// No description provided for @businessParty.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan / Pemasok'**
  String get businessParty;

  /// No description provided for @businessDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal'**
  String get businessDate;

  /// No description provided for @businessDueDate.
  ///
  /// In id, this message translates to:
  /// **'Jatuh Tempo'**
  String get businessDueDate;

  /// No description provided for @businessBucket.
  ///
  /// In id, this message translates to:
  /// **'Kelompok Umur'**
  String get businessBucket;

  /// No description provided for @businessAmount.
  ///
  /// In id, this message translates to:
  /// **'Nilai Dokumen'**
  String get businessAmount;

  /// No description provided for @businessPaid.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran pada Cutoff'**
  String get businessPaid;

  /// No description provided for @businessCredited.
  ///
  /// In id, this message translates to:
  /// **'Kredit / Retur pada Cutoff'**
  String get businessCredited;

  /// No description provided for @businessName.
  ///
  /// In id, this message translates to:
  /// **'Nama Produk'**
  String get businessName;

  /// No description provided for @businessAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun'**
  String get businessAccount;

  /// No description provided for @businessQuantity.
  ///
  /// In id, this message translates to:
  /// **'Kuantitas'**
  String get businessQuantity;

  /// No description provided for @businessValue.
  ///
  /// In id, this message translates to:
  /// **'Nilai'**
  String get businessValue;

  /// No description provided for @businessStatus.
  ///
  /// In id, this message translates to:
  /// **'Status Bukti'**
  String get businessStatus;

  /// No description provided for @businessUnit.
  ///
  /// In id, this message translates to:
  /// **'Satuan Dasar'**
  String get businessUnit;

  /// No description provided for @businessMinimum.
  ///
  /// In id, this message translates to:
  /// **'Batas Minimum'**
  String get businessMinimum;

  /// No description provided for @businessReorder.
  ///
  /// In id, this message translates to:
  /// **'Titik Restok'**
  String get businessReorder;

  /// No description provided for @businessOpeningQuantity.
  ///
  /// In id, this message translates to:
  /// **'Kuantitas Awal'**
  String get businessOpeningQuantity;

  /// No description provided for @businessIncoming.
  ///
  /// In id, this message translates to:
  /// **'Barang Masuk'**
  String get businessIncoming;

  /// No description provided for @businessOutgoing.
  ///
  /// In id, this message translates to:
  /// **'Barang Keluar'**
  String get businessOutgoing;

  /// No description provided for @businessAdjustment.
  ///
  /// In id, this message translates to:
  /// **'Penyesuaian'**
  String get businessAdjustment;

  /// No description provided for @businessOtherMovement.
  ///
  /// In id, this message translates to:
  /// **'Perubahan Lain'**
  String get businessOtherMovement;

  /// No description provided for @businessClosingQuantity.
  ///
  /// In id, this message translates to:
  /// **'Kuantitas Akhir'**
  String get businessClosingQuantity;

  /// No description provided for @businessDescription.
  ///
  /// In id, this message translates to:
  /// **'Keterangan'**
  String get businessDescription;

  /// No description provided for @businessActivity.
  ///
  /// In id, this message translates to:
  /// **'Aktivitas'**
  String get businessActivity;

  /// No description provided for @businessOperating.
  ///
  /// In id, this message translates to:
  /// **'Operasional'**
  String get businessOperating;

  /// No description provided for @businessInvesting.
  ///
  /// In id, this message translates to:
  /// **'Investasi'**
  String get businessInvesting;

  /// No description provided for @businessFinancing.
  ///
  /// In id, this message translates to:
  /// **'Pendanaan'**
  String get businessFinancing;

  /// No description provided for @businessUnclassified.
  ///
  /// In id, this message translates to:
  /// **'Belum Terklasifikasi'**
  String get businessUnclassified;

  /// No description provided for @businessCurrent.
  ///
  /// In id, this message translates to:
  /// **'Belum jatuh tempo'**
  String get businessCurrent;

  /// No description provided for @businessDays30.
  ///
  /// In id, this message translates to:
  /// **'Terlambat 1–30 hari'**
  String get businessDays30;

  /// No description provided for @businessDays60.
  ///
  /// In id, this message translates to:
  /// **'Terlambat 31–60 hari'**
  String get businessDays60;

  /// No description provided for @businessDays90.
  ///
  /// In id, this message translates to:
  /// **'Terlambat 61–90 hari'**
  String get businessDays90;

  /// No description provided for @businessDaysMore90.
  ///
  /// In id, this message translates to:
  /// **'Terlambat lebih dari 90 hari'**
  String get businessDaysMore90;

  /// No description provided for @businessComplete.
  ///
  /// In id, this message translates to:
  /// **'Bukti yang diperiksa lengkap'**
  String get businessComplete;

  /// No description provided for @businessPartial.
  ///
  /// In id, this message translates to:
  /// **'Sebagian sumber belum lengkap'**
  String get businessPartial;

  /// No description provided for @businessUnknown.
  ///
  /// In id, this message translates to:
  /// **'Bukti belum dapat dipastikan'**
  String get businessUnknown;

  /// No description provided for @businessDiscrepancy.
  ///
  /// In id, this message translates to:
  /// **'Ada selisih yang perlu diperiksa'**
  String get businessDiscrepancy;

  /// No description provided for @businessEmpty.
  ///
  /// In id, this message translates to:
  /// **'Tidak ada rincian sesuai filter. Periksa juga catatan cakupan sumber.'**
  String get businessEmpty;

  /// No description provided for @businessDetails.
  ///
  /// In id, this message translates to:
  /// **'Rincian laporan'**
  String get businessDetails;

  /// No description provided for @businessSourceNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan sumber dan cakupan'**
  String get businessSourceNotes;

  /// No description provided for @businessPage.
  ///
  /// In id, this message translates to:
  /// **'Halaman'**
  String get businessPage;

  /// No description provided for @businessRows.
  ///
  /// In id, this message translates to:
  /// **'baris'**
  String get businessRows;

  /// No description provided for @businessDenied.
  ///
  /// In id, this message translates to:
  /// **'Laporan ini memerlukan izin Finance dan izin sumber terkait. Persediaan historis memerlukan izin jurnal; restok gabungan memerlukan akses seluruh lokasi.'**
  String get businessDenied;

  /// No description provided for @businessCashMissing.
  ///
  /// In id, this message translates to:
  /// **'Akun kas/bank belum dipetakan. Saldo tidak dianggap nol.'**
  String get businessCashMissing;

  /// No description provided for @businessGrossAmbiguous.
  ///
  /// In id, this message translates to:
  /// **'Ada jurnal gabungan yang belum dapat dipisahkan menjadi penerimaan dan pengeluaran bruto. Saldo bersih tetap mengikuti buku besar.'**
  String get businessGrossAmbiguous;

  /// No description provided for @businessAgingBasis.
  ///
  /// In id, this message translates to:
  /// **'Sisa tagihan dan pembayaran direkonstruksi sampai akhir tanggal cutoff, bukan saldo hari ini.'**
  String get businessAgingBasis;

  /// No description provided for @businessAgingExclusions.
  ///
  /// In id, this message translates to:
  /// **'Total hanya mencakup sumber yang dapat direkonstruksi. Rincian yang dikeluarkan tercantum pada catatan sumber.'**
  String get businessAgingExclusions;

  /// No description provided for @businessPosOnly.
  ///
  /// In id, this message translates to:
  /// **'Hanya invoice yang berasal dari transaksi POS; pesanan belum dibayar tidak otomatis menjadi piutang Finance.'**
  String get businessPosOnly;

  /// No description provided for @businessTradeAR.
  ///
  /// In id, this message translates to:
  /// **'Piutang pelanggan dari sumber yang didukung. Bukan seluruh aset piutang perusahaan.'**
  String get businessTradeAR;

  /// No description provided for @businessTradeAP.
  ///
  /// In id, this message translates to:
  /// **'Utang dagang pemasok dari sumber yang didukung. Pinjaman, utang gaji, dan pajak tidak termasuk.'**
  String get businessTradeAP;

  /// No description provided for @businessHistoricalStock.
  ///
  /// In id, this message translates to:
  /// **'Saldo dan nilai stok mengikuti bukti historis seluruh lokasi, bukan harga katalog saat ini.'**
  String get businessHistoricalStock;

  /// No description provided for @businessStockMissing.
  ///
  /// In id, this message translates to:
  /// **'Baseline atau rantai bukti belum lengkap. Stok hari ini tidak dipakai sebagai saldo masa lalu.'**
  String get businessStockMissing;

  /// No description provided for @businessMovementBasis.
  ///
  /// In id, this message translates to:
  /// **'Kuantitas per produk menggunakan satuan dasar. Saldo awal + masuk − keluar + penyesuaian + perubahan lain = saldo akhir.'**
  String get businessMovementBasis;

  /// No description provided for @businessMovementMissing.
  ///
  /// In id, this message translates to:
  /// **'Mutasi bruto memerlukan baseline yang sama dan rantai perubahan terverifikasi sepanjang periode. Bukti cutoff terpisah saja tidak membuktikan seluruh mutasi.'**
  String get businessMovementMissing;

  /// No description provided for @businessRestockLive.
  ///
  /// In id, this message translates to:
  /// **'Daftar restok menunjukkan kondisi hari ini dan ambang minimum/reorder saat ini; bukan laporan historis.'**
  String get businessRestockLive;

  /// No description provided for @businessExport.
  ///
  /// In id, this message translates to:
  /// **'Ekspor laporan'**
  String get businessExport;

  /// No description provided for @businessCsv.
  ///
  /// In id, this message translates to:
  /// **'CSV / Excel'**
  String get businessCsv;

  /// No description provided for @businessPdf.
  ///
  /// In id, this message translates to:
  /// **'PDF'**
  String get businessPdf;

  /// No description provided for @businessExportChanged.
  ///
  /// In id, this message translates to:
  /// **'Data berubah. Perbarui laporan sebelum mengekspor agar seluruh baris konsisten.'**
  String get businessExportChanged;

  /// No description provided for @businessExportLimit.
  ///
  /// In id, this message translates to:
  /// **'Ekspor terlalu besar. Persempit periode atau pencarian.'**
  String get businessExportLimit;

  /// No description provided for @businessExportFailed.
  ///
  /// In id, this message translates to:
  /// **'Ekspor belum berhasil. Coba lagi setelah memperbarui laporan.'**
  String get businessExportFailed;

  /// No description provided for @businessPdfGlyph.
  ///
  /// In id, this message translates to:
  /// **'PDF belum mendukung sebagian karakter pada data ini. Gunakan CSV agar seluruh nama tetap utuh.'**
  String get businessPdfGlyph;

  /// No description provided for @businessExportScope.
  ///
  /// In id, this message translates to:
  /// **'Cakupan'**
  String get businessExportScope;

  /// No description provided for @businessExportCurrency.
  ///
  /// In id, this message translates to:
  /// **'Mata uang'**
  String get businessExportCurrency;

  /// No description provided for @businessExportCoverage.
  ///
  /// In id, this message translates to:
  /// **'Cakupan bukti'**
  String get businessExportCoverage;

  /// No description provided for @businessExportAllRows.
  ///
  /// In id, this message translates to:
  /// **'Ekspor mencakup seluruh halaman untuk filter ini.'**
  String get businessExportAllRows;

  /// No description provided for @businessWithheld.
  ///
  /// In id, this message translates to:
  /// **'Potongan Pajak'**
  String get businessWithheld;

  /// No description provided for @businessCashReconciliation.
  ///
  /// In id, this message translates to:
  /// **'Selisih Rekonsiliasi Kas'**
  String get businessCashReconciliation;

  /// No description provided for @businessOpenSource.
  ///
  /// In id, this message translates to:
  /// **'Buka dokumen terkini'**
  String get businessOpenSource;

  /// No description provided for @businessSourceFailed.
  ///
  /// In id, this message translates to:
  /// **'Dokumen sumber tidak dapat dibuka. Periksa izin akses lalu coba lagi.'**
  String get businessSourceFailed;

  /// No description provided for @posPreparingSales.
  ///
  /// In id, this message translates to:
  /// **'Mempersiapkan penjualan...'**
  String get posPreparingSales;

  /// No description provided for @posCashierNavigationShortcuts.
  ///
  /// In id, this message translates to:
  /// **'Alt+1 / Alt+2 Kasir · Alt+3 Katalog'**
  String get posCashierNavigationShortcuts;

  /// No description provided for @tradeTitle.
  ///
  /// In id, this message translates to:
  /// **'Utang & Piutang'**
  String get tradeTitle;

  /// No description provided for @tradeCreate.
  ///
  /// In id, this message translates to:
  /// **'Catat Tagihan Manual'**
  String get tradeCreate;

  /// No description provided for @tradeNewBill.
  ///
  /// In id, this message translates to:
  /// **'Tagihan baru'**
  String get tradeNewBill;

  /// No description provided for @tradeOpening.
  ///
  /// In id, this message translates to:
  /// **'Saldo awal belum tercatat'**
  String get tradeOpening;

  /// No description provided for @tradeManualNote.
  ///
  /// In id, this message translates to:
  /// **'Untuk tagihan uang tanpa rincian stok atau pajak. Jangan mencatat ulang invoice yang sudah ada di Finance.'**
  String get tradeManualNote;

  /// No description provided for @tradeOpeningNote.
  ///
  /// In id, this message translates to:
  /// **'Hanya saldo yang belum pernah dicatat di Finance. Saldo awal masuk ke ekuitas dan tidak menjadi pendapatan atau beban baru.'**
  String get tradeOpeningNote;

  /// No description provided for @tradeCustomer.
  ///
  /// In id, this message translates to:
  /// **'Nama pelanggan'**
  String get tradeCustomer;

  /// No description provided for @tradeSupplier.
  ///
  /// In id, this message translates to:
  /// **'Nama pemasok'**
  String get tradeSupplier;

  /// No description provided for @tradeExistingCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan terdaftar (opsional)'**
  String get tradeExistingCustomer;

  /// No description provided for @tradeNewCustomer.
  ///
  /// In id, this message translates to:
  /// **'Gunakan nama pelanggan'**
  String get tradeNewCustomer;

  /// No description provided for @tradeControl.
  ///
  /// In id, this message translates to:
  /// **'Kelompok tagihan'**
  String get tradeControl;

  /// No description provided for @tradeCounter.
  ///
  /// In id, this message translates to:
  /// **'Kategori pencatatan'**
  String get tradeCounter;

  /// No description provided for @tradeSave.
  ///
  /// In id, this message translates to:
  /// **'Simpan Tagihan'**
  String get tradeSave;

  /// No description provided for @tradePay.
  ///
  /// In id, this message translates to:
  /// **'Catat Pembayaran'**
  String get tradePay;

  /// No description provided for @tradeReceive.
  ///
  /// In id, this message translates to:
  /// **'Catat Penerimaan'**
  String get tradeReceive;

  /// No description provided for @tradePaymentNote.
  ///
  /// In id, this message translates to:
  /// **'Pencatatan online ke akun Finance. Ini bukan penjualan baru dan tidak mengubah uang laci shift.'**
  String get tradePaymentNote;

  /// No description provided for @tradeCash.
  ///
  /// In id, this message translates to:
  /// **'Tunai — kas Finance'**
  String get tradeCash;

  /// No description provided for @tradeTransfer.
  ///
  /// In id, this message translates to:
  /// **'Transfer bank'**
  String get tradeTransfer;

  /// No description provided for @tradeCashAccount.
  ///
  /// In id, this message translates to:
  /// **'Akun kas penerimaan'**
  String get tradeCashAccount;

  /// No description provided for @tradeBank.
  ///
  /// In id, this message translates to:
  /// **'Rekening bank'**
  String get tradeBank;

  /// No description provided for @tradePending.
  ///
  /// In id, this message translates to:
  /// **'Permintaan belum terkonfirmasi'**
  String get tradePending;

  /// No description provided for @tradePendingNote.
  ///
  /// In id, this message translates to:
  /// **'Jangan membuat pencatatan atau pembayaran pengganti. Konfirmasi kembali menggunakan permintaan yang sama.'**
  String get tradePendingNote;

  /// No description provided for @tradeRetrySame.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi ulang'**
  String get tradeRetrySame;

  /// No description provided for @tradeCreateSuccess.
  ///
  /// In id, this message translates to:
  /// **'Tagihan dan jurnal berhasil dicatat.'**
  String get tradeCreateSuccess;

  /// No description provided for @tradePaySuccess.
  ///
  /// In id, this message translates to:
  /// **'Pembayaran dan jurnal berhasil dicatat.'**
  String get tradePaySuccess;

  /// No description provided for @tradeDetails.
  ///
  /// In id, this message translates to:
  /// **'Rincian tagihan'**
  String get tradeDetails;

  /// No description provided for @tradeHistory.
  ///
  /// In id, this message translates to:
  /// **'Riwayat pembayaran'**
  String get tradeHistory;

  /// No description provided for @tradeNoHistory.
  ///
  /// In id, this message translates to:
  /// **'Belum ada pembayaran.'**
  String get tradeNoHistory;

  /// No description provided for @tradeLastHistory.
  ///
  /// In id, this message translates to:
  /// **'Menampilkan maksimal 50 pembayaran terakhir.'**
  String get tradeLastHistory;

  /// No description provided for @tradeConfirm.
  ///
  /// In id, this message translates to:
  /// **'Konfirmasi pencatatan'**
  String get tradeConfirm;

  /// No description provided for @tradeConfirmNote.
  ///
  /// In id, this message translates to:
  /// **'Periksa kembali pihak, nominal, tanggal dan kategori. Tindakan ini membentuk jurnal serta memperbarui saldo Finance.'**
  String get tradeConfirmNote;

  /// No description provided for @tradeCancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get tradeCancel;

  /// No description provided for @tradeContinue.
  ///
  /// In id, this message translates to:
  /// **'Ya, catat'**
  String get tradeContinue;

  /// No description provided for @tradeRequired.
  ///
  /// In id, this message translates to:
  /// **'Wajib diisi.'**
  String get tradeRequired;

  /// No description provided for @tradeInvalidAmount.
  ///
  /// In id, this message translates to:
  /// **'Masukkan Rupiah bulat positif sesuai sisa tagihan.'**
  String get tradeInvalidAmount;

  /// No description provided for @tradeInvalidDate.
  ///
  /// In id, this message translates to:
  /// **'Tanggal atau jatuh tempo tidak valid.'**
  String get tradeInvalidDate;

  /// No description provided for @tradeNoAccounts.
  ///
  /// In id, this message translates to:
  /// **'Kategori akun belum tersedia. Lengkapi pemetaan akun melalui Finance terlebih dahulu.'**
  String get tradeNoAccounts;

  /// No description provided for @tradeSettled.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan yang sudah selesai'**
  String get tradeSettled;

  /// No description provided for @tradeSearch.
  ///
  /// In id, this message translates to:
  /// **'Cari pihak atau nomor dokumen'**
  String get tradeSearch;

  /// No description provided for @tradeNoAccess.
  ///
  /// In id, this message translates to:
  /// **'Akses utang/piutang belum tersedia untuk pengguna ini.'**
  String get tradeNoAccess;

  /// No description provided for @tradePOSScope.
  ///
  /// In id, this message translates to:
  /// **'Hanya piutang POS pada toko yang diizinkan. Pencatatan manual memerlukan akses Finance seluruh instansi.'**
  String get tradePOSScope;

  /// No description provided for @tradeProof.
  ///
  /// In id, this message translates to:
  /// **'Bukti pencatatan'**
  String get tradeProof;

  /// No description provided for @tradeJournal.
  ///
  /// In id, this message translates to:
  /// **'Nomor jurnal'**
  String get tradeJournal;

  /// No description provided for @tradeUnverified.
  ///
  /// In id, this message translates to:
  /// **'Bukti jurnal belum dapat dipastikan.'**
  String get tradeUnverified;

  /// No description provided for @tradeNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan (opsional)'**
  String get tradeNotes;

  /// No description provided for @tradeSavedCustomer.
  ///
  /// In id, this message translates to:
  /// **'Pelanggan terpilih'**
  String get tradeSavedCustomer;

  /// No description provided for @tradeUnknown.
  ///
  /// In id, this message translates to:
  /// **'Hasil permintaan belum dapat dipastikan. Konfirmasi ulang dengan bukti yang sama.'**
  String get tradeUnknown;

  /// No description provided for @setupSalesGuideTitle.
  ///
  /// In id, this message translates to:
  /// **'Panduan mulai berjualan'**
  String get setupSalesGuideTitle;

  /// No description provided for @setupSalesGuideHelp.
  ///
  /// In id, this message translates to:
  /// **'Opsional. Tambahkan produk atau layanan; pengaturan lainnya bisa menyusul.'**
  String get setupSalesGuideHelp;

  /// No description provided for @setupSalesGuideView.
  ///
  /// In id, this message translates to:
  /// **'Lihat panduan'**
  String get setupSalesGuideView;

  /// No description provided for @setupSalesGuideHide.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan panduan'**
  String get setupSalesGuideHide;

  /// No description provided for @inventoryOpeningStockLabel.
  ///
  /// In id, this message translates to:
  /// **'Stok Awal'**
  String get inventoryOpeningStockLabel;

  /// No description provided for @serviceDirectLabel.
  ///
  /// In id, this message translates to:
  /// **'Layanan Langsung'**
  String get serviceDirectLabel;

  /// No description provided for @serviceReservationEndOptional.
  ///
  /// In id, this message translates to:
  /// **'Selesai reservasi (opsional)'**
  String get serviceReservationEndOptional;

  /// No description provided for @serviceReservationDefaultDuration.
  ///
  /// In id, this message translates to:
  /// **'Jika tidak diubah, durasi awal reservasi 2 jam.'**
  String get serviceReservationDefaultDuration;

  /// No description provided for @serviceItemOrNotesRequired.
  ///
  /// In id, this message translates to:
  /// **'Isi objek layanan atau catatan pekerjaan.'**
  String get serviceItemOrNotesRequired;

  /// No description provided for @serviceCartQuantityHelp.
  ///
  /// In id, this message translates to:
  /// **'Berat/jumlah mengikuti keranjang. Tidak perlu diisi ulang.'**
  String get serviceCartQuantityHelp;

  /// No description provided for @serviceCloseObjectDetails.
  ///
  /// In id, this message translates to:
  /// **'Tutup detail per objek'**
  String get serviceCloseObjectDetails;

  /// No description provided for @serviceObjectDetailsOptional.
  ///
  /// In id, this message translates to:
  /// **'Detail per objek (opsional)'**
  String get serviceObjectDetailsOptional;

  /// No description provided for @serviceObjectWeight.
  ///
  /// In id, this message translates to:
  /// **'Berat objek (kg)'**
  String get serviceObjectWeight;

  /// No description provided for @serviceObjectQuantity.
  ///
  /// In id, this message translates to:
  /// **'Jumlah objek'**
  String get serviceObjectQuantity;

  /// No description provided for @serviceObjectTag.
  ///
  /// In id, this message translates to:
  /// **'Identitas / tag objek'**
  String get serviceObjectTag;

  /// No description provided for @serviceObjectNotes.
  ///
  /// In id, this message translates to:
  /// **'Catatan objek'**
  String get serviceObjectNotes;

  /// No description provided for @serviceSplitOneItem.
  ///
  /// In id, this message translates to:
  /// **'Pisahkan 1 ke objek lain'**
  String get serviceSplitOneItem;

  /// No description provided for @serviceRemoveObjectDetails.
  ///
  /// In id, this message translates to:
  /// **'Hapus detail objek ini'**
  String get serviceRemoveObjectDetails;

  /// No description provided for @pinIncorrectAttemptsRemaining.
  ///
  /// In id, this message translates to:
  /// **'PIN salah. Sisa percobaan {count}.'**
  String pinIncorrectAttemptsRemaining(String count);

  /// No description provided for @secretShow.
  ///
  /// In id, this message translates to:
  /// **'Tampilkan {field}'**
  String secretShow(String field);

  /// No description provided for @googleSignInIncomplete.
  ///
  /// In id, this message translates to:
  /// **'Login Google dibatalkan atau belum selesai. Jika Anda sudah memilih akun, coba lagi atau gunakan email dan password.'**
  String get googleSignInIncomplete;

  /// No description provided for @googleSignInConfigurationError.
  ///
  /// In id, this message translates to:
  /// **'Konfigurasi login Google untuk versi aplikasi ini belum sesuai. Gunakan email dan password sementara, lalu hubungi dukungan Pantoo.'**
  String get googleSignInConfigurationError;

  /// No description provided for @checkoutRecoveryReference.
  ///
  /// In id, this message translates to:
  /// **'Referensi pembayaran'**
  String get checkoutRecoveryReference;

  /// No description provided for @orderPaymentUnconfirmed.
  ///
  /// In id, this message translates to:
  /// **'Hasil pembayaran pesanan belum terkonfirmasi. Periksa pesanan yang sama atau hubungi admin; jangan terima pembayaran kedua.'**
  String get orderPaymentUnconfirmed;

  /// No description provided for @checkoutInvalidFreshData.
  ///
  /// In id, this message translates to:
  /// **'Data pembayaran belum valid. Periksa keranjang dan jumlah pembayaran, lalu coba lagi. Pembayaran belum dikirim.'**
  String get checkoutInvalidFreshData;

  /// No description provided for @checkoutRecoveryConnection.
  ///
  /// In id, this message translates to:
  /// **'Koneksi ke server belum berhasil saat memulihkan pembayaran. Bukti transaksi tetap tersimpan; coba lagi saat server dapat dijangkau. Jangan bayar ulang.'**
  String get checkoutRecoveryConnection;

  /// No description provided for @checkoutRecoveryUnconfirmed.
  ///
  /// In id, this message translates to:
  /// **'Server belum dapat memastikan hasil pembayaran. Hubungi admin dengan referensi pembayaran ini; jangan membuat pembayaran pengganti.'**
  String get checkoutRecoveryUnconfirmed;

  /// No description provided for @checkoutRecoveryResponse.
  ///
  /// In id, this message translates to:
  /// **'Respons server belum cocok dengan bukti pembayaran. Hubungi admin dengan referensi pembayaran ini; jangan bayar ulang.'**
  String get checkoutRecoveryResponse;

  /// No description provided for @secretHide.
  ///
  /// In id, this message translates to:
  /// **'Sembunyikan {field}'**
  String secretHide(String field);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
