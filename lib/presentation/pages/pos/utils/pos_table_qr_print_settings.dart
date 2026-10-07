import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PosTableQrPrintSettings {
  const PosTableQrPrintSettings({
    this.title = 'Scan & Pesan',
    this.subtitle = 'Arahkan kamera HP Anda ke QR Code untuk melihat menu',
    this.useLogo = true,
    this.orientation = 'portrait',
    this.theme = 'light',
  });

  final String title;
  final String subtitle;
  final bool useLogo;
  final String orientation;
  final String theme;

  static const _orientations = {'portrait', 'landscape'};
  static const _themes = {'light', 'dark', 'primary'};

  PosTableQrPrintSettings copyWith({
    String? title,
    String? subtitle,
    bool? useLogo,
    String? orientation,
    String? theme,
  }) => PosTableQrPrintSettings(
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    useLogo: useLogo ?? this.useLogo,
    orientation: orientation ?? this.orientation,
    theme: theme ?? this.theme,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'useLogo': useLogo,
    'orientation': orientation,
    'theme': theme,
  };

  factory PosTableQrPrintSettings.fromJson(Map<String, dynamic> json) =>
      PosTableQrPrintSettings(
        title: (json['title'] as String?)?.trim() ?? 'Scan & Pesan',
        subtitle:
            (json['subtitle'] as String?)?.trim() ??
            'Arahkan kamera HP Anda ke QR Code untuk melihat menu',
        useLogo: json['useLogo'] != false,
        orientation: _orientations.contains(json['orientation'])
            ? json['orientation'] as String
            : 'portrait',
        theme: _themes.contains(json['theme'])
            ? json['theme'] as String
            : 'light',
      );

  static String _key(String instansiId) =>
      'pos_table_qr_print_settings:$instansiId';

  static PosTableQrPrintSettings load(
    SharedPreferences preferences,
    String instansiId,
  ) {
    final raw = preferences.getString(_key(instansiId));
    if (raw == null) return const PosTableQrPrintSettings();
    try {
      return PosTableQrPrintSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return const PosTableQrPrintSettings();
    }
  }

  Future<bool> save(SharedPreferences preferences, String instansiId) =>
      preferences.setString(_key(instansiId), jsonEncode(toJson()));
}
