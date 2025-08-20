import 'package:dartz/dartz.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';

class PhotoUseCases {
  final PhotoRepository repository;

  PhotoUseCases(this.repository);

  Future<Either<Failure, List<Photo>>> getPhotos() async {
    return await repository.getPhotos();
  }

  Future<Either<Failure, List<Photo>>> getLibraryPhotos() async {
    return await repository.getLibraryPhotos();
  }

  Future<Either<Failure, List<Photo>>> getSelectedPhotos() async {
    return await repository.getSelectedPhotos();
  }

  Future<Either<Failure, Photo>> selectPhoto(String photoId) async {
    return await repository.selectPhoto(photoId);
  }

  Future<Either<Failure, Photo>> deselectPhoto(String photoId) async {
    return await repository.deselectPhoto(photoId);
  }

  Future<Either<Failure, List<Photo>>> getRandomPair() async {
    return await repository.getRandomPair();
  }

  Future<Either<Failure, void>> keepPhoto(String photoId) async {
    return await repository.keepPhoto(photoId);
  }

  Future<Either<Failure, void>> deletePhoto(String photoId) async {
    return await repository.deletePhoto(photoId);
  }

  Future<Either<Failure, void>> keepBothPhotos() async {
    return await repository.keepBothPhotos();
  }

  Future<Either<Failure, void>> deleteBothPhotos() async {
    return await repository.deleteBothPhotos();
  }

  Future<Either<Failure, int>> getSelectedPhotoCount() async {
    return await repository.getSelectedPhotoCount();
  }

  Future<Either<Failure, int>> getRemainingPhotoCount() async {
    return await repository.getRemainingPhotoCount();
  }

  Future<Either<Failure, void>> clearAllSelections() async {
    return await repository.clearAllSelections();
  }
}
