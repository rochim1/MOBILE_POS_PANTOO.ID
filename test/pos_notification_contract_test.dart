import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('navbar POS exposes notification preview and full page navigation', () {
    final shell = File(
      'lib/presentation/pages/pos/pos_shell_page.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/domain/repositories/pos_notification_repository.dart',
    ).readAsStringSync();

    expect(shell, contains('_notificationButton()'));
    expect(shell, contains("value: 'all'"));
    expect(shell, contains('PosNotificationPage'));
    expect(repository, contains('GetAllNotifikasi'));
    expect(repository, contains('CountUnreadNotifikasi'));
    expect(repository, contains('readThisNotif'));
  });
}
