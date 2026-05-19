import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/system_error.dart';
import 'package:zirofit_fl/features/admin/providers/admin_provider.dart';
import 'package:zirofit_fl/features/admin/screens/admin_error_logs_screen.dart';
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
  Future<void> fetchErrors({int page = 1, int limit = 20, String? severity}) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SystemError _createError({
  String id = 'err-1',
  String message = 'Test error',
  String? path = '/api/test',
  int? statusCode = 500,
  String? severity = 'error',
}) {
  return SystemError(
    id: id,
    message: message,
    path: path,
    statusCode: statusCode,
    severity: severity,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  testWidgets('shows loading indicator when loading', (tester) async {
    await tester.pumpApp(
      const AdminErrorLogsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: true),
            )),
      ],
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when no errors', (tester) async {
    await tester.pumpApp(
      const AdminErrorLogsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(errors: [], isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('No errors found'), findsOneWidget);
  });

  testWidgets('shows errors list when data loaded', (tester) async {
    final errors = [
      _createError(id: 'err-1', message: 'First error', path: '/api/test1'),
      _createError(id: 'err-2', message: 'Second error', path: '/api/test2', severity: 'warning'),
    ];

    await tester.pumpApp(
      const AdminErrorLogsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(errors: errors, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('First error'), findsOneWidget);
    expect(find.text('Second error'), findsOneWidget);
    expect(find.text('Path: /api/test1'), findsOneWidget);
    expect(find.text('Path: /api/test2'), findsOneWidget);
  });

  testWidgets('shows severity filter chips', (tester) async {
    await tester.pumpApp(
      const AdminErrorLogsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              const AdminState(isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
  });

  testWidgets('shows severity badges on error cards', (tester) async {
    final errors = [
      _createError(id: 'err-1', severity: 'error'),
      _createError(id: 'err-2', severity: 'warning'),
    ];

    await tester.pumpApp(
      const AdminErrorLogsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(errors: errors, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('ERROR'), findsOneWidget);
    expect(find.text('WARNING'), findsOneWidget);
  });

  testWidgets('shows status code on error cards', (tester) async {
    final errors = [
      _createError(id: 'err-1', statusCode: 500),
      _createError(id: 'err-2', statusCode: 404),
    ];

    await tester.pumpApp(
      const AdminErrorLogsScreen(),
      overrides: [
        adminProvider.overrideWith((ref) => FakeAdminNotifier(
              AdminState(errors: errors, isLoading: false),
            )),
      ],
    );
    await tester.pump();

    expect(find.text('500'), findsOneWidget);
    expect(find.text('404'), findsOneWidget);
  });
}
