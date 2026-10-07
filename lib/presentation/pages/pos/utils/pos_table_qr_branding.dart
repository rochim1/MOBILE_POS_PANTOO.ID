import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../../../domain/repositories/pos_receipt_repository.dart';
import '../../../../injections.dart';

class PosTableQrBranding {
  const PosTableQrBranding._();

  static Future<Uint8List> loadLogoPng() async {
    try {
      final printData = await sl<PosReceiptRepository>()
          .getReceiptPrintData()
          .timeout(const Duration(seconds: 5));
      final logoUrl = printData.fold<String>(
        (_) => '',
        (data) => data.company['logo'] ?? '',
      );
      final uri = Uri.tryParse(logoUrl);
      if (uri != null && uri.hasScheme && uri.host.isNotEmpty) {
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
            if (png != null) return png.buffer.asUint8List();
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }
    } catch (_) {
      // QR must remain printable even when the company logo is unavailable.
    }
    final fallback = await rootBundle.load('assets/images/pantoo.png');
    return fallback.buffer.asUint8List(
      fallback.offsetInBytes,
      fallback.lengthInBytes,
    );
  }
}
