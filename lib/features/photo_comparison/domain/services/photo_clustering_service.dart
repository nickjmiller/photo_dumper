import 'package:dart_imagehash/dart_imagehash.dart';
import 'package:photo_dumper/features/photo_comparison/domain/entities/photo.dart';
import 'image_hashing_service.dart';

class PhotoClusteringService {
  final ImageHashingService imageHashingService;

  PhotoClusteringService({required this.imageHashingService});

  Future<List<List<Photo>>> findClusters(List<Photo> photos) async {
    if (photos.length < 2) {
      return [];
    }

    // Sort photos by creation date
    photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Group photos by time (e.g., within 60 seconds of each other)
    final List<List<Photo>> timeClusters = [];
    List<Photo> currentCluster = [photos.first];

    for (int i = 1; i < photos.length; i++) {
      final previousPhoto = photos[i - 1];
      final currentPhoto = photos[i];
      final timeDifference = currentPhoto.createdAt.difference(
        previousPhoto.createdAt,
      );

      if (timeDifference.inSeconds <= 60) {
        currentCluster.add(currentPhoto);
      } else {
        if (currentCluster.length > 1) {
          timeClusters.add(List.from(currentCluster));
        }
        currentCluster = [currentPhoto];
      }
    }
    if (currentCluster.length > 1) {
      timeClusters.add(List.from(currentCluster));
    }

    // Refine clusters with image similarity
    final List<List<Photo>> finalClusters = [];
    for (final cluster in timeClusters) {
      final subClusters = await _refineClusterWithSimilarity(cluster);
      finalClusters.addAll(subClusters);
    }

    return finalClusters;
  }

  Future<List<List<Photo>>> _refineClusterWithSimilarity(
    List<Photo> cluster,
  ) async {
    if (cluster.length < 2) return [cluster];

    final Map<String, ImageHash?> hashes = {};
    for (final photo in cluster) {
      if (photo.imagePath != null) {
        hashes[photo.id] = await imageHashingService.getHash(photo.imagePath!);
      }
    }

    final List<List<Photo>> subClusters = [];
    final Set<Photo> processedPhotos = {};

    for (int i = 0; i < cluster.length; i++) {
      final photoA = cluster[i];
      if (processedPhotos.contains(photoA)) {
        continue;
      }

      final List<Photo> newSubCluster = [photoA];
      processedPhotos.add(photoA);

      for (int j = i + 1; j < cluster.length; j++) {
        final photoB = cluster[j];
        if (processedPhotos.contains(photoB)) {
          continue;
        }

        final hashA = hashes[photoA.id];
        final hashB = hashes[photoB.id];

        if (hashA != null && hashB != null) {
          final distance = hashA - hashB;
          if (distance <= 5) {
            newSubCluster.add(photoB);
            processedPhotos.add(photoB);
          }
        }
      }
      if (newSubCluster.length > 1) {
        subClusters.add(newSubCluster);
      }
    }

    return subClusters;
  }
}
