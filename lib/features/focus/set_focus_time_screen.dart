import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../tasks/models/task.dart';
import 'providers/focus_provider.dart';
import 'services/blocking_service.dart';

class SetFocusTimeScreen extends ConsumerStatefulWidget {
  final FocusTask? task;

  const SetFocusTimeScreen({super.key, this.task});

  @override
  ConsumerState<SetFocusTimeScreen> createState() => _SetFocusTimeScreenState();
}

class _SetFocusTimeScreenState extends ConsumerState<SetFocusTimeScreen> {
  late int _selectedMinutes;
  bool _strictMode = false;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    // Pre-fill from task if available
    _selectedMinutes = widget.task?.estimatedMinutes ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    final hasTask = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasTask ? 'Focus Session' : AppStrings.setFocusTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Task card (if task linked)
              if (hasTask) ...[
                _buildTaskCard(widget.task!),
                const SizedBox(height: AppTheme.spacingL),
              ],

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_selectedMinutes',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 80,
                      ),
                    ).animate().scale(),
                    Text(
                      AppStrings.minutes,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXL),
                    Wrap(
                          spacing: AppTheme.spacingM,
                          runSpacing: AppTheme.spacingM,
                          alignment: WrapAlignment.center,
                          children: _durations.map((minutes) {
                            final isSelected = _selectedMinutes == minutes;
                            return ChoiceChip(
                              label: Text('${minutes}m'),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedMinutes = minutes);
                                }
                              },
                              backgroundColor: AppTheme.surface,
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.white10,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: AppTheme.spacingL),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                      ),
                      child: Column(
                        children: [
                          Slider(
                            value: _selectedMinutes.toDouble(),
                            min: 1,
                            max: 240,
                            divisions: 239,
                            activeColor: AppTheme.primary,
                            inactiveColor: Colors.white10,
                            onChanged: (value) {
                              setState(() => _selectedMinutes = value.toInt());
                            },
                          ),
                          Text(
                            'Drag to customize time (up to 4 hours)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),

              // Strict mode toggle
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                    color: _strictMode ? AppTheme.error : Colors.transparent,
                  ),
                ),
                child: SwitchListTile(
                  value: _strictMode,
                  onChanged: (value) => setState(() => _strictMode = value),
                  title: const Text(AppStrings.strictMode),
                  subtitle: const Text(AppStrings.strictModeDesc),
                  activeColor: AppTheme.error,
                  secondary: Icon(
                    Icons.lock_rounded,
                    color: _strictMode ? AppTheme.error : Colors.grey,
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: AppTheme.spacingL),

              ElevatedButton(
                onPressed: _startSession,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_arrow_rounded),
                    const SizedBox(width: 8),
                    Text(
                      hasTask
                          ? 'Focus on ${widget.task!.title.length > 20 ? "${widget.task!.title.substring(0, 20)}..." : widget.task!.title}'
                          : 'Start Focus',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(FocusTask task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            task.priority.color.withOpacity(0.2),
            task.priority.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: task.priority.color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: task.priority.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(task.priority.icon, color: task.priority.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Focusing on',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  task.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task.priority.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: task.priority.color.withOpacity(0.4)),
            ),
            child: Text(
              task.priority.label,
              style: TextStyle(
                color: task.priority.color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  Future<void> _startSession() async {
    final blockingService = BlockingService();
    final hasPermissions = await blockingService.hasRequiredPermissions();

    if (!hasPermissions) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please grant all permissions first')),
        );
        context.push('/permissions');
      }
      return;
    }

    await ref
        .read(focusProvider.notifier)
        .startSession(_selectedMinutes, _strictMode, task: widget.task);

    if (mounted) {
      context.push('/focus-active');
    }
  }
}
