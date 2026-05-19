import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/user.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_users_screen.dart';
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
  AdminState get state => _overriddenState;

  @override
  Future<void> fetchUsers({int page = 1, int limit = 20, String? role}) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

User _createUser({
  String id = 'user-1',
  String name = 'Test User',
  String email = 'test@test.com',
  String role = 'client',
}) {
  return User(
    id: id,
    name: name,
    email: email,
    role: role,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpApp(
      const AdminUsersScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no users', (tester) async {
    await tester.pumpApp(
      const AdminUsersScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(users: [], isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('No users found'), findsOneWidget);
  });

  testWidgets('shows users list when data loaded', (tester) async {
    final users = [
      _createUser(id: 'u1', name: 'Alice', role: 'trainer'),
      _createUser(id: 'u2', name: 'Bob', role: 'client'),
    ];

    await tester.pumpApp(
      const AdminUsersScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(users: users, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  testWidgets('shows role filter chips', (tester) async {
    await tester.pumpApp(
      const AdminUsersScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Trainer'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('shows user detail dialog on tap', (tester) async {
    final users = [
      _createUser(id: 'u1', name: 'Alice', email: 'alice@test.com', role: 'trainer'),
    ];

    await tester.pumpApp(
      const AdminUsersScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(users: users, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    // Tap on user tile
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    // Detail dialog should show email, role, tier
    expect(find.text('alice@test.com'), findsAtLeast(1));
    expect(find.text('TRAINER'), findsAtLeast(1));
  });
}
