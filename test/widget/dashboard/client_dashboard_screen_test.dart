import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/screens/client_dashboard_screen.dart';
import '../../helpers/test_setup.dart';

class FakeCD extends ClientDashboardNotifier {
  final ClientDashboardState _s;
  FakeCD(this._s) : super(apiClient: ApiClient.instance) { super.state = _s; }
  @override ClientDashboardState get state => _s;
  @override Future<void> fetchDashboard() async {}
  @override Future<void> refresh() async {}
  @override void markCheckInCompleted() {}
}

class FakeAuth extends AuthNotifier {
  final AuthState _s;
  FakeAuth(this._s) : super(apiClient: ApiClient.instance, secureStorage: FakeSecureStorage()) { super.state = _s; }
  @override AuthState get state => _s;
}

Widget b(ClientDashboardState ds) => ProviderScope(overrides: [
  clientDashboardProvider.overrideWith((ref) => FakeCD(ds)),
  authProvider.overrideWith((ref) => FakeAuth(const AuthState(status: AuthStatus.authenticated, user: User(id: '1', email: 'c@t.com', name: 'TC'))))
], child: const MaterialApp(home: ClientDashboardScreen()));

void main() {
  setUpAll(() => configureTestApiClient());
  testWidgets('loading', (t) async { await t.pumpWidget(b(const ClientDashboardState(status: ClientDashboardStatus.loading))); await t.pump(); expect(find.byType(CircularProgressIndicator), findsOneWidget); });
  testWidgets('data', (t) async {
    await t.pumpWidget(b(ClientDashboardState(status: ClientDashboardStatus.loaded, data: ClientDashboardData.mock())));
    await t.pump(); await t.pump(const Duration(seconds: 1));
    // "Hello," appears in the sliver app bar title (and possibly elsewhere)
    expect(find.text('Hello,'), findsAtLeastNWidgets(1));
    expect(find.text('Start Workout'), findsOneWidget);
    expect(find.text('Last Workout'), findsOneWidget);
  });
  testWidgets('error', (t) async {
    await t.pumpWidget(b(const ClientDashboardState(status: ClientDashboardStatus.error, error: 'err')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Try Again'), findsOneWidget);
  });
}
