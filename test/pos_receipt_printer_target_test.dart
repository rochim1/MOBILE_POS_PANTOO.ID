import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/receipt/pos_receipt_print_service.dart';

class _Driver extends PosReceiptPrintService {
  _Driver(super.preferences, this.change);
  final bool change;
  @override
  Future<List<Printer>> availablePrinters() async {
    if (change) {
      await preferences.setString('pos.receipt_printer_url', 'driver-b');
    }
    return const [Printer(url: 'driver-a'), Printer(url: 'driver-b')];
  }
}

void main() {
  for (final change in [false, true]) {
    testWidgets(
      'driver receipt uses original target or safely aborts: changed=$change',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        SharedPreferences.setMockInitialValues({
          'pos.receipt_printer_url': 'driver-a',
        });
        final prefs = await SharedPreferences.getInstance();
        final printed = <String>[];
        const channel = MethodChannel('net.nfet.printing');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'printPdf') {
              final args = call.arguments as Map;
              printed.add(args['printer'] as String);
              ServicesBinding.instance.channelBuffers.push(
                'net.nfet.printing',
                const StandardMethodCodec().encodeMethodCall(
                  MethodCall('onCompleted', {
                    'job': args['job'],
                    'completed': true,
                  }),
                ),
                (_) {},
              );
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await tester.runAsync(() async {
          final result = _Driver(prefs, change).printPdf(
            bytes: Uint8List.fromList([1]),
            name: 'fixture',
            format: PdfPageFormat.roll57,
          );
          if (change) {
            await expectLater(result, throwsA(isA<StateError>()));
          } else {
            expect(await result, true);
          }
        });
        expect(printed, change ? isEmpty : ['driver-a']);
        debugDefaultTargetPlatformOverride = null;
      },
    );
  }
}
