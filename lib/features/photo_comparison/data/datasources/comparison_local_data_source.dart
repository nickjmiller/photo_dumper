import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../models/comparison_session_model.dart';

abstract class ComparisonLocalDataSource {
  Future<void> saveComparison(ComparisonSessionModel session);
  Future<ComparisonSessionModel?> getComparison(String id);
  Future<List<ComparisonSessionModel>> getAllComparisons();
  Future<void> deleteComparison(String id);
  Future<void> deleteAllComparisons();
  Future<List<String>> getAllPhotoIdsInUse();
}

class ComparisonLocalDataSourceImpl implements ComparisonLocalDataSource {
  final DatabaseHelper dbHelper;

  ComparisonLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<void> saveComparison(ComparisonSessionModel session) async {
    final db = await dbHelper.database;
    await db.insert(
      DatabaseHelper.table,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<ComparisonSessionModel?> getComparison(String id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.table,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ComparisonSessionModel.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<List<ComparisonSessionModel>> getAllComparisons() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      DatabaseHelper.table,
      orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
    );
    return maps.map((map) => ComparisonSessionModel.fromMap(map)).toList();
  }

  @override
  Future<void> deleteComparison(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseHelper.table,
      where: '${DatabaseHelper.columnId} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteAllComparisons() async {
    final db = await dbHelper.database;
    await db.delete(DatabaseHelper.table);
  }

  @override
  Future<List<String>> getAllPhotoIdsInUse() async {
    final sessions = await getAllComparisons();
    final allIds = <String>{};
    for (final session in sessions) {
      allIds.addAll(session.allPhotoIds);
    }
    return allIds.toList();
  }
}
