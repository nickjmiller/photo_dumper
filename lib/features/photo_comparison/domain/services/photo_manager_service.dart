import 'package:photo_manager/photo_manager.dart';

class PhotoManagerService {
  Future<List<String>> deleteWithIds(List<String> ids) {
    return PhotoManager.editor.deleteWithIds(ids);
  }

  Future<void> moveToTrash(List<AssetEntity> entities) async {
    // This method is only available on Android, so we might need platform checks
    // in the BLoC, but the service can just expose the method.
    // The BLoC will be responsible for catching the exception on non-Android platforms.
    await PhotoManager.editor.android.moveToTrash(entities);
  }

  Future<AssetEntity?> assetEntityFromId(String id) {
    return AssetEntity.fromId(id);
  }
}
