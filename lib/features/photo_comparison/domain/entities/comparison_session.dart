import 'package:equatable/equatable.dart';

import 'photo.dart';

class ComparisonSession extends Equatable {
  final String id;
  final List<Photo> allPhotos;
  final List<Photo> remainingPhotos;
  final List<Photo> eliminatedPhotos;
  final DateTime createdAt;

  const ComparisonSession({
    required this.id,
    required this.allPhotos,
    required this.remainingPhotos,
    required this.eliminatedPhotos,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        allPhotos,
        remainingPhotos,
        eliminatedPhotos,
        createdAt,
      ];
}
