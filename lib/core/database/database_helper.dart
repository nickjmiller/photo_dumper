import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "PhotoComparer.db";
  static const _databaseVersion = 2;

  static const table = 'comparison_sessions';

  static const columnId = 'id';
  static const columnAllPhotoIds = 'allPhotoIds';
  static const columnEliminatedPhotoIds = 'eliminatedPhotoIds';
  static const columnCreatedAt = 'createdAt';

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Only have a single app-wide reference to the database
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade);
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId TEXT PRIMARY KEY,
            $columnAllPhotoIds TEXT NOT NULL,
            $columnEliminatedPhotoIds TEXT NOT NULL,
            $columnCreatedAt TEXT NOT NULL
          )
          ''');
  }

  // SQL code to upgrade the database
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS $table');
    await _onCreate(db, newVersion);
  }
}
