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
  /// When [role] is provided, role-specific route prefixes are used (e.g.
  /// `/trainer/chat` for trainers, `/client/chat` for clients). Falls back to
  /// the generic `/chat` when role is unknown.
  ///
  /// Returns `null` when:
  /// - The notification type is unknown / unsupported.
  /// - A required identifier (e.g. event ID for `event_reminder`) is missing.
  static String? routeForNotificationType(
    String notificationType, {
    String? id,
    String? role,
    String? token,
  }) {
    switch (notificationType) {
      case typeNewMessage:
        if (id != null && id.isNotEmpty) {
          final prefix = _chatPrefix(role);
          return '$prefix/$id';
        }
        return _chatPrefix(role);

      case typeCheckInReviewed:
        return '/client/check-in/history';

      case typeWorkoutReminder:
        return '/client/workout';

      case typeEventReminder:
        if (id != null && id.isNotEmpty) return '/events/$id';
        return null;

      case typeTrainerInvite:
        // Use the invitation token if provided; otherwise fall back to the
        // client/trainer screen.
        if (token != null && token.isNotEmpty) {
          return '/connect?token=$token';
        }
        return '/client/trainer';

      default:
        return null;
    }
  }

  /// Returns the role-aware chat route prefix.
  static String _chatPrefix(String? role) {
    switch (role) {
      case 'trainer':
        return '/trainer/chat';
      case 'client':
        return '/client/chat';
      default:
        return '/chat';
    }
  }

  /// Navigates to the screen indicated by a push notification tap.
  ///
  /// Extracts `notification_type`, `id`, and `role` from the FCM [data] payload
  /// and navigates via [router]. When [role] is present, role-specific routes
  /// (e.g. `/trainer/chat`) are used. Falls back to `/notifications` when the
  /// type is unknown or required data fields are missing.
  static void handleNotificationTap(
    Map<String, dynamic> data,
    GoRouter router,
  ) {
    final type = data['notification_type'] as String?;
    final id = data['id'] as String?;
    final role = data['role'] as String?;
    final token = data['token'] as String?;

    if (type == null) {
      router.go('/notifications');
      return;
    }

    final route = routeForNotificationType(
      type,
      id: id,
      role: role,
      token: token,
    );
    if (route != null) {
      router.go(route);
    } else {
      router.go('/notifications');
    }
  }
}
