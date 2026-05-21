import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import 'models/task.dart';
import 'models/scheduled_block.dart';
import 'providers/tasks_provider.dart';
import 'services/ai_scheduler.dart';
import 'widgets/task_card.dart';
import 'widgets/add_task_bottom_sheet.dart';

// Provider to hold generated schedule
final generatedScheduleProvider =
    StateProvider<List<ScheduledBlock>>((ref) => []);

class DailyPlanScreen extends ConsumerStatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  ConsumerState<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends ConsumerState<DailyPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _generateSchedule() {
    final tasks = ref.read(tasksProvider);
    final startTime = AiScheduler.suggestStartTime();
    final blocks = AiScheduler.generate(tasks: tasks, startTime: startTime);
    ref.read(generatedScheduleProvider.notifier).state = blocks;

    // Update scheduled times on tasks
    for (final block in blocks) {
      if (!block.isBreak && block.task != null) {
        ref
            .read(tasksProvider.notifier)
            .updateScheduledTime(block.task!.id, block.startTime);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              'AI generated ${blocks.where((b) => !b.isBreak).length} focus blocks!',
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final schedule = ref.watch(generatedScheduleProvider);
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.background,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context, tasks),
              ),
              title: const Text(
                'Daily Plan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: [
                if (schedule.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.update_rounded),
                    tooltip: 'Reschedule Remaining',
                    onPressed: pending.isEmpty ? null : _generateSchedule,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_rounded),
                    tooltip: 'Generate AI Schedule',
                    onPressed: pending.isEmpty ? null : _generateSchedule,
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(schedule.isEmpty ? 'Timeline' : 'Timeline (${schedule.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checklist_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text('Tasks (${tasks.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTimelineTab(schedule, tasks),
            _buildTasksTab(pending, completed),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTask,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 300.ms),
    );
  }

  Widget _buildHeader(BuildContext context, List<FocusTask> tasks) {
    final completed = tasks.where((t) => t.isCompleted).length;
    final total = tasks.length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getTodayLabel(),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? "Let's plan your day! 🚀"
                      : '$completed of $total tasks done',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                if (total > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1.0
                            ? Colors.greenAccent
                            : AppTheme.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (total > 0)
            _CircularProgress(progress: progress, completed: completed, total: total),
        ],
      ),
    );
  }

  Widget _buildTimelineTab(List<ScheduledBlock> schedule, List<FocusTask> tasks) {
    if (schedule.isEmpty) {
      return _buildEmptyTimeline(tasks);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: schedule.length,
      itemBuilder: (context, index) {
        return _buildTimelineBlock(schedule[index], index);
      },
    );
  }

  Widget _buildEmptyTimeline(List<FocusTask> tasks) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: AppTheme.primary,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(
            tasks.isEmpty ? 'No tasks yet' : 'Ready to generate your plan',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tasks.isEmpty
                ? 'Add tasks first, then generate\nyour AI-powered daily plan'
                : 'Tap ✨ to have AI arrange\nyour ${tasks.length} tasks intelligently',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (tasks.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _generateSchedule,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Generate AI Schedule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildTimelineBlock(ScheduledBlock block, int index) {
    final isActive = block.isActive;
    final isPast = block.isPast && !block.isCompleted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time column
        SizedBox(
          width: 52,
          child: Column(
            children: [
              Text(
                _formatTime(block.startTime),
                style: TextStyle(
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        // Timeline line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: block.isBreak
                    ? AppTheme.secondary.withOpacity(0.5)
                    : isActive
                    ? AppTheme.primary
                    : isPast
                    ? Colors.white24
                    : block.task?.priority.color ?? AppTheme.primary,
                border: isActive
                    ? Border.all(color: AppTheme.primary, width: 2)
                    : null,
              ),
            ),
            if (index < 100)
              Container(
                width: 2,
                height: block.isBreak ? 32 : 70,
                color: Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Block card
        Expanded(
          child: GestureDetector(
            onTap: block.isBreak ? null : () => _startFocusForBlock(block),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(block.isBreak ? 8 : 14),
              decoration: BoxDecoration(
                color: block.isBreak
                    ? Colors.white.withOpacity(0.03)
                    : isActive
                    ? AppTheme.primary.withOpacity(0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppTheme.primary.withOpacity(0.5)
                      : block.isBreak
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: block.isBreak
                  ? Row(
                      children: [
                        const Icon(
                          Icons.coffee_rounded,
                          size: 14,
                          color: AppTheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Break · ${block.durationMinutes} min',
                          style: const TextStyle(
                            color: AppTheme.secondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'NOW',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Text(
                                block.task?.title ?? 'Focus Block',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isPast ? Colors.white38 : Colors.white,
                                  decoration: block.task?.isCompleted == true
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${block.durationMinutes} min · ${_formatTime(block.startTime)} – ${_formatTime(block.endTime)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPast
                                      ? Colors.white24
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!block.isBreak && block.task?.isCompleted != true)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                        if (block.task?.isCompleted == true)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.greenAccent,
                            size: 22,
                          ),
                      ],
                    ),
            ),
          ).animate().fadeIn(delay: (index * 50).ms).slideX(
            begin: 0.05,
            end: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab(
    List<FocusTask> pending,
    List<FocusTask> completed,
  ) {
    if (pending.isEmpty && completed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 64,
              color: AppTheme.textSecondary,
            ).animate().scale(delay: 100.ms),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first task',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionLabel('Pending · ${pending.length}'),
          const SizedBox(height: 8),
          ...pending.asMap().entries.map((e) => Dismissible(
            key: Key(e.value.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            ),
            onDismissed: (_) =>
                ref.read(tasksProvider.notifier).removeTask(e.value.id),
            child: TaskCard(
              task: e.value,
              animationDelay: e.key * 50,
              onTap: () => _startFocusForTask(e.value),
            ),
          )),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionLabel('Completed · ${completed.length}', color: Colors.greenAccent),
          const SizedBox(height: 8),
          ...completed.asMap().entries.map(
            (e) => TaskCard(task: e.value, animationDelay: e.key * 30),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String label, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color ?? AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAddTask() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskBottomSheet(),
    );
  }

  void _startFocusForBlock(ScheduledBlock block) {
    if (block.task == null) return;
    context.push('/set-focus', extra: {'task': block.task});
  }

  void _startFocusForTask(FocusTask task) {
    context.push('/set-focus', extra: {'task': task});
  }

  String _getTodayLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _CircularProgress extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const _CircularProgress({
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.greenAccent : AppTheme.primary,
            ),
          ),
          Text(
            '$completed/$total',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
