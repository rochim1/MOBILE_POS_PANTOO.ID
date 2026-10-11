import 'dart:ui' as ui;

import 'package:flutter/services.dart';

class PosBusinessPrintBranding {
  const PosBusinessPrintBranding._();

  static Future<Uint8List?> loadCompanyLogo(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    try {
      final data = await NetworkAssetBundle(
        uri,
      ).load(uri.toString()).timeout(const Duration(seconds: 5));
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          final png = await frame.image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          return png?.buffer.asUint8List();
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } catch (_) {
      // A company document remains printable when the logo host is offline.
      return null;
    }
  }
}
