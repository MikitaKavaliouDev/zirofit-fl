import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/notification_model.dart' as models;
import 'package:zirofit_fl/features/dashboard/providers/sharing_requests_provider.dart';
import 'package:zirofit_fl/features/dashboard/screens/sharing_requests_screen.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake Notifier for static states (loading, empty, error)
// ---------------------------------------------------------------------------

class _FakeSharingRequestsNotifier extends SharingRequestsNotifier {
  final SharingRequestsState _s;
  _FakeSharingRequestsNotifier(this._s)
      : super(apiClient: ApiClient.instance) {
    super.state = _s;
  }

  @override
  SharingRequestsState get state => _s;

  @override
  Future<void> fetchRequests() async {}

  @override
  void clearError() {}
}

Widget _buildApp(SharingRequestsState state) => ProviderScope(
      overrides: [
        sharingRequestsProvider.overrideWith(
          (ref) => _FakeSharingRequestsNotifier(state),
        ),
      ],
      child: const MaterialApp(home: SharingRequestsScreen()),
    );

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

final DateTime _baseTime = DateTime.fromMillisecondsSinceEpoch(1700000000000);

models.Notification _request({
  String id = 'lr-1',
  String clientId = 'client-123',
  String clientName = 'John Doe',
  String message = 'John Doe wants to connect with you',
}) {
  return models.Notification(
    id: id,
    userId: 'user-1',
    message: message,
    type: 'client_link_request',
    readStatus: false,
    metadata: {'client_id': clientId, 'client_name': clientName},
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
      _buildApp(const SharingRequestsState(isLoading: true)),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no requests', (tester) async {
    await tester.pumpWidget(
      _buildApp(const SharingRequestsState(isLoading: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('No sharing requests'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('shows error state with retry button', (tester) async {
    await tester.pumpWidget(
      _buildApp(const SharingRequestsState(
        isLoading: false,
        error: 'Something went wrong',
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('displays list of sharing requests', (tester) async {
    final requests = <models.Notification>[
      _request(id: 'lr-1', clientName: 'John Doe', clientId: 'client-123'),
      _request(id: 'lr-2', clientName: 'Jane Smith', clientId: 'client-456'),
    ];
    await tester.pumpWidget(
      _buildApp(SharingRequestsState(
        requests: requests,
        isLoading: false,
      )),
    );
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Accept'), findsNWidgets(2));
    expect(find.text('Decline'), findsNWidgets(2));
  });

  testWidgets('accept button triggers accept and shows snackbar',
      (tester) async {
    final fake = _AcceptDeclineFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharingRequestsProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: SharingRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);

    // Tap Accept
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(fake.acceptCalled, true);
    expect(fake.acceptedClientId, 'client-123');
    // Snackbar shown
    expect(find.text('Client request accepted'), findsOneWidget);
    // Request removed from UI
    expect(find.text('John Doe'), findsNothing);
  });

  testWidgets('decline shows confirmation dialog then calls decline',
      (tester) async {
    final fake = _AcceptDeclineFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharingRequestsProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: SharingRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Decline on the card
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    // Confirmation dialog visible
    expect(find.text('Decline Request'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to decline the connection request from John Doe?',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);

    // Confirm decline via the dialog's FilledButton
    await tester.tap(find.widgetWithText(FilledButton, 'Decline'));
    await tester.pumpAndSettle();

    expect(fake.declineCalled, true);
    expect(fake.declinedClientId, 'client-123');
    // Request removed from UI
    expect(find.text('John Doe'), findsNothing);
  });

  testWidgets('decline dialog cancel does not call decline', (tester) async {
    final fake = _AcceptDeclineFake();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharingRequestsProvider.overrideWith((ref) => fake),
        ],
        child: const MaterialApp(home: SharingRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('John Doe'), findsOneWidget);

    // Tap Decline on the card
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();

    // Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fake.declineCalled, false);
    // Request still present
    expect(find.text('John Doe'), findsOneWidget);
  });
}

// ---------------------------------------------------------------------------
// Accept/Decline Tracker Fake
// ---------------------------------------------------------------------------

class _AcceptDeclineFake extends SharingRequestsNotifier {
  bool acceptCalled = false;
  bool declineCalled = false;
  String? acceptedClientId;
  String? declinedClientId;

  _AcceptDeclineFake() : super(apiClient: ApiClient.instance) {
    final request = models.Notification(
      id: 'lr-1',
      userId: 'user-1',
      message: 'John Doe wants to connect with you',
      type: 'client_link_request',
      readStatus: false,
      metadata: const {'client_id': 'client-123', 'client_name': 'John Doe'},
      createdAt: _baseTime,
      updatedAt: _baseTime,
    );
    super.state = SharingRequestsState(
      requests: [request],
      isLoading: false,
    );
  }

  @override
  Future<void> fetchRequests() async {}

  @override
  Future<bool> acceptRequest(String clientId) async {
    acceptCalled = true;
    acceptedClientId = clientId;
    _removeRequest(clientId);
    return true;
  }

  @override
  Future<bool> declineRequest(String clientId) async {
    declineCalled = true;
    declinedClientId = clientId;
    _removeRequest(clientId);
    return true;
  }

  void _removeRequest(String clientId) {
    final remaining = state.requests.where((n) {
      return n.metadata?['client_id'] != clientId;
    }).toList();
    super.state = state.copyWith(requests: remaining);
  }
}
