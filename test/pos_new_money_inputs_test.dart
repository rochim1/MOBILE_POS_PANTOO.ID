import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('direct purchase and purchase advance reuse RupiahInputFormatter', () {
    for (final page in ['pos_direct_purchase_page.dart', 'pos_purchase_advance_page.dart']) {
      final source = File('lib/presentation/pages/pos/$page').readAsStringSync();
      expect(source, contains("import '../../../core/utils/rupiah_input_formatter.dart'"));
      expect(source, contains('inputFormatters: const [RupiahInputFormatter()]'));
      expect(source, contains("replaceAll(RegExp(r'[^0-9]'), '')"));
    }
  });
  test('restored direct purchase draft displays a formatted nominal', () {
    final source=File('lib/presentation/pages/pos/pos_direct_purchase_page.dart').readAsStringSync();
    expect(source, contains('formatRupiahInput(parseRupiah(draftAmount))'));
  });
}
