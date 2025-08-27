import 'package:dart_imagehash/dart_imagehash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'package:photo_dumper/features/photo_comparison/domain/services/image_hashing_service.dart';
import 'package:photo_dumper/features/photo_comparison/domain/services/photo_clustering_service.dart';

class MockImageHashingService extends Mock implements ImageHashingService {}

void main() {
  group('PhotoClusteringService', () {
    late PhotoClusteringService service;
    late MockImageHashingService mockImageHashingService;

    setUp(() {
      mockImageHashingService = MockImageHashingService();
      service = PhotoClusteringService(
        imageHashingService: mockImageHashingService,
      );
    });

    test(
      'findClusters should return correct clusters based on time and similarity',
      () async {
        // Arrange
        final now = DateTime.now();
        final photos = [
          Photo(
            id: '1',
            name: 'p1',
            createdAt: now,
            imagePath: '/path/to/image1.jpg',
          ),
          Photo(
            id: '2',
            name: 'p2',
            createdAt: now.add(const Duration(seconds: 10)),
            imagePath: '/path/to/image2.jpg',
          ),
          Photo(
            id: '3',
            name: 'p3',
            createdAt: now.add(const Duration(seconds: 20)),
            imagePath: '/path/to/image3.jpg',
          ),
          Photo(
            id: '4',
            name: 'p4',
            createdAt: now.add(const Duration(minutes: 2)),
            imagePath: '/path/to/image4.jpg',
          ),
          Photo(
            id: '5',
            name: 'p5',
            createdAt: now.add(const Duration(minutes: 2, seconds: 15)),
            imagePath: '/path/to/image5.jpg',
          ),
          Photo(
            id: '6',
            name: 'p6',
            createdAt: now.add(const Duration(minutes: 5)),
            imagePath: '/path/to/image6.jpg',
          ),
        ];

        // Mocking getHash calls
        when(
          () => mockImageHashingService.getHash(any()),
        ).thenAnswer((_) async => null);
        when(
          () => mockImageHashingService.getHash('/path/to/image1.jpg'),
        ).thenAnswer((_) async => ImageHash.fromHex('f8e0a060c020f8e0'));
        when(
          () => mockImageHashingService.getHash('/path/to/image2.jpg'),
        ).thenAnswer(
          (_) async => ImageHash.fromHex('f8e0a060c020f8e1'),
        ); // similar to 1
        when(
          () => mockImageHashingService.getHash('/path/to/image3.jpg'),
        ).thenAnswer(
          (_) async => ImageHash.fromHex('ffffffffffffffff'),
        ); // not similar
        when(
          () => mockImageHashingService.getHash('/path/to/image4.jpg'),
        ).thenAnswer((_) async => ImageHash.fromHex('a0a0a0a0a0a0a0a0'));
        when(
          () => mockImageHashingService.getHash('/path/to/image5.jpg'),
        ).thenAnswer(
          (_) async => ImageHash.fromHex('a0a0a0a0a0a0a0a1'),
        ); // similar to 4
        when(
          () => mockImageHashingService.getHash('/path/to/image6.jpg'),
        ).thenAnswer(
          (_) async => ImageHash.fromHex('0000000000000000'),
        ); // not similar to anything

        // Act
        final clusters = await service.findClusters(photos);

        // Assert
        expect(clusters.length, 2);
        expect(clusters[0].length, 2);
        expect(clusters[0].map((p) => p.id).toList(), ['1', '2']);
        expect(clusters[1].length, 2);
        expect(clusters[1].map((p) => p.id).toList(), ['4', '5']);
      },
    );
  });
}
