import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosReceiptPrintService {
  static const _printerUrlKey = 'pos.receipt_printer_url';
  static const _printerNameKey = 'pos.receipt_printer_name';
  static const _bluetoothAddressKey = 'pos.receipt_bluetooth_address';
  static const _bluetoothNameKey = 'pos.receipt_bluetooth_name';
  static const _renderModeKey = 'pos.receipt_render_mode';
  static Future<void> _bluetoothPrintQueue = Future<void>.value();

  final SharedPreferences preferences;

  const PosReceiptPrintService(this.preferences);

  String get selectedPrinterUrl =>
      preferences.getString(_printerUrlKey)?.trim() ?? '';

  String get selectedPrinterName =>
      preferences.getString(_printerNameKey)?.trim() ?? '';

  String get selectedBluetoothAddress =>
      preferences.getString(_bluetoothAddressKey)?.trim() ?? '';

  String get selectedBluetoothName =>
      preferences.getString(_bluetoothNameKey)?.trim() ?? '';

  /// `fast` sends template-aware ESC/POS text; `pdf` renders the full visual
  /// template (including logo) before sending it to the printer.
  String get renderMode =>
      preferences.getString(_renderModeKey)?.trim() == 'pdf' ? 'pdf' : 'fast';

  Future<void> setRenderMode(String mode) async {
    await preferences.setString(
      _renderModeKey,
      mode == 'pdf' ? 'pdf' : 'fast',
    );
  }

  bool get hasConfiguredPrinter =>
      selectedBluetoothAddress.isNotEmpty || selectedPrinterUrl.isNotEmpty;

  Future<void> selectPrinter(Printer? printer) async {
    if (printer == null) {
      await preferences.remove(_printerUrlKey);
      await preferences.remove(_printerNameKey);
      return;
    }
    await preferences.remove(_bluetoothAddressKey);
    await preferences.remove(_bluetoothNameKey);
    await preferences.setString(_printerUrlKey, printer.url);
    await preferences.setString(_printerNameKey, printer.name);
  }

  /// Opens the native Bluetooth device picker and persists the selected
  /// printer on this terminal. Classic SPP and BLE devices are handled by the
  /// plugin; no system print driver is required.
  Future<bool> selectBluetoothPrinter(BuildContext context) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final device = await FlutterBluetoothPrinter.selectDevice(context);
    if (device == null) return false;
    await preferences.remove(_printerUrlKey);
    await preferences.remove(_printerNameKey);
    await preferences.setString(_bluetoothAddressKey, device.address);
    await preferences.setString(
      _bluetoothNameKey,
      (device.name ?? '').trim().isEmpty ? device.address : device.name!,
    );
    return true;
  }

  Future<void> clearBluetoothPrinter() async {
    await preferences.remove(_bluetoothAddressKey);
    await preferences.remove(_bluetoothNameKey);
  }

  Future<List<Printer>> availablePrinters() async {
    if (kIsWeb) return const [];
    final info = await Printing.info();
    if (!info.canListPrinters) return const [];
    final printers = await Printing.listPrinters();
    printers.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return printers.where((printer) => printer.isAvailable).toList();
  }

  Future<bool> printPdf({
    required Uint8List bytes,
    required String name,
    required PdfPageFormat format,
    bool useConfiguredPrinter = true,
  }) async {
    // On Android a receipt must not silently open the generic system dialog:
    // that dialog normally exposes Wi-Fi printers and cannot drive a small
    // Bluetooth ESC/POS printer. The user must explicitly select a device in
    // POS Printer Settings first.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !hasConfiguredPrinter) {
      throw StateError('PRINTER_NOT_CONFIGURED');
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        selectedBluetoothAddress.isNotEmpty) {
      try {
        final raster = await Printing.raster(
          bytes,
          pages: const [0],
          dpi: 203,
        ).first.timeout(const Duration(seconds: 20));
        final png = await raster.toPng();
        final codec = await ui.instantiateImageCodec(png);
        final frame = await codec.getNextFrame();
        final paperSize = format.width > 190 ? PaperSize.mm80 : PaperSize.mm58;
        final success = await FlutterBluetoothPrinter.printImageSingle(
          address: selectedBluetoothAddress,
          imageBytes: png,
          imageWidth: frame.image.width,
          imageHeight: frame.image.height,
          paperSize: paperSize,
          keepConnected: true,
          addFeeds: 3,
        ).timeout(const Duration(seconds: 45));
        await FlutterBluetoothPrinter.disconnect(selectedBluetoothAddress);
        frame.image.dispose();
        codec.dispose();
        if (success) return true;
        throw StateError('Printer Bluetooth menolak data struk');
      } catch (_) {
        // Do not silently print to a different device. If Bluetooth dipilih,
        // surface the error to the caller instead of opening a PDF dialog.
        rethrow;
      }
    }
    if (!kIsWeb && useConfiguredPrinter && selectedPrinterUrl.isNotEmpty) {
      try {
        final printer = (await availablePrinters()).cast<Printer?>().firstWhere(
          (candidate) => candidate?.url == selectedPrinterUrl,
          orElse: () => null,
        );
        if (printer != null) {
          return await Printing.directPrintPdf(
            printer: printer,
            name: name,
            format: format,
            onLayout: (_) async => bytes,
          );
        }
      } catch (_) {
        // Driver/printer yang tersimpan dapat hilang. Dialog sistem adalah
        // fallback aman agar kasir tetap bisa menyelesaikan pencetakan.
      }
    }

    return Printing.layoutPdf(
      name: name,
      format: format,
      onLayout: (_) async => bytes,
    );
  }

  /// Fast path for small Bluetooth thermal printers. Sending plain ESC/POS
  /// text avoids the expensive PDF -> raster image conversion and is much
  /// more reliable on mini 58/80 mm printers. The PDF path remains available
  /// for Wi-Fi/system printers and sharing.
  Future<bool> printText({
    required String text,
    int addFeeds = 3,
    int charactersPerLine = 32,
  }) async {
    if (selectedBluetoothAddress.isEmpty) {
      throw StateError('PRINTER_NOT_CONFIGURED');
    }
    final previous = _bluetoothPrintQueue;
    final current = previous.then<bool>(
      (_) => _printTextOnce(
        text: text,
        addFeeds: addFeeds,
        charactersPerLine: charactersPerLine,
      ),
    );
    _bluetoothPrintQueue = current.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return current;
  }

  Future<bool> _printTextOnce({
    required String text,
    required int addFeeds,
    required int charactersPerLine,
  }) async {
    final normalized = text.replaceAll('\r\n', '\n').trimRight();
    final lines = normalized.split('\n');
    final data = <int>[0x1B, 0x40]; // initialize
    var centered = false;
    var footer = false;
    for (final sourceLine in lines) {
      final lineParts = sourceLine == '[[PANTOO_CENTER_FOOTER]]'
          ? [sourceLine]
          : _wrapLine(sourceLine, charactersPerLine);
      for (final line in lineParts) {
        if (line == '[[PANTOO_CENTER_FOOTER]]') {
          footer = true;
          if (!centered) data.addAll(const [0x1B, 0x61, 0x01]);
          centered = true;
          continue;
        }
        final isDivider = line.startsWith('---');
        if (!footer && !isDivider && !centered) {
          data.addAll(const [0x1B, 0x61, 0x01]); // center header
          centered = true;
        }
        if (!footer && isDivider && centered) {
          data.addAll(const [0x1B, 0x61, 0x00]); // left body
          centered = false;
        }
        data.addAll(utf8.encode(line));
        data.add(0x0A);
      }
    }
    data.addAll(const [0x1B, 0x61, 0x00]);
    data.addAll(List<int>.filled(addFeeds + 1, 0x0A));
    data.addAll(const [0x1B, 0x64, 0x03]); // feed before disconnect
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (attempt > 0) {
          await FlutterBluetoothPrinter.disconnect(selectedBluetoothAddress);
          await Future<void>.delayed(const Duration(milliseconds: 350));
        }
        final success = await FlutterBluetoothPrinter.printBytes(
          address: selectedBluetoothAddress,
          data: Uint8List.fromList(data),
          // Keep the native connection until the write has completed, then
          // close it ourselves. This avoids the second-print close race.
          keepConnected: true,
          maxBufferSize: 512,
          delayTime: 60,
        ).timeout(const Duration(seconds: 12));
        await FlutterBluetoothPrinter.disconnect(selectedBluetoothAddress);
        if (success) return true;
        lastError = StateError('Printer Bluetooth menolak data struk');
      } catch (error) {
        lastError = error;
        try {
          await FlutterBluetoothPrinter.disconnect(selectedBluetoothAddress);
        } catch (_) {}
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    throw lastError ?? StateError('Printer Bluetooth tidak merespons');
  }

  List<String> _wrapLine(String value, int width) {
    if (width < 8 || value.length <= width) return [value];
    final words = value.split(RegExp(r'\s+'));
    final result = <String>[];
    var current = '';
    for (final word in words) {
      if (word.isEmpty) continue;
      if (current.isNotEmpty && current.length + word.length + 1 > width) {
        result.add(current);
        current = '';
      }
      if (current.isEmpty && word.length > width) {
        for (var i = 0; i < word.length; i += width) {
          final end = i + width < word.length ? i + width : word.length;
          result.add(word.substring(i, end));
        }
      } else {
        current = current.isEmpty ? word : '$current $word';
      }
    }
    if (current.isNotEmpty) result.add(current);
    return result.isEmpty ? [''] : result;
  }
}
