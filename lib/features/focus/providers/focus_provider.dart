import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/blocking_service.dart';
import '../../apps/providers/apps_provider.dart';
import '../../stats/providers/stats_provider.dart';

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
    );
  }
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
        // Automatically sync with native service if session is active
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
          durationSeconds:
              remainingSeconds, // Approximation for restored session
          remainingSeconds: remainingSeconds,
          endTime: endTime,
          blockedApps: blockedApps,
          blockedAttempts: attempts,
          isStrict: true, // Assume strict if recovered context likely lost
        );
        _startTimer();
        _subscribeToEvents();
      }
    }
  }

  Future<void> startSession(int durationMinutes, bool isStrict) async {
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
    );

    // Start native app focus mode
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
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        completeSession();
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

    // Log the session
    await _statsNotifier.logSession(state.durationSeconds);

    state = state.copyWith(status: FocusStatus.completed);
  }

  Future<void> cancelSession() async {
    if (state.isStrict) return; // Cannot cancel in strict mode
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
    // _blockingService.stopBlocking(); // Don't stop native service on dispose, keeps running in background
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
