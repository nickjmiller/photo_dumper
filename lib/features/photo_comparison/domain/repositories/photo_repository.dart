import 'package:dartz/dartz.dart';
import '../entities/photo.dart';
import '../../../../core/error/failures.dart';

abstract class PhotoRepository {
  Future<Either<Failure, List<Photo>>> getPhotosFromGallery();
}
