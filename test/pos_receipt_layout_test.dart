import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:mobile_pos_pantoo/core/receipt/pos_receipt_document_builder.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_receipt_template.dart';

const receiptData = PosReceiptDocumentData(
  invoice: 'PANTOO-20261126-0003',
  dateLabel: '26/11/2026 00:08',
  cashierName: 'Rochim',
  storeName: 'Toko Bandung [Dummy]',
  shiftReference: '6b074e24c0565aed26c71ae8',
  transactionReference: 'df4adb55-648e-42cc-a01c-143ab59b9dc9',
  paymentMethod: 'tunai',
  orderType: 'take_away',
  subtotal: 16500,
  total: 16500,
  cashReceived: 20000,
  change: 3500,
  items: [
    {
      'nama_inventaris': 'Air Mineral 600 ml [Dummy]',
      'qty': 3.0,
      'harga_jual': 5500,
      'subtotal': 16500,
    },
  ],
);
const receiptTemplate = PosReceiptTemplate(
  showLogo: false,
  headerTitle: '{{nama_instansi}}',
  headerSubtitle: 'Retail Multi Cabang',
  headerLine3: 'Jakarta / Bandung / Surabaya',
  headerLine4: 'DATA SIMULASI',
  footerLine1: 'Terima kasih',
  paperWidth: 58,
  fontSize: 12,
);
const receiptCompany = {'nama_instansi': 'Pantoo 123 [Dummy]'};

