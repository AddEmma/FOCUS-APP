import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

enum TaskEnergyLevel { high, medium, low }

extension TaskEnergyLevelExtension on TaskEnergyLevel {
  String get label {
    switch (this) {
      case TaskEnergyLevel.high:
        return 'High Energy (Hard)';
      case TaskEnergyLevel.medium:
        return 'Medium Energy';
      case TaskEnergyLevel.low:
        return 'Low Energy (Easy)';
    }
  }

  int get sortOrder {
    switch (this) {
      case TaskEnergyLevel.high:
        return 0;
      case TaskEnergyLevel.medium:
        return 1;
      case TaskEnergyLevel.low:
        return 2;
    }
  }
}

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
  final TaskEnergyLevel energyLevel;
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
    this.energyLevel = TaskEnergyLevel.medium,
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
    TaskEnergyLevel? energyLevel,
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
      energyLevel: energyLevel ?? this.energyLevel,
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
      'energyLevel': energyLevel.index,
      'estimatedMinutes': estimatedMinutes,
      'deadline': deadline?.millisecondsSinceEpoch,
      'isCompleted': isCompleted ? 1 : 0,
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
      energyLevel: map['energyLevel'] != null ? TaskEnergyLevel.values[map['energyLevel'] as int] : TaskEnergyLevel.medium,
      estimatedMinutes: map['estimatedMinutes'] as int,
      deadline: map['deadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deadline'] as int)
          : null,
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
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
