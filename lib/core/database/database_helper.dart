import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "focuslock_ai.db";
  static const _databaseVersion = 4;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic
    if (oldVersion < 2) {
      // e.g. add new columns
    }
    if (oldVersion < 3) {
      // Added focus_sessions table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableFocusSessions (
          id TEXT PRIMARY KEY,
          taskId TEXT,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          durationSeconds INTEGER NOT NULL,
          completedSuccessfully INTEGER NOT NULL,
          FOREIGN KEY (taskId) REFERENCES $tableTasks (id) ON DELETE SET NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Performance indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_focus_sessions_taskId ON $tableFocusSessions (taskId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_tasks_isCompleted ON $tableTasks (isCompleted)');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        priority INTEGER NOT NULL,
        energyLevel INTEGER NOT NULL,
        estimatedMinutes INTEGER NOT NULL,
        deadline INTEGER,
        isCompleted INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        scheduledStartTime INTEGER,
        completedAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableFocusSessions (
        id TEXT PRIMARY KEY,
        taskId TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        completedSuccessfully INTEGER NOT NULL,
        FOREIGN KEY (taskId) REFERENCES $tableTasks (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableAppBlockRules (
        packageName TEXT PRIMARY KEY,
        isBlocked INTEGER NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_focus_sessions_taskId ON $tableFocusSessions (taskId)');
    await db.execute('CREATE INDEX idx_tasks_isCompleted ON $tableTasks (isCompleted)');
  }

  // Common CRUD operations can go here, though it's better to use Repositories for specific tables.
}
