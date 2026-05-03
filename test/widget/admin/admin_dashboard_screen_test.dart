import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_dashboard_screen.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Fake notifier for testing
// ---------------------------------------------------------------------------

class FakeAdminNotifier extends AdminNotifier {
  final AdminState _overriddenState;

  FakeAdminNotifier(this._overriddenState)
      : super(apiClient: ApiClient.instance) {
    state = _overriddenState;
  }

  @override
  AdminState get state {
    print('FakeAdminNotifier state accessed: isLoading=${_overriddenState.isLoading}, stats=${_overriddenState.stats}, error=${_overriddenState.error}');
    if (_overriddenState.error != null) {
      print('Error length: ${_overriddenState.error!.length}');
      print('Error chars: ${_overriddenState.error!.codeUnits}');
    }
    return _overriddenState;
  }

  @override
  Future<void> fetchStats() async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _createStats({
  int totalUsers = 100,
  int totalTrainers = 10,
  int totalClients = 90,
  int totalEvents = 25,
  int pendingEvents = 5,
  int totalBlogPosts = 12,
  int openTickets = 3,
}) {
  return {
    'totalUsers': totalUsers,
    'totalTrainers': totalTrainers,
    'totalClients': totalClients,
    'totalEvents': totalEvents,
    'pendingEvents': pendingEvents,
    'totalBlogPosts': totalBlogPosts,
    'openTickets': openTickets,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading and stats null',
      (tester) async {
    await tester.pumpApp(
      const AdminDashboardScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows error state without crashing', (tester) async {
    await tester.pumpApp(
      const AdminDashboardScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(error: 'Something went wrong'),
            )),
      ],
    );
    await tester.pump();

    // Error is not displayed in this screen, but stats grid should appear with default values
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    // Ensure loading indicator is not shown
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows error state with stats without crashing', (tester) async {
    final stats = _createStats();
    await tester.pumpApp(
      const AdminDashboardScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(stats: stats, error: 'Something went wrong'),
            )),
      ],
    );
    await tester.pump();

    // Error is not displayed in this screen, but stats grid should appear with provided stats
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    // Ensure loading indicator is not shown
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows stats grid when data loaded', (tester) async {
    final stats = _createStats();

    await tester.pumpApp(
      const AdminDashboardScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(stats: stats, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    // Check for stat labels
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('Total Trainers'), findsOneWidget);
    expect(find.text('Total Clients'), findsOneWidget);
    expect(find.text('Total Events'), findsOneWidget);
    expect(find.text('Pending Events'), findsOneWidget);
    expect(find.text('Blog Posts'), findsOneWidget);
    expect(find.text('Open Tickets'), findsOneWidget);
    // Check for values
    expect(find.text('100'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('90'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('shows empty stats when stats null but not loading',
      (tester) async {
    await tester.pumpApp(
      const AdminDashboardScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(stats: null, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    // Should still show stat labels with default values (0)
    expect(find.text('Total Users'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
  });




}