import 'package:dartz/dartz.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';

class PhotoUseCases {
  final PhotoRepository repository;

  PhotoUseCases({required this.repository});

  Future<Either<Failure, List<Photo>>> getPhotos() async {
    return await repository.getPhotos();
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
}
