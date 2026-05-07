import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zirofit_fl/data/models/notification_model.dart';
import 'package:zirofit_fl/features/notifications/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(notificationsProvider.notifier).fetchNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.unreadCount} new',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state, theme),
    );
  }

  Widget _buildBody(NotificationsState state, ThemeData theme) {
    // Initial loading
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).fetchNotifications(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (state.notifications.isEmpty && !state.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re all caught up! Check back later for updates.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(notificationsProvider.notifier).fetchNotifications(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Notification list
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(notificationsProvider.notifier).fetchNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.notifications.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          // Loading indicator at bottom during refresh
          if (index == state.notifications.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final notification = state.notifications[index];
          final notifier = ref.read(notificationsProvider.notifier);
          return _NotificationCard(
            notification: notification,
            onTap: () {
              if (!notification.readStatus) {
                notifier.markRead(notification.id);
              }
            },
            onAccept: notification.type == 'client_link_request'
                ? () {
                    final clientId = notification.metadata?['client_id'] as String?;
                    if (clientId != null) {
                      notifier.acceptLinkRequest(clientId);
                    }
                  }
                : null,
            onDecline: notification.type == 'client_link_request'
                ? () {
                    final clientId = notification.metadata?['client_id'] as String?;
                    if (clientId != null) {
                      notifier.declineLinkRequest(clientId);
                    }
                  }
                : null,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification Card
// ---------------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'workout_reminder':
        return Icons.fitness_center;
      case 'check_in':
        return Icons.assignment_turned_in;
      case 'message':
        return Icons.message;
      case 'achievement':
        return Icons.emoji_events;
      case 'booking':
        return Icons.calendar_today;
      case 'progress':
        return Icons.trending_up;
      case 'system':
        return Icons.info_outline;
      case 'client_link_request':
        return Icons.link;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final showActions = onAccept != null || onDecline != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.readStatus
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: notification.readStatus
                          ? theme.colorScheme.surfaceContainerHighest
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForType(notification.type),
                      size: 22,
                      color: notification.readStatus
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.message,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: notification.readStatus
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${dateFormat.format(notification.createdAt)} at ${timeFormat.format(notification.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Unread badge
                  if (!notification.readStatus)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              // Accept / Decline buttons
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onDecline != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          onPressed: onDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                    if (onAccept != null)
                      FilledButton(
                        onPressed: onAccept,
                        child: const Text('Accept'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
