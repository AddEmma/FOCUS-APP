import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import 'providers/apps_provider.dart';

class AppSelectionScreen extends ConsumerStatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  ConsumerState<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends ConsumerState<AppSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appsAsyncValue = ref.watch(installedAppsProvider);
    final selectedApps = ref.watch(selectedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.selectAppsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingM,
              0,
              AppTheme.spacingM,
              AppTheme.spacingM,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: AppStrings.searchApps,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: appsAsyncValue.when(
        data: (apps) {
          final filteredApps = apps.where((app) {
            return app.appName.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredApps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Text(
                    'No apps found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ).animate().fadeIn(),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: AppTheme.spacingM,
              right: AppTheme.spacingM,
              bottom: 100, // Space for FLOATING BUTTON
            ),
            itemCount: filteredApps.length,
            itemBuilder: (context, index) {
              final app = filteredApps[index];
              final isSelected = selectedApps.contains(app.packageName);

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                color: isSelected
                    ? AppTheme.error.withOpacity(
                        0.1,
                      ) // Red tint for blocked logic
                    : AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  side: BorderSide(
                    color: isSelected ? AppTheme.error : Colors.transparent,
                  ),
                ),
                child: ListTile(
                  leading: Image.memory(app.icon, width: 40, height: 40),
                  title: Text(
                    app.appName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppTheme.error : Colors.white,
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      ref
                          .read(selectedAppsProvider.notifier)
                          .toggleApp(app.packageName);
                    },
                    activeColor: AppTheme.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onTap: () {
                    ref
                        .read(selectedAppsProvider.notifier)
                        .toggleApp(app.packageName);
                  },
                ),
              ).animate().fadeIn(delay: (index * 20).ms).slideX();
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: selectedApps.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/set-focus'),
              backgroundColor: AppTheme.error,
              icon: const Icon(Icons.block),
              label: Text('Block ${selectedApps.length} Apps'),
            ).animate().scale()
          : null,
    );
  }
}
