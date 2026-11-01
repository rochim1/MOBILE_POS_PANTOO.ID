import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active order realtime is disconnected before widget teardown', () {
    final page = File(
      'lib/presentation/pages/pos/pos_table_order_page.dart',
    ).readAsStringSync();
    expect(page, contains('_isDisposing = true;'));
    expect(page, contains('_channelSubscription?.cancel();'));
    expect(page, contains('if (!mounted || _isDisposing) return;'));
  });
}
