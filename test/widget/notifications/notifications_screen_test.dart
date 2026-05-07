import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/notification_model.dart' as models;
import 'package:zirofit_fl/features/notifications/providers/notifications_provider.dart';
import 'package:zirofit_fl/features/notifications/screens/notifications_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// FakeNotifier
// ---------------------------------------------------------------------------

class Fake extends NotificationsNotifier {
  final NotificationsState _s;
  Fake(this._s) : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  NotificationsState get state => _s;

  @override
  Future<void> fetchNotifications({List<String>? notificationTypes}) async {}

  @override
  Future<void> markRead(String id) async {}

  @override
  void clearError() {}
}

Widget buildApp(NotificationsState state) => ProviderScope(
      overrides: [
        notificationsProvider.overrideWith((ref) => Fake(state)),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    );

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final DateTime _baseTime = DateTime.fromMillisecondsSinceEpoch(1700000000000);

models.Notification _notif({
  String id = 'n1',
  String message = 'Test notification',
  String type = 'system',
  bool readStatus = false,
}) {
  return models.Notification(
    id: id,
    userId: 'user-1',
    message: message,
    type: type,
    readStatus: readStatus,
    createdAt: _baseTime,
    updatedAt: _baseTime,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());
  mainLinkRequest();

  testWidgets('shows loading spinner when isLoading and empty',
      (tester) async {
    await tester.pumpWidget(
      buildApp(const NotificationsState(isLoading: true)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays notifications with unread badge', (tester) async {
    final notifications = <models.Notification>[
      _notif(id: 'n1', message: 'Unread notification', readStatus: false),
      _notif(id: 'n2', message: 'Read notification', readStatus: true),
    ];
    await tester.pumpWidget(
      buildApp(NotificationsState(
        notifications: notifications,
        unreadCount: 1,
        isLoading: false,
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unread notification'), findsOneWidget);
    expect(find.text('Read notification'), findsOneWidget);
    expect(find.text('1 new'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
  });

  testWidgets('shows no badge when all notifications are read',
      (tester) async {
    final notifications = <models.Notification>[
      _notif(id: 'n1', message: 'Read one', readStatus: true),
      _notif(id: 'n2', message: 'Read two', readStatus: true),
    ];
    await tester.pumpWidget(
      buildApp(NotificationsState(
        notifications: notifications,
        unreadCount: 0,
        isLoading: false,
      )),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('new'), findsNothing);
  });

  testWidgets('shows empty state when no notifications', (tester) async {
    await tester.pumpWidget(
      buildApp(const NotificationsState(isLoading: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(
      buildApp(const NotificationsState(
        isLoading: false,
        error: 'Something went wrong',
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('tapping unread notification calls markRead', (tester) async {
    var markReadCalled = false;

    final trackerNotifier = _MarkReadTracker(
      (id) => markReadCalled = true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) => trackerNotifier),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // State already has data from the tracker
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();

    expect(markReadCalled, true);
  });
}

// ---------------------------------------------------------------------------
// Tracker Fake for tap test
// ---------------------------------------------------------------------------

class _MarkReadTracker extends NotificationsNotifier {
  final void Function(String id) onMarkRead;

  _MarkReadTracker(this.onMarkRead) : super(apiClient: ApiClient.instance) {
    // Seed with an unread notification
    final notif = models.Notification(
      id: 'n1',
      userId: 'user-1',
      message: 'Tap me',
      type: 'system',
      readStatus: false,
      createdAt: _baseTime,
      updatedAt: _baseTime,
    );
    super.state = NotificationsState(
      notifications: [notif],
      unreadCount: 1,
      isLoading: false,
    );
  }

  @override
  Future<void> fetchNotifications({List<String>? notificationTypes}) async {}

  @override
  Future<void> markRead(String id) async {
    onMarkRead(id);
  }
}

// ---------------------------------------------------------------------------
// Link Request Tests
// ---------------------------------------------------------------------------

class _LinkRequestFake extends NotificationsNotifier {
  bool acceptCalled = false;
  bool declineCalled = false;
  String? acceptedClientId;
  String? declinedClientId;

  _LinkRequestFake() : super(apiClient: ApiClient.instance) {
    final notif1 = models.Notification(
      id: 'lr-1',
      userId: 'user-1',
      message: 'John Doe wants to connect with you',
      type: 'client_link_request',
      readStatus: false,
      metadata: const {'client_id': 'client-123', 'client_name': 'John Doe'},
      createdAt: _baseTime,
      updatedAt: _baseTime,
    );
    super.state = NotificationsState(
      notifications: [notif1],
      unreadCount: 1,
      isLoading: false,
    );
  }

  @override
  Future<void> fetchNotifications({List<String>? notificationTypes}) async {}

  @override
  Future<void> acceptLinkRequest(String clientId) async {
    acceptCalled = true;
    acceptedClientId = clientId;
    // Remove the notification from state
    final remaining = state.notifications.where((n) {
      return n.metadata?['client_id'] != clientId;
    }).toList();
    super.state = state.copyWith(
      notifications: remaining,
      unreadCount: remaining.where((n) => !n.readStatus).length,
    );
  }

  @override
  Future<void> declineLinkRequest(String clientId) async {
    declineCalled = true;
    declinedClientId = clientId;
    // Remove the notification from state
    final remaining = state.notifications.where((n) {
      return n.metadata?['client_id'] != clientId;
    }).toList();
    super.state = state.copyWith(
      notifications: remaining,
      unreadCount: remaining.where((n) => !n.readStatus).length,
    );
  }
}

void mainLinkRequest() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows accept and decline buttons for link request',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) => _LinkRequestFake()),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('John Doe wants to connect with you'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
  });

  testWidgets('accept removes notification and updates badge', (tester) async {
    final fake = _LinkRequestFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Accept
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(fake.acceptCalled, true);
    expect(fake.acceptedClientId, 'client-123');
    // Notification removed
    expect(
      find.text('John Doe wants to connect with you'),
      findsNothing,
    );
    // Badge gone
    expect(find.textContaining('new'), findsNothing);
  });

  testWidgets('decline removes notification and updates badge',
      (tester) async {
    final fake = _LinkRequestFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationsProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Decline
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    expect(fake.declineCalled, true);
    expect(fake.declinedClientId, 'client-123');
    // Notification removed
    expect(
      find.text('John Doe wants to connect with you'),
      findsNothing,
    );
    // Badge gone
    expect(find.textContaining('new'), findsNothing);
  });
}
