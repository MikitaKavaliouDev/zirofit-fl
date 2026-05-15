import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/services/notification_routing.dart';

class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('NotificationRoutingService.routeForNotificationType', () {
    // ===========================================================================
    // new_message – role-aware routing
    // ===========================================================================
    group('new_message with role', () {
      test('new_message with role=trainer and id routes to trainer chat', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: 'conv_123',
          role: 'trainer',
        );
        expect(route, '/trainer/chat/conv_123');
      });

      test('new_message with role=trainer without id routes to trainer chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          role: 'trainer',
        );
        expect(route, '/trainer/chat');
      });

      test('new_message with role=trainer with empty id routes to trainer chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: '',
          role: 'trainer',
        );
        expect(route, '/trainer/chat');
      });

      test('new_message with role=client and id routes to client chat', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: 'conv_123',
          role: 'client',
        );
        expect(route, '/client/chat/conv_123');
      });

      test('new_message with role=client without id routes to client chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          role: 'client',
        );
        expect(route, '/client/chat');
      });

      test('new_message with role=client with empty id routes to client chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: '',
          role: 'client',
        );
        expect(route, '/client/chat');
      });
    });

    group('new_message without role (default / fallback)', () {
      test('new_message without role param and with id routes to top-level chat', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: 'conv_123',
        );
        expect(route, '/chat/conv_123');
      });

      test('new_message without role param and without id routes to chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
        );
        expect(route, '/chat');
      });

      test('new_message without role param and with empty id routes to chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: '',
        );
        expect(route, '/chat');
      });

      test('new_message with null role and id routes to top-level chat', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: 'conv_123',
          role: null,
        );
        expect(route, '/chat/conv_123');
      });

      test('new_message with null role and without id routes to chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          role: null,
        );
        expect(route, '/chat');
      });

      test('new_message with null role and empty id routes to chat list', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'new_message',
          id: '',
          role: null,
        );
        expect(route, '/chat');
      });
    });

    // ===========================================================================
    // check_in_reviewed (unchanged)
    // ===========================================================================
    group('check_in_reviewed', () {
      test('check_in_reviewed routes to check-in history', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'check_in_reviewed',
        );
        expect(route, '/client/check-in/history');
      });

      test('check_in_reviewed ignores any provided id', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'check_in_reviewed',
          id: 'ci_999',
        );
        expect(route, '/client/check-in/history');
      });

      test('check_in_reviewed ignores any provided role', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'check_in_reviewed',
          id: 'ci_999',
          role: 'trainer',
        );
        expect(route, '/client/check-in/history');
      });
    });

    // ===========================================================================
    // workout_reminder (unchanged)
    // ===========================================================================
    group('workout_reminder', () {
      test('workout_reminder routes to active workout', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'workout_reminder',
        );
        expect(route, '/client/workout');
      });

      test('workout_reminder ignores any provided id', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'workout_reminder',
          id: 'wo_456',
        );
        expect(route, '/client/workout');
      });

      test('workout_reminder ignores any provided role', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'workout_reminder',
          id: 'wo_456',
          role: 'client',
        );
        expect(route, '/client/workout');
      });
    });

    // ===========================================================================
    // event_reminder (unchanged)
    // ===========================================================================
    group('event_reminder', () {
      test('event_reminder with id routes to event detail', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'event_reminder',
          id: 'evt_001',
        );
        expect(route, '/events/evt_001');
      });

      test('event_reminder without id returns null', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'event_reminder',
        );
        expect(route, isNull);
      });

      test('event_reminder with empty id returns null', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'event_reminder',
          id: '',
        );
        expect(route, isNull);
      });

      test('event_reminder ignores any provided role', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'event_reminder',
          id: 'evt_001',
          role: 'trainer',
        );
        expect(route, '/events/evt_001');
      });
    });

    // ===========================================================================
    // trainer_invite (unchanged)
    // ===========================================================================
    group('trainer_invite', () {
      test('trainer_invite routes to my trainer screen', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'trainer_invite',
        );
        expect(route, '/client/trainer');
      });

      test('trainer_invite ignores any provided id', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'trainer_invite',
          id: 'tr_789',
        );
        expect(route, '/client/trainer');
      });

      test('trainer_invite ignores any provided role', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'trainer_invite',
          id: 'tr_789',
          role: 'trainer',
        );
        expect(route, '/client/trainer');
      });
    });

    // ===========================================================================
    // Unrecognised / edge cases (unchanged)
    // ===========================================================================
    group('unknown types', () {
      test('unknown notification type returns null', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'unknown_type',
        );
        expect(route, isNull);
      });

      test('unknown notification type with role returns null', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'unknown_type',
          role: 'trainer',
        );
        expect(route, isNull);
      });

      test('empty string type returns null', () {
        final route = NotificationRoutingService.routeForNotificationType('');
        expect(route, isNull);
      });

      test('case-sensitive matching: wrong case returns null', () {
        final route = NotificationRoutingService.routeForNotificationType(
          'New_Message',
        );
        expect(route, isNull);
      });
    });
  });

  group('NotificationRoutingService.handleNotificationTap', () {
    late GoRouter router;

    setUp(() {
      router = _MockGoRouter();
    });

    // ===========================================================================
    // Each known type navigates correctly (backward-compatible – no role)
    // ===========================================================================
    test('new_message navigates to chat conversation', () {
      final data = <String, dynamic>{
        'notification_type': 'new_message',
        'id': 'conv_123',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/chat/conv_123')).called(1);
    });

    test('new_message without id navigates to chat list', () {
      final data = <String, dynamic>{
        'notification_type': 'new_message',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/chat')).called(1);
    });

    test('check_in_reviewed navigates to check-in history', () {
      final data = <String, dynamic>{
        'notification_type': 'check_in_reviewed',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/client/check-in/history')).called(1);
    });

    test('workout_reminder navigates to active workout', () {
      final data = <String, dynamic>{
        'notification_type': 'workout_reminder',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/client/workout')).called(1);
    });

    test('event_reminder navigates to event detail', () {
      final data = <String, dynamic>{
        'notification_type': 'event_reminder',
        'id': 'evt_001',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/events/evt_001')).called(1);
    });

    test('trainer_invite navigates to my trainer screen', () {
      final data = <String, dynamic>{
        'notification_type': 'trainer_invite',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/client/trainer')).called(1);
    });

    // ===========================================================================
    // Fallback behavior (unchanged)
    // ===========================================================================
    test('unknown notification type falls back to notifications', () {
      final data = <String, dynamic>{
        'notification_type': 'bogus_type',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/notifications')).called(1);
    });

    test('event_reminder without id falls back to notifications', () {
      final data = <String, dynamic>{
        'notification_type': 'event_reminder',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/notifications')).called(1);
    });

    test('event_reminder with empty id falls back to notifications', () {
      final data = <String, dynamic>{
        'notification_type': 'event_reminder',
        'id': '',
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/notifications')).called(1);
    });

    test('missing notification_type falls back to notifications', () {
      final data = <String, dynamic>{'some_other_key': 'value'};

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/notifications')).called(1);
    });

    test('null notification_type falls back to notifications', () {
      final data = <String, dynamic>{
        'notification_type': null,
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/notifications')).called(1);
    });

    test('empty data falls back to notifications', () {
      final data = <String, dynamic>{};

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/notifications')).called(1);
    });

    // ===========================================================================
    // Extra payload data is ignored (unchanged)
    // ===========================================================================
    test('extra fields in payload do not affect navigation', () {
      final data = <String, dynamic>{
        'notification_type': 'workout_reminder',
        'id': 'wo_456',
        'title': 'Time to work out!',
        'body': 'Your scheduled workout is ready.',
        'badge': 1,
      };

      NotificationRoutingService.handleNotificationTap(data, router);

      verify(() => router.go('/client/workout')).called(1);
    });
  });
}
