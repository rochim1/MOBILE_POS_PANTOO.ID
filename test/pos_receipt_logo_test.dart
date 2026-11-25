import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/receipt/pos_receipt_document_builder.dart';
import 'package:mobile_pos_pantoo/core/receipt/pos_receipt_print_service.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_receipt_template.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_business_profile_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'pos_receipt_layout_test.dart' show receiptData;

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  late GraphQLClient client;
  @override
  String subscriptionScope = 'endpoint|tenant|user|operator';
  @override
  String resolveMediaUrl(dynamic value) => value == null || value == ''
      ? ''
      : Uri.parse('https://fixture.invalid/').resolve('$value').toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Provider provider;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'pos.receipt_bluetooth_address': 'fixture-printer',
    });
    prefs = await SharedPreferences.getInstance();
    provider = _Provider();
  });
  void respond(Map<String, dynamic> data) {
    provider.client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield Response(data: data, response: {});
      }),
    );
  }
  const receipt = {
    'GetPOSReceiptData': {
      'template': {'show_logo': true, 'paper_width': 58},
      'instansi': {'nama_instansi': 'Old', 'logo': '/old.png'},
    },
  };
  test('saved business logo and removal immediately update cached receipt', () async {
    respond(receipt);
    final receipts = PosReceiptRepository(provider);
    await receipts.preloadReceiptPrintData();
    final business = PosBusinessProfileRepository(
      provider, prefs,
      onSaved: (profile) => receipts.updateCompany({
        'nama_instansi': profile.name, 'logo': profile.logo,
      }),
    );
    for (final logo in ['/new.png', null]) {
      respond({'UpdateMyPOSBusinessProfile': {
        '_id': 'tenant', 'name': 'New', 'phone': '08123456789', 'logo': logo,
      }});
      expect((await business.save(name: 'New', phone: '08123456789',
        removeLogo: logo == null)).isRight(), true);
      final data = (await receipts.getReceiptPrintData()).getOrElse(() => throw StateError('failed'));
      expect(data.company['logo'], logo == null ? '' : 'https://fixture.invalid/new.png');
      expect(data.company['nama_instansi'], 'New');
      expect(data.template.showLogo, true);
    }
  });
  test('receipt cache must not leak logo into a different tenant or account', () async {
    respond(receipt);
    final receipts = PosReceiptRepository(provider);
    await receipts.getReceiptPrintData();
    provider.subscriptionScope = 'endpoint|other|user|operator';
    respond({'GetPOSReceiptData': {'template': {}, 'instansi': {'logo': '/other.png'}}});
    final data = (await receipts.getReceiptPrintData()).getOrElse(() => throw StateError('failed'));
    expect(data.company['logo'], 'https://fixture.invalid/other.png');
  });
  test('slow old receipt response must not overwrite saved business logo', () async {
    respond(receipt);
    final receipts = PosReceiptRepository(provider);
    await receipts.getReceiptPrintData();
    final completer = Completer<void>();
    provider.client = GraphQLClient(cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        await completer.future;
        yield const Response(data: receipt, response: {});
      }));
    final pending = receipts.getReceiptPrintData(forceRefresh: true);
    await Future<void>.delayed(Duration.zero);
    receipts.updateCompany({'logo': 'https://fixture.invalid/new.png'});
    completer.complete();
    await pending;
    final data = (await receipts.getReceiptPrintData()).getOrElse(() => throw StateError('failed'));
    expect(data.company['logo'], 'https://fixture.invalid/new.png');
  });
  test('PDF embeds logo, respects toggle, and survives unavailable logo', () async {
    final png = (await rootBundle.load('assets/images/brand_logo.png')).buffer.asUint8List();
    var requests = 0;
    final client = MockClient((request) async {
      requests++;
      return http.Response.bytes(png, 200, headers: {'content-type': 'image/png'});
    });
    for (final enabled in [true, false]) {
      final pdf = await http.runWithClient(() => PosReceiptDocumentBuilder.build(
        data: receiptData, template: PosReceiptTemplate(showLogo: enabled),
        company: {'logo': 'https://fixture.invalid/pdf-logo.png'},
      ), () => client);
      expect(latin1.decode(pdf).contains('/Subtype /Image'), enabled);
    }
    expect(requests, 1);
    final pdf = await http.runWithClient(() => PosReceiptDocumentBuilder.build(
      data: receiptData, template: const PosReceiptTemplate(),
      company: {'logo': 'https://fixture.invalid/unavailable.png'},
    ), () => MockClient((_) async => http.Response('not found', 404)));
    expect(latin1.decode(pdf), startsWith('%PDF'));
  });
  testWidgets('fast Bluetooth job includes centered logo and text in one write', (tester) async {
    final png = (await rootBundle.load('assets/images/brand_logo.png')).buffer.asUint8List();
    final calls = <MethodCall>[];
    const channel = MethodChannel('maseka.dev/flutter_bluetooth_printer');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final service = PosReceiptPrintService(prefs);
    await tester.runAsync(() => service.printText(text: 'Usaha\n---\nTOTAL Rp 5.000', logoBytes: png));
    final writes = calls.where((call) => call.method == 'write').toList();
    expect(writes, hasLength(1));
    final bytes = (writes.single.arguments as Map)['data'] as Uint8List;
    final marker = latin1.decode(bytes).indexOf(latin1.decode([0x1d, 0x76, 0x30, 0]));
    expect(marker, greaterThan(0));
    final width = bytes[marker + 4] + 256 * bytes[marker + 5];
    final height = bytes[marker + 6] + 256 * bytes[marker + 7];
    expect(width * 8, lessThanOrEqualTo(272));
    expect(height, lessThanOrEqualTo(128));
    expect(latin1.decode(bytes), contains('TOTAL Rp 5.000'));
  });
}
