import 'dart:convert';

import 'package:equatable/equatable.dart';

class ComparisonSessionModel extends Equatable {
  final String id;
  final List<String> allPhotoIds;
  final List<String> remainingPhotoIds;
  final List<String> eliminatedPhotoIds;
  final List<String> skippedPairKeys;
  final bool dontAskAgain;
  final DateTime createdAt;

  const ComparisonSessionModel({
    required this.id,
    required this.allPhotoIds,
    required this.remainingPhotoIds,
    required this.eliminatedPhotoIds,
    required this.skippedPairKeys,
    required this.dontAskAgain,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        allPhotoIds,
        remainingPhotoIds,
        eliminatedPhotoIds,
        skippedPairKeys,
        dontAskAgain,
        createdAt,
      ];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'allPhotoIds': jsonEncode(allPhotoIds),
      'remainingPhotoIds': jsonEncode(remainingPhotoIds),
      'eliminatedPhotoIds': jsonEncode(eliminatedPhotoIds),
      'skippedPairKeys': jsonEncode(skippedPairKeys),
      'dontAskAgain': dontAskAgain ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ComparisonSessionModel.fromMap(Map<String, dynamic> map) {
    return ComparisonSessionModel(
      id: map['id'],
      allPhotoIds: List<String>.from(jsonDecode(map['allPhotoIds'])),
      remainingPhotoIds: List<String>.from(jsonDecode(map['remainingPhotoIds'])),
      eliminatedPhotoIds: List<String>.from(jsonDecode(map['eliminatedPhotoIds'])),
      skippedPairKeys: List<String>.from(jsonDecode(map['skippedPairKeys'])),
      dontAskAgain: map['dontAskAgain'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
