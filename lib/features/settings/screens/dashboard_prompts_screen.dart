import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/dashboard_prompts_provider.dart';
import 'package:zirofit_fl/shared/widgets/ziro_sheet_header.dart';

// ---------------------------------------------------------------------------
// Dashboard Prompts Screen
// ---------------------------------------------------------------------------

/// A settings screen that lets users toggle which banner prompts appear
/// on their dashboard.
///
/// Mirrors the iOS [`DashboardPromptsView`] from the Swift codebase:
///   - **"Need a Coach?"** toggle — controls the coach banner when the user
///     has no active trainer.
///   - **"Weekly Check-in"** toggle — controls the training update reminder
///     banner.
///
/// Changes are persisted immediately through [dashboardPromptsProvider].
class DashboardPromptsScreen extends ConsumerStatefulWidget {
  const DashboardPromptsScreen({super.key});

  @override
  ConsumerState<DashboardPromptsScreen> createState() =>
      _DashboardPromptsScreenState();
}

class _DashboardPromptsScreenState
    extends ConsumerState<DashboardPromptsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardPromptsProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardPromptsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Navigation header (ZiroSheetHeader as requested)
            ZiroSheetHeader(
              title: 'Dashboard Prompts',
              showCancel: true,
              onCancel: () => Navigator.of(context).pop(),
            ),

            // Error banner
            if (state.error != null)
              _ErrorBanner(
                message: state.error!,
                onDismiss: () {
                  ref
                      .read(dashboardPromptsProvider.notifier)
                      .loadPreferences();
                },
              ),

            // Loading indicator
            if (state.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // -- Section header --
                    const _SectionHeader(
                      icon: Icons.dashboard_outlined,
                      title: 'Dashboard Prompts',
                    ),
                    const SizedBox(height: 12),

                    // -- "Need a Coach?" Toggle --
                    _PromptToggle(
                      icon: Icons.person_search_outlined,
                      iconColor: Colors.blue,
                      title: 'Need a Coach?',
                      description: 'Show banner if no active trainer',
                      value: !state.coachBannerDismissed,
                      onChanged: (shown) {
                        ref
                            .read(dashboardPromptsProvider.notifier)
                            .setCoachBannerShown(shown);
                      },
                    ),
                    const SizedBox(height: 8),

                    // -- "Weekly Check-in" Toggle --
                    _PromptToggle(
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.orange,
                      title: 'Weekly Check-in',
                      description:
                          'Show banner for training updates',
                      value: !state.checkInBannerDismissed,
                      onChanged: (shown) {
                        ref
                            .read(dashboardPromptsProvider.notifier)
                            .setCheckInBannerShown(shown);
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
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
// Prompt Toggle Card
// ---------------------------------------------------------------------------

class _PromptToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PromptToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Title & description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
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

            // Switch
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.error,
                  size: 20, color: theme.colorScheme.onErrorContainer),
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
                icon: Icon(Icons.close,
                    size: 16, color: theme.colorScheme.onErrorContainer),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
