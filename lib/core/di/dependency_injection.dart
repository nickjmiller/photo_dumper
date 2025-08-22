import 'package:get_it/get_it.dart';
import '../../features/photo_comparison/data/datasources/comparison_local_data_source.dart';
import '../../features/photo_comparison/data/repositories/comparison_repository_impl.dart';
import '../../features/photo_comparison/domain/repositories/comparison_repository.dart';
import '../../features/photo_comparison/domain/usecases/comparison_usecases.dart';
import '../../features/photo_comparison/presentation/bloc/comparison_list_bloc.dart';
import '../database/database_helper.dart';
import '../../features/photo_comparison/data/repositories/photo_repository_impl.dart';
import '../../features/photo_comparison/data/datasources/photo_library_datasource.dart';
import '../../features/photo_comparison/domain/repositories/photo_repository.dart';
import '../../features/photo_comparison/domain/usecases/photo_usecases.dart';
import '../services/permission_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // BLoCs
  getIt.registerFactory(() => ComparisonListBloc(useCases: getIt()));

  // Use cases
  getIt.registerLazySingleton(() => PhotoUseCases(getIt()));
  getIt.registerLazySingleton(() => ComparisonUseCases(getIt()));

  // Repositories
  getIt.registerLazySingleton<PhotoRepository>(
    () => PhotoRepositoryImpl(photoLibraryDataSource: getIt()),
  );
  getIt.registerLazySingleton<ComparisonRepository>(
    () => ComparisonRepositoryImpl(
      localDataSource: getIt(),
      photoRepository: getIt(),
    ),
  );

  // Data sources
  getIt.registerLazySingleton<PhotoLibraryDataSource>(
    () => PhotoLibraryDataSourceImpl(),
  );
  getIt.registerLazySingleton<ComparisonLocalDataSource>(
    () => ComparisonLocalDataSourceImpl(dbHelper: getIt()),
  );

  // Core
  getIt.registerLazySingleton(() => DatabaseHelper.instance);
  getIt.registerLazySingleton(() => PermissionService());
}
