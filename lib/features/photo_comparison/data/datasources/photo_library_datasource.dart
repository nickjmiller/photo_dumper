import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/photo.dart';
import '../../../../core/error/exceptions.dart';

abstract class PhotoLibraryDataSource {
  Future<List<Photo>> getPhotosFromGallery();
  Future<List<Photo>> getPhotosByIds(List<String> ids);
  Future<PermissionState> requestPhotoPermission();
}

class PhotoLibraryDataSourceImpl implements PhotoLibraryDataSource {
  @override
  Future<List<Photo>> getPhotosByIds(List<String> ids) async {
    try {
      final List<Photo> photos = [];
      for (final id in ids) {
        final asset = await AssetEntity.fromId(id);
        if (asset != null) {
          final file = await asset.file;
          if (file != null) {
            photos.add(
              Photo(
                id: asset.id,
                name: asset.title ?? 'No title',
                imagePath: file.path,
                thumbnailPath: file.path,
                createdAt: asset.createDateTime,
                file: file,
              ),
            );
          }
        }
      }
      return photos;
    } catch (e) {
      throw Exception('Failed to get photos by IDs: $e');
    }
  }

  @override
  Future<PermissionState> requestPhotoPermission() async {
    return await PhotoManager.requestPermissionExtend();
  }

  @override
  Future<List<Photo>> getPhotosFromGallery() async {
    try {
      final permissionState = await requestPhotoPermission();
      if (!permissionState.hasAccess) {
        throw PhotoPermissionException(permissionState);
      }

      final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      if (paths.isEmpty) {
        return [];
      }

      // Instead of iterating all paths, which can cause duplicates,
      // we just use the first path. This is typically the "Recents" or "All Photos" album.
      final List<AssetEntity> assets = await paths.first.getAssetListPaged(
        page: 0,
        size:
            5000, // A large number to fetch a substantial amount of recent photos
      );

      final List<Photo> photos = [];
      for (final asset in assets) {
        final file = await asset.file;
        if (file != null) {
          photos.add(
            Photo(
              id: asset.id,
              name: asset.title ?? 'No title',
              imagePath: file.path,
              thumbnailPath: file.path,
              createdAt: asset.createDateTime,
              file: file,
            ),
          );
        }
      }

      // Sort photos by creation date, most recent first
      photos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return photos;
    } catch (e) {
      throw Exception('Failed to access photo library: $e');
    }
  }

  // This method is no longer needed as we are fetching all photos
  // and letting the user select them in the app.
  // The selection logic is handled in the presentation layer.
  Future<List<Photo>> pickMultiplePhotos() async {
    // This can be removed or left empty as it's no longer part of the interface.
    return [];
  }
}
