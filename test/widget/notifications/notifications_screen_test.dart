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
  Future<void> fetchNotifications() async {}

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
  Future<void> fetchNotifications() async {}

  @override
  Future<void> markRead(String id) async {
    onMarkRead(id);
  }
}
