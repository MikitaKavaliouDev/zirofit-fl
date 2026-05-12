import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

// ---------------------------------------------------------------------------
// Experimental Features Screen
// ---------------------------------------------------------------------------

/// Allows the user to opt in or out of in-development features.
///
/// Toggles are persisted immediately through [preferencesProvider] and
/// default to disabled.
class ExperimentalFeaturesScreen extends ConsumerStatefulWidget {
  const ExperimentalFeaturesScreen({super.key});

  @override
  ConsumerState<ExperimentalFeaturesScreen> createState() =>
      _ExperimentalFeaturesScreenState();
}

class _ExperimentalFeaturesScreenState
    extends ConsumerState<ExperimentalFeaturesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(preferencesProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experimental Features'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error banner
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ErrorBanner(
                        message: state.error!,
                        onDismiss: () {
                          ref
                              .read(preferencesProvider.notifier)
                              .loadPreferences();
                        },
                      ),
                    ),

                  // -- Section Header --
                  const _SectionHeader(
                    icon: Icons.science_outlined,
                    title: 'Experimental Features',
                  ),
                  const SizedBox(height: 12),

                  // Info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'These features are still in development and may '
                              'change. Enable them to try out what\'s coming next.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Feature Toggles --
                  _ExperimentalFeatureToggle(
                    icon: Icons.track_changes_outlined,
                    title: 'Daily Exercise Targets',
                    description:
                        'Set and track daily exercise goals',
                    value: state.isDailyTargetsEnabled,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setDailyTargetsEnabled(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ExperimentalFeatureToggle(
                    icon: Icons.record_voice_over_outlined,
                    title: 'Voice Feedback (Beta)',
                    description:
                        'Hear audio cues and feedback during workouts',
                    value: state.isVoiceFeedbackEnabled,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setVoiceFeedbackEnabled(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _ExperimentalFeatureToggle(
                    icon: Icons.repeat_outlined,
                    title: 'Personal Routines',
                    description:
                        'Create and follow customized workout routines',
                    value: state.isRoutinesEnabled,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setRoutinesEnabled(v);
                    },
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
// Experimental Feature Toggle Card
// ---------------------------------------------------------------------------

class _ExperimentalFeatureToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ExperimentalFeatureToggle({
    required this.icon,
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
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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

    return Material(
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
    );
  }
}
