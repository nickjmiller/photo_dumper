import 'package:flutter_test/flutter_test.dart';
import 'package:photo_dumper/features/photo_comparison/data/repositories/photo_repository_impl.dart';
import 'package:photo_dumper/features/photo_comparison/data/datasources/photo_library_datasource.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';

class MockPhotoLibraryDataSource implements PhotoLibraryDataSource {
  @override
  Future<List<Photo>> getLibraryPhotos() async {
    return [
      Photo(
        id: '1',
        name: 'Test Photo 1',
        imagePath: '/test/path/1.jpg',
        createdAt: DateTime.now(),
      ),
      Photo(
        id: '2',
        name: 'Test Photo 2',
        imagePath: '/test/path/2.jpg',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<bool> requestPhotoPermission() async {
    return true;
  }

  @override
  Future<List<Photo>> pickMultiplePhotos() async {
    return [
      Photo(
        id: '1',
        name: 'Test Photo 1',
        imagePath: '/test/path/1.jpg',
        createdAt: DateTime.now(),
      ),
      Photo(
        id: '2',
        name: 'Test Photo 2',
        imagePath: '/test/path/2.jpg',
        createdAt: DateTime.now(),
      ),
    ];
  }
}

void main() {
  group('PhotoRepositoryImpl', () {
    late PhotoRepositoryImpl repository;
    late MockPhotoLibraryDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockPhotoLibraryDataSource();
      repository = PhotoRepositoryImpl(photoLibraryDataSource: mockDataSource);
    });

    test('should load library photos and store them', () async {
      final result = await repository.getLibraryPhotos();

      expect(result.isRight(), true);
      final photos = result.getOrElse(() => []);
      expect(photos.length, 2);
      expect(photos[0].id, '1');
      expect(photos[1].id, '2');
    });

    test('should add more photos to existing library', () async {
      // First load
      await repository.getLibraryPhotos();

      // Add more photos (mock will return same photos, but in real app would be different)
      final result = await repository.getLibraryPhotos();

      expect(result.isRight(), true);
      final photos = result.getOrElse(() => []);
      expect(photos.length, 4); // 2 + 2 = 4
    });
  });
}
