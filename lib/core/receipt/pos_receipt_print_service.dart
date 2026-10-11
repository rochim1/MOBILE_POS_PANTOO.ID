import 'dart:async';
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
    await preferences.setString(_renderModeKey, mode == 'pdf' ? 'pdf' : 'fast');
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
      ui.Codec? codec;
      ui.FrameInfo? frame;
      try {
        final raster = await Printing.raster(
          bytes,
          pages: const [0],
          dpi: 203,
        ).first.timeout(const Duration(seconds: 20));
        final png = await raster.toPng();
        codec = await ui.instantiateImageCodec(png);
        frame = await codec.getNextFrame();
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
        if (success) return true;
        throw StateError('Printer Bluetooth menolak data struk');
      } catch (error) {
        // A timeout/error can occur after bytes reached the printer. Never
        // retry or switch devices automatically for this document.
        throw StateError(
          'Status cetak Bluetooth tidak pasti. Periksa kertas printer sebelum mengulang. $error',
        );
      } finally {
        try {
          await FlutterBluetoothPrinter.disconnect(
            selectedBluetoothAddress,
          ).timeout(const Duration(seconds: 2));
        } catch (_) {}
        frame?.image.dispose();
        codec?.dispose();
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
        throw StateError(
          'Printer terminal tersimpan tidak tersedia. Pilih ulang printer di Pengaturan Printer.',
        );
      } catch (error) {
        // Never switch to a different printer without the operator choosing
        // it. A driver error may occur after a job has already been queued.
        throw StateError(
          'Status cetak tidak pasti pada printer terminal. Periksa hasil cetak sebelum mengulang. $error',
        );
      }
    }

    return Printing.layoutPdf(
      name: name,
      format: format,
      onLayout: (_) async => bytes,
    );
  }

  /// A4 purchase documents use Android's system print dialog. The operator
  /// chooses the actual A4 printer there; it is separate from the POS thermal
  /// printer and must never fall back to it automatically.
  Future<bool> printDocumentPdf({
    required Uint8List bytes,
    required String name,
  }) => Printing.layoutPdf(
    name: name,
    format: PdfPageFormat.a4,
    onLayout: (_) async => bytes,
  );

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
    // A timeout does not prove that the printer received nothing. Retrying the
    // same bytes automatically can produce a second PO/payment receipt.
    try {
      final success = await FlutterBluetoothPrinter.printBytes(
        address: selectedBluetoothAddress,
        data: Uint8List.fromList(data),
        // Keep the native connection until the write has completed, then
        // close it ourselves. This avoids the second-print close race.
        keepConnected: true,
        maxBufferSize: 512,
        delayTime: 60,
      ).timeout(const Duration(seconds: 12));
      if (!success) {
        throw StateError(
          'Status cetak tidak pasti. Periksa kertas printer sebelum mencetak ulang.',
        );
      }
      return true;
    } on TimeoutException {
      throw StateError(
        'Status cetak tidak pasti. Printer tidak merespons tepat waktu; periksa hasil cetak sebelum mengulang.',
      );
    } catch (error) {
      if (error is StateError) rethrow;
      throw StateError(
        'Status cetak tidak pasti. Periksa hasil cetak sebelum mengulang. $error',
      );
    } finally {
      try {
        await FlutterBluetoothPrinter.disconnect(
          selectedBluetoothAddress,
        ).timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
  }

  List<String> _wrapLine(String value, int width) {
    if (width < 8 || value.length <= width) return [value];
    final result = <String>[];
    var offset = 0;
    while (offset < value.length) {
      final end = offset + width < value.length ? offset + width : value.length;
      if (end == value.length) {
        result.add(value.substring(offset));
        break;
      }
      // Preserve spaces used for columns and indentation. Wrapping at a
      // whitespace boundary must never normalize or discard them.
      final breakAt = value.lastIndexOf(' ', end);
      final split = breakAt > offset ? breakAt + 1 : end;
      result.add(value.substring(offset, split));
      offset = split;
    }
    return result.isEmpty ? [''] : result;
  }
}
