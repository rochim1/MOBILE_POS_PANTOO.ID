import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_pdf_preview_bytes.dart';

void main() {
  test('each PDF preview render receives an independent byte buffer', () {
    final source = Uint8List.fromList([1, 2, 3]);
    final preview = PosPdfPreviewBytes(source);
    source[0] = 9;

    final first = preview.freshBytes();
    first[1] = 8;
    final second = preview.freshBytes();

    expect(first, [1, 8, 3]);
    expect(second, [1, 2, 3]);
    expect(identical(first.buffer, second.buffer), isFalse);
  });
}
