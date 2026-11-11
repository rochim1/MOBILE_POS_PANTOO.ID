import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/auth/pos_login_navigation.dart';

void main() {
  for (final setup in [true, false]) {
    testWidgets(
      'verified login opens ${setup ? "setup" : "dashboard"} without waiting for roster',
      (tester) async {
        final roster = Completer<void>();
        bool locked = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  child: const Text('Google verified'),
                  onPressed: () => finishPosLoginNavigation(
                    needsWorkspace: setup,
                    readLockEnabled: () async => true,
                    lock: () {
                      locked = true;
                      return roster.future;
                    },
                    resetLock: () => locked = false,
                    isCurrent: () => context.mounted,
                    navigate: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) =>
                            Scaffold(body: Text(setup ? 'Setup' : 'Dashboard')),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Google verified'));
        await tester.pumpAndSettle();
        expect(find.text(setup ? 'Setup' : 'Dashboard'), findsOneWidget);
        expect(locked, !setup);
        roster.complete();
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('slow lock check times out and navigates with PIN still locked', (
    tester,
  ) async {
    final pending = Completer<bool>();
    bool locked = false, navigated = false;
    final action = finishPosLoginNavigation(
      needsWorkspace: false,
      readLockEnabled: () => pending.future,
      lock: () async {
        locked = true;
      },
      resetLock: () => locked = false,
      isCurrent: () => true,
      navigate: () => navigated = true,
    );
    await tester.pump(const Duration(seconds: 9));
    await action;
    expect(locked, isTrue);
    expect(navigated, isTrue);
  });
  test('logout while checking lock cannot reopen dashboard', () async {
    final pending = Completer<bool>();
    bool current = true, navigated = false, locked = false;
    final action = finishPosLoginNavigation(
      needsWorkspace: false,
      readLockEnabled: () => pending.future,
      lock: () async {
        locked = true;
      },
      resetLock: () {},
      isCurrent: () => current,
      navigate: () => navigated = true,
    );
    current = false;
    pending.complete(true);
    await action;
    expect(navigated, isFalse);
    expect(locked, isFalse);
  });
  test(
    'explicitly disabled lock navigates without PIN; error keeps PIN',
    () async {
      for (final fail in [false, true]) {
        bool locked = false, navigated = false;
        await finishPosLoginNavigation(
          needsWorkspace: false,
          readLockEnabled: () async {
            if (fail) throw StateError('offline');
            return false;
          },
          lock: () async {
            locked = true;
          },
          resetLock: () => locked = false,
          isCurrent: () => true,
          navigate: () => navigated = true,
        );
        expect(locked, fail);
        expect(navigated, isTrue);
      }
    },
  );
}
