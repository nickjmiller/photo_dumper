import 'package:dartz/dartz.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';
import '../datasources/photo_library_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  final PhotoLibraryDataSource _photoLibraryDataSource;

  PhotoRepositoryImpl({PhotoLibraryDataSource? photoLibraryDataSource})
    : _photoLibraryDataSource =
          photoLibraryDataSource ?? PhotoLibraryDataSourceImpl();

  @override
  Future<Either<Failure, List<Photo>>> getPhotosFromGallery() async {
    try {
      final photos = await _photoLibraryDataSource.getPhotosFromGallery();
      return Right(photos);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch photos from gallery: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Photo>>> getPhotosByIds(List<String> ids) async {
    try {
      final photos = await _photoLibraryDataSource.getPhotosByIds(ids);
      return Right(photos);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch photos by IDs: $e'));
    }
  }
}
