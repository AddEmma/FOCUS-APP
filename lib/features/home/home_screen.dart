import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../focus/providers/focus_provider.dart';
import '../stats/providers/stats_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusSession = ref.watch(focusProvider);
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Focus Status Card
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  gradient: AppTheme.fireGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                          focusSession.status == FocusStatus.active
                              ? Icons.timer
                              : Icons.local_fire_department_rounded,
                          color: Colors.white,
                          size: 48,
                        )
                        .animate(
                          target: focusSession.status == FocusStatus.active
                              ? 1
                              : 0,
                        )
                        .scale(duration: 1.seconds, curve: Curves.easeInOut)
                        .then()
                        .shimmer(),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      focusSession.status == FocusStatus.active
                          ? 'Focusing: ${_formatTime(focusSession.remainingSeconds)}'
                          : AppStrings.statusFree,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [const FontFeature.tabularFigures()],
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    if (focusSession.status == FocusStatus.active)
                      ElevatedButton(
                        onPressed: () => context.push('/focus-active'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXL,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                        child: const Text('View Session'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => context.push('/select-apps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingXL,
                            vertical: AppTheme.spacingM,
                          ),
                        ),
                        child: const Text('Start Focus'),
                      ),
                  ],
                ),
              ).animate().fadeIn().slideY(),

              const SizedBox(height: AppTheme.spacingL),

              // Stats Grid
              Text(
                'Today\'s Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppTheme.spacingM),

              Expanded(
                child: statsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox(),
                  data: (statsData) {
                    final today = DateTime.now().toIso8601String().split(
                      'T',
                    )[0];
                    final todaySeconds = statsData.dailyUsage[today] ?? 0;
                    final todayHours = (todaySeconds / 3600).toStringAsFixed(1);

                    final sessionCount = statsData.totalSessions;

                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: AppTheme.spacingM,
                      mainAxisSpacing: AppTheme.spacingM,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.timer_rounded,
                          color: Colors.blueAccent,
                          value: '${todayHours}h',
                          label: AppStrings.cardFocusTime,
                          delay: 300,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent,
                          value: '${statsData.currentStreak}',
                          label: AppStrings.cardStreak,
                          delay: 400,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.block_rounded,
                          color: Colors.redAccent,
                          value: '$sessionCount',
                          label: AppStrings.cardBlocked,
                          delay: 500,
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.trending_up_rounded,
                          color: Colors.greenAccent,
                          value: 'Top 5%',
                          label: 'Rank', // Placeholder for rank
                          delay: 600,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).scale();
  }
}