List<double> fontSizes(Uint8List bytes) {
  final encoded = latin1.decode(bytes);
  final sizes = <double>[];
  for (final stream in RegExp(
    r'stream\r?\n([\s\S]*?)\r?\nendstream',
  ).allMatches(encoded)) {
    final compressed = latin1.encode(stream[1]!);
    String content;
    try {
      content = latin1.decode(zlib.decode(compressed));
    } catch (_) {
      content = stream[1]!;
    }
    sizes.addAll(
      RegExp(
        r'/\w+\s+([\d.]+)\s+Tf',
      ).allMatches(content).map((m) => double.parse(m[1]!)),
    );
  }
  return sizes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'customer thermal receipt excludes internal recovery identities but retains trace data',
    () {
      final text = PosReceiptDocumentBuilder.buildThermalText(
        data: receiptData,
        template: receiptTemplate,
        company: receiptCompany,
      );
      expect(text, isNot(contains(receiptData.shiftReference)));
      expect(text, isNot(contains(receiptData.transactionReference)));
      expect(text, contains(receiptData.invoice));
      expect(text, contains('Rochim'));
      expect(text, contains('Toko Bandung'));
      expect(text, contains('Rp 16.500'));
      expect(text, contains('Rp 20.000'));
      expect(text, contains('Rp 3.500'));
      expect(text, contains('3 x Rp 5.500'));
      expect(receiptData.shiftReference, '6b074e24c0565aed26c71ae8');
    },
  );
  for (final font in [null, 12, 18]) {
    test('58mm PDF remains compact with saved/default font $font', () async {
      final template = font == null
          ? const PosReceiptTemplate(paperWidth: 58, showLogo: false)
          : receiptTemplate.copyWith(fontSize: font);
      final bytes = await PosReceiptDocumentBuilder.build(
        data: receiptData,
        template: template,
        company: receiptCompany,
      );
      final sizes = fontSizes(bytes);
      expect(sizes, isNotEmpty, reason: 'Read actual PDF text font operations');
      expect(sizes.reduce(math.max), lessThanOrEqualTo(11));
    });
  }
  test('whole-unit quantities do not waste narrow receipt space', () {
    final text = PosReceiptDocumentBuilder.buildThermalText(
      data: receiptData,
      template: receiptTemplate,
      company: receiptCompany,
    );
    expect(text, contains('3 x Rp 5.500'));
    expect(text, isNot(contains('3.0 x')));
  });
  test(
    'short receipt uses content height rather than a fixed long page',
    () async {
      final bytes = await PosReceiptDocumentBuilder.build(
        data: receiptData,
        template: receiptTemplate,
        company: receiptCompany,
      );
      final box = RegExp(
        r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]',
      ).firstMatch(latin1.decode(bytes));
      expect(box, isNotNull);
      expect(double.parse(box![2]!), lessThan(140 * PdfPageFormat.mm));
    },
  );
  test('58mm print area keeps safe margins while 80mm remains wider', () {
    final small = PosReceiptDocumentBuilder.pageFormatFor(receiptTemplate, 1);
    final large = PosReceiptDocumentBuilder.pageFormatFor(
      receiptTemplate.copyWith(paperWidth: 80),
      1,
    );
    expect(small.width, closeTo(58 * PdfPageFormat.mm, 0.01));
    expect(small.availableWidth, greaterThanOrEqualTo(48 * PdfPageFormat.mm));
    expect(small.marginLeft, greaterThanOrEqualTo(3 * PdfPageFormat.mm));
    expect(large.availableWidth, greaterThan(small.availableWidth));
  });
  test('thermal money columns fit a 32-character 58mm printer', () {
    const data = PosReceiptDocumentData(
      invoice: 'INV-1',
      dateLabel: '26/11/2026',
      paymentMethod: 'tunai',
      subtotal: 123456789,
      total: 123456789,
      items: [
        {
          'name': 'Produk',
          'qty': 1,
          'harga_jual': 123456789,
          'subtotal': 123456789,
        },
      ],
    );
    final text = PosReceiptDocumentBuilder.buildThermalText(
      data: data,
      template: receiptTemplate,
      company: receiptCompany,
    );
    final amounts = text
        .split('\n')
        .where((line) => line.contains('123.456.789'));
    expect(amounts, isNotEmpty);
    expect(amounts.every((line) => line.length <= 32), isTrue);
  });
  test(
    'long product and large amounts keep a complete dynamic receipt',
    () async {
      final items = List.generate(
        12,
        (i) => {
          'name': 'Layanan perawatan produk dengan nama panjang nomor ${i + 1}',
          'qty': 1.0,
          'harga_jual': 123456789,
          'subtotal': 123456789,
        },
      );
      final data = PosReceiptDocumentData(
        invoice: 'PANTOO-LONG-20261126',
        dateLabel: '26/11/2026 08:00',
        paymentMethod: 'tunai',
        subtotal: 1481481468,
        total: 1481481468,
        cashReceived: 1500000000,
        change: 18518532,
        items: items,
      );
      final bytes = await PosReceiptDocumentBuilder.build(
        data: data,
        template: receiptTemplate,
        company: receiptCompany,
      );
      expect(bytes.length, greaterThan(500));
      final box = RegExp(
        r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)\s*\]',
      ).firstMatch(latin1.decode(bytes));
      expect(double.parse(box![2]!), greaterThan(140 * PdfPageFormat.mm));
      final directory = Platform.environment['POS_RECEIPT_FIXTURES'];
      if (directory != null) {
        await Directory(directory).create(recursive: true);
        await File('$directory/receipt-58-long.pdf').writeAsBytes(bytes);
      }
    },
  );
  test(
    'generate real PDF fixtures for visual and text inspection when requested',
    () async {
      final directory = Platform.environment['POS_RECEIPT_FIXTURES'];
      for (final width in [58, 80]) {
        final template = receiptTemplate.copyWith(paperWidth: width);
        final bytes = await PosReceiptDocumentBuilder.build(
          data: receiptData,
          template: template,
          company: receiptCompany,
        );
        expect(bytes.length, greaterThan(500));
        if (directory != null) {
          await Directory(directory).create(recursive: true);
          await File('$directory/receipt-$width.pdf').writeAsBytes(bytes);
        }
      }
    },
  );
}
