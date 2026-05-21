import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'providers/focus_provider.dart';
import '../tasks/models/task.dart';

class FocusActiveScreen extends ConsumerStatefulWidget {
  const FocusActiveScreen({super.key});

  @override
  ConsumerState<FocusActiveScreen> createState() => _FocusActiveScreenState();
}

class _FocusActiveScreenState extends ConsumerState<FocusActiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  static const List<String> _quotes = [
    '"Discipline is doing what needs to be done,\neven if you don\'t want to."',
    '"Focus is the art of knowing what to ignore."',
    '"The secret of getting ahead is getting started."',
    '"Don\'t count the days. Make the days count."',
    '"Work hard in silence. Let success make the noise."',
    '"Small daily improvements lead to stunning results."',
    '"Your future self is watching you right now."',
  ];

  String get _currentQuote {
    final idx = DateTime.now().minute % _quotes.length;
    return _quotes[idx];
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final focusSession = ref.watch(focusProvider);

    ref.listen(focusProvider, (previous, next) {
      if (next.status == FocusStatus.completed) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _CompletionDialog(
            taskTitle: next.currentTask?.title,
            focusedMinutes: next.durationSeconds ~/ 60,
          ),
        );
      } else if (next.status == FocusStatus.idle &&
          previous?.status == FocusStatus.active) {
        context.go('/home');
      }
    });

    final progress = focusSession.progressFraction;
    final task = focusSession.currentTask;

    return PopScope(
      canPop: false,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            if (focusSession.blockedAttempts > 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          size: 12,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${focusSession.blockedAttempts} blocked',
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: task != null
                  ? [
                      const Color(0xFF0F0C29),
                      const Color(0xFF1A1A2E),
                    ]
                  : [
                      const Color(0xFF6C63FF),
                      const Color(0xFF5A52CC),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Task name display
                if (task != null) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: task.priority.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: task.priority.color.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.priority.icon,
                          size: 14,
                          color: task.priority.color,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 32),
                ] else ...[
                  const Icon(
                    Icons.lock_rounded,
                    size: 56,
                    color: Colors.white70,
                  ).animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                        duration: 2.seconds,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .scale(
                        begin: const Offset(1.05, 1.05),
                        end: const Offset(1, 1),
                        duration: 2.seconds,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 24),
                ],

                // Circular progress ring with timer
                _buildProgressRing(context, focusSession, progress),

                const SizedBox(height: 12),
                Text(
                  'remaining',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),

                const SizedBox(height: 24),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        child: const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.greenAccent,
                        ),
                        builder: (context, child) => Opacity(
                          opacity: 0.5 + _pulseController.value * 0.5,
                          child: child,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        focusSession.isStrict
                            ? 'STRICT MODE — Apps blocked'
                            : 'FOCUS LOCK — Distractions blocked',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const Spacer(),

                // Motivational quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _currentQuote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ).animate().fadeIn(delay: 1.seconds),

                const SizedBox(height: 24),

                // Give up / strict notice
                if (!focusSession.isStrict)
                  TextButton.icon(
                    onPressed: () => _showGiveUpDialog(context, ref),
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white30,
                      size: 16,
                    ),
                    label: const Text(
                      'Give Up Session',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: Colors.white24),
                        const SizedBox(width: 6),
                        Text(
                          'Strict Mode: Session cannot be cancelled',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppTheme.spacingL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing(
    BuildContext context,
    FocusSession session,
    double progress,
  ) {
    return AnimatedBuilder(
      animation: _pulseController,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          // Progress ring
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              color: progress > 0.75
                  ? Colors.greenAccent
                  : AppTheme.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
          // Inner content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatTime(session.remainingSeconds),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% done',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      builder: (context, child) {
        final glowIntensity = 0.3 + _pulseController.value * 0.15;
        return Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: glowIntensity),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  void _showGiveUpDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Give Up?'),
        content: const Text(
          'Are you sure? Your progress on this task won\'t be saved.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay Strong 💪'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(focusProvider.notifier).cancelSession();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Give Up'),
          ),
        ],
      ),
    );
  }
}

class _CompletionDialog extends StatelessWidget {
  final String? taskTitle;
  final int focusedMinutes;

  const _CompletionDialog({this.taskTitle, required this.focusedMinutes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56))
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (taskTitle != null)
              Text(
                '"$taskTitle" — Marked complete ✅',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'You focused for $focusedMinutes minutes.\nKeep the momentum going!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                  ref.read(focusProvider.notifier).reset();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Continue 🚀'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
