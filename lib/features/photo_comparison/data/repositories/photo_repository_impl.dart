import 'package:dartz/dartz.dart';
import '../../domain/entities/photo.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_constants.dart';
import 'dart:math';
import '../datasources/photo_library_datasource.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  // In-memory storage for photos
  final List<Photo> _libraryPhotos = [];
  final List<Photo> _selectedPhotos = [];
  final List<Photo> _remainingPhotos = [];
  final PhotoLibraryDataSource _photoLibraryDataSource;

  PhotoRepositoryImpl({PhotoLibraryDataSource? photoLibraryDataSource})
    : _photoLibraryDataSource =
          photoLibraryDataSource ?? PhotoLibraryDataSourceImpl();

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

  @override
  Future<Either<Failure, List<Photo>>> getSelectedPhotos() async {
    try {
      return Right(_selectedPhotos);
    } catch (e) {
      return Left(ServerFailure('Failed to get selected photos: $e'));
    }
  }

  @override
  Future<Either<Failure, Photo>> selectPhoto(String photoId) async {
    try {
      // Find the photo in the already loaded library photos
      final photo = _libraryPhotos.firstWhere(
        (photo) => photo.id == photoId,
        orElse: () => throw Exception('Photo not found'),
      );

      final selectedPhoto = photo.copyWith(isSelected: true);
      _selectedPhotos.add(selectedPhoto);
      _remainingPhotos.add(selectedPhoto);

      return Right(selectedPhoto);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to select photo: $e'));
    }
  }

  @override
  Future<Either<Failure, Photo>> deselectPhoto(String photoId) async {
    try {
      final photo = _selectedPhotos.firstWhere(
        (photo) => photo.id == photoId,
        orElse: () => throw Exception('Photo not found'),
      );

      _selectedPhotos.removeWhere((photo) => photo.id == photoId);
      _remainingPhotos.removeWhere((photo) => photo.id == photoId);

      return Right(photo.copyWith(isSelected: false));
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to deselect photo: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Photo>>> getRandomPair() async {
    try {
      if (_remainingPhotos.length < 2) {
        return Left(PhotoOperationFailure('Not enough photos for comparison'));
      }

      final random = Random();
      final index1 = random.nextInt(_remainingPhotos.length);
      final photo1 = _remainingPhotos[index1];

      // Get a different photo for the second one
      int index2;
      do {
        index2 = random.nextInt(_remainingPhotos.length);
      } while (index2 == index1);

      final photo2 = _remainingPhotos[index2];

      return Right([photo1, photo2]);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to get random pair: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getSelectedPhotoCount() async {
    try {
      return Right(_selectedPhotos.length);
    } catch (e) {
      return Left(ServerFailure('Failed to get selected photo count: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getRemainingPhotoCount() async {
    try {
      return Right(_remainingPhotos.length);
    } catch (e) {
      return Left(ServerFailure('Failed to get remaining photo count: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> keepPhoto(String photoId) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 200));

      // Remove the other photo from remaining photos
      final currentPair = await getRandomPair();
      if (currentPair.isRight()) {
        final pair = currentPair.getOrElse(() => []);
        final otherPhoto = pair.firstWhere(
          (photo) => photo.id != photoId,
          orElse: () => throw Exception('Other photo not found'),
        );
        _remainingPhotos.removeWhere((photo) => photo.id == otherPhoto.id);
      }

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

      // Remove the photo from remaining photos
      _remainingPhotos.removeWhere((photo) => photo.id == photoId);

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

      // Remove both photos from remaining photos
      final currentPair = await getRandomPair();
      if (currentPair.isRight()) {
        final pair = currentPair.getOrElse(() => []);
        for (final photo in pair) {
          _remainingPhotos.removeWhere((p) => p.id == photo.id);
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to delete both photos: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllSelections() async {
    try {
      _selectedPhotos.clear();
      _remainingPhotos.clear();

      // Reset selection state in library photos
      for (int i = 0; i < _libraryPhotos.length; i++) {
        _libraryPhotos[i] = _libraryPhotos[i].copyWith(isSelected: false);
      }

      return const Right(null);
    } catch (e) {
      return Left(PhotoOperationFailure('Failed to clear all selections: $e'));
    }
  }
}
