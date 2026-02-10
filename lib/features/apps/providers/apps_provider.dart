import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/apps_service.dart';

final appsServiceProvider = Provider<AppsService>((ref) => AppsService());

final installedAppsProvider = FutureProvider<List<AppInfo>>((ref) async {
  final service = ref.watch(appsServiceProvider);
  final apps = await service.getInstalledApps();
  // Sort alphabetically
  apps.sort(
    (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()),
  );
  return apps;
});

class SelectedAppsNotifier extends StateNotifier<Set<String>> {
  SelectedAppsNotifier() : super({}) {
    _loadSelection();
  }

  Future<void> _loadSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedApps = prefs.getStringList('selected_apps');
    if (savedApps != null) {
      state = savedApps.toSet();
    }
  }

  Future<void> _saveSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selected_apps', state.toList());
  }

  void toggleApp(String packageName) {
    if (state.contains(packageName)) {
      state = {...state}..remove(packageName);
    } else {
      state = {...state, packageName};
    }
    _saveSelection();
  }

  void clearSelection() {
    state = {};
    _saveSelection();
  }

  void setSelection(Set<String> selection) {
    state = selection;
    _saveSelection();
  }
}

final selectedAppsProvider =
    StateNotifierProvider<SelectedAppsNotifier, Set<String>>((ref) {
      return SelectedAppsNotifier();
    });
