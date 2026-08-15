import 'package:flutter/material.dart';
import '../../widgets/pos_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PosBarcodeScannerPage extends StatefulWidget {
  const PosBarcodeScannerPage({super.key});

  @override
  State<PosBarcodeScannerPage> createState() => _PosBarcodeScannerPageState();
}

class _PosBarcodeScannerPageState extends State<PosBarcodeScannerPage> {
  bool _handled = false;

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
              if (_handled || capture.barcodes.isEmpty) return;
              final value = capture.barcodes.first.rawValue?.trim();
              if (value == null || value.isEmpty) return;
              _handled = true;
              Navigator.pop(context, value);
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
          const Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: Text(
              'Arahkan barcode ke dalam bingkai',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
