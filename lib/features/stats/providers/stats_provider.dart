import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import '../repositories/analytics_repository.dart';

class StatsData {
  final Map<String, int> dailyUsage; // Date string (YYYY-MM-DD) -> Seconds
  final int totalSessions;
  final int totalFocusSeconds;
  final int currentStreak;

  const StatsData({
    this.dailyUsage = const {},
    this.totalSessions = 0,
    this.totalFocusSeconds = 0,
    this.currentStreak = 0,
  });

  StatsData copyWith({
    Map<String, int>? dailyUsage,
    int? totalSessions,
    int? totalFocusSeconds,
    int? currentStreak,
  }) {
    return StatsData(
      dailyUsage: dailyUsage ?? this.dailyUsage,
      totalSessions: totalSessions ?? this.totalSessions,
      totalFocusSeconds: totalFocusSeconds ?? this.totalFocusSeconds,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}

class StatsNotifier extends StateNotifier<AsyncValue<StatsData>> {
  final AnalyticsRepository _repository;

  StatsNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dailyUsage = await _repository.getDailyUsageLast7Days();
      final totalSessions = await _repository.getTotalSessions();
      final totalSeconds = await _repository.getTotalFocusSeconds();

      // Streak calculation would go here based on dates, mock to 0 for MVP
      const currentStreak = 0;

      state = AsyncValue.data(StatsData(
        dailyUsage: dailyUsage,
        totalSessions: totalSessions,
        totalFocusSeconds: totalSeconds,
        currentStreak: currentStreak,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logSession(int durationSeconds, {String? taskId, required bool completedSuccessfully}) async {
    try {
      final now = DateTime.now();
      final session = SessionRecord(
        id: const Uuid().v4(),
        taskId: taskId,
        startTime: now.subtract(Duration(seconds: durationSeconds)),
        endTime: now,
        durationSeconds: durationSeconds,
        completedSuccessfully: completedSuccessfully,
      );

      await _repository.saveSession(session);
      await _loadStats(); // Reload to get fresh aggregates
    } catch (e) {
      print('Error loading stats: $e');
    }
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<StatsData>>((ref) {
      final repo = ref.watch(analyticsRepositoryProvider);
      return StatsNotifier(repo);
    });
