import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/photo.dart';

abstract class PhotoLibraryDataSource {
  Future<List<Photo>> getLibraryPhotos();
  Future<bool> requestPhotoPermission();
  Future<List<Photo>> pickMultiplePhotos();
}

class PhotoLibraryDataSourceImpl implements PhotoLibraryDataSource {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Future<bool> requestPhotoPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }
    return false;
  }

  @override
  Future<List<Photo>> getLibraryPhotos() async {
    try {
      final hasPermission = await requestPhotoPermission();
      if (!hasPermission) {
        throw Exception('Photo library permission not granted');
      }

      // For now, we'll return a list of photos that the user can select from
      // In a real implementation, you might want to use a different approach
      // to get all photos from the library
      return [];
    } catch (e) {
      throw Exception('Failed to access photo library: $e');
    }
  }

  @override
  Future<List<Photo>> pickMultiplePhotos() async {
    try {
      final hasPermission = await requestPhotoPermission();
      if (!hasPermission) {
        throw Exception('Photo library permission not granted');
      }

      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) {
        return [];
      }

      final List<Photo> photos = [];
      for (int i = 0; i < pickedFiles.length; i++) {
        final file = pickedFiles[i];
        final photo = Photo(
          id: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: file.name,
          imagePath: file.path,
          thumbnailPath: file.path, // For simplicity, using same path
          createdAt: DateTime.now(),
        );
        photos.add(photo);
      }

      return photos;
    } catch (e) {
      throw Exception('Failed to pick photos: $e');
    }
  }
}
