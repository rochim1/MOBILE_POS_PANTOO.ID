import 'package:equatable/equatable.dart';

class PosSettings extends Equatable {
  final double? pajakPersen;
  final String? defaultMetodePembayaran;
  final String? defaultChannelPenjualan;
  final List<String> salesChannelOptions;
  final String? defaultPriceLevel;
  final List<String> priceLevelOptions;
  final String? defaultDiscountPolicy;
  final String? invoicePrefix;
  final bool? autoPrintReceipt;
  final bool? allowOutOfShift;
  final bool? allowKasirPriceEdit;
  final String? defaultCatatan;
  final double? minTransaksiTunai;
  final String? pembulatanHarga;

  const PosSettings({
    this.pajakPersen,
    this.defaultMetodePembayaran,
    this.defaultChannelPenjualan,
    this.salesChannelOptions = const [],
    this.defaultPriceLevel,
    this.priceLevelOptions = const [],
    this.defaultDiscountPolicy,
    this.invoicePrefix,
    this.autoPrintReceipt,
    this.allowOutOfShift,
    this.allowKasirPriceEdit,
    this.defaultCatatan,
    this.minTransaksiTunai,
    this.pembulatanHarga,
  });

  factory PosSettings.fromJson(Map<String, dynamic> json) {
    return PosSettings(
      pajakPersen: (json['pajak_persen'] as num?)?.toDouble(),
      defaultMetodePembayaran: json['default_metode_pembayaran'] as String?,
      defaultChannelPenjualan: json['default_channel_penjualan'] as String?,
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
      defaultCatatan: json['default_catatan'] as String?,
      minTransaksiTunai: (json['min_transaksi_tunai'] as num?)?.toDouble(),
      pembulatanHarga: json['pembulatan_harga'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pajak_persen': pajakPersen,
      'default_metode_pembayaran': defaultMetodePembayaran,
      'default_channel_penjualan': defaultChannelPenjualan,
      'sales_channel_options': salesChannelOptions,
      'default_price_level': defaultPriceLevel,
      'price_level_options': priceLevelOptions,
      'default_discount_policy': defaultDiscountPolicy,
      'invoice_prefix': invoicePrefix,
      'auto_print_receipt': autoPrintReceipt,
      'allow_out_of_shift': allowOutOfShift,
      'allow_kasir_price_edit': allowKasirPriceEdit,
      'default_catatan': defaultCatatan,
      'min_transaksi_tunai': minTransaksiTunai,
      'pembulatan_harga': pembulatanHarga,
    };
  }

  PosSettings copyWith({
    double? pajakPersen,
    String? defaultMetodePembayaran,
    String? defaultChannelPenjualan,
    List<String>? salesChannelOptions,
    String? defaultPriceLevel,
    List<String>? priceLevelOptions,
    String? defaultDiscountPolicy,
    String? invoicePrefix,
    bool? autoPrintReceipt,
    bool? allowOutOfShift,
    bool? allowKasirPriceEdit,
    String? defaultCatatan,
    double? minTransaksiTunai,
    String? pembulatanHarga,
  }) {
    return PosSettings(
      pajakPersen: pajakPersen ?? this.pajakPersen,
      defaultMetodePembayaran:
          defaultMetodePembayaran ?? this.defaultMetodePembayaran,
      defaultChannelPenjualan:
          defaultChannelPenjualan ?? this.defaultChannelPenjualan,
      salesChannelOptions: salesChannelOptions ?? this.salesChannelOptions,
      defaultPriceLevel: defaultPriceLevel ?? this.defaultPriceLevel,
      priceLevelOptions: priceLevelOptions ?? this.priceLevelOptions,
      defaultDiscountPolicy:
          defaultDiscountPolicy ?? this.defaultDiscountPolicy,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      allowOutOfShift: allowOutOfShift ?? this.allowOutOfShift,
      allowKasirPriceEdit: allowKasirPriceEdit ?? this.allowKasirPriceEdit,
      defaultCatatan: defaultCatatan ?? this.defaultCatatan,
      minTransaksiTunai: minTransaksiTunai ?? this.minTransaksiTunai,
      pembulatanHarga: pembulatanHarga ?? this.pembulatanHarga,
    );
  }

  @override
  List<Object?> get props => [
    pajakPersen,
    defaultMetodePembayaran,
    defaultChannelPenjualan,
    salesChannelOptions,
    defaultPriceLevel,
    priceLevelOptions,
    defaultDiscountPolicy,
    invoicePrefix,
    autoPrintReceipt,
    allowOutOfShift,
    allowKasirPriceEdit,
    defaultCatatan,
    minTransaksiTunai,
    pembulatanHarga,
  ];
}
