import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
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
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_success_page.dart';
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
      cache: GraphQLCache(partialDataPolicy: PartialDataCachePolicy.accept),
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
  test('slow template read cannot undo a confirmed show-logo save', () async {
    respond(receipt);
    final receipts = PosReceiptRepository(provider);
    await receipts.getReceiptPrintData();
    final release = Completer<void>();
    provider.client = GraphQLClient(
      cache: GraphQLCache(partialDataPolicy: PartialDataCachePolicy.accept),
      link: Link.function((request, [forward]) async* {
        if (request.variables.containsKey('input')) {
          yield const Response(
            data: {
              'UpdatePOSReceiptTemplate': {
                'pos_receipt_template': {'show_logo': false, 'font_size': 8},
              },
            },
            response: {},
          );
        } else {
          await release.future;
          yield const Response(data: receipt, response: {});
        }
      }),
    );
    final pending = receipts.getReceiptPrintData(forceRefresh: true);
    await Future<void>.delayed(Duration.zero);
    expect(
      (await receipts.updateReceiptTemplate({'show_logo': false})).isRight(),
      true,
    );
    release.complete();
    await pending;
    final data = (await receipts.getReceiptPrintData()).getOrElse(
      () => throw StateError('failed'),
    );
    expect(data.template.showLogo, false);
  });
  test(
    'late response from an old scope visit cannot overwrite a fresh revisit',
    () async {
      final release = Completer<void>();
      provider.client = GraphQLClient(
        cache: GraphQLCache(partialDataPolicy: PartialDataCachePolicy.accept),
        link: Link.function((request, [forward]) async* {
          await release.future;
          yield const Response(data: receipt, response: {});
        }),
      );
      final receipts = PosReceiptRepository(provider);
      final pending = receipts.getReceiptPrintData();
      await Future<void>.delayed(Duration.zero);
      final originalScope = provider.subscriptionScope;
      provider.subscriptionScope = 'another-scope';
      respond(receipt);
      await receipts.getReceiptPrintData();
      provider.subscriptionScope = originalScope;
      respond({
        'GetPOSReceiptData': {
          'template': {'show_logo': false},
          'instansi': {'logo': '/new-scope-visit.png'},
        },
      });
      await receipts.getReceiptPrintData();
      release.complete();
      await pending;
      final data = (await receipts.getReceiptPrintData()).getOrElse(
        () => throw StateError('failed'),
      );
      expect(
        data.company['logo'],
        'https://fixture.invalid/new-scope-visit.png',
      );
      expect(data.template.showLogo, false);
    },
  );
  testWidgets(
    'queued receipt cannot move to another printer and disconnects original target',
    (tester) async {
      MethodChannelBluetoothPrinter.registerWith();
      const channel = MethodChannel('maseka.dev/flutter_bluetooth_printer');
      late Completer<bool> release;
      final writes = <String>[];
      final disconnects = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'write') {
          writes.add((call.arguments as Map)['address'] as String);
          return release.future;
        }
        if (call.method == 'disconnect') {
          disconnects.add((call.arguments as Map)['address'] as String);
        }
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.runAsync(() async {
        release = Completer<bool>();
        final service = PosReceiptPrintService(prefs);
        final first = service.printText(text: 'first');
        await Future<void>.delayed(Duration.zero);
        expect(writes, ['fixture-printer']);
        final second = service.printText(text: 'second');
        final rejected = expectLater(second, throwsA(isA<StateError>()));
        await prefs.setString('pos.receipt_bluetooth_address', 'other-printer');
        release.complete(true);
        await first;
        await rejected;
      });
      expect(writes, ['fixture-printer']);
      expect(disconnects, ['fixture-printer']);
    },
  );
  test(
    'saved business logo and removal immediately update cached receipt',
    () async {
      respond(receipt);
      final receipts = PosReceiptRepository(provider);
      await receipts.preloadReceiptPrintData();
      final business = PosBusinessProfileRepository(
        provider,
        prefs,
        onSaved: (profile) => receipts.updateCompany({
          'nama_instansi': profile.name,
          'logo': profile.logo,
        }),
      );
      for (final logo in ['/new.png', null]) {
        respond({
          'UpdateMyPOSBusinessProfile': {
            '_id': 'tenant',
            'name': 'New',
            'phone': '08123456789',
            'logo': logo,
          },
        });
        expect(
          (await business.save(
            name: 'New',
            phone: '08123456789',
            removeLogo: logo == null,
          )).isRight(),
          true,
        );
        final data = (await receipts.getReceiptPrintData()).getOrElse(
          () => throw StateError('failed'),
        );
        expect(
          data.company['logo'],
          logo == null ? '' : 'https://fixture.invalid/new.png',
        );
        expect(data.company['nama_instansi'], 'New');
        expect(data.template.showLogo, true);
      }
    },
  );
  test(
    'receipt cache must not leak logo into a different tenant or account',
    () async {
      respond(receipt);
      final receipts = PosReceiptRepository(provider);
      await receipts.getReceiptPrintData();
      provider.subscriptionScope = 'endpoint|other|user|operator';
      respond({
        'GetPOSReceiptData': {
          'template': {},
          'instansi': {'logo': '/other.png'},
        },
      });
      final data = (await receipts.getReceiptPrintData()).getOrElse(
        () => throw StateError('failed'),
      );
      expect(data.company['logo'], 'https://fixture.invalid/other.png');
    },
  );
  test(
    'slow old receipt response must not overwrite saved business logo',
    () async {
      respond(receipt);
      final receipts = PosReceiptRepository(provider);
      await receipts.getReceiptPrintData();
      final completer = Completer<void>();
      provider.client = GraphQLClient(
        cache: GraphQLCache(partialDataPolicy: PartialDataCachePolicy.accept),
        link: Link.function((request, [forward]) async* {
          await completer.future;
          yield const Response(data: receipt, response: {});
        }),
      );
      final pending = receipts.getReceiptPrintData(forceRefresh: true);
      await Future<void>.delayed(Duration.zero);
      receipts.updateCompany({'logo': 'https://fixture.invalid/new.png'});
      completer.complete();
      await pending;
      final data = (await receipts.getReceiptPrintData()).getOrElse(
        () => throw StateError('failed'),
      );
      expect(data.company['logo'], 'https://fixture.invalid/new.png');
    },
  );
  test(
    'offline refresh uses only same-session receipt, forbidden never does',
    () async {
      respond(receipt);
      final receipts = PosReceiptRepository(provider);
      await receipts.getReceiptPrintData();
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          throw OperationException(
            linkException: ServerException(originalException: 'offline'),
          );
        }),
      );
      expect(
        (await receipts.getReceiptPrintData(forceRefresh: true)).isRight(),
        true,
      );
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield const Response(
            errors: [
              GraphQLError(
                message: 'denied',
                extensions: {'code': 'FORBIDDEN'},
              ),
            ],
            response: {},
          );
        }),
      );
      expect(
        (await receipts.getReceiptPrintData(forceRefresh: true)).isLeft(),
        true,
      );
      provider.subscriptionScope = 'another-session';
      expect((await receipts.getReceiptPrintData()).isLeft(), true);
    },
  );
  test(
    'receipt template save keeps logo and applies show-logo choice',
    () async {
      respond(receipt);
      final receipts = PosReceiptRepository(provider);
      await receipts.getReceiptPrintData();
      respond({
        'UpdatePOSReceiptTemplate': {
          'pos_receipt_template': {'show_logo': false},
        },
      });
      expect(
        (await receipts.updateReceiptTemplate({'show_logo': false})).isRight(),
        true,
      );
      final data = (await receipts.getReceiptPrintData()).getOrElse(
        () => throw StateError('failed'),
      );
      expect(data.company['logo'], 'https://fixture.invalid/old.png');
      expect(data.template.showLogo, false);
    },
  );
  test(
    'PDF embeds logo, respects toggle, and survives unavailable logo',
    () async {
      final png = (await rootBundle.load(
        'assets/images/brand_logo.png',
      )).buffer.asUint8List();
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response.bytes(
          png,
          200,
          headers: {'content-type': 'image/png'},
        );
      });
      for (final enabled in [true, false]) {
        final pdf = await http.runWithClient(
          () => PosReceiptDocumentBuilder.build(
            data: receiptData,
            template: PosReceiptTemplate(showLogo: enabled),
            company: {'logo': 'https://fixture.invalid/pdf-logo.png'},
          ),
          () => client,
        );
        expect(
          RegExp(r'/Subtype\s*/Image').hasMatch(latin1.decode(pdf)),
          enabled,
        );
      }
      expect(requests, 1);
      final pdf = await http.runWithClient(
        () => PosReceiptDocumentBuilder.build(
          data: receiptData,
          template: const PosReceiptTemplate(),
          company: {'logo': 'https://fixture.invalid/unavailable.png'},
        ),
        () => MockClient((_) async => http.Response('not found', 404)),
      );
      expect(latin1.decode(pdf), startsWith('%PDF'));
    },
  );
  testWidgets(
    'fast Bluetooth job includes centered logo and text in one write',
    (tester) async {
      final png = (await rootBundle.load(
        'assets/images/brand_logo.png',
      )).buffer.asUint8List();
      final calls = <MethodCall>[];
      MethodChannelBluetoothPrinter.registerWith();
      const channel = MethodChannel('maseka.dev/flutter_bluetooth_printer');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final service = PosReceiptPrintService(prefs);
      await tester.runAsync(
        () => service.printText(
          text: 'Usaha\n---\nTOTAL Rp 5.000',
          logoBytes: png,
        ),
      );
      final writes = calls.where((call) => call.method == 'write').toList();
      expect(writes, hasLength(1));
      final bytes = (writes.single.arguments as Map)['data'] as Uint8List;
      final marker = latin1
          .decode(bytes)
          .indexOf(latin1.decode([0x1d, 0x76, 0x30, 0]));
      expect(marker, greaterThan(0));
      final width = bytes[marker + 4] + 256 * bytes[marker + 5];
      final height = bytes[marker + 6] + 256 * bytes[marker + 7];
      expect(width * 8, lessThanOrEqualTo(272));
      expect(height, lessThanOrEqualTo(128));
      expect(latin1.decode(bytes), contains('TOTAL Rp 5.000'));
    },
  );
  for (final input in [
    <int>[],
    [1, 2, 3],
    List<int>.filled(5 * 1024 * 1024 + 1, 0),
  ]) {
    testWidgets(
      'invalid logo (${input.length} bytes) never blocks thermal text',
      (tester) async {
        MethodChannelBluetoothPrinter.registerWith();
        final writes = <Uint8List>[];
        const channel = MethodChannel('maseka.dev/flutter_bluetooth_printer');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'write') {
              writes.add((call.arguments as Map)['data'] as Uint8List);
            }
            return true;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          ),
        );
        await tester.runAsync(
          () => PosReceiptPrintService(
            prefs,
          ).printText(text: 'TOTAL 1000', logoBytes: Uint8List.fromList(input)),
        );
        expect(writes, hasLength(1));
        expect(latin1.decode(writes.single), contains('TOTAL 1000'));
        expect(
          latin1.decode(writes.single),
          isNot(contains(latin1.decode([0x1d, 0x76, 0x30, 0]))),
        );
      },
    );
  }
  testWidgets('transparent logo prints white rather than a solid black box', (
    tester,
  ) async {
    MethodChannelBluetoothPrinter.registerWith();
    Uint8List? written;
    const channel = MethodChannel('maseka.dev/flutter_bluetooth_printer');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'write') {
        written = (call.arguments as Map)['data'] as Uint8List;
      }
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder);
      final picture = recorder.endRecording();
      final image = await picture.toImage(8, 1);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await PosReceiptPrintService(
        prefs,
      ).printText(text: 'TOTAL', logoBytes: png!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
    });
    final marker = latin1
        .decode(written!)
        .indexOf(latin1.decode([0x1d, 0x76, 0x30, 0]));
    expect(marker, greaterThan(0));
    expect(written![marker + 8], 0);
  });
  testWidgets('payment success print button sends configured business logo', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    sl.pushNewScope();
    addTearDown(sl.popScope);
    sl.registerSingleton<SharedPreferences>(prefs);
    respond(receipt);
    sl.registerSingleton<PosReceiptRepository>(PosReceiptRepository(provider));
    MethodChannelBluetoothPrinter.registerWith();
    final writes = <Uint8List>[];
    const channel = MethodChannel('maseka.dev/flutter_bluetooth_printer');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'write') {
        writes.add((call.arguments as Map)['data'] as Uint8List);
      }
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final png = (await rootBundle.load(
      'assets/images/brand_logo.png',
    )).buffer.asUint8List();
    final client = MockClient(
      (_) async =>
          http.Response.bytes(png, 200, headers: {'content-type': 'image/png'}),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PosSuccessPage(
          transaction: PosTransactionResult(
            id: 'fixture',
            invoice: 'INV-LOGO',
            subtotal: 1000,
            discount: 0,
            promoDiscount: 0,
            tax: 0,
            total: 1000,
            cashReceived: 1000,
            change: 0,
            paymentMethod: 'cash',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final print = find.text('Cetak Struk');
    await tester.ensureVisible(print);
    await tester.runAsync(
      () => http.runWithClient(() async {
        await tester.tap(print);
        for (var i = 0; i < 50 && writes.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }, () => client),
    );
    await tester.pumpAndSettle();
    expect(writes, hasLength(1));
    expect(
      latin1.decode(writes.single),
      contains(latin1.decode([0x1d, 0x76, 0x30, 0])),
    );
    expect(latin1.decode(writes.single), contains('INV-LOGO'));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
