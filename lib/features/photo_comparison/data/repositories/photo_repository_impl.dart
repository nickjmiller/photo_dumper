import 'package:dartz/dartz.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_constants.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  @override
  Future<Either<Failure, List<Photo>>> getPhotos() async {
    try {
      // Simulate API call or database fetch
      await Future.delayed(const Duration(milliseconds: 100));

      final photos = [
        Photo(
          id: '1',
          name: AppConstants.photo1Name,
          createdAt: DateTime.now(),
        ),
        Photo(
          id: '2',
          name: AppConstants.photo2Name,
          createdAt: DateTime.now(),
        ),
      ];

      return Right(photos);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch photos: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> keepPhoto(String photoId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 200));
      return const Right(null);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to keep photo: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(String photoId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 200));
      return const Right(null);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to delete photo: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> keepBothPhotos() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to keep both photos: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBothPhotos() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to delete both photos: $e'));
    }
  }
}
