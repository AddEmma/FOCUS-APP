import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import 'providers/focus_provider.dart';

class FocusActiveScreen extends ConsumerWidget {
  const FocusActiveScreen({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusSession = ref.watch(focusProvider);

    // Listen for completion or cancellation
    ref.listen(focusProvider, (previous, next) {
      if (next.status == FocusStatus.completed) {
        // Show success dialog or navigate
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Session Completed!'),
            content: const Text('Great job staying focused!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  context.go('/home');
                  ref.read(focusProvider.notifier).reset();
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      } else if (next.status == FocusStatus.idle &&
          previous?.status == FocusStatus.active) {
        // Session cancelled
        context.go('/home');
      }
    });

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/home'),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded, size: 100, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 2.seconds, delay: 1.seconds)
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
                const SizedBox(height: AppTheme.spacingXL),
                Text(
                  AppStrings.focusShieldTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  focusSession.isStrict
                      ? 'Strict Mode Active'
                      : AppStrings.focusShieldBody,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  _formatTime(focusSession.remainingSeconds),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXL * 2),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingXL,
                  ),
                  child: Text(
                    '"Discipline is doing what needs to be done, even if you don\'t want to do it."',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ).animate().fadeIn(delay: 1.seconds),
                const Spacer(),
                if (!focusSession.isStrict)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(focusProvider.notifier).cancelSession();
                    },
                    icon: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white70,
                    ),
                    label: const Text(
                      'Give Up',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                    child: Text(
                      'Strict Mode: Cannot Cancel',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
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
}
