import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/notifications/providers/notifications_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_setup.dart';

void main() {
  late MockApiClient mockApiClient;
  late NotificationsNotifier notifier;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = NotificationsNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  Map<String, dynamic> notificationJson({
    String id = 'notif-1',
    String message = 'Test notification',
    String type = 'system',
    bool readStatus = false,
  }) {
    return {
      'id': id,
      'user_id': 'user-1',
      'message': message,
      'type': type,
      'read_status': readStatus,
      'metadata': null,
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'deleted_at': null,
    };
  }

  Map<String, dynamic> responseWithData(List<Map<String, dynamic>> items) {
    return <String, dynamic>{'data': items};
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('notifications empty, isLoading=false, unreadCount=0', () {
      final state = notifier.state;
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchNotifications
  // ---------------------------------------------------------------------------

  group('fetchNotifications', () {
    test('populates notifications and unreadCount on success', () async {
      final notif1 = notificationJson(
        id: 'notif-1',
        message: 'First notification',
        readStatus: false,
      );
      final notif2 = notificationJson(
        id: 'notif-2',
        message: 'Second notification',
        type: 'message',
        readStatus: true,
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([notif1, notif2]));

      final future = notifier.fetchNotifications();
      // Intermediate loading state
      expect(notifier.state.isLoading, true);

      await future;

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.notifications.length, 2);
      expect(state.notifications[0].id, 'notif-1');
      expect(state.notifications[1].id, 'notif-2');
      expect(state.unreadCount, 1); // only notif-1 is unread
      expect(state.error, isNull);
    });

    test('handles empty list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([]));

      await notifier.fetchNotifications();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
      expect(state.error, isNull);
    });

    test('sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.notifications),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.notifications),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Server error'},
        ),
      ));

      await notifier.fetchNotifications();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.notifications, isEmpty);
      expect(state.error, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // markRead
  // ---------------------------------------------------------------------------

  group('markRead', () {
    test('updates notification locally and decrements unreadCount on success',
        () async {
      // Arrange: fetch some notifications first
      final notif1 = notificationJson(
        id: 'notif-1',
        message: 'Unread notification',
        readStatus: false,
      );
      final notif2 = notificationJson(
        id: 'notif-2',
        message: 'Read notification',
        readStatus: true,
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([notif1, notif2]));

      await notifier.fetchNotifications();
      expect(notifier.state.notifications.length, 2);
      expect(notifier.state.unreadCount, 1);

      // Act: mark notif-1 as read
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.notificationMarkRead('notif-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.markRead('notif-1');

      // Assert
      final state = notifier.state;
      expect(state.notifications.length, 2);
      expect(state.notifications[0].readStatus, true);
      expect(state.notifications[1].readStatus, true);
      expect(state.unreadCount, 0);
      expect(state.error, isNull);
    });

    test('does not change unreadCount when marking already-read notification',
        () async {
      // Arrange
      final notif = notificationJson(
        id: 'notif-1',
        message: 'Already read',
        readStatus: true,
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([notif]));

      await notifier.fetchNotifications();
      expect(notifier.state.unreadCount, 0);

      // Act
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.notificationMarkRead('notif-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.markRead('notif-1');

      // Assert
      expect(notifier.state.unreadCount, 0);
    });

    test('sets error on markRead failure', () async {
      // Arrange: fetch first
      final notif = notificationJson(
        id: 'notif-1',
        message: 'Unread notification',
        readStatus: false,
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([notif]));

      await notifier.fetchNotifications();
      expect(notifier.state.unreadCount, 1);

      // Act: markRead fails
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.notificationMarkRead('notif-1'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.notificationMarkRead('notif-1')),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.notificationMarkRead('notif-1')),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Mark read failed'},
        ),
      ));

      await notifier.markRead('notif-1');

      // Assert: unread count unchanged, error set
      final state = notifier.state;
      expect(state.unreadCount, 1);
      expect(state.error, isNotNull);
      expect(state.notifications[0].readStatus, false);
    });
  });
}
