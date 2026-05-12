import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

/// Allows the user to enable/disable manual mode switching between
/// Personal and Professional (trainer/client) modes.
///
/// When enabled, the bottom navigation bar includes a control to toggle
/// between mode views rather than being locked to the default role-based shell.
class CustomAppModeScreen extends ConsumerStatefulWidget {
  const CustomAppModeScreen({super.key});

  @override
  ConsumerState<CustomAppModeScreen> createState() =>
      _CustomAppModeScreenState();
}

class _CustomAppModeScreenState extends ConsumerState<CustomAppModeScreen> {
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
        title: const Text('Custom App Mode'),
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

                  // -- App Mode Toggle --
                  const _SectionHeader(
                    icon: Icons.swap_horiz_rounded,
                    title: 'App Mode',
                  ),
                  const SizedBox(height: 12),
                  _ModeToggle(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Enable manual Personal/Professional switching',
                    description:
                        'Enable manual Personal/Professional switching',
                    value: state.isCustomModeEnabled,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setCustomModeEnabled(v);
                    },
                  ),
                  const SizedBox(height: 24),

                  // -- Info Card --
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
                              'When enabled, you can manually switch '
                              'between Personal and Professional mode '
                              'from the bottom navigation bar.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
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
// Mode Toggle Card
// ---------------------------------------------------------------------------

class _ModeToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({
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
