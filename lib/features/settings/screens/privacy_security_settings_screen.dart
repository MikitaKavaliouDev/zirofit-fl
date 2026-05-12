import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

// ---------------------------------------------------------------------------
// Privacy & Security Screen
// ---------------------------------------------------------------------------

/// Combined privacy and security settings for clients, including data access
/// control, sharing duration, trainer connection management, and account
/// deletion.
///
/// Mirrors the iOS `PrivacySecuritySettingsView` from the original Ziro Fit
/// codebase.
class PrivacySecuritySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySecuritySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySecuritySettingsScreen> createState() =>
      _PrivacySecuritySettingsScreenState();
}

class _PrivacySecuritySettingsScreenState
    extends ConsumerState<PrivacySecuritySettingsScreen> {
  // -- Unlink trainer state --
  bool _isUnlinking = false;
  Map<String, dynamic>? _trainerData;
  bool _isLoadingTrainer = true;
  String? _trainerError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(preferencesProvider.notifier).loadPreferences();
      _fetchTrainer();
    });
  }

  // -----------------------------------------------------------------------
  // Trainer connection
  // -----------------------------------------------------------------------

  Future<void> _fetchTrainer() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTrainer = true;
      _trainerError = null;
    });

    try {
      final client = ApiClient.instance;
      final response = await client.get('/client/trainer');
      final data = response['data'];
      if (!mounted) return;
      setState(() {
        _trainerData = data is Map<String, dynamic> ? data : null;
        _isLoadingTrainer = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTrainer = false;
        // 404 or empty means no trainer linked — not an error
        if (e is DioException && e.response?.statusCode == 404) {
          _trainerData = null;
        } else {
          _trainerError = _extractErrorMessage(e);
          _trainerData = null;
        }
      });
    }
  }

  Future<void> _unlinkTrainer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink Trainer'),
        content: const Text(
          'Are you sure you want to unlink from your trainer? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUnlinking = true);

    try {
      final client = ApiClient.instance;
      await client.delete('/client/trainer');
      if (!mounted) return;
      setState(() {
        _trainerData = null;
        _isUnlinking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully unlinked from trainer.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUnlinking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractErrorMessage(e)),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Delete account
  // -----------------------------------------------------------------------

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: const Text('Delete Account'),
        content: const Text(
          'This action is permanent and cannot be undone. '
          'All your data will be deleted and you will be signed out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    context.push('/delete-account');
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final data = error.response!.data as Map;
        if (data['error'] is Map) {
          return (data['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (data['message'] is String) return data['message'] as String;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }

  String _durationDescription(String duration) {
    switch (duration) {
      case '30_days':
        return 'Your trainer can access your data for 30 days';
      case '90_days':
        return 'Your trainer can access your data for 90 days';
      case 'forever':
        return 'Your trainer has ongoing access to your data';
      default:
        return '';
    }
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final preferences = ref.watch(preferencesProvider);
    final authState = ref.watch(authProvider);
    final isClient = authState.isClient;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -- Error banner --
            if (preferences.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ErrorBanner(
                  message: preferences.error!,
                  onDismiss: () {
                    ref
                        .read(preferencesProvider.notifier)
                        .loadPreferences();
                  },
                ),
              ),

            // -- Data Access Control Section --
            const _SectionHeader(
              icon: Icons.share,
              title: 'Data Access Control',
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 12),
              child: Text(
                'Control what data your trainer can access.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.tune,
                  color: colorScheme.primary,
                ),
                title: const Text('Manage Sharing Categories'),
                subtitle: const Text(
                  'Workouts, measurements, photos, and check-ins',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/settings/data-sharing'),
              ),
            ),
            const SizedBox(height: 24),

            // -- Data Sharing Duration Section --
            const _SectionHeader(
              icon: Icons.schedule,
              title: 'Data Sharing Duration',
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 12),
              child: Text(
                'How long your trainer can access your shared data.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sharing Period',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _durationDescription(preferences.sharingDuration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: '30_days',
                            label: Text('30 Days'),
                            icon: Icon(Icons.calendar_view_month, size: 18),
                          ),
                          ButtonSegment(
                            value: '90_days',
                            label: Text('90 Days'),
                            icon: Icon(Icons.date_range, size: 18),
                          ),
                          ButtonSegment(
                            value: 'forever',
                            label: Text('Forever'),
                            icon: Icon(Icons.all_inclusive, size: 18),
                          ),
                        ],
                        selected: {preferences.sharingDuration},
                        onSelectionChanged: (selected) {
                          ref
                              .read(preferencesProvider.notifier)
                              .setSharingDuration(selected.first);
                        },
                        showSelectedIcon: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // -- Trainer Connection Section (Client only) --
            if (isClient) ...[
              const _SectionHeader(
                icon: Icons.link,
                title: 'Trainer Connection',
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 12),
                child: Text(
                  'Manage your connection with your trainer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildTrainerSection(theme, colorScheme),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // -- Security Section --
            const _SectionHeader(
              icon: Icons.security,
              title: 'Security',
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 12),
              child: Text(
                'Dangerous account actions.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.delete_forever,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Delete Account',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text(
                  'Permanently remove your account and all data',
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.error,
                ),
                onTap: _confirmDeleteAccount,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Your privacy matters. All data is encrypted in transit and at rest.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainerSection(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingTrainer) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_trainerError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline,
                  size: 20, color: colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _trainerError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fetchTrainer,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      );
    }

    if (_trainerData == null) {
      return Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_off_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Trainer Connected',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'You are not currently linked to a trainer.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final trainerName = _trainerData!['name'] as String? ?? 'Your Trainer';
    final trainerSpecialty =
        _trainerData!['specialty'] as String? ?? 'Personal Trainer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trainer info row
        Row(
          children: [
            // Avatar placeholder
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                trainerName.isNotEmpty
                    ? trainerName[0].toUpperCase()
                    : 'T',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trainerName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trainerSpecialty,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Connected badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Connected',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        // Unlink button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUnlinking ? null : _unlinkTrainer,
            icon: _isUnlinking
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.error,
                    ),
                  )
                : const Icon(Icons.link_off, size: 18),
            label: Text(
              _isUnlinking ? 'Unlinking...' : 'Unlink from Trainer',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable private widgets
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
