import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/core/customer_display/local_customer_display_host_io.dart';

class _LocalNetwork extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // These integration tests use a real loopback server, not Flutter's HTTP stub.
  setUp(() => HttpOverrides.global = _LocalNetwork());
  tearDown(() => HttpOverrides.global = null);
  test(
    'local screen follows POS language while preserving cart data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final language = AppLanguageController.instance;
      await language.select('en');
      final host = LocalCustomerDisplayHost();
      final client = HttpClient();
      WebSocket? socket;
      StreamIterator<dynamic>? messages;
      try {
        final url = Uri.parse(
          await host.start(
            'b' * 32,
            advertisedHost: '127.0.0.1',
            onClientCountChanged: (_) {},
          ),
        );
        final response = await (await client.getUrl(url)).close();
        final html = await utf8.decoder.bind(response).join();
        expect(html, contains('<html lang="en">'));
        expect(html, contains('"title":"Customer Display"'));
        expect(html, isNot(contains('__PANTOO_DISPLAY_COPY__')));
        socket = await WebSocket.connect(
          url.replace(scheme: 'ws', path: '/ws').toString(),
        );
        messages = StreamIterator(socket);
        host.publish({
          'items': [
            {'name': 'Bayar', 'quantity': 2},
          ],
          'total': 24000,
          'status': 'payment_success',
          'store_name': 'Simpan',
        });
        expect(
          await messages.moveNext().timeout(const Duration(seconds: 3)),
          isTrue,
        );
        var data = jsonDecode(messages.current as String) as Map;
        expect(data['display_labels']['paymentSuccess'], 'Payment successful!');
        expect(data['items'][0]['name'], 'Bayar');
        await language.select('id');
        expect(
          await messages.moveNext().timeout(const Duration(seconds: 3)),
          isTrue,
        );
        data = jsonDecode(messages.current as String) as Map;
        expect(
          data['display_labels']['paymentSuccess'],
          'Pembayaran berhasil!',
        );
        expect(data['display_language'], 'id');
        expect(data['items'][0]['name'], 'Bayar');
        expect(data['total'], 24000);
        expect(data['status'], 'payment_success');
        expect(data['store_name'], 'Simpan');
      } finally {
        await messages?.cancel();
        await socket?.close();
        await host.stop();
        client.close(force: true);
        await language.select('id');
      }
    },
  );
  test(
    'Wi-Fi display serves a token-only page and streams cart updates',
    () async {
      final host = LocalCustomerDisplayHost();
      final client = HttpClient();
      var viewers = 0;
      final token = 'a' * 32;
      try {
        final url = Uri.parse(
          await host.start(
            token,
            advertisedHost: '127.0.0.1',
            onClientCountChanged: (count) => viewers = count,
          ),
        );
        final invalid = await (await client.getUrl(
          url.replace(queryParameters: {'pair': 'invalid'}),
        )).close();
        expect(invalid.statusCode, HttpStatus.forbidden);
        await invalid.drain<void>();

        final page = await (await client.getUrl(url)).close();
        expect(page.statusCode, HttpStatus.ok);
        expect(
          await utf8.decoder.bind(page).join(),
          contains('Layar Pelanggan'),
        );

        final socket = await WebSocket.connect(
          url.replace(scheme: 'ws', path: '/ws').toString(),
        );
        final received = Completer<String>();
        final subscription = socket.listen((message) {
          if (!received.isCompleted) received.complete(message.toString());
        });
        host.publish({
          'items': [
            {'name': 'Kopi', 'quantity': 1, 'subtotal': 1500},
          ],
          'subtotal': 1500,
          'discount': 0,
          'total': 1500,
          'store_name': 'Toko Uji',
          'status': 'cart',
        });
        expect(
          await received.future.timeout(const Duration(seconds: 3)),
          contains('Kopi'),
        );
        expect(viewers, 1);
        await subscription.cancel();
        await socket.close();
        for (var attempt = 0; attempt < 50 && viewers != 0; attempt++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(viewers, 0);

        final reopened = await WebSocket.connect(
          url.replace(scheme: 'ws', path: '/ws').toString(),
        );
        expect(
          await reopened.first.timeout(const Duration(seconds: 3)),
          contains('Kopi'),
        );
        await reopened.close();
        await expectLater(
          WebSocket.connect(
            url
                .replace(
                  scheme: 'ws',
                  path: '/ws',
                  queryParameters: {'pair': 'invalid'},
                )
                .toString(),
          ),
          throwsA(isA<WebSocketException>()),
        );
      } finally {
        await host.stop();
        client.close(force: true);
      }
    },
  );
}
