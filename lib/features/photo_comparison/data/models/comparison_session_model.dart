import 'dart:convert';

import 'package:equatable/equatable.dart';

class ComparisonSessionModel extends Equatable {
  final String id;
  final List<String> allPhotoIds;
  final List<String> eliminatedPhotoIds;
  final DateTime createdAt;

  const ComparisonSessionModel({
    required this.id,
    required this.allPhotoIds,
    required this.eliminatedPhotoIds,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, allPhotoIds, eliminatedPhotoIds, createdAt];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'allPhotoIds': jsonEncode(allPhotoIds),
      'eliminatedPhotoIds': jsonEncode(eliminatedPhotoIds),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ComparisonSessionModel.fromMap(Map<String, dynamic> map) {
    return ComparisonSessionModel(
      id: map['id'],
      allPhotoIds: List<String>.from(jsonDecode(map['allPhotoIds'])),
      eliminatedPhotoIds: List<String>.from(
        jsonDecode(map['eliminatedPhotoIds']),
      ),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
