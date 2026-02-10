import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selectedDayIndex = 0;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              // TODO: Implement add schedule logic
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Day Selector
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                ),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedDayIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.white10,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _days[index],
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${12 + index}', // Mock date
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn().slideX(),

            const SizedBox(height: AppTheme.spacingM),

            // Schedule List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                children: [
                  _buildScheduleCard(
                    context,
                    timeRange: '09:00 AM - 11:00 AM',
                    title: 'Deep Work',
                    appsCount: 5,
                    isActive: true,
                    delay: 100,
                  ),
                  _buildScheduleCard(
                    context,
                    timeRange: '02:00 PM - 04:00 PM',
                    title: 'No Social Media',
                    appsCount: 3,
                    isActive: false,
                    delay: 200,
                  ),
                  // Empty State Placeholder
                  if (false) ...[
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 64,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            'No schedules for this day',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add schedule dialog
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildScheduleCard(
    BuildContext context, {
    required String timeRange,
    required String title,
    required int appsCount,
    required bool isActive,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
          color: isActive
              ? AppTheme.primary.withOpacity(0.5)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeRange,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$appsCount apps blocked',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: (value) {},
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideX();
  }
}
