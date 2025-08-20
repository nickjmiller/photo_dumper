import 'package:flutter_test/flutter_test.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';

void main() {
  group('Photo Entity', () {
    final testPhoto = Photo(
      id: '1',
      name: 'Test Photo',
      imagePath: '/path/to/image.jpg',
      createdAt: DateTime(2023, 1, 1),
    );

    test('should create a Photo instance with correct properties', () {
      final photo = Photo(
        id: '1',
        name: 'Test Photo',
        imagePath: '/path/to/image.jpg',
        createdAt: DateTime(2023, 1, 1),
      );

      expect(photo.id, '1');
      expect(photo.name, 'Test Photo');
      expect(photo.imagePath, '/path/to/image.jpg');
      expect(photo.createdAt, DateTime(2023, 1, 1));
    });

    test('should be equal when properties are the same', () {
      final photo1 = Photo(
        id: '1',
        name: 'Test Photo',
        createdAt: DateTime(2023, 1, 1),
      );
      final photo2 = Photo(
        id: '1',
        name: 'Test Photo',
        createdAt: DateTime(2023, 1, 1),
      );

      expect(photo1, equals(photo2));
    });

    test('should not be equal when properties are different', () {
      final photo1 = Photo(
        id: '1',
        name: 'Test Photo 1',
        createdAt: DateTime(2023, 1, 1),
      );
      final photo2 = Photo(
        id: '2',
        name: 'Test Photo 2',
        createdAt: DateTime(2023, 1, 1),
      );

      expect(photo1, isNot(equals(photo2)));
    });

    test('should copy with new values', () {
      final originalPhoto = Photo(
        id: '1',
        name: 'Original Photo',
        imagePath: '/original/path.jpg',
        createdAt: DateTime(2023, 1, 1),
      );

      final copiedPhoto = originalPhoto.copyWith(
        name: 'Updated Photo',
        imagePath: '/updated/path.jpg',
      );

      expect(copiedPhoto.id, '1');
      expect(copiedPhoto.name, 'Updated Photo');
      expect(copiedPhoto.imagePath, '/updated/path.jpg');
      expect(copiedPhoto.createdAt, DateTime(2023, 1, 1));
    });

    test('should maintain original values when copying without parameters', () {
      final originalPhoto = Photo(
        id: '1',
        name: 'Original Photo',
        imagePath: '/original/path.jpg',
        createdAt: DateTime(2023, 1, 1),
      );

      final copiedPhoto = originalPhoto.copyWith();

      expect(copiedPhoto, equals(originalPhoto));
    });
  });
}
