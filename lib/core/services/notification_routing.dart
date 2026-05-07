import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// Notification type → route mapping
// ---------------------------------------------------------------------------

/// Maps push notification types to GoRouter navigation paths.
///
/// Each known [NotificationType] resolves to a GoRouter route. When the
/// payload includes an entity `id` (conversation ID, event ID, etc.) it is
/// appended to the route where applicable.
///
/// Usage:
/// ```dart
/// final route = NotificationRoutingService.routeForNotificationType(
///   'new_message',
///   id: 'conv_123',
/// );
/// router.go(route);
/// ```
class NotificationRoutingService {
  NotificationRoutingService._();

  /// Notification type constants used in the push notification `notification_type` field.
  static const String typeNewMessage = 'new_message';
  static const String typeCheckInReviewed = 'check_in_reviewed';
  static const String typeWorkoutReminder = 'workout_reminder';
  static const String typeEventReminder = 'event_reminder';
  static const String typeTrainerInvite = 'trainer_invite';

  /// Resolves a GoRouter location path from [notificationType] and optional [id].
  ///
  /// Returns `null` when:
  /// - The notification type is unknown / unsupported.
  /// - A required identifier (e.g. event ID for `event_reminder`) is missing.
  static String? routeForNotificationType(
    String notificationType, {
    String? id,
  }) {
    switch (notificationType) {
      case typeNewMessage:
        if (id != null && id.isNotEmpty) return '/chat/$id';
        return '/chat';

      case typeCheckInReviewed:
        return '/client/check-in/history';

      case typeWorkoutReminder:
        return '/client/workout';

      case typeEventReminder:
        if (id != null && id.isNotEmpty) return '/events/$id';
        return null;

      case typeTrainerInvite:
        return '/client/trainer';

      default:
        return null;
    }
  }

  /// Navigates to the screen indicated by a push notification tap.
  ///
  /// Extracts `notification_type` and `id` from the FCM [data] payload and
  /// navigates via [router]. Falls back to `/notifications` when the type is
  /// unknown or required data fields are missing.
  static void handleNotificationTap(
    Map<String, dynamic> data,
    GoRouter router,
  ) {
    final type = data['notification_type'] as String?;
    final id = data['id'] as String?;

    if (type == null) {
      router.go('/notifications');
      return;
    }

    final route = routeForNotificationType(type, id: id);
    if (route != null) {
      router.go(route);
    } else {
      router.go('/notifications');
    }
  }
}
