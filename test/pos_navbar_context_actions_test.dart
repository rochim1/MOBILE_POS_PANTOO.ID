import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_navbar_action_policy.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_navbar_context_actions.dart';

void main() {
  final runtime = <String, dynamic>{'permissions': {'use_cashier': true}, 'pos_lock_enabled': true};
  var displayBuilds = 0;
  final called = <String>[];
  Future<void> mount(WidgetTester tester, PosNavbarActionPolicy policy, {bool compact = false}) async {
    await tester.binding.setSurfaceSize(Size(compact ? 320 : 1200, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: AppBar(title: const Text('POS'), actions: [
      PosNavbarContextActions(
        policy: policy, compact: compact, showKeyboardIcon: true,
        notificationButton: IconButton(tooltip: 'Notifikasi', onPressed: () => called.add('notifications'), icon: const Icon(Icons.notifications_none)),
        customerDisplayBuilder: (_) { displayBuilds++; return IconButton(tooltip: 'Hubungkan layar pelanggan', onPressed: () => called.add('display'), icon: const Icon(Icons.connected_tv_outlined)); },
        onKeyboardHelp: () => called.add('keyboard'), onToggleGuide: () => called.add('setup'),
        onLock: () => called.add('lock'), onCustomerDisplay: () => called.add('display'),
      ),
    ]))));
    await tester.pumpAndSettle();
  }
  setUp(() {displayBuilds = 0; called.clear();});
  testWidgets('unrelated page does not build display connection or show keyboard/checklist', (tester) async {
    await mount(tester, PosNavbarActionPolicy(runtime, page: 17));
    expect(displayBuilds, 0);
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsNothing);
    expect(find.byIcon(Icons.connected_tv_outlined), findsNothing);
    expect(find.byIcon(Icons.fact_check_outlined), findsNothing);
    expect(find.byTooltip('Kunci POS'), findsOneWidget);
    expect(find.byTooltip('Notifikasi'), findsOneWidget);
  });
  testWidgets('cashier gets relevant actions and working callbacks', (tester) async {
    await mount(tester, PosNavbarActionPolicy(runtime, page: 1));
    expect(displayBuilds, 1);
    await tester.tap(find.byTooltip('Shortcut keyboard (F1)'));
    await tester.tap(find.byTooltip('Hubungkan layar pelanggan'));
    await tester.tap(find.byTooltip('Kunci POS'));
    expect(called, ['keyboard', 'display', 'lock']);
  });
  testWidgets('compact unrelated page has no empty overflow when lock disabled', (tester) async {
    await mount(tester, PosNavbarActionPolicy({'pos_lock_enabled': false}, page: 14), compact: true);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byTooltip('Notifikasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact overflow only contains contextual actions and retains locking', (tester) async {
    await mount(tester, PosNavbarActionPolicy(runtime, page: 7), compact: true);
    await tester.tap(find.byTooltip('Aksi lainnya')); await tester.pumpAndSettle();
    expect(find.text('Layar pelanggan'), findsNothing);
    expect(find.text('Shortcut keyboard'), findsNothing);
    expect(find.text('Checklist kesiapan'), findsNothing);
    await tester.tap(find.text('Kunci POS')); await tester.pumpAndSettle();
    expect(called, ['lock']);
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact cashier shows display/keyboard but not the optional checklist', (tester) async {
    await mount(tester, PosNavbarActionPolicy(runtime, page: 1), compact: true);
    await tester.tap(find.byTooltip('Aksi lainnya')); await tester.pumpAndSettle();
    expect(find.text('Shortcut keyboard'), findsOneWidget);
    expect(find.text('Layar pelanggan'), findsOneWidget);
    expect(find.text('Checklist kesiapan'), findsNothing);
    await tester.tap(find.text('Layar pelanggan')); await tester.pumpAndSettle();
    expect(called, ['display']); expect(tester.takeException(), isNull);
  });
  testWidgets('open guide retains its close action without cashier controls', (tester) async {
    await mount(tester, PosNavbarActionPolicy(runtime, page: 1, showSetupGuide: true));
    expect(displayBuilds, 0);
    await tester.tap(find.byTooltip('Checklist kesiapan POS'));
    expect(called, ['setup']);
  });
  testWidgets('locked or revoked context never retains a display action', (tester) async {
    await mount(tester, PosNavbarActionPolicy(runtime, page: 1, locked: true));
    expect(find.byType(IconButton), findsNothing);
    await mount(tester, PosNavbarActionPolicy({'permissions': {}}, page: 1));
    expect(find.byIcon(Icons.connected_tv_outlined), findsNothing);
    expect(find.byIcon(Icons.keyboard_alt_outlined), findsNothing);
    expect(displayBuilds, 0);
  });
}
