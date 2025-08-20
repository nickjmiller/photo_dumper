import 'package:get_it/get_it.dart';
import '../../features/photo_comparison/data/repositories/photo_repository_impl.dart';
import '../../features/photo_comparison/data/datasources/photo_library_datasource.dart';
import '../../features/photo_comparison/domain/repositories/photo_repository.dart';
import '../../features/photo_comparison/domain/usecases/photo_usecases.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Clear any existing registrations for testing
  if (getIt.isRegistered<PhotoRepository>()) {
    getIt.unregister<PhotoRepository>();
  }
  if (getIt.isRegistered<PhotoUseCases>()) {
    getIt.unregister<PhotoUseCases>();
  }

  // Data sources
  getIt.registerLazySingleton<PhotoLibraryDataSource>(
    () => PhotoLibraryDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<PhotoRepository>(
    () => PhotoRepositoryImpl(photoLibraryDataSource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton(() => PhotoUseCases(getIt()));
}
