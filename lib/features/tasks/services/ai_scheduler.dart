import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/scheduled_block.dart';

const _uuid = Uuid();

/// Pure Dart AI-powered rule-based scheduler.
/// Produces a daily plan from a list of tasks.
class AiScheduler {
  static const int _workBlockMinutes = 50;
  static const int _breakMinutes = 10;
  static const int _shortBreakMinutes = 5;

  /// Generate a full daily schedule starting from [startTime].
  /// Applies energy-based ordering: High tasks first in AM, Low tasks last.
  static List<ScheduledBlock> generate({
    required List<FocusTask> tasks,
    required DateTime startTime,
  }) {
    if (tasks.isEmpty) return [];

    final List<FocusTask> pending = tasks.where((t) => !t.isCompleted).toList();
    if (pending.isEmpty) return [];

    // Sort by priority + energy-based ordering
    final sorted = _sortByEnergyAndPriority(pending, startTime);

    final List<ScheduledBlock> blocks = [];
    DateTime cursor = startTime;
    int workMinutesSinceBreak = 0;

    for (int i = 0; i < sorted.length; i++) {
      final task = sorted[i];

      // Check if we need a break before this task
      if (workMinutesSinceBreak >= _workBlockMinutes && i > 0) {
        final breakEnd = cursor.add(const Duration(minutes: _breakMinutes));
        blocks.add(
          ScheduledBlock(
            id: _uuid.v4(),
            task: null,
            startTime: cursor,
            endTime: breakEnd,
            isBreak: true,
          ),
        );
        cursor = breakEnd;
        workMinutesSinceBreak = 0;
      }

      // Schedule the task
      final taskEnd = cursor.add(Duration(minutes: task.estimatedMinutes));
      blocks.add(
        ScheduledBlock(
          id: _uuid.v4(),
          task: task,
          startTime: cursor,
          endTime: taskEnd,
          isBreak: false,
        ),
      );
      cursor = taskEnd;
      workMinutesSinceBreak += task.estimatedMinutes;

      // Add short break between tasks (if not last)
      if (i < sorted.length - 1 && workMinutesSinceBreak < _workBlockMinutes) {
        final shortBreakEnd =
            cursor.add(const Duration(minutes: _shortBreakMinutes));
        blocks.add(
          ScheduledBlock(
            id: _uuid.v4(),
            task: null,
            startTime: cursor,
            endTime: shortBreakEnd,
            isBreak: true,
          ),
        );
        cursor = shortBreakEnd;
        workMinutesSinceBreak += _shortBreakMinutes;
      }
    }

    return blocks;
  }

  /// Energy-based ordering:
  /// - Morning (before 12pm): Hard/High tasks first
  /// - Afternoon (12pm–5pm): Medium tasks
  /// - Evening (after 5pm): Light/Low tasks first
  static List<FocusTask> _sortByEnergyAndPriority(
    List<FocusTask> tasks,
    DateTime startTime,
  ) {
    final hour = startTime.hour;
    final List<FocusTask> sorted = List.from(tasks);

    if (hour < 12) {
      // Morning: High Energy → Medium → Low Energy. Tie-break by priority
      sorted.sort((a, b) {
        final cmp = a.energyLevel.sortOrder.compareTo(b.energyLevel.sortOrder);
        if (cmp != 0) return cmp;
        return a.priority.sortOrder.compareTo(b.priority.sortOrder);
      });
    } else if (hour < 17) {
      // Afternoon: Medium Energy → High Energy → Low Energy
      sorted.sort((a, b) {
        const order = {
          TaskEnergyLevel.medium: 0,
          TaskEnergyLevel.high: 1,
          TaskEnergyLevel.low: 2,
        };
        final cmp = (order[a.energyLevel] ?? 1).compareTo(order[b.energyLevel] ?? 1);
        if (cmp != 0) return cmp;
        return a.priority.sortOrder.compareTo(b.priority.sortOrder);
      });
    } else {
      // Evening: Low Energy → Medium → High Energy (light tasks to wind down)
      sorted.sort((a, b) {
        final cmp = b.energyLevel.sortOrder.compareTo(a.energyLevel.sortOrder);
        if (cmp != 0) return cmp;
        return a.priority.sortOrder.compareTo(b.priority.sortOrder);
      });
    }

    return sorted;
  }

  /// Suggest a good start time for today based on current time.
  static DateTime suggestStartTime() {
    final now = DateTime.now();
    // Round up to next quarter hour
    final minutes = now.minute;
    final roundedMinutes = ((minutes / 15).ceil() * 15) % 60;
    final addHours = ((minutes / 15).ceil() * 15) ~/ 60;
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + addHours,
      roundedMinutes,
    );
  }

  /// Calculate total planned focus time in minutes for a list of blocks
  static int totalFocusMinutes(List<ScheduledBlock> blocks) {
    return blocks
        .where((b) => !b.isBreak)
        .fold(0, (sum, b) => sum + b.durationMinutes);
  }

  /// Find the currently active or next upcoming block
  static ScheduledBlock? findCurrentOrNext(List<ScheduledBlock> blocks) {
    // First check if any block is active now
    for (final block in blocks) {
      if (block.isActive) return block;
    }
    // Otherwise find the next upcoming one
    final upcoming = blocks.where((b) => b.isFuture).toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.first;
  }
}
