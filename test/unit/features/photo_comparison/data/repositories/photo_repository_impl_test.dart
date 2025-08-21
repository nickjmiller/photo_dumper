import 'package:flutter_test/flutter_test.dart';
import 'package:photo_dumper/features/photo_comparison/data/repositories/photo_repository_impl.dart';
import 'package:photo_dumper/features/photo_comparison/data/datasources/photo_library_datasource.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
// ignore: unused_import
import 'package:dartz/dartz.dart';
import 'package:photo_dumper/core/error/failures.dart';

class MockPhotoLibraryDataSource implements PhotoLibraryDataSource {
  @override
  Future<List<Photo>> getPhotosFromGallery() async {
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
  Future<List<Photo>> getPhotosByIds(List<String> ids) async {
    return [];
  }
}

class MockPhotoLibraryDataSourceEmpty implements PhotoLibraryDataSource {
  @override
  Future<List<Photo>> getPhotosFromGallery() async {
    return [];
  }

  @override
  Future<bool> requestPhotoPermission() async {
    return true;
  }

  @override
  Future<List<Photo>> getPhotosByIds(List<String> ids) async {
    return [];
  }
}

class MockPhotoLibraryDataSourceThrowsException
    implements PhotoLibraryDataSource {
  @override
  Future<List<Photo>> getPhotosFromGallery() async {
    throw Exception('Test Exception');
  }

  @override
  Future<bool> requestPhotoPermission() async {
    return true;
  }

  @override
  Future<List<Photo>> getPhotosByIds(List<String> ids) async {
    throw Exception('Test Exception');
  }
}

void main() {
  group('PhotoRepositoryImpl', () {
    late PhotoRepositoryImpl repository;
    late MockPhotoLibraryDataSource mockDataSource;
    late MockPhotoLibraryDataSourceEmpty mockDataSourceEmpty;
    late MockPhotoLibraryDataSourceThrowsException mockDataSourceThrows;

    setUp(() {
      mockDataSource = MockPhotoLibraryDataSource();
      mockDataSourceEmpty = MockPhotoLibraryDataSourceEmpty();
      mockDataSourceThrows = MockPhotoLibraryDataSourceThrowsException();
    });

    test(
      'should return list of photos when data source call is successful',
      () async {
        // Arrange
        repository = PhotoRepositoryImpl(
          photoLibraryDataSource: mockDataSource,
        );

        // Act
        final result = await repository.getPhotosFromGallery();

        // Assert
        expect(result.isRight(), true);
        final photos = result.getOrElse(() => []);
        expect(photos.length, 2);
        expect(photos[0].id, '1');
      },
    );

    test(
      'should return empty list when data source returns empty list',
      () async {
        // Arrange
        repository = PhotoRepositoryImpl(
          photoLibraryDataSource: mockDataSourceEmpty,
        );

        // Act
        final result = await repository.getPhotosFromGallery();

        // Assert
        expect(result.isRight(), true);
        final photos = result.getOrElse(() => []);
        expect(photos.isEmpty, true);
      },
    );

    test(
      'should return a failure when data source throws an exception',
      () async {
        // Arrange
        repository = PhotoRepositoryImpl(
          photoLibraryDataSource: mockDataSourceThrows,
        );

        // Act
        final result = await repository.getPhotosFromGallery();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (photos) => fail('should not return photos'),
        );
      },
    );
  });
}
