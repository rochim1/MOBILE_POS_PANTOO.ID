import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedProductImage {
  const PickedProductImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<PickedProductImage?> pickProductImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 2048,
    maxHeight: 2048,
    imageQuality: 88,
  );
  if (file == null) return null;
  return PickedProductImage(name: file.name, bytes: await file.readAsBytes());
}
