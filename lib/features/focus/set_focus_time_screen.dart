import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import 'providers/focus_provider.dart';
import 'services/blocking_service.dart';

class SetFocusTimeScreen extends ConsumerStatefulWidget {
  const SetFocusTimeScreen({super.key});

  @override
  ConsumerState<SetFocusTimeScreen> createState() => _SetFocusTimeScreenState();
}

class _SetFocusTimeScreenState extends ConsumerState<SetFocusTimeScreen> {
  int _selectedMinutes = 30;
  bool _strictMode = false;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.setFocusTitle),
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
                  ],
                ),
              ),
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
                onPressed: () async {
                  final blockingService = BlockingService();
                  final hasPermissions = await blockingService
                      .hasRequiredPermissions();

                  if (!hasPermissions) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please grant all permissions first'),
                        ),
                      );
                      context.push('/permissions');
                    }
                    return;
                  }

                  await ref
                      .read(focusProvider.notifier)
                      .startSession(_selectedMinutes, _strictMode);
                  if (context.mounted) {
                    context.push('/focus-active');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Start Focus'),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
