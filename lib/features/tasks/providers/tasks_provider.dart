import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';

const _uuid = Uuid();

class TasksNotifier extends StateNotifier<List<FocusTask>> {
  final TaskRepository _repository;

  TasksNotifier(this._repository) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final tasks = await _repository.getAllTasks();
    state = tasks;
  }

  Future<void> addTask({
    required String title,
    required TaskPriority priority,
    required TaskEnergyLevel energyLevel,
    required int estimatedMinutes,
    DateTime? deadline,
  }) async {
    final task = FocusTask(
      id: _uuid.v4(),
      title: title,
      priority: priority,
      energyLevel: energyLevel,
      estimatedMinutes: estimatedMinutes,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    state = [...state, task];
    await _repository.saveTask(task);
  }

  Future<void> removeTask(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _repository.deleteTask(id);
  }

  Future<void> completeTask(String id) async {
    final updatedState = <FocusTask>[];
    for (var t in state) {
      if (t.id == id) {
        final updated = t.copyWith(isCompleted: true, completedAt: DateTime.now());
        updatedState.add(updated);
        await _repository.updateTask(updated);
      } else {
        updatedState.add(t);
      }
    }
    state = updatedState;
  }

  Future<void> uncompleteTask(String id) async {
    final updatedState = <FocusTask>[];
    for (var t in state) {
      if (t.id == id) {
        final updated = t.copyWith(isCompleted: false, clearCompletedAt: true);
        updatedState.add(updated);
        await _repository.updateTask(updated);
      } else {
        updatedState.add(t);
      }
    }
    state = updatedState;
  }

  Future<void> updateScheduledTime(String id, DateTime? startTime) async {
    final updatedState = <FocusTask>[];
    for (var t in state) {
      if (t.id == id) {
        final updated = startTime == null
            ? t.copyWith(clearScheduledTime: true)
            : t.copyWith(scheduledStartTime: startTime);
        updatedState.add(updated);
        await _repository.updateTask(updated);
      } else {
        updatedState.add(t);
      }
    }
    state = updatedState;
  }

  Future<void> clearCompletedTasks() async {
    final completed = state.where((t) => t.isCompleted).toList();
    for (var t in completed) {
      await _repository.deleteTask(t.id);
    }
    state = state.where((t) => !t.isCompleted).toList();
  }

  Future<void> clearAllTasks() async {
    state = [];
    await _repository.clearAllTasks();
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
      final repo = ref.watch(taskRepositoryProvider);
      return TasksNotifier(repo);
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
