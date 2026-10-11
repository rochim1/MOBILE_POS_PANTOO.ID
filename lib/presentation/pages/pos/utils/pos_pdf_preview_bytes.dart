import 'dart:typed_data';

/// Keeps a non-transferable snapshot so PDF.js can detach each render's buffer
/// without breaking subsequent previews (or sharing) on Flutter Web.
class PosPdfPreviewBytes {
  PosPdfPreviewBytes(Uint8List bytes)
    : _snapshot = List<int>.unmodifiable(bytes);

  final List<int> _snapshot;

  Uint8List freshBytes() => Uint8List.fromList(_snapshot);
}
