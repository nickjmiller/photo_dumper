import 'package:dartz/dartz.dart';
import '../entities/photo.dart';
import '../repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';

class PhotoUseCases {
  final PhotoRepository repository;

  PhotoUseCases(this.repository);

  Future<Either<Failure, List<Photo>>> getLibraryPhotos() async {
    return await repository.getLibraryPhotos();
  }
}
