import 'package:flutter/material.dart';
import 'generated/app_localizations.dart';
import 'pos_translation_lookup.dart';
import 'app_language_controller.dart';

// Feature copy is kept outside the generated legacy lookup.
const _purchasePaymentEnglish = {
  'Dibutuhkan paling lambat (opsional)': 'Required by (optional)',
  'Dibutuhkan paling lambat': 'Required by',
  'Estimasi kirim dari pemasok': 'Supplier shipping estimate',
  'Estimasi tanggal kirim dari pemasok (opsional)':
      'Supplier shipping estimate (optional)',
  'Estimasi tanggal tiba dari pemasok (opsional)':
      'Supplier arrival estimate (optional)',
  'Pengaturan lanjutan: pembayaran dan informasi tambahan':
      'Advanced: payment and additional information',
  'Jumlah cicilan (2–12)': 'Installment count (2–12)',
  'Cicilan': 'Installment',
  'Buat ulang jadwal cicilan': 'Regenerate installment schedule',
  'Jumlah cicilan harus 2 sampai 12':
      'Installment count must be between 2 and 12',
  'Jumlah cicilan harus 2 sampai 12 dan sesuai jadwal':
      'Installment count must be between 2 and 12 and match the schedule',
  'Isi nominal positif dan tanggal setiap cicilan':
      'Enter a positive amount and a valid date for each installment',
  'Total pembayaran cicilan harus sama dengan total PO':
      'Installment amounts must add up to the PO total',
  'Isi tanggal jatuh tempo': 'Enter the due date',
};

String _translatePosCopy(String source, AppLocalizations locale) {
  final paymentCopy = _purchasePaymentEnglish[source];
  if (paymentCopy != null) {
    return locale.localeName.startsWith('en') ? paymentCopy : source;
  }
  return translatePosText(source, locale);
}

// Legacy standalone widgets without app delegates keep their Indonesian default.
AppLocalizations posLocale(BuildContext context) =>
    AppLocalizations.of(context) ?? lookupAppLocalizations(const Locale('id'));

AppLocalizations posCurrentLocale() =>
    lookupAppLocalizations(AppLanguageController.instance.effectiveLocale);

extension PosLocalizedString on String {
  String tr(BuildContext context) => this == 'Utang & Piutang'
      ? posLocale(context).tradeTitle
      : _translatePosCopy(this, posLocale(context));

  /// Global toasts can outlive their originating page after an async operation.
  String trCurrent() => _translatePosCopy(
    this,
    lookupAppLocalizations(AppLanguageController.instance.effectiveLocale),
  );
}

/// Enum labels describe UI choices; model names and free-text choices are data.
String posOptionLabel(Object? option, String label, BuildContext context) =>
    option is Enum ? label.tr(context) : label;

/// Stock direction has a different meaning from signing in or out.
String posStockMovementLabel(String code, BuildContext context) =>
    switch (code) {
      'masuk' || 'in' => posLocale(context).stockMovementIn,
      'keluar' || 'out' => posLocale(context).stockMovementOut,
      'penyesuaian' || 'adjustment' => 'Koreksi'.tr(context),
      'retur' || 'return' => 'Retur'.tr(context),
      '' => 'Semua'.tr(context),
      _ => code,
    };

/// Translate a displayed status without changing its stored/API value.
String posStatusLabel(String value, BuildContext context) {
  const labels = {
    'draft': 'Draf',
    'pending': 'Menunggu',
    'submitted': 'Diajukan',
    'credited': 'Dikreditkan',
    'acknowledged': 'Dikonfirmasi',
    'partially_received': 'Diterima sebagian',
    'fully_received': 'Lengkap',
    'in_transit': 'Dalam perjalanan',
    'active': 'Aktif',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
    'canceled': 'Dibatalkan',
    'paid': 'Lunas',
    'unpaid': 'Belum dibayar',
    'partial': 'Dibayar sebagian',
    'partially_paid': 'Dibayar sebagian',
    'approved': 'Disetujui',
    'rejected': 'Ditolak',
    'posted': 'Dibukukan',
    'validated': 'Tervalidasi',
    'failed': 'Gagal',
    'received': 'Diterima',
    'preparing': 'Diproses',
    'ready': 'Siap',
    'delivered': 'Terkirim',
    'open': 'Terbuka',
    'closed': 'Ditutup',
  };
  return (labels[value.trim().toLowerCase()] ?? value).tr(context);
}

/// FormField caches validator results; render them again when locale changes.
Widget posValidationError(BuildContext context, String error) => Text(
  error.tr(context),
  style:
      Theme.of(context).inputDecorationTheme.errorStyle ??
      Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
);

/// Explicitly used for UI copy only. Keep Text for names, chat, and user input.
/// Rendering at build time allows const widgets to respond to locale changes.
class PosText extends StatelessWidget {
  const PosText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.signIn = false,
  });
  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  final bool signIn;
  @override
  Widget build(BuildContext context) {
    final l = posLocale(context);
    final translated = _translatePosCopy(data, l);
    return Text(
      translated,
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler:
          textScaler ??
          (textScaleFactor == null
              ? null
              : TextScaler.linear(textScaleFactor!)),
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null
          ? null
          : translatePosText(semanticsLabel!, l),
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
