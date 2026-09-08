import 'package:equatable/equatable.dart';

class PosSettings extends Equatable {
  final bool? onboardingCompleted;
  final int? onboardingVersion;
  final bool? operationalSetupCompleted;
  final String? businessProfile;
  final Map<String, bool> enabledFeatures;
  final double? pajakPersen;
  final String? defaultMetodePembayaran;
  final String? defaultChannelPenjualan;
  final String? defaultTipePesanan;
  final List<String> salesChannelOptions;
  final String? defaultPriceLevel;
  final List<String> priceLevelOptions;
  final String? defaultDiscountPolicy;
  final String? invoicePrefix;
  final bool? autoPrintReceipt;
  final bool? allowOutOfShift;
  final bool? allowKasirPriceEdit;
  final String? expiredSalePolicy;
  final bool? posLockEnabled;
  final bool? posLockOnBackground;
  final int? posAutoLockMinutes;
  final String? defaultCatatan;
  final double? minTransaksiTunai;
  final String? pembulatanHarga;

  const PosSettings({
    this.onboardingCompleted,
    this.onboardingVersion,
    this.operationalSetupCompleted,
    this.businessProfile,
    this.enabledFeatures = const {},
    this.pajakPersen,
    this.defaultMetodePembayaran,
    this.defaultChannelPenjualan,
    this.defaultTipePesanan,
    this.salesChannelOptions = const [],
    this.defaultPriceLevel,
    this.priceLevelOptions = const [],
    this.defaultDiscountPolicy,
    this.invoicePrefix,
    this.autoPrintReceipt,
    this.allowOutOfShift,
    this.allowKasirPriceEdit,
    this.expiredSalePolicy,
    this.posLockEnabled,
    this.posLockOnBackground,
    this.posAutoLockMinutes,
    this.defaultCatatan,
    this.minTransaksiTunai,
    this.pembulatanHarga,
  });

