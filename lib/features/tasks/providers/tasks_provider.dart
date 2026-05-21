import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

const _tasksKey = 'focus_tasks';
const _uuid = Uuid();

class TasksNotifier extends StateNotifier<List<FocusTask>> {
  TasksNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw != null) {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      state = decoded
          .map((e) => FocusTask.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((t) => t.toMap()).toList());
    await prefs.setString(_tasksKey, encoded);
  }

  Future<void> addTask({
    required String title,
    required TaskPriority priority,
    required int estimatedMinutes,
    DateTime? deadline,
  }) async {
    final task = FocusTask(
      id: _uuid.v4(),
      title: title,
      priority: priority,
      estimatedMinutes: estimatedMinutes,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    state = [...state, task];
    await _persist();
  }

  Future<void> removeTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _persist();
  }

  Future<void> completeTask(String id) async {
    state = state.map((t) {
      if (t.id == id) {
        return t.copyWith(isCompleted: true, completedAt: DateTime.now());
      }
      return t;
    }).toList();
    await _persist();
  }

  Future<void> uncompleteTask(String id) async {
    state = state.map((t) {
      if (t.id == id) {
        return t.copyWith(isCompleted: false, clearCompletedAt: true);
      }
      return t;
    }).toList();
    await _persist();
  }

  Future<void> updateScheduledTime(String id, DateTime? startTime) async {
    state = state.map((t) {
      if (t.id == id) {
        if (startTime == null) {
          return t.copyWith(clearScheduledTime: true);
        }
        return t.copyWith(scheduledStartTime: startTime);
      }
      return t;
    }).toList();
    await _persist();
  }

  /// Clear tasks from previous day (call at day boundary or manually)
  Future<void> clearCompletedTasks() async {
    state = state.where((t) => !t.isCompleted).toList();
    await _persist();
  }

  Future<void> clearAllTasks() async {
    state = [];
    await _persist();
  }

  // Today's tasks only
  List<FocusTask> get todayTasks {
    final today = DateTime.now();
    return state.where((t) {
      final created = t.createdAt;
      return created.year == today.year &&
          created.month == today.month &&
          created.day == today.day;
    }).toList();
  }

  List<FocusTask> get pendingTasks =>
      state.where((t) => !t.isCompleted).toList();

  List<FocusTask> get completedTasks =>
      state.where((t) => t.isCompleted).toList();

  int get productivityScore {
    final total = state.length;
    if (total == 0) return 0;
    final completed = state.where((t) => t.isCompleted).length;
    // Weight by priority
    int weightedCompleted = 0;
    int weightedTotal = 0;
    for (final task in state) {
      final weight = task.priority == TaskPriority.high
          ? 3
          : task.priority == TaskPriority.medium
          ? 2
          : 1;
      weightedTotal += weight;
      if (task.isCompleted) weightedCompleted += weight;
    }
    if (weightedTotal == 0) return 0;
    return ((weightedCompleted / weightedTotal) * 100).round();
  }
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<FocusTask>>((ref) {
      return TasksNotifier();
    });

// Derived providers
final pendingTasksProvider = Provider<List<FocusTask>>((ref) {
  return ref.watch(tasksProvider).where((t) => !t.isCompleted).toList();
});

final completedTasksProvider = Provider<List<FocusTask>>((ref) {
  return ref.watch(tasksProvider).where((t) => t.isCompleted).toList();
});

final productivityScoreProvider = Provider<int>((ref) {
  return ref.watch(tasksProvider.notifier).productivityScore;
});
