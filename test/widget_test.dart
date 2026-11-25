// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/app.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await dotenv.load(fileName: '.env');
    FlutterSecureStorage.setMockInitialValues({});
    await initLocator(FlavorConfig.development());
  });

  testWidgets('App loads successfully', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: App()));

    expect(find.byType(App), findsOneWidget);
  });

  testWidgets('all app routes reserve the phone system navigation area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 48);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pumpWidget(const App());
    await tester.pump();
    final viewport = tester.getRect(find.byKey(App.navigatorKey));
    expect(viewport.bottom, lessThanOrEqualTo(844 - 48));
    await tester.pumpWidget(const SizedBox());
  });
}
