import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../focus/services/blocking_service.dart';

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
  StreamSubscription? _eventSubscription;
  String? _currentApp;
  DateTime? _appStartTime;

  StatsNotifier() : super(const AsyncValue.loading()) {
    _loadStats();
    _listenToEvents();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  void _listenToEvents() {
    _eventSubscription = BlockingService().blockingEventsStream.listen((event) {
      if (event is Map) {
        final eventType = event['event'];
        if (eventType == 'app_activity') {
          _handleAppActivity(event['packageName'] as String);
        } else if (eventType == 'blocked_attempt') {
          // You could also log blocked attempts here if you want to track them in stats
        }
      }
    });
  }

  void _handleAppActivity(String packageName) {
    if (!state.hasValue) return;

    final now = DateTime.now();
    if (_currentApp != null && _appStartTime != null) {
      final duration = now.difference(_appStartTime!).inSeconds;
      if (duration > 0) {
        _logAppUsage(_currentApp!, duration);
      }
    }

    _currentApp = packageName;
    _appStartTime = now;
  }

  Future<void> _logAppUsage(String packageName, int durationSeconds) async {
    final currentData = state.value!;
    final today = DateTime.now().toIso8601String().split('T')[0];

    final newDailyUsage = Map<String, int>.from(currentData.dailyUsage);
    newDailyUsage[today] = (newDailyUsage[today] ?? 0) + durationSeconds;

    final newData = currentData.copyWith(
      dailyUsage: newDailyUsage,
      totalFocusSeconds: currentData.totalFocusSeconds + durationSeconds,
    );

    state = AsyncValue.data(newData);
    await _saveStats(newData);
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
