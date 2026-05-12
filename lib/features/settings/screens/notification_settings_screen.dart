import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/features/settings/providers/preferences_provider.dart';

// ---------------------------------------------------------------------------
// Notification Settings Screen
// ---------------------------------------------------------------------------

/// Allows the user to configure notification preferences including push
/// notifications, email notifications, workout reminders, booking alerts,
/// and cross-profile notification visibility.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
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
        title: const Text('Notification Settings'),
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

                  // -- Notification Channels --
                  const _SectionHeader(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Channels',
                  ),
                  const SizedBox(height: 12),
                  _NotificationToggle(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    description:
                        'Receive push notifications on your device',
                    value: state.pushNotifications,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setPushNotifications(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _NotificationToggle(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    description: 'Receive notifications via email',
                    value: state.emailNotifications,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setEmailNotifications(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _NotificationToggle(
                    icon: Icons.fitness_center_outlined,
                    title: 'Workout Reminders',
                    description:
                        'Get reminded about upcoming workouts',
                    value: state.workoutReminders,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setWorkoutReminders(v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _NotificationToggle(
                    icon: Icons.calendar_today_outlined,
                    title: 'Booking Alerts',
                    description:
                        'Get notified about session bookings and changes',
                    value: state.bookingAlerts,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setBookingAlerts(v);
                    },
                  ),
                  const SizedBox(height: 24),

                  // -- Cross-Profile Notifications --
                  const _SectionHeader(
                    icon: Icons.swap_horiz_outlined,
                    title: 'Cross-Profile Notifications',
                  ),
                  const SizedBox(height: 12),
                  _NotificationToggle(
                    icon: Icons.person_outlined,
                    title:
                        'Trainer Notifications in Client Mode',
                    description:
                        'Show trainer-related notifications while '
                        'viewing as a client',
                    value: state
                        .showTrainerNotificationsInClientMode,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setShowTrainerNotificationsInClientMode(
                              v);
                    },
                  ),
                  const SizedBox(height: 8),
                  _NotificationToggle(
                    icon: Icons.people_outlined,
                    title:
                        'Client Notifications in Trainer Mode',
                    description:
                        'Show client-related notifications while '
                        'viewing as a trainer',
                    value: state
                        .showClientNotificationsInTrainerMode,
                    onChanged: (v) {
                      ref
                          .read(preferencesProvider.notifier)
                          .setShowClientNotificationsInTrainerMode(
                              v);
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
// Notification Toggle Card
// ---------------------------------------------------------------------------

class _NotificationToggle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationToggle({
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
