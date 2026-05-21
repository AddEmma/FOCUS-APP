import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'providers/focus_provider.dart';

class BreakScreen extends ConsumerStatefulWidget {
  final int breakDurationSeconds;
  final String? nextTaskTitle;

  const BreakScreen({
    super.key,
    this.breakDurationSeconds = 600,
    this.nextTaskTitle,
  });

  @override
  ConsumerState<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends ConsumerState<BreakScreen>
    with TickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  late AnimationController _pulseController;

  final List<String> _breakTips = [
    "Stand up and stretch 🧘",
    "Hydrate — drink some water 💧",
    "Step outside for fresh air 🌿",
    "Take 5 deep breaths 🌬️",
    "Close your eyes and rest 👁️",
    "Do some light movement 🚶",
    "Reflect on what you accomplished 🌟",
  ];

  String get _currentTip {
    final index = (widget.breakDurationSeconds - _remaining) ~/ 60 %
        _breakTips.length;
    return _breakTips[index];
  }

  @override
  void initState() {
    super.initState();
    _remaining = widget.breakDurationSeconds;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        _onBreakEnd();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  void _onBreakEnd() {
    if (mounted) {
      context.go('/focus-active');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isWarning => _remaining <= 120; // last 2 mins

  @override
  Widget build(BuildContext context) {
    final progress =
        1.0 - (_remaining / widget.breakDurationSeconds);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isWarning
                ? [const Color(0xFF1A1A2E), const Color(0xFF2D1B00)]
                : [const Color(0xFF0F2027), const Color(0xFF1A3A2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Break icon with pulse
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isWarning
                        ? 1.0 + _pulseController.value * 0.08
                        : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isWarning
                        ? AppTheme.error.withOpacity(0.15)
                        : AppTheme.secondary.withOpacity(0.15),
                    border: Border.all(
                      color: _isWarning
                          ? AppTheme.error.withOpacity(0.4)
                          : AppTheme.secondary.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _isWarning
                        ? Icons.timer_rounded
                        : Icons.self_improvement_rounded,
                    size: 56,
                    color: _isWarning ? AppTheme.error : AppTheme.secondary,
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Status label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  _isWarning ? '⚠️  Resuming soon...' : '☕  Break Time',
                  key: ValueKey(_isWarning),
                  style: TextStyle(
                    color: _isWarning ? AppTheme.error : AppTheme.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Big timer
              Text(
                _formatTime(_remaining),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 72,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(
                duration: 3.seconds,
                delay: 1.seconds,
                color: _isWarning ? AppTheme.error : AppTheme.secondary,
              ),

              const SizedBox(height: 8),
              Text(
                'remaining',
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),

              const SizedBox(height: 24),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isWarning ? AppTheme.error : AppTheme.secondary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tip card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    _currentTip,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // Next task preview
              if (widget.nextTaskTitle != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Up next',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.nextTaskTitle!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),

              const Spacer(),

              // Skip break button
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  context.go('/focus-active');
                },
                child: const Text(
                  'Skip Break — Start Focusing',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
