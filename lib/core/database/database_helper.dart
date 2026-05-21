import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "focuslock_ai.db";
  static const _databaseVersion = 1;

  // Tables
  static const tableTasks = 'tasks';
  static const tableFocusSessions = 'focus_sessions';
  static const tableAppBlockRules = 'app_block_rules';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        priority TEXT NOT NULL,
        estimatedMinutes INTEGER NOT NULL,
        deadline TEXT,
        isCompleted INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFocusSessions (
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        completedSuccessfully INTEGER NOT NULL,
        FOREIGN KEY (taskId) REFERENCES $tableTasks (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAppBlockRules (
        packageName TEXT PRIMARY KEY,
        isBlocked INTEGER NOT NULL
      )
    ''');
  }

  // Common CRUD operations can go here, though it's better to use Repositories for specific tables.
}
