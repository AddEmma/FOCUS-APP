import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../focus/services/blocking_service.dart';

// Provider for BlockingService in permissions screen
final permissionsBlockingServiceProvider = Provider<BlockingService>((ref) {
  return BlockingService();
});

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _usageGranted = false;
  bool _overlayGranted = false;
  bool _accessibilityGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permissions when app resumes (user might have granted in settings)
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final blockingService = ref.read(permissionsBlockingServiceProvider);
    final hasUsage = await blockingService.hasUsageStatsPermission();
    final hasOverlay = await blockingService.hasOverlayPermission();
    final hasAccessibility = await blockingService.hasAccessibilityPermission();

    if (mounted) {
      setState(() {
        _usageGranted = hasUsage;
        _overlayGranted = hasOverlay;
        _accessibilityGranted = hasAccessibility;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestUsagePermission() async {
    final blockingService = ref.read(permissionsBlockingServiceProvider);
    await blockingService.requestUsageStatsPermission();
  }

  Future<void> _requestOverlayPermission() async {
    final blockingService = ref.read(permissionsBlockingServiceProvider);
    await blockingService.requestOverlayPermission();
  }

  Future<void> _requestAccessibilityPermission() async {
    final blockingService = ref.read(permissionsBlockingServiceProvider);
    await blockingService.requestAccessibilityPermission();
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = _usageGranted && _overlayGranted && _accessibilityGranted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/onboarding'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.permissionsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().slideX(),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                AppStrings.permissionsSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: AppTheme.spacingL),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: ListView(
                    children: [
                      _buildPermissionCard(
                        title: AppStrings.permUsageTitle,
                        description: AppStrings.permUsageDesc,
                        icon: Icons.data_usage_rounded,
                        isGranted: _usageGranted,
                        onTap: _requestUsagePermission,
                        delay: 300,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildPermissionCard(
                        title: AppStrings.permOverlayTitle,
                        description: AppStrings.permOverlayDesc,
                        icon: Icons.layers_rounded,
                        isGranted: _overlayGranted,
                        onTap: _requestOverlayPermission,
                        delay: 400,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildPermissionCard(
                        title: AppStrings.permAccessTitle,
                        description: AppStrings.permAccessDesc,
                        icon: Icons.accessibility_new_rounded,
                        isGranted: _accessibilityGranted,
                        onTap: _requestAccessibilityPermission,
                        delay: 500,
                      ),
                    ],
                  ),
                ),
              ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: allGranted
                      ? AppTheme.primary
                      : Colors.grey[800],
                  foregroundColor: allGranted ? Colors.white : Colors.grey[400],
                ),
                child: Text(allGranted ? 'Continue' : 'Skip for Now'),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 1, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
    required int delay,
  }) {
    return InkWell(
      onTap: isGranted ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isGranted
                ? AppTheme.secondary
                : Colors.white.withOpacity(0.05),
            width: isGranted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppTheme.secondary.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? AppTheme.secondary : Colors.white70,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isGranted)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.secondary,
              ).animate().scale()
            else
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }
}
