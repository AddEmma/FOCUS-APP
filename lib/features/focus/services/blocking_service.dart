import 'package:flutter/services.dart';

/// Service for communicating with native Android app blocking functionality
class BlockingService {
  static const _channel = MethodChannel('com.example.add_focus_app/blocking');

  /// Starts focus mode for the specified apps until the end time
  Future<bool> startBlocking({
    required List<String> allowedApps,
    required DateTime endTime,
  }) async {
    try {
      await _channel.invokeMethod('startBlocking', {
        'blockedApps': allowedApps,
        'endTimeMillis': endTime.millisecondsSinceEpoch,
      });
      return true;
    } on PlatformException catch (e) {
      print('Failed to start focus mode: ${e.message}');
      return false;
    }
  }

  /// Stops the app blocking service
  Future<bool> stopBlocking() async {
    try {
      await _channel.invokeMethod('stopBlocking');
      return true;
    } on PlatformException catch (e) {
      print('Failed to stop blocking: ${e.message}');
      return false;
    }
  }

  /// Checks if app blocking is currently active
  Future<bool> isBlockingActive() async {
    try {
      return await _channel.invokeMethod('isBlockingActive') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if the app has usage stats permission
  Future<bool> hasUsageStatsPermission() async {
    try {
      return await _channel.invokeMethod('hasUsageStatsPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Checks if the app has overlay permission
  Future<bool> hasOverlayPermission() async {
    try {
      return await _channel.invokeMethod('hasOverlayPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system settings to request usage stats permission
  Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } on PlatformException catch (e) {
      print('Failed to request usage stats permission: ${e.message}');
    }
  }

  /// Opens the system settings to request overlay permission
  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print('Failed to request overlay permission: ${e.message}');
    }
  }

  /// Checks if all required permissions are granted
  Future<bool> hasRequiredPermissions() async {
    final hasUsage = await hasUsageStatsPermission();
    final hasOverlay = await hasOverlayPermission();
    return hasUsage && hasOverlay;
  }
}
