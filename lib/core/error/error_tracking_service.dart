import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ErrorTrackingService {
  void recordError(dynamic error, StackTrace? stackTrace, {String? reason});
  void log(String message);
}

class ConsoleErrorTracker implements ErrorTrackingService {
  @override
  void recordError(dynamic error, StackTrace? stackTrace, {String? reason}) {
    print('🚨 ERROR: \$error');
    if (reason != null) print('Reason: \$reason');
    if (stackTrace != null) print('StackTrace: \$stackTrace');
    // TODO: Send to Crashlytics or Sentry in production
  }

  @override
  void log(String message) {
    print('📝 LOG: \$message');
    // TODO: Send to Crashlytics or Sentry in production
  }
}

final errorTrackerProvider = Provider<ErrorTrackingService>((ref) {
  return ConsoleErrorTracker();
});
