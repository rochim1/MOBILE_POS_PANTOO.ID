import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/notifications/pos_push_repository.dart';
import 'package:mobile_pos_pantoo/core/notifications/pos_push_service.dart';

// This QA app never authenticates or calls the real business backend.
class _LocalTokenRepository implements PosPushTokenRepository {
  _LocalTokenRepository(this.file);
  final File file;
  String? token;
  Future<void> stage(String stage) => file
      .writeAsString(jsonEncode({'stage': stage, 'token': token}))
      .then((_) {});
  @override
  Future<void> register({
    required String token,
    required String projectId,
    required String installationId,
  }) async {
    this.token = token;
    await stage('ready');
  }

  @override
  Future<void> unregister({
    required String token,
    required String installationId,
  }) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real Android FCM foreground and background delivery',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Pantoo POS Push QA'))),
        ),
      );
      await tester.runAsync(() async {
        final temp = await getTemporaryDirectory();
        final repository = _LocalTokenRepository(
          File('${temp.path}/pos_push_qa.json'),
        );
        await repository.stage('initializing');
        SharedPreferences.setMockInitialValues({
          'user_id': 'push-qa-only',
          'instansi_id': 'push-qa-only',
        });
        final prefs = await SharedPreferences.getInstance();
        final foreground = Completer<void>();
        var backgroundDeliveredToForeground = false;
        final service = PosPushService(repository: repository, prefs: prefs);
        await service.initialize();
        final subscription = FirebaseMessaging.onMessage.listen((message) {
          if (message.data['qa_case'] == 'background')
            backgroundDeliveredToForeground = true;
          if (message.data['qa_case'] == 'foreground' &&
              !foreground.isCompleted)
            foreground.complete();
        });
        try {
          await service.activate();
          expect(service.status.value, PosPushStatus.ready);
          await foreground.future.timeout(const Duration(minutes: 4));
          Future<void> waitForNotification(String title) async {
            final deadline = DateTime.now().add(const Duration(minutes: 4));
            while (DateTime.now().isBefore(deadline)) {
              final active = await FlutterLocalNotificationsPlugin()
                  .getActiveNotifications();
              if (active.any((notification) => notification.title == title))
                return;
              await Future<void>.delayed(const Duration(milliseconds: 500));
            }
            fail('Android did not post $title');
          }

          await waitForNotification('Pantoo POS QA foreground');
          final movedToBackground = await const MethodChannel(
            'pantoo.pos/push_qa',
          ).invokeMethod<bool>('background', 'pantoo-pos-push-qa');
          expect(movedToBackground, isTrue);
          await repository.stage('foreground_received');
          await waitForNotification('Pantoo POS QA background');
          expect(
            backgroundDeliveredToForeground,
            isFalse,
            reason: 'Android must actually be in background for this case',
          );
          await repository.stage('background_verified');
        } finally {
          await subscription.cancel();
          await service.deactivate();
          await service.dispose();
        }
      });
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
