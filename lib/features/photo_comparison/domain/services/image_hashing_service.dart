import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:dart_imagehash/dart_imagehash.dart';

class ImageHashingService {
  Future<ImageHash?> getHash(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      final image = img.decodeImage(await file.readAsBytes());
      if (image != null) {
        return ImageHasher.perceptualHash(image);
      }
    }
    return null;
  }
}
