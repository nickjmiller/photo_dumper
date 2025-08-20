import 'package:equatable/equatable.dart';

class Photo extends Equatable {
  final String id;
  final String name;
  final String? imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  final bool isSelected;

  const Photo({
    required this.id,
    required this.name,
    this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    this.isSelected = false,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    imagePath,
    thumbnailPath,
    createdAt,
    isSelected,
  ];

  Photo copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    return Photo(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
