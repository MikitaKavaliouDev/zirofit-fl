import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/screens/trainer_dashboard_screen.dart';
import '../../helpers/test_setup.dart';

class FakeTD extends TrainerDashboardNotifier {
  final TrainerDashboardState _s;
  FakeTD(this._s) : super(apiClient: ApiClient.instance) { super.state = _s; }
  @override TrainerDashboardState get state => _s;
  @override Future<void> fetchDashboard() async {}
  @override Future<void> refresh() async {}
}

class FakeAuth extends AuthNotifier {
  final AuthState _s;
  FakeAuth(this._s) : super(apiClient: ApiClient.instance, secureStorage: FakeSecureStorage()) { super.state = _s; }
  @override AuthState get state => _s;
}

Widget b(TrainerDashboardState ds) => ProviderScope(overrides: [
  trainerDashboardProvider.overrideWith((ref) => FakeTD(ds)),
  authProvider.overrideWith((ref) => FakeAuth(const AuthState(status: AuthStatus.authenticated, user: User(id: '1', email: 't@t.com', name: 'Coach'), role: 'trainer')))
], child: const MaterialApp(home: TrainerDashboardScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  testWidgets('loading', (t) async { await t.pumpWidget(b(const TrainerDashboardState(status: TrainerDashboardStatus.loading))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('data', (t) async {
    final now = DateTime.now();
    const testData = TrainerDashboardData(
      stats: TrainerDashboardStats(
        revenue: 4250,
        activeClients: 24,
        todaySessions: 0,
        pendingCheckIns: 3,
        pendingBookings: 5,
      ),
      upcomingSessions: [],
      recentActivity: [],
      activeClients: [],
    );
    await t.pumpWidget(b(const TrainerDashboardState(status: TrainerDashboardStatus.loaded, data: testData)));
    await t.pump(); await t.pump(const Duration(seconds: 1));
    // Today's Overview and stats grid are in the initial viewport
    expect(find.text("Today's Overview"), findsOneWidget);
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(b(const TrainerDashboardState(status: TrainerDashboardStatus.error, error: 'err')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Try Again'), findsOneWidget);
  });
}
