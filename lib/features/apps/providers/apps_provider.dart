import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  SelectedAppsNotifier() : super({});

  void toggleApp(String packageName) {
    if (state.contains(packageName)) {
      state = {...state}..remove(packageName);
    } else {
      state = {...state, packageName};
    }
  }

  void clearSelection() {
    state = {};
  }

  void setSelection(Set<String> selection) {
    state = selection;
  }
}

final selectedAppsProvider =
    StateNotifierProvider<SelectedAppsNotifier, Set<String>>((ref) {
      return SelectedAppsNotifier();
    });
