import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/blocking_service.dart';
import '../../apps/providers/apps_provider.dart';
import '../../stats/providers/stats_provider.dart';
import '../../tasks/models/task.dart';
import '../../tasks/providers/tasks_provider.dart';

enum FocusStatus { idle, active, completed }

class FocusSession {
  final FocusStatus status;
  final int durationSeconds;
  final int remainingSeconds;
  final bool isStrict;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> blockedApps;
  final int blockedAttempts;
  final String? lastDetectedApp;
  final FocusTask? currentTask; // The task being focused on

  const FocusSession({
    this.status = FocusStatus.idle,
    this.durationSeconds = 0,
    this.remainingSeconds = 0,
    this.isStrict = false,
    this.startTime,
    this.endTime,
    this.blockedApps = const [],
    this.blockedAttempts = 0,
    this.lastDetectedApp,
    this.currentTask,
  });

  FocusSession copyWith({
    FocusStatus? status,
    int? durationSeconds,
    int? remainingSeconds,
    bool? isStrict,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? blockedApps,
    int? blockedAttempts,
    String? lastDetectedApp,
    FocusTask? currentTask,
    bool clearTask = false,
  }) {
    return FocusSession(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isStrict: isStrict ?? this.isStrict,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedAttempts: blockedAttempts ?? this.blockedAttempts,
      lastDetectedApp: lastDetectedApp ?? this.lastDetectedApp,
      currentTask: clearTask ? null : (currentTask ?? this.currentTask),
    );
  }

  double get progressFraction {
    if (durationSeconds == 0) return 0;
    final elapsed = durationSeconds - remainingSeconds;
    return (elapsed / durationSeconds).clamp(0.0, 1.0);
  }

  int get elapsedSeconds => durationSeconds - remainingSeconds;
}

class FocusNotifier extends StateNotifier<FocusSession> {
  Timer? _timer;
  StreamSubscription? _eventSubscription;
  final BlockingService _blockingService;
  final Ref _ref;
  final StatsNotifier _statsNotifier;

  FocusNotifier(this._blockingService, this._statsNotifier, this._ref)
    : super(const FocusSession()) {
    _checkActiveSession();
    _listenToSelectedApps();
  }

  void _listenToSelectedApps() {
    _ref.listen<Set<String>>(selectedAppsProvider, (previous, next) {
      if (state.status == FocusStatus.active) {
        final appsToBlock = next.toList();
        state = state.copyWith(blockedApps: appsToBlock);
        _blockingService.startBlocking(
          blockedApps: appsToBlock,
          endTime: state.endTime!,
        );
      }
    });
  }

  Future<void> _checkActiveSession() async {
    final status = await _blockingService.getBlockingStatus();
    if (status['isActive'] == true) {
      final endTimeMillis = status['endTimeMillis'] as int;
      final endTime = DateTime.fromMillisecondsSinceEpoch(endTimeMillis);
      final now = DateTime.now();

      if (endTime.isAfter(now)) {
        final remainingSeconds = endTime.difference(now).inSeconds;
        final blockedApps =
            (status['blockedApps'] as List?)?.cast<String>() ?? [];
        final attempts = status['blockedAttempts'] as int? ?? 0;

        state = FocusSession(
          status: FocusStatus.active,
          durationSeconds: remainingSeconds,
          remainingSeconds: remainingSeconds,
          endTime: endTime,
          blockedApps: blockedApps,
          blockedAttempts: attempts,
          isStrict: true,
        );
        _startTimer();
        _subscribeToEvents();
      }
    }
  }

  Future<void> startSession(
    int durationMinutes,
    bool isStrict, {
    FocusTask? task,
  }) async {
    final durationSeconds = durationMinutes * 60;
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: durationSeconds));
    final appsToBlock = _ref.read(selectedAppsProvider).toList();

    state = FocusSession(
      status: FocusStatus.active,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isStrict: isStrict,
      startTime: now,
      endTime: endTime,
      blockedApps: appsToBlock,
      blockedAttempts: 0,
      lastDetectedApp: null,
      currentTask: task,
    );

    await _blockingService.startBlocking(
      blockedApps: appsToBlock,
      endTime: endTime,
    );

    _startTimer();
    _subscribeToEvents();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.endTime != null) {
        final remaining = state.endTime!.difference(DateTime.now()).inSeconds;
        if (remaining > 0) {
          state = state.copyWith(remainingSeconds: remaining);
        } else {
          completeSession();
        }
      } else {
        // Fallback if no endTime (shouldn't happen in active session)
        if (state.remainingSeconds > 0) {
          state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
        } else {
          completeSession();
        }
      }
    });
  }

  void _subscribeToEvents() {
    _eventSubscription?.cancel();
    _eventSubscription = _blockingService.blockingEventsStream.listen((event) {
      if (event is Map) {
        if (event['event'] == 'blocked_attempt') {
          final attempts = event['totalAttempts'] as int;
          final pkg = event['packageName'] as String?;
          state = state.copyWith(
            blockedAttempts: attempts,
            lastDetectedApp: pkg,
          );
        }
      }
    });
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    _eventSubscription?.cancel();
    await _blockingService.stopBlocking();

    // Auto-complete the task if one is linked
    final task = state.currentTask;
    if (task != null) {
      _ref.read(tasksProvider.notifier).completeTask(task.id);
    }

    // Log the session
    await _statsNotifier.logSession(
      state.durationSeconds,
      taskId: task?.id,
      completedSuccessfully: true,
    );

    state = state.copyWith(status: FocusStatus.completed);
  }

  Future<void> cancelSession() async {
    if (state.isStrict) return;
    await reset();
  }

  Future<void> reset() async {
    _timer?.cancel();
    _eventSubscription?.cancel();
    await _blockingService.stopBlocking();
    state = const FocusSession(status: FocusStatus.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// Provider for BlockingService
final blockingServiceProvider = Provider<BlockingService>((ref) {
  return BlockingService();
});

// Updated focusProvider that uses BlockingService and selected apps
final focusProvider = StateNotifierProvider<FocusNotifier, FocusSession>((ref) {
  final blockingService = ref.watch(blockingServiceProvider);
  final statsNotifier = ref.watch(statsProvider.notifier);
  return FocusNotifier(blockingService, statsNotifier, ref);
});
