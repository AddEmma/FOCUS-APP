import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';

class SessionRecord {
  final String id;
  final String? taskId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final bool completedSuccessfully;

  SessionRecord({
    required this.id,
    this.taskId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.completedSuccessfully,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationSeconds': durationSeconds,
      'completedSuccessfully': completedSuccessfully ? 1 : 0,
    };
  }

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'],
      taskId: map['taskId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      durationSeconds: map['durationSeconds'],
      completedSuccessfully: map['completedSuccessfully'] == 1,
    );
  }
}

abstract class AnalyticsRepository {
  Future<void> saveSession(SessionRecord session);
  Future<Map<String, int>> getDailyUsageLast7Days();
  Future<int> getTotalFocusSeconds();
  Future<int> getTotalSessions();
}

class SqliteAnalyticsRepository implements AnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveSession(SessionRecord session) async {
    final db = await _dbHelper.database;
    await db.insert(
      DatabaseHelper.tableFocusSessions,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, int>> getDailyUsageLast7Days() async {
    final db = await _dbHelper.database;
    
    // Get date 7 days ago
    final startDateString = "${DateTime.now().subtract(const Duration(days: 6)).toIso8601String().substring(0, 10)}T00:00:00";

    // Group by date string (YYYY-MM-DD)
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT substr(startTime, 1, 10) as date, SUM(durationSeconds) as totalSeconds
      FROM ${DatabaseHelper.tableFocusSessions}
      WHERE startTime >= ? AND completedSuccessfully = 1
      GROUP BY substr(startTime, 1, 10)
    ''', [startDateString]);

    final Map<String, int> dailyUsage = {};
    for (var row in result) {
      dailyUsage[row['date'] as String] = (row['totalSeconds'] as num).toInt();
    }
    return dailyUsage;
  }

  Future<int> getTotalFocusSeconds() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(durationSeconds) as totalSeconds
      FROM \${DatabaseHelper.tableFocusSessions}
      WHERE completedSuccessfully = 1
    ''');
    return (result.first['totalSeconds'] as num?)?.toInt() ?? 0;
  }

  Future<int> getTotalSessions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM \${DatabaseHelper.tableFocusSessions}
      WHERE completedSuccessfully = 1
    ''');
    return (result.first['count'] as num?)?.toInt() ?? 0;
  }
}

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return SqliteAnalyticsRepository();
});
