import 'package:flutter/material.dart';
import '../../widgets/pos_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PosBarcodeScannerPage extends StatefulWidget {
  const PosBarcodeScannerPage({super.key, this.onScan});

  /// Keep the camera open for inventory workflows. Return a short result
  /// message after the quantity/location dialog is finished.
  final Future<String> Function(String code)? onScan;

  @override
  State<PosBarcodeScannerPage> createState() => _PosBarcodeScannerPageState();
}

class _PosBarcodeScannerPageState extends State<PosBarcodeScannerPage> {
  final _manualCode = TextEditingController();
  bool _busy = false;
  String _feedback = '';
  String? _lastCameraCode;

  @override
  void dispose() {
    _manualCode.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String raw, {bool fromCamera = false}) async {
    final code = raw.trim();
    if (_busy || code.isEmpty) return;
    if (fromCamera && widget.onScan != null && code == _lastCameraCode) {
      return;
    }
    _busy = true;
    if (fromCamera) _lastCameraCode = code;
    if (widget.onScan == null) {
      Navigator.pop(context, code);
      return;
    }
    try {
      final feedback = await widget.onScan!(code);
      if (!mounted) return;
      setState(() => _feedback = feedback);
      _manualCode.clear();
      await Future<void>.delayed(const Duration(milliseconds: 700));
    } catch (_) {
      if (mounted) setState(() => _feedback = 'Scan gagal. Coba lagi.');
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Scan Barcode',
          subtitle: 'Arahkan kamera ke kode produk',
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_busy || capture.barcodes.isEmpty) return;
              final value = capture.barcodes.first.rawValue?.trim();
              if (value == null || value.isEmpty) return;
              _handleCode(value, fromCamera: true);
            },
          ),
          Center(
            child: Container(
              width: 280,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.onScan == null
                      ? 'Arahkan barcode ke dalam bingkai'
                      : 'Scan beruntun aktif · tutup halaman jika selesai',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                if (_feedback.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _feedback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
                if (widget.onScan != null && _lastCameraCode != null)
                  TextButton(
                    onPressed: () => setState(() => _lastCameraCode = null),
                    child: const Text(
                      'Scan ulang kode terakhir',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(
                  controller: _manualCode,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) => _handleCode(value),
                  decoration: InputDecoration(
                    hintText: 'Atau ketik barcode / SKU',
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: 'Gunakan kode',
                      onPressed: () => _handleCode(_manualCode.text),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
