import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  Future<PermissionState> requestPhotoPermission() {
    return PhotoManager.requestPermissionExtend();
  }
}
