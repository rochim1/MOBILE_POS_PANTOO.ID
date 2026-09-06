// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class PickedProductImage {
  const PickedProductImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<PickedProductImage?> pickProductImage() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/jpeg,image/png,image/webp';
  input.click();
  await input.onChange.first;
  final file = input.files?.firstOrNull;
  if (file == null) return null;

  final reader = html.FileReader()..readAsArrayBuffer(file);
  await reader.onLoad.first;
  final result = reader.result;
  final bytes = switch (result) {
    Uint8List value => value,
    ByteBuffer value => value.asUint8List(),
    _ => throw StateError('Browser tidak dapat membaca data gambar'),
  };
  return PickedProductImage(name: file.name, bytes: bytes);
}
