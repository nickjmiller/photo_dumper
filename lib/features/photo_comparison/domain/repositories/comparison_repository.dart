import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/comparison_session.dart';

abstract class ComparisonRepository {
  Future<Either<Failure, List<ComparisonSession>>> getComparisonSessions();
  Future<Either<Failure, ComparisonSession?>> getComparisonSession(String id);
  Future<Either<Failure, void>> saveComparisonSession(ComparisonSession session);
  Future<Either<Failure, void>> deleteComparisonSession(String id);
  Future<Either<Failure, List<String>>> getAllPhotoIdsInUse();
}
