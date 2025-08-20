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
        // Only add photos to library if we have 2 or more photos
        if (photos.length >= 2) {
          // Clear previous library and add new photos
          _libraryPhotos.clear();
          _libraryPhotos.addAll(photos);
          return Right(_libraryPhotos);
        } else {
          // Return empty list for invalid selection (less than 2 photos)
          return Right([]);
        }
      }
      return Right(_libraryPhotos);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch library photos: $e'));
    }
  }

  // Method to clear the library (useful for testing or reset scenarios)
  void clearLibrary() {
    _libraryPhotos.clear();
  }
}
