import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';

String _flutterRoot() {
  var current = File(Platform.resolvedExecutable).parent;
  while (current.parent.path != current.path) {
    if (File('${current.path}/packages/flutter_tools/.dart_tool/package_config.json').existsSync()) return current.path;
    current = current.parent;
  }
  throw StateError('Flutter SDK not found for its bundled read-only Dart syntax auditor');
}
void main() {
  test('all InputDecorations have a label or a reviewed persistent external label', () async {
    final root = _flutterRoot();
    final result = await Process.run('$root/bin/cache/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}', [
      '--packages=$root/packages/flutter_tools/.dart_tool/package_config.json',
      'tool/audit_field_labels.dart.txt', '--verify',
    ]);
    final report = jsonDecode(result.stdout as String) as Map;
    expect(result.exitCode, 0, reason: '${report['missing']}\n${result.stderr}');
    expect((report['fields'] as List).length, greaterThan(350));
    expect(report['missing'], isEmpty);
  });
  testWidgets('theme keeps an empty and filled form label permanently visible', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const Scaffold(
      body: TextField(decoration: InputDecoration(labelText: 'Nama pelanggan', hintText: 'Contoh: Budi')))));
    var decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(decorator.decoration.floatingLabelBehavior, FloatingLabelBehavior.always);
    await tester.enterText(find.byType(TextField), 'Nama tetap');
    FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();
    decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(decorator.decoration.labelText, 'Nama pelanggan');
    expect(decorator.decoration.floatingLabelBehavior, FloatingLabelBehavior.always);
    expect(find.text('Nama tetap'), findsOneWidget);
  });
  testWidgets('shared search field has a persistent label after typing', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const Scaffold(
      body: PosSearchField(hint: 'Cari produk...'))));
    await tester.enterText(find.byType(TextField), 'Produk QA');
    await tester.pumpAndSettle();
    final decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    expect(decorator.decoration.labelText, isNotEmpty);
    expect(decorator.decoration.floatingLabelBehavior, FloatingLabelBehavior.always);
    expect(find.text('Produk QA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
