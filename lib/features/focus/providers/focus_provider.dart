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
  final List<String> allowedApps;

  const FocusSession({
    this.status = FocusStatus.idle,
    this.durationSeconds = 0,
    this.remainingSeconds = 0,
    this.isStrict = false,
    this.startTime,
    this.endTime,
    this.allowedApps = const [],
  });

  FocusSession copyWith({
    FocusStatus? status,
    int? durationSeconds,
    int? remainingSeconds,
    bool? isStrict,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? allowedApps,
  }) {
    return FocusSession(
      status: status ?? this.status,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isStrict: isStrict ?? this.isStrict,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      allowedApps: allowedApps ?? this.allowedApps,
    );
  }
}

class FocusNotifier extends StateNotifier<FocusSession> {
  Timer? _timer;
  final BlockingService _blockingService;
  final Set<String> _selectedApps;
  final StatsNotifier _statsNotifier;

  FocusNotifier(this._blockingService, this._selectedApps, this._statsNotifier)
    : super(const FocusSession());

  Future<void> startSession(int durationMinutes, bool isStrict) async {
    if (state.status == FocusStatus.active) return;

    final durationSeconds = durationMinutes * 60;
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: durationSeconds));
    final allowedAppsList = _selectedApps.toList();

    state = FocusSession(
      status: FocusStatus.active,
      durationSeconds: durationSeconds,
      remainingSeconds: durationSeconds,
      isStrict: isStrict,
      startTime: now,
      endTime: endTime,
      allowedApps: allowedAppsList,
    );

    // Start native app focus mode
    await _blockingService.startBlocking(
      allowedApps: allowedAppsList,
      endTime: endTime,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        completeSession();
      }
    });
  }

  Future<void> completeSession() async {
    _timer?.cancel();
    await _blockingService.stopBlocking();

    // Log the session
    await _statsNotifier.logSession(state.durationSeconds);

    state = state.copyWith(status: FocusStatus.completed);
  }

  Future<void> cancelSession() async {
    if (state.isStrict) return; // Cannot cancel in strict mode
    _timer?.cancel();
    await _blockingService.stopBlocking();
    state = const FocusSession(status: FocusStatus.idle);
  }

  Future<void> reset() async {
    _timer?.cancel();
    await _blockingService.stopBlocking();
    state = const FocusSession(status: FocusStatus.idle);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blockingService.stopBlocking();
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
  final selectedApps = ref.watch(selectedAppsProvider);
  final statsNotifier = ref.watch(statsProvider.notifier);
  return FocusNotifier(blockingService, selectedApps, statsNotifier);
});
