import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/task.dart';

abstract class TaskRepository {
  Future<List<FocusTask>> getAllTasks();
  Future<void> saveTask(FocusTask task);
  Future<void> updateTask(FocusTask task);
  Future<void> deleteTask(String id);
  Future<void> clearAllTasks();
}

class SqliteTaskRepository implements TaskRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<FocusTask>> getAllTasks() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(DatabaseHelper.tableTasks);
    return List.generate(maps.length, (i) {
      return FocusTask.fromMap(maps[i]);
    });
  }

  @override
  Future<void> saveTask(FocusTask task) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableTasks,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTask(FocusTask task) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableTasks,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseHelper.tableTasks,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> clearAllTasks() async {
    final db = await _dbHelper.database;
    await db.delete(DatabaseHelper.tableTasks);
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return SqliteTaskRepository();
});
