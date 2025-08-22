import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  Future<PermissionState> requestPhotoPermission() {
    const requestOption = PermissionRequestOption(
      androidPermission: AndroidPermission(
        type: RequestType.common,
        mediaLocation: false, // My app doesn't need location
      ),
    );
    return PhotoManager.requestPermissionExtend(requestOption: requestOption);
  }
}
