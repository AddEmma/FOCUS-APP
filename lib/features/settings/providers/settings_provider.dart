import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool notificationsEnabled;
  final bool darkMode;
  final bool strictMode;
  final int defaultDurationMinutes;

  const AppSettings({
    this.notificationsEnabled = true,
    this.darkMode = true,
    this.strictMode = false,
    this.defaultDurationMinutes = 30,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    bool? strictMode,
    int? defaultDurationMinutes,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      strictMode: strictMode ?? this.strictMode,
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppSettings(
      notificationsEnabled: prefs.getBool('settings_notifications') ?? true,
      darkMode: prefs.getBool('settings_dark_mode') ?? true,
      strictMode: prefs.getBool('settings_strict_mode') ?? false,
      defaultDurationMinutes: prefs.getInt('settings_default_duration') ?? 30,
    );
  }

  Future<void> setNotificationsEnabled(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_notifications', value);
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_dark_mode', value);
  }

  Future<void> setStrictMode(bool value) async {
    state = state.copyWith(strictMode: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_strict_mode', value);
  }

  Future<void> setDefaultDuration(int minutes) async {
    state = state.copyWith(defaultDurationMinutes: minutes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('settings_default_duration', minutes);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});
