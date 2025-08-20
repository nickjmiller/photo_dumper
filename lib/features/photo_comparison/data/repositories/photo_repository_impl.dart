import 'package:dartz/dartz.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';
import '../datasources/photo_library_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  // In-memory storage for photos
  final List<Photo> _libraryPhotos = [];
  final PhotoLibraryDataSource _photoLibraryDataSource;

  PhotoRepositoryImpl({PhotoLibraryDataSource? photoLibraryDataSource})
    : _photoLibraryDataSource =
          photoLibraryDataSource ?? PhotoLibraryDataSourceImpl();

  @override
  Future<Either<Failure, List<Photo>>> getLibraryPhotos() async {
    try {
      final photos = await _photoLibraryDataSource.pickMultiplePhotos();
      if (photos.isNotEmpty) {
        // Add the newly picked photos to the library
        _libraryPhotos.addAll(photos);
        // Return all photos in the library
        return Right(_libraryPhotos);
      }
      return Right(_libraryPhotos);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch library photos: $e'));
    }
  }
}
