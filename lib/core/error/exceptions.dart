import 'package:photo_manager/photo_manager.dart';

class PhotoPermissionException implements Exception {
  final PermissionState permissionState;

  PhotoPermissionException(this.permissionState);
}
