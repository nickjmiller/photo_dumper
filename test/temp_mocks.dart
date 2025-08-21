import 'package:mockito/annotations.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/photo_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/domain/usecases/comparison_usecases.dart';
import 'package:photo_dumper/features/photo_comparison/domain/services/photo_manager_service.dart';
import 'package:photo_dumper/features/photo_comparison/domain/repositories/photo_repository.dart';
import 'package:photo_dumper/core/services/platform_service.dart';

@GenerateMocks([
  PhotoUseCases,
  ComparisonUseCases,
  PhotoManagerService,
  PhotoRepository,
  PlatformService,
])
void main() {} // Annotation needs to be on a top-level element to be processed.