  factory PosSettings.fromJson(Map<String, dynamic> json) {
    return PosSettings(
      onboardingCompleted: json['onboarding_completed'] as bool?,
      onboardingVersion: (json['onboarding_version'] as num?)?.toInt(),
      operationalSetupCompleted: json['operational_setup_completed'] as bool?,
      businessProfile: json['business_profile'] as String?,
      enabledFeatures:
          (json['enabled_features'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value == true),
          ) ??
          const {},
      pajakPersen: (json['pajak_persen'] as num?)?.toDouble(),
      defaultMetodePembayaran: json['default_metode_pembayaran'] as String?,
      defaultChannelPenjualan: json['default_channel_penjualan'] as String?,
      defaultTipePesanan: json['default_tipe_pesanan'] as String?,
      salesChannelOptions:
          (json['sales_channel_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      defaultPriceLevel: json['default_price_level'] as String?,
      priceLevelOptions:
          (json['price_level_options'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      defaultDiscountPolicy: json['default_discount_policy'] as String?,
      invoicePrefix: json['invoice_prefix'] as String?,
      autoPrintReceipt: json['auto_print_receipt'] as bool?,
      allowOutOfShift: json['allow_out_of_shift'] as bool?,
      allowKasirPriceEdit: json['allow_kasir_price_edit'] as bool?,
      expiredSalePolicy: json['expired_sale_policy'] as String?,
      posLockEnabled: json['pos_lock_enabled'] as bool?,
      posLockOnBackground: json['pos_lock_on_background'] as bool?,
      posAutoLockMinutes: (json['pos_auto_lock_minutes'] as num?)?.toInt(),
      defaultCatatan: json['default_catatan'] as String?,
      minTransaksiTunai: (json['min_transaksi_tunai'] as num?)?.toDouble(),
      pembulatanHarga: json['pembulatan_harga'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'onboarding_completed': onboardingCompleted,
      'onboarding_version': onboardingVersion,
      'operational_setup_completed': operationalSetupCompleted,
      'business_profile': businessProfile,
      'enabled_features': enabledFeatures,
      'pajak_persen': pajakPersen,
      'default_metode_pembayaran': defaultMetodePembayaran,
      'default_channel_penjualan': defaultChannelPenjualan,
      'default_tipe_pesanan': defaultTipePesanan,
      'sales_channel_options': salesChannelOptions,
      'default_price_level': defaultPriceLevel,
      'price_level_options': priceLevelOptions,
      'default_discount_policy': defaultDiscountPolicy,
      'invoice_prefix': invoicePrefix,
      'auto_print_receipt': autoPrintReceipt,
      'allow_out_of_shift': allowOutOfShift,
      'allow_kasir_price_edit': allowKasirPriceEdit,
      'expired_sale_policy': expiredSalePolicy,
      'pos_lock_enabled': posLockEnabled,
      'pos_lock_on_background': posLockOnBackground,
      'pos_auto_lock_minutes': posAutoLockMinutes,
      'default_catatan': defaultCatatan,
      'min_transaksi_tunai': minTransaksiTunai,
      'pembulatan_harga': pembulatanHarga,
    };
  }

  PosSettings copyWith({
    bool? onboardingCompleted,
    int? onboardingVersion,
    bool? operationalSetupCompleted,
    String? businessProfile,
    Map<String, bool>? enabledFeatures,
    double? pajakPersen,
    String? defaultMetodePembayaran,
    String? defaultChannelPenjualan,
    String? defaultTipePesanan,
    List<String>? salesChannelOptions,
    String? defaultPriceLevel,
    List<String>? priceLevelOptions,
    String? defaultDiscountPolicy,
    String? invoicePrefix,
    bool? autoPrintReceipt,
    bool? allowOutOfShift,
    bool? allowKasirPriceEdit,
    String? expiredSalePolicy,
    bool? posLockEnabled,
    bool? posLockOnBackground,
    int? posAutoLockMinutes,
    String? defaultCatatan,
    double? minTransaksiTunai,
    String? pembulatanHarga,
  }) {
    return PosSettings(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      onboardingVersion: onboardingVersion ?? this.onboardingVersion,
      operationalSetupCompleted:
          operationalSetupCompleted ?? this.operationalSetupCompleted,
      businessProfile: businessProfile ?? this.businessProfile,
      enabledFeatures: enabledFeatures ?? this.enabledFeatures,
      pajakPersen: pajakPersen ?? this.pajakPersen,
      defaultMetodePembayaran:
          defaultMetodePembayaran ?? this.defaultMetodePembayaran,
      defaultChannelPenjualan:
          defaultChannelPenjualan ?? this.defaultChannelPenjualan,
      defaultTipePesanan: defaultTipePesanan ?? this.defaultTipePesanan,
      salesChannelOptions: salesChannelOptions ?? this.salesChannelOptions,
      defaultPriceLevel: defaultPriceLevel ?? this.defaultPriceLevel,
      priceLevelOptions: priceLevelOptions ?? this.priceLevelOptions,
      defaultDiscountPolicy:
          defaultDiscountPolicy ?? this.defaultDiscountPolicy,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      allowOutOfShift: allowOutOfShift ?? this.allowOutOfShift,
      allowKasirPriceEdit: allowKasirPriceEdit ?? this.allowKasirPriceEdit,
      expiredSalePolicy: expiredSalePolicy ?? this.expiredSalePolicy,
      posLockEnabled: posLockEnabled ?? this.posLockEnabled,
      posLockOnBackground: posLockOnBackground ?? this.posLockOnBackground,
      posAutoLockMinutes: posAutoLockMinutes ?? this.posAutoLockMinutes,
      defaultCatatan: defaultCatatan ?? this.defaultCatatan,
      minTransaksiTunai: minTransaksiTunai ?? this.minTransaksiTunai,
      pembulatanHarga: pembulatanHarga ?? this.pembulatanHarga,
    );
  }

  @override
  List<Object?> get props => [
    onboardingCompleted,
    onboardingVersion,
    operationalSetupCompleted,
    businessProfile,
    enabledFeatures,
    pajakPersen,
    defaultMetodePembayaran,
    defaultChannelPenjualan,
    defaultTipePesanan,
    salesChannelOptions,
    defaultPriceLevel,
    priceLevelOptions,
    defaultDiscountPolicy,
    invoicePrefix,
    autoPrintReceipt,
    allowOutOfShift,
    allowKasirPriceEdit,
    expiredSalePolicy,
    posLockEnabled,
    posLockOnBackground,
    posAutoLockMinutes,
    defaultCatatan,
    minTransaksiTunai,
    pembulatanHarga,
  ];
}
