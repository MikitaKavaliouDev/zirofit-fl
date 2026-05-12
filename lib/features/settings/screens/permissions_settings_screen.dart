import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------------
// Permissions Settings Screen
// ---------------------------------------------------------------------------

/// Displays the current status of device permissions used by the app and
/// provides a shortcut to the system settings so the user can adjust them.
///
/// Mirrors the iOS `PermissionsSettingsView` from the original Ziro Fit code.
class PermissionsSettingsScreen extends ConsumerStatefulWidget {
  const PermissionsSettingsScreen({super.key});

  @override
  ConsumerState<PermissionsSettingsScreen> createState() =>
      _PermissionsSettingsScreenState();
}

class _PermissionsSettingsScreenState
    extends ConsumerState<PermissionsSettingsScreen> {
  bool _isLoading = true;
  String? _error;

  // Permission statuses
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _photosStatus = PermissionStatus.denied;
  PermissionStatus _healthStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAll());
  }

  Future<void> _checkAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        Permission.camera.status,
        Permission.photos.status,
        _healthPermissionStatus(),
        Permission.locationWhenInUse.status,
      ]);

      if (!mounted) return;

      setState(() {
        _cameraStatus = results[0];
        _photosStatus = results[1];
        _healthStatus = results[2];
        _locationStatus = results[3];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load permission statuses.';
        _isLoading = false;
      });
    }
  }

  /// HealthKit permission is not directly supported by permission_handler.
  /// Returns `denied` as a neutral fallback status so the tile renders in
  /// "Not Requested" appearance on both platforms.
  Future<PermissionStatus> _healthPermissionStatus() async {
    return PermissionStatus.denied;
  }

  /// Opens the system settings page for this app so the user can manually
  /// toggle permissions.
  Future<void> _openSystemSettings() async {
    final opened = await openAppSettings();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open system settings. Please open them '
              'manually from your device settings.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkAll,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error banner
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ErrorBanner(
                          message: _error!,
                          onDismiss: _checkAll,
                        ),
                      ),

                    // System Access header
                    const _SectionHeader(
                      icon: Icons.security,
                      title: 'System Access',
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 28, bottom: 12),
                      child: Text(
                        'Manage what Ziro Fit can access on your device.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                    // Camera
                    _PermissionTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      description: 'Access to take photos and record video',
                      status: _cameraStatus,
                    ),
                    const SizedBox(height: 8),

                    // Photos
                    _PermissionTile(
                      icon: Icons.photo_library_outlined,
                      title: 'Photos',
                      description: 'Access to your photo library',
                      status: _photosStatus,
                    ),
                    const SizedBox(height: 8),

                    // Health Data
                    _PermissionTile(
                      icon: Icons.favorite_border,
                      title: 'Health Data',
                      description: 'Read and write health metrics',
                      status: _healthStatus,
                    ),
                    const SizedBox(height: 8),

                    // Location
                    _PermissionTile(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      description: 'Access to your location while using the app',
                      status: _locationStatus,
                    ),
                    const SizedBox(height: 24),

                    // Open System Settings button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openSystemSettings,
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text('Open System Settings'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Permission changes take effect immediately.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission Tile
// ---------------------------------------------------------------------------

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionStatus status;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color color, String label) = _statusAttributes(theme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _statusAttributes(ThemeData theme) {
    switch (status) {
      case PermissionStatus.granted:
        return (theme.colorScheme.primary, 'Granted');
      case PermissionStatus.limited:
        return (Colors.amber.shade700, 'Limited');
      case PermissionStatus.denied:
        return (theme.colorScheme.error, 'Denied');
      case PermissionStatus.permanentlyDenied:
        return (theme.colorScheme.error, 'Blocked');
      case PermissionStatus.restricted:
        return (Colors.orange.shade700, 'Restricted');
      case PermissionStatus.provisional:
        return (Colors.amber.shade700, 'Provisional');
    }
  }
}

// ---------------------------------------------------------------------------
// Section Header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Error Banner
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.error,
              size: 20,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onErrorContainer,
              ),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
