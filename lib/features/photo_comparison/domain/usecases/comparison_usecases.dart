import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/comparison_session.dart';
import '../repositories/comparison_repository.dart';

class ComparisonUseCases {
  final ComparisonRepository repository;

  ComparisonUseCases(this.repository);

  Future<Either<Failure, List<ComparisonSession>>> getComparisonSessions() {
    return repository.getComparisonSessions();
  }

  Future<Either<Failure, ComparisonSession?>> getComparisonSession(String id) {
    return repository.getComparisonSession(id);
  }

  Future<Either<Failure, void>> saveComparisonSession(ComparisonSession session) {
    return repository.saveComparisonSession(session);
  }

  Future<Either<Failure, void>> deleteComparisonSession(String id) {
    return repository.deleteComparisonSession(id);
  }

  Future<Either<Failure, List<String>>> getAllPhotoIdsInUse() {
    return repository.getAllPhotoIdsInUse();
  }
}
