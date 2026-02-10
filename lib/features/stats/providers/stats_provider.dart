import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  Map<String, dynamic> toMap() {
    return {
      'dailyUsage': dailyUsage,
      'totalSessions': totalSessions,
      'totalFocusSeconds': totalFocusSeconds,
      'currentStreak': currentStreak,
    };
  }

  factory StatsData.fromMap(Map<String, dynamic> map) {
    return StatsData(
      dailyUsage: Map<String, int>.from(map['dailyUsage'] ?? {}),
      totalSessions: map['totalSessions'] ?? 0,
      totalFocusSeconds: map['totalFocusSeconds'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
    );
  }

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
  StatsNotifier() : super(const AsyncValue.loading()) {
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsString = prefs.getString('stats_data');
      if (statsString != null) {
        final map = json.decode(statsString);
        state = AsyncValue.data(StatsData.fromMap(map));
      } else {
        state = const AsyncValue.data(StatsData());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logSession(int durationSeconds) async {
    if (!state.hasValue) return;

    final currentData = state.value!;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final newDailyUsage = Map<String, int>.from(currentData.dailyUsage);
    newDailyUsage[today] = (newDailyUsage[today] ?? 0) + durationSeconds;

    // Simple streak logic: if yesterday had usage, increment, else 1
    // For now, simple increment if usage > 0 today
    int newStreak = currentData.currentStreak;
    if ((newDailyUsage[today] ?? 0) > 0 &&
        (currentData.dailyUsage[today] ?? 0) == 0) {
      // Logic to check yesterday would go here
    }

    final newData = currentData.copyWith(
      dailyUsage: newDailyUsage,
      totalSessions: currentData.totalSessions + 1,
      totalFocusSeconds: currentData.totalFocusSeconds + durationSeconds,
    );

    state = AsyncValue.data(newData);
    await _saveStats(newData);
  }

  Future<void> _saveStats(StatsData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('stats_data', json.encode(data.toMap()));
  }
}

final statsProvider =
    StateNotifierProvider<StatsNotifier, AsyncValue<StatsData>>((ref) {
      return StatsNotifier();
    });
