import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import 'package:zirofit_fl/features/onboarding/providers/onboarding_provider.dart';

/// Step 8: Request system permissions with Grant/Deny cards.
class PermissionsStep extends ConsumerStatefulWidget {
  const PermissionsStep({super.key});

  @override
  ConsumerState<PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends ConsumerState<PermissionsStep> {
  bool _isRequesting = false;

  Future<void> _requestPermission(PermissionType type) async {
    setState(() => _isRequesting = true);

    try {
      ph.Permission permission;
      switch (type) {
        case PermissionType.camera:
          permission = ph.Permission.camera;
        case PermissionType.microphone:
          permission = ph.Permission.microphone;
        case PermissionType.notifications:
          permission = ph.Permission.notification;
        case PermissionType.location:
          permission = ph.Permission.locationWhenInUse;
      }

      final status = await permission.request();
      if (!mounted) return;

      final mapped = status == ph.PermissionStatus.granted
          ? PermissionStatus.granted
          : PermissionStatus.denied;

      ref.read(onboardingProvider.notifier).setPermission(type, mapped);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        ref.read(onboardingProvider.notifier).setPermission(
              type,
              PermissionStatus.denied,
            );
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const types = PermissionType.values;
    final granted = state.grantedPermissionsCount;
    final total = types.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Header
            Icon(
              Icons.shield_rounded,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Optimize Your Experience',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Allow permissions to get the most\nout of Ziro Fit',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Progress: "X of 4 granted"
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: granted == total
                        ? Colors.green
                        : colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$granted of $total permissions granted',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: granted == total
                          ? Colors.green
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Permission cards
            ...types.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PermissionCard(
                  type: type,
                  status: state.permissions[type] ?? PermissionStatus.unknown,
                  isRequesting: _isRequesting,
                  onGrant: () => _requestPermission(type),
                  onDeny: () {
                    HapticFeedback.lightImpact();
                    ref.read(onboardingProvider.notifier).setPermission(
                          type,
                          PermissionStatus.denied,
                        );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'We value your privacy. Your data remains encrypted and under your control. You can change these anytime in Settings.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final PermissionType type;
  final PermissionStatus status;
  final bool isRequesting;
  final VoidCallback onGrant;
  final VoidCallback onDeny;

  const _PermissionCard({
    required this.type,
    required this.status,
    required this.isRequesting,
    required this.onGrant,
    required this.onDeny,
  });

  String _description(PermissionType t) {
    switch (t) {
      case PermissionType.camera:
        return 'Take profile photos and record workout videos';
      case PermissionType.microphone:
        return 'Voice commands and hands-free workout logging';
      case PermissionType.notifications:
        return 'Stay motivated with rest timers and reminders';
      case PermissionType.location:
        return 'Find trainers and gyms near you';
    }
  }

  Color _tintColor(PermissionType t) {
    switch (t) {
      case PermissionType.camera:
        return Colors.blue;
      case PermissionType.microphone:
        return Colors.purple;
      case PermissionType.notifications:
        return Colors.orange;
      case PermissionType.location:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = _tintColor(type);
    final isGranted = status == PermissionStatus.granted;
    final isDenied = status == PermissionStatus.denied;

    return Container(
      decoration: BoxDecoration(
        color: isGranted
            ? color.withValues(alpha: 0.05)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? color.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isGranted
                        ? color.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    type.icon,
                    size: 22,
                    color: isGranted ? color : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            type.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isGranted) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _description(type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isGranted)
                  TextButton(
                    onPressed: isGranted ? null : onDeny,
                    child: Text(
                      isDenied ? 'Denied' : 'Skip',
                      style: TextStyle(
                        color: isDenied
                            ? Colors.red.shade400
                            : colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                if (!isGranted)
                  ElevatedButton(
                    onPressed: isRequesting ? null : onGrant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: isRequesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Grant',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                if (isGranted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Granted',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
