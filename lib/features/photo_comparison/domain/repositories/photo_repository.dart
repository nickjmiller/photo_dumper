import 'package:dartz/dartz.dart';
import '../entities/photo.dart';
import '../../../../core/error/failures.dart';

abstract class PhotoRepository {
  Future<Either<Failure, List<Photo>>> getPhotos();
  Future<Either<Failure, List<Photo>>> getLibraryPhotos();
  Future<Either<Failure, List<Photo>>> getSelectedPhotos();
  Future<Either<Failure, Photo>> selectPhoto(String photoId);
  Future<Either<Failure, Photo>> deselectPhoto(String photoId);
  Future<Either<Failure, List<Photo>>> getRandomPair();
  Future<Either<Failure, void>> keepPhoto(String photoId);
  Future<Either<Failure, void>> deletePhoto(String photoId);
  Future<Either<Failure, void>> keepBothPhotos();
  Future<Either<Failure, void>> deleteBothPhotos();
  Future<Either<Failure, int>> getSelectedPhotoCount();
  Future<Either<Failure, int>> getRemainingPhotoCount();
  Future<Either<Failure, void>> clearAllSelections();
}
