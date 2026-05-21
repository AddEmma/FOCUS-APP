import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

extension TaskPriorityExtension on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.high:
        return const Color(0xFFFF512F);
      case TaskPriority.medium:
        return const Color(0xFFFFD93D);
      case TaskPriority.low:
        return const Color(0xFF4ECDC4);
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.high:
        return Icons.local_fire_department_rounded;
      case TaskPriority.medium:
        return Icons.bolt_rounded;
      case TaskPriority.low:
        return Icons.water_drop_rounded;
    }
  }

  int get sortOrder {
    switch (this) {
      case TaskPriority.high:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.low:
        return 2;
    }
  }
}

class FocusTask {
  final String id;
  final String title;
  final TaskPriority priority;
  final int estimatedMinutes;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? scheduledStartTime;
  final DateTime? completedAt;

  const FocusTask({
    required this.id,
    required this.title,
    required this.priority,
    required this.estimatedMinutes,
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
    this.scheduledStartTime,
    this.completedAt,
  });

  FocusTask copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    int? estimatedMinutes,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? scheduledStartTime,
    DateTime? completedAt,
    bool clearDeadline = false,
    bool clearScheduledTime = false,
    bool clearCompletedAt = false,
  }) {
    return FocusTask(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      scheduledStartTime: clearScheduledTime
          ? null
          : (scheduledStartTime ?? this.scheduledStartTime),
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'priority': priority.index,
      'estimatedMinutes': estimatedMinutes,
      'deadline': deadline?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'scheduledStartTime': scheduledStartTime?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory FocusTask.fromMap(Map<String, dynamic> map) {
    return FocusTask(
      id: map['id'] as String,
      title: map['title'] as String,
      priority: TaskPriority.values[map['priority'] as int],
      estimatedMinutes: map['estimatedMinutes'] as int,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      scheduledStartTime: map['scheduledStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['scheduledStartTime'] as int,
            )
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
    );
  }
}
