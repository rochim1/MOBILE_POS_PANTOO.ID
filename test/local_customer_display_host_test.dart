import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/customer_display/local_customer_display_host_io.dart';

void main() {
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
