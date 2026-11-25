import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_app_exit_confirmation.dart';

void main() {
  for (final locale in ['id', 'en']) {
    testWidgets('exit needs explicit confirmation and is localized: $locale', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final exit = PosAppExitConfirmation();
      final calls = <String>[];
      var allowed = true;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  exit.request(context, canExit: () => allowed);
                  exit.request(context, canExit: () => allowed);
                },
                child: const Text('Ask exit'),
              ),
            ),
          ),
        ),
      );
      final title = locale == 'id' ? 'Keluar dari aplikasi?' : 'Exit the app?';
      final cancel = locale == 'id' ? 'Batal' : 'Cancel';
      final confirm = locale == 'id' ? 'Keluar aplikasi' : 'Exit app';
      await tester.tap(find.text('Ask exit'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text(cancel));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await tester.tap(find.text('Ask exit'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(calls, isNot(contains('SystemNavigator.pop')));
      await tester.tap(find.text('Ask exit'));
      await tester.pumpAndSettle();
      allowed = false;
      await tester.tap(find.text(confirm));
      await tester.pumpAndSettle();
      expect(
        calls,
        isNot(contains('SystemNavigator.pop')),
        reason: 'Recheck busy/PIN guard after dialog',
      );
      await tester.tap(find.text('Ask exit'));
      await tester.pumpAndSettle();
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'No dialog when busy or locked',
      );
      allowed = true;
      await tester.tap(find.text('Ask exit'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(confirm));
      await tester.pumpAndSettle();
      expect(
        calls.where((method) => method == 'SystemNavigator.pop'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
  testWidgets('iOS never closes app programmatically', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PosAppExitConfirmation().request(
                context,
                canExit: () => true,
              ),
              child: const Text('Ask exit'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ask exit'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });
}
