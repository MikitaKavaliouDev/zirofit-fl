import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Base class for E2E integration tests.
///
/// Provides:
/// - One-time [IntegrationTestWidgetsFlutterBinding] initialization
/// - Standard setUp / tearDown lifecycle
/// - Common helpers (login, navigation)
abstract class E2ETestBase {
  static bool _initialized = false;

  /// Ensures [IntegrationTestWidgetsFlutterBinding] is initialized exactly once.
  static void ensureInitialized() {
    if (!_initialized) {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
      _initialized = true;
    }
  }

  /// Per-test setUp.
  ///
  /// Call this from each test file's `setUp`:
  /// ```dart
  /// setUp(() => testBase.setUp(tester));
  /// ```
  Future<void> setUp(WidgetTester tester) async {
    ensureInitialized();
  }

  /// Per-test tearDown.
  ///
  /// Call this from each test file's `tearDown`:
  /// ```dart
  /// tearDown(() => testBase.tearDown(tester));
  /// ```
  Future<void> tearDown(WidgetTester tester) async {
    // Override to add cleanup logic (e.g., reset state, clear caches).
  }

  /// Fills in the login form and taps Sign In.
  ///
  /// Expects exactly two [TextFormField] widgets to be present (email, password).
  /// After tapping Sign In, pumps until the widget tree settles.
  Future<void> login(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    // Find all text form fields – login screen has two: email then password.
    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(2));

    await tester.enterText(textFields.at(0), email);
    await tester.enterText(textFields.at(1), password);

    // Tap the Sign In button.
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
  }

  /// Convenience: pump the app widget until the first frame renders.
  ///
  /// Useful in setUp for awaiting router redirects before interacting.
  Future<void> pumpUntilSettled(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }
}
