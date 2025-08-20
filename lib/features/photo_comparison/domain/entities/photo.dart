import 'package:equatable/equatable.dart';
import 'dart:io';

class Photo extends Equatable {
  final String id;
  final String name;
  final String? imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;
  final bool isSelected;
  final File? file;

  const Photo({
    required this.id,
    required this.name,
    this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    this.isSelected = false,
    this.file,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    imagePath,
    thumbnailPath,
    createdAt,
    isSelected,
    file,
  ];

  Photo copyWith({
    String? id,
    String? name,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
    bool? isSelected,
    File? file,
  }) {
    return Photo(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
      file: file ?? this.file,
    );
  }
}
