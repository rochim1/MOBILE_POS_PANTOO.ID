import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('filter status inventori tidak overflow pada lebar toolbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                initialValue: '',
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: '', child: Text('Semua')),
                  DropdownMenuItem(
                    value: 'partially_received',
                    child: Text(
                      'Diterima sebagian',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
