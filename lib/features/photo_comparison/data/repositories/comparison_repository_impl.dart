import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/photo.dart';
import '../../domain/entities/comparison_session.dart';
import '../../domain/repositories/comparison_repository.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/comparison_local_data_source.dart';
import '../models/comparison_session_model.dart';

class ComparisonRepositoryImpl implements ComparisonRepository {
  final ComparisonLocalDataSource localDataSource;
  final PhotoRepository photoRepository;

  ComparisonRepositoryImpl({
    required this.localDataSource,
    required this.photoRepository,
  });

  @override
  Future<Either<Failure, void>> saveComparisonSession(ComparisonSession session) async {
    try {
      final sessionModel = ComparisonSessionModel(
        id: session.id,
        allPhotoIds: session.allPhotos.map((p) => p.id).toList(),
        eliminatedPhotoIds: session.eliminatedPhotos.map((p) => p.id).toList(),
        createdAt: session.createdAt,
      );
      await localDataSource.saveComparison(sessionModel);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to save comparison session'));
    }
  }

  @override
  Future<Either<Failure, ComparisonSession?>> getComparisonSession(String id) async {
    try {
      final sessionModel = await localDataSource.getComparison(id);
      if (sessionModel == null) {
        return const Right(null);
      }
      return _mapModelToEntity(sessionModel);
    } catch (e) {
      return Left(CacheFailure('Failed to get comparison session'));
    }
  }

  @override
  Future<Either<Failure, List<ComparisonSession>>> getComparisonSessions() async {
    try {
      final sessionModels = await localDataSource.getAllComparisons();
      final List<ComparisonSession> sessions = [];
      for (final model in sessionModels) {
        final eitherEntity = await _mapModelToEntity(model);
        if (eitherEntity.isLeft()) {
          return Left(eitherEntity.fold((l) => l, (r) => null)!);
        }
        sessions.add(eitherEntity.getOrElse(() => throw 'unreachable'));
      }
      return Right(sessions);
    } catch (e) {
      return Left(CacheFailure('Failed to get comparison sessions'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComparisonSession(String id) async {
    try {
      await localDataSource.deleteComparison(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete comparison session'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAllPhotoIdsInUse() async {
    try {
      final ids = await localDataSource.getAllPhotoIdsInUse();
      return Right(ids);
    } catch (e) {
      return Left(CacheFailure('Failed to get photo IDs in use'));
    }
  }

  Future<Either<Failure, ComparisonSession>> _mapModelToEntity(ComparisonSessionModel model) async {
    try {
      final allPhotoIds = model.allPhotoIds;
      final eitherPhotos = await photoRepository.getPhotosByIds(allPhotoIds);

      return eitherPhotos.fold(
        (failure) => Left(failure),
        (photos) {
          final photoMap = {for (var p in photos) p.id: p};

          final allPhotosList = model.allPhotoIds.map((id) => photoMap[id]).whereType<Photo>().toList();
          final eliminatedPhotosList = model.eliminatedPhotoIds.map((id) => photoMap[id]).whereType<Photo>().toList();

          // Check if any photo was not found, which would indicate data inconsistency
          if (allPhotosList.length != model.allPhotoIds.length) {
            return Left(CacheFailure('Failed to reconstruct session: Photo data missing'));
          }

          // Calculate remaining photos
          final eliminatedIds = eliminatedPhotosList.map((p) => p.id).toSet();
          final remainingPhotosList = allPhotosList.where((p) => !eliminatedIds.contains(p.id)).toList();

          return Right(ComparisonSession(
            id: model.id,
            allPhotos: allPhotosList,
            remainingPhotos: remainingPhotosList,
            eliminatedPhotos: eliminatedPhotosList,
            createdAt: model.createdAt,
          ));
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to map session model to entity'));
    }
  }
}
