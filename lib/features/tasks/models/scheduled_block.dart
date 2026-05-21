import 'task.dart';

class ScheduledBlock {
  final String id;
  final FocusTask? task; // null if it's a break
  final DateTime startTime;
  final DateTime endTime;
  final bool isBreak;
  bool isCompleted;

  ScheduledBlock({
    required this.id,
    this.task,
    required this.startTime,
    required this.endTime,
    this.isBreak = false,
    this.isCompleted = false,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;

  String get displayTitle {
    if (isBreak) return '☕ Break';
    return task?.title ?? 'Focus Block';
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  bool get isPast {
    return DateTime.now().isAfter(endTime);
  }

  bool get isFuture {
    return DateTime.now().isBefore(startTime);
  }
}
