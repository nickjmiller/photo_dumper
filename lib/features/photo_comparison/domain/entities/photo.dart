import 'package:equatable/equatable.dart';

class Photo extends Equatable {
  final String id;
  final String name;
  final String? imagePath;
  final DateTime createdAt;

  const Photo({
    required this.id,
    required this.name,
    this.imagePath,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, imagePath, createdAt];

  Photo copyWith({
    String? id,
    String? name,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Photo(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
