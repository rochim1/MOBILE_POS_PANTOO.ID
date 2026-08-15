import 'package:equatable/equatable.dart';

class PosReceiptTemplate extends Equatable {
  final bool? showLogo;
  final String? headerTitle;
  final String? headerSubtitle;
  final String? headerLine3;
  final String? headerLine4;
  final bool? showInvoice;
  final bool? showTanggal;
  final bool? showKasir;
  final bool? showToko;
  final bool? showPelanggan;
  final bool? showChannel;
  final bool? showSegment;
  final bool? showPromo;
  final String? footerLine1;
  final String? footerLine2;
  final String? footerLine3;
  final int? paperWidth;
  final int? fontSize;
  final String? customCss;

  const PosReceiptTemplate({
    this.showLogo,
    this.headerTitle,
    this.headerSubtitle,
    this.headerLine3,
    this.headerLine4,
    this.showInvoice,
    this.showTanggal,
    this.showKasir,
    this.showToko,
    this.showPelanggan,
    this.showChannel,
    this.showSegment,
    this.showPromo,
    this.footerLine1,
    this.footerLine2,
    this.footerLine3,
    this.paperWidth,
    this.fontSize,
    this.customCss,
  });

  factory PosReceiptTemplate.fromJson(Map<String, dynamic> json) {
    return PosReceiptTemplate(
      showLogo: json['show_logo'] as bool?,
      headerTitle: json['header_title'] as String?,
      headerSubtitle: json['header_subtitle'] as String?,
      headerLine3: json['header_line3'] as String?,
      headerLine4: json['header_line4'] as String?,
      showInvoice: json['show_invoice'] as bool?,
      showTanggal: json['show_tanggal'] as bool?,
      showKasir: json['show_kasir'] as bool?,
      showToko: json['show_toko'] as bool?,
      showPelanggan: json['show_pelanggan'] as bool?,
      showChannel: json['show_channel'] as bool?,
      showSegment: json['show_segment'] as bool?,
      showPromo: json['show_promo'] as bool?,
      footerLine1: json['footer_line1'] as String?,
      footerLine2: json['footer_line2'] as String?,
      footerLine3: json['footer_line3'] as String?,
      paperWidth: json['paper_width'] as int?,
      fontSize: json['font_size'] as int?,
      customCss: json['custom_css'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_logo': showLogo,
      'header_title': headerTitle,
      'header_subtitle': headerSubtitle,
      'header_line3': headerLine3,
      'header_line4': headerLine4,
      'show_invoice': showInvoice,
      'show_tanggal': showTanggal,
      'show_kasir': showKasir,
      'show_toko': showToko,
      'show_pelanggan': showPelanggan,
      'show_channel': showChannel,
      'show_segment': showSegment,
      'show_promo': showPromo,
      'footer_line1': footerLine1,
      'footer_line2': footerLine2,
      'footer_line3': footerLine3,
      'paper_width': paperWidth,
      'font_size': fontSize,
      'custom_css': customCss,
    };
  }

  PosReceiptTemplate copyWith({
    bool? showLogo,
    String? headerTitle,
    String? headerSubtitle,
    String? headerLine3,
    String? headerLine4,
    bool? showInvoice,
    bool? showTanggal,
    bool? showKasir,
    bool? showToko,
    bool? showPelanggan,
    bool? showChannel,
    bool? showSegment,
    bool? showPromo,
    String? footerLine1,
    String? footerLine2,
    String? footerLine3,
    int? paperWidth,
    int? fontSize,
    String? customCss,
  }) {
    return PosReceiptTemplate(
      showLogo: showLogo ?? this.showLogo,
      headerTitle: headerTitle ?? this.headerTitle,
      headerSubtitle: headerSubtitle ?? this.headerSubtitle,
      headerLine3: headerLine3 ?? this.headerLine3,
      headerLine4: headerLine4 ?? this.headerLine4,
      showInvoice: showInvoice ?? this.showInvoice,
      showTanggal: showTanggal ?? this.showTanggal,
      showKasir: showKasir ?? this.showKasir,
      showToko: showToko ?? this.showToko,
      showPelanggan: showPelanggan ?? this.showPelanggan,
      showChannel: showChannel ?? this.showChannel,
      showSegment: showSegment ?? this.showSegment,
      showPromo: showPromo ?? this.showPromo,
      footerLine1: footerLine1 ?? this.footerLine1,
      footerLine2: footerLine2 ?? this.footerLine2,
      footerLine3: footerLine3 ?? this.footerLine3,
      paperWidth: paperWidth ?? this.paperWidth,
      fontSize: fontSize ?? this.fontSize,
      customCss: customCss ?? this.customCss,
    );
  }

  @override
  List<Object?> get props => [
    showLogo,
    headerTitle,
    headerSubtitle,
    headerLine3,
    headerLine4,
    showInvoice,
    showTanggal,
    showKasir,
    showToko,
    showPelanggan,
    showChannel,
    showSegment,
    showPromo,
    footerLine1,
    footerLine2,
    footerLine3,
    paperWidth,
    fontSize,
    customCss,
  ];
}
