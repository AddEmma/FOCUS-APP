import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../models/task.dart';
import '../providers/tasks_provider.dart';

class TaskCard extends ConsumerWidget {
  final FocusTask task;
  final int animationDelay;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.animationDelay = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? AppTheme.surface.withOpacity(0.5)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: task.isCompleted
                ? Colors.white.withOpacity(0.04)
                : task.priority.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Priority indicator bar
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    task.priority.color,
                    task.priority.color.withOpacity(0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: task.isCompleted
                                    ? AppTheme.textSecondary
                                    : Colors.white,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                      // Priority badge
                      _PriorityBadge(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.estimatedMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (task.deadline != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.event_rounded,
                          size: 13,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDeadline(task.deadline!),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: _isOverdue(task.deadline!)
                                ? AppTheme.error
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Completion toggle
            GestureDetector(
              onTap: () {
                if (task.isCompleted) {
                  ref.read(tasksProvider.notifier).uncompleteTask(task.id);
                } else {
                  ref.read(tasksProvider.notifier).completeTask(task.id);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: task.isCompleted
                      ? Colors.greenAccent.withOpacity(0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: task.isCompleted
                        ? Colors.greenAccent
                        : Colors.white30,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Colors.greenAccent,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: animationDelay.ms).slideX(
        begin: -0.05,
        end: 0,
        duration: 300.ms,
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    if (diff.inDays < 0) return 'Overdue';
    return '${diff.inDays}d left';
  }

  bool _isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: priority.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: priority.color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, size: 10, color: priority.color),
          const SizedBox(width: 3),
          Text(
            priority.label,
            style: TextStyle(
              color: priority.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
