import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zirofit_fl/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(settingsProvider.notifier).loadSettings(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Success/Error feedback
                    if (state.successMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _MessageBanner(
                          message: state.successMessage!,
                          type: _MessageType.success,
                          onDismiss: () {
                            ref.read(settingsProvider.notifier).loadSettings();
                          },
                        ),
                      ),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _MessageBanner(
                          message: state.error!,
                          type: _MessageType.error,
                          onDismiss: () {
                            ref.read(settingsProvider.notifier).loadSettings();
                          },
                        ),
                      ),

                    // Check-in Defaults Section
                    const _SectionHeader(
                      icon: Icons.checklist,
                      title: 'Check-in Defaults',
                    ),
                    const SizedBox(height: 12),
                    _CheckInDayCard(
                      day: state.defaultCheckInDay,
                      isSaving: state.isSaving,
                      onSaved: (day) {
                        ref
                            .read(settingsProvider.notifier)
                            .saveCheckInDefaults(day, state.defaultCheckInHour);
                      },
                    ),
                    const SizedBox(height: 12),
                    _CheckInHourCard(
                      hour: state.defaultCheckInHour,
                      isSaving: state.isSaving,
                      onSaved: (hour) {
                        ref
                            .read(settingsProvider.notifier)
                            .saveCheckInDefaults(state.defaultCheckInDay, hour);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Assessment Templates Section
                    const _SectionHeader(
                      icon: Icons.assignment,
                      title: 'Assessment Templates',
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment_outlined),
                        title: const Text('Manage Templates'),
                        subtitle: const Text(
                          'Create and manage assessment templates for clients',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/trainer/assessments'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Weight Unit Section
                    const _SectionHeader(
                      icon: Icons.monitor_weight,
                      title: 'Weight Unit',
                    ),
                    const SizedBox(height: 12),
                    _WeightUnitCard(
                      weightUnit: state.weightUnit,
                      isSaving: state.isSaving,
                      onToggle: (unit) {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleWeightUnit(unit);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Data Sharing Section
                    const _SectionHeader(
                      icon: Icons.share,
                      title: 'Data & Privacy',
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.sync_alt),
                        title: const Text('Data Sharing'),
                        subtitle: const Text(
                          'Choose what data to share with your trainer',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/settings/data-sharing'),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account Section
                    const _SectionHeader(
                      icon: Icons.account_circle,
                      title: 'Account',
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/auth/update-password'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red.shade600),
                        title: Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                        subtitle: const Text('Permanently remove your account and data'),
                        onTap: () => context.push('/delete-account'),
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
// Message Banner
// ---------------------------------------------------------------------------

enum _MessageType { success, error }

class _MessageBanner extends StatelessWidget {
  final String message;
  final _MessageType type;
  final VoidCallback onDismiss;

  const _MessageBanner({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = type == _MessageType.success
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.errorContainer;
    final fgColor = type == _MessageType.success
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;
    final icon = type == _MessageType.success ? Icons.check_circle : Icons.error;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: fgColor),
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
// Check-In Day Card
// ---------------------------------------------------------------------------

class _CheckInDayCard extends ConsumerWidget {
  final int day;
  final bool isSaving;
  final void Function(int day) onSaved;

  const _CheckInDayCard({
    required this.day,
    required this.isSaving,
    required this.onSaved,
  });

  static const _dayLabels = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Check-In Day',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'The day of the week clients check in by default',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: day,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(7, (i) {
                return DropdownMenuItem(
                  value: i,
                  child: Text(_dayLabels[i]),
                );
              }),
              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        final previousDay = ref.read(settingsProvider).defaultCheckInDay;
                        // Only save if changed
                        if (value != previousDay) {
                          onSaved(value);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Check-In Hour Card
// ---------------------------------------------------------------------------

class _CheckInHourCard extends ConsumerWidget {
  final int hour;
  final bool isSaving;
  final void Function(int hour) onSaved;

  const _CheckInHourCard({
    required this.hour,
    required this.isSaving,
    required this.onSaved,
  });

  String _formatHour(int h) {
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:00 $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Default Check-In Hour',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'The time of day check-ins are scheduled',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: hour,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(24, (h) {
                return DropdownMenuItem(
                  value: h,
                  child: Text(_formatHour(h)),
                );
              }),
              onChanged: isSaving
                  ? null
                  : (value) {
                      if (value != null) {
                        final previousHour = ref.read(settingsProvider).defaultCheckInHour;
                        if (value != previousHour) {
                          onSaved(value);
                        }
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weight Unit Card
// ---------------------------------------------------------------------------

class _WeightUnitCard extends ConsumerWidget {
  final String weightUnit;
  final bool isSaving;
  final void Function(String unit) onToggle;

  const _WeightUnitCard({
    required this.weightUnit,
    required this.isSaving,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferred Weight Unit',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Choose between kilograms and pounds',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WeightUnitOption(
                    label: 'Kilograms (KG)',
                    isSelected: weightUnit == 'KG',
                    onTap: isSaving ? null : () => onToggle('KG'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WeightUnitOption(
                    label: 'Pounds (LB)',
                    isSelected: weightUnit == 'LB',
                    onTap: isSaving ? null : () => onToggle('LB'),
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

class _WeightUnitOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _WeightUnitOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : null,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
