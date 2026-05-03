import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/notifications/providers/notifications_provider.dart';
import '../helpers/mock_api_client.dart';
import '../helpers/provider_utils.dart';
import '../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      notificationsProvider.overrideWith(
        (ref) => NotificationsNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
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
    return <String, dynamic>{
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
  // Notification Flow
  // ---------------------------------------------------------------------------

  group('Notification Flow', () {
    test('fetch list → mark one as read → unread count decreases', () async {
      // Arrange: mock GET /notifications to return two notifications
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

      // Act 1: fetchNotifications
      await container
          .read(notificationsProvider.notifier)
          .fetchNotifications();

      // Assert 1: initial state
      var state = container.read(notificationsProvider);
      expect(state.notifications, hasLength(2));
      expect(state.unreadCount, 1);
      expect(state.isLoading, false);
      expect(state.error, isNull);

      // Arrange: mock PUT /notifications/notif-1
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.notificationMarkRead('notif-1'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      // Act 2: markRead
      await container
          .read(notificationsProvider.notifier)
          .markRead('notif-1');

      // Assert 2: unread count decreased
      state = container.read(notificationsProvider);
      expect(state.unreadCount, 0);
      expect(state.notifications[0].readStatus, true);
      expect(state.notifications[1].readStatus, true);
      expect(state.error, isNull);
    });

    test('fetchNotifications handles error gracefully', () async {
      // Arrange: mock error
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(
        Exception('Network error'),
      );

      // Act
      await container
          .read(notificationsProvider.notifier)
          .fetchNotifications();

      // Assert
      final state = container.read(notificationsProvider);
      expect(state.notifications, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });
}
