import 'package:dartz/dartz.dart';
import '../entities/photo.dart';
import '../../../../core/error/failures.dart';

abstract class PhotoRepository {
  Future<Either<Failure, List<Photo>>> getPhotos();
  Future<Either<Failure, void>> keepPhoto(String photoId);
  Future<Either<Failure, void>> deletePhoto(String photoId);
  Future<Either<Failure, void>> keepBothPhotos();
  Future<Either<Failure, void>> deleteBothPhotos();
}
