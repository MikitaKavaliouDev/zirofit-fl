import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/screens/my_trainer_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Processes microtasks so that async work (API calls via mocktail) completes
/// and the widget rebuilds. Does NOT use pumpAndSettle which hangs on
/// RefreshIndicator glow animations.
Future<void> _pumpUntilSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump();
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Builds [MyTrainerScreen] with [mock] injected and pumps until settled.
Future<void> _pumpWithMock(WidgetTester tester, MockApiClient mock) async {
  await tester.pumpApp(MyTrainerScreen(apiClient: mock));
  await _pumpUntilSettled(tester);
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _trainerResponse(Map<String, dynamic> trainer) =>
    {'data': trainer};

DioException _apiError(int statusCode, String message) =>
    DioException(
      requestOptions: RequestOptions(path: '/client/trainer'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/client/trainer'),
        statusCode: statusCode,
        data: {'message': message},
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() => configureTestApiClient());

  group('MyTrainerScreen', () {
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
    });

    // =====================================================================
    // 1. Loading state
    // =====================================================================

    testWidgets('shows loading indicator initially', (tester) async {
      // Use a Completer to hold the API response open so the loading
      // indicator stays visible without creating orphaned timers.
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.get(
            '/client/trainer',
          )).thenAnswer((_) => completer.future);

      await tester.pumpApp(MyTrainerScreen(apiClient: mockApiClient));

      // Loading indicator should be visible before the API completes.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Clean up: resolve the completer so the test doesn't leak.
      completer.complete(_trainerResponse({}));
      await tester.pump();
    });

    // =====================================================================
    // 2. Error state
    // =====================================================================

    testWidgets('shows error state when API fails', (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenThrow(_apiError(500, 'Failed to fetch trainer'));

      await _pumpWithMock(tester, mockApiClient);

      expect(find.text('Failed to fetch trainer'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('tapping Try Again triggers reload', (tester) async {
      var callCount = 0;
      when(() => mockApiClient.get('/client/trainer')).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw _apiError(500, 'First attempt failed');
        }
        return _trainerResponse({'name': 'Retry Trainer'});
      });

      // First load: error state
      await _pumpWithMock(tester, mockApiClient);
      expect(find.text('First attempt failed'), findsOneWidget);

      // Tap "Try Again"
      await tester.tap(find.text('Try Again'));
      await _pumpUntilSettled(tester);

      // Second load succeeds — trainer details appear
      expect(find.text('Retry Trainer'), findsOneWidget);
      expect(find.text('First attempt failed'), findsNothing);
    });

    // =====================================================================
    // 3. Empty / no trainer state
    // =====================================================================

    testWidgets('shows no trainer state when trainer is null', (tester) async {
      // Backend returns {"data": null} when no trainer is assigned.
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer((_) async => <String, dynamic>{'data': null});

      await _pumpWithMock(tester, mockApiClient);

      expect(find.text('No trainer assigned yet.'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('shows no trainer state when data key is missing',
        (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer((_) async => <String, dynamic>{});

      await _pumpWithMock(tester, mockApiClient);

      expect(find.text('No trainer assigned yet.'), findsOneWidget);
    });

    // =====================================================================
    // 4. Trainer data display
    // =====================================================================

    testWidgets('shows all trainer details when trainer exists',
        (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({
              'name': 'John Doe',
              'email': 'john@example.com',
              'phone': '+1234567890',
              'average_rating': 4.5,
              'about_me': 'Experienced fitness trainer',
              'specialties': ['Strength Training', 'Cardio'],
              'location': 'New York',
            }),
          );

      await _pumpWithMock(tester, mockApiClient);

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);
      expect(find.text('Experienced fitness trainer'), findsOneWidget);
      expect(find.text('Strength Training'), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('New York'), findsOneWidget);
      expect(find.text('Unlink from Trainer'), findsOneWidget);
    });

    // =====================================================================
    // 5. Trainer without optional fields
    // =====================================================================

    testWidgets('handles missing optional fields gracefully',
        (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({
              'name': 'Jane Smith',
              // no email, phone, location, average_rating
            }),
          );

      await _pumpWithMock(tester, mockApiClient);

      // Name is always present
      expect(find.text('Jane Smith'), findsOneWidget);

      // Optional fields should not appear
      expect(find.byIcon(Icons.email), findsNothing);
      expect(find.byIcon(Icons.phone), findsNothing);
      expect(find.byIcon(Icons.location_on), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);

      // About section should not appear
      expect(find.text('About'), findsNothing);

      // Specialties section should not appear (empty list)
      expect(find.text('Specialties'), findsNothing);

      // Unlink button remains
      expect(find.text('Unlink from Trainer'), findsOneWidget);
    });

    testWidgets('handles empty specialties list gracefully', (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({
              'name': 'Jane Smith',
              'specialties': [],
            }),
          );

      await _pumpWithMock(tester, mockApiClient);

      // Empty specialties should not render the Specialties section
      expect(find.text('Specialties'), findsNothing);
    });

    testWidgets('handles null rating without crashing', (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({
              'name': 'Jane Smith',
              'average_rating': null,
            }),
          );

      await _pumpWithMock(tester, mockApiClient);

      expect(find.text('Jane Smith'), findsOneWidget);
      // Star icon should not appear because rating is null
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('shows initials when no avatar path', (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({
              'name': 'Jane Smith',
              'email': 'jane@example.com',
            }),
          );

      await _pumpWithMock(tester, mockApiClient);

      expect(find.text('JS'), findsOneWidget);
    });

    // =====================================================================
    // 6. Unlink confirmation dialog
    // =====================================================================

    /// Sets up the initial trainer fetch and pumps until the trainer details
    /// are rendered.
    Future<void> _setupTrainer(WidgetTester tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({'name': 'Test Trainer'}),
          );
      await _pumpWithMock(tester, mockApiClient);
    }

    /// Opens the unlink confirmation dialog after [_setupTrainer].
    Future<void> _openUnlinkDialog(WidgetTester tester) async {
      await _setupTrainer(tester);
      await tester.tap(find.text('Unlink from Trainer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('shows unlink confirmation dialog', (tester) async {
      await _openUnlinkDialog(tester);

      expect(find.text('Unlink Trainer'), findsOneWidget);
      expect(
        find.text(
          'Are you sure you want to unlink from your trainer? '
          'This action cannot be undone.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Unlink'), findsOneWidget);
    });

    testWidgets('closes dialog when Cancel is tapped', (tester) async {
      await _openUnlinkDialog(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Unlink Trainer'), findsNothing);
      expect(find.text('Test Trainer'), findsOneWidget);
    });

    testWidgets('shows unlinking state while delete is in progress',
        (tester) async {
      // Hold the delete response open so the unlinking state is visible.
      final deleteCompleter = Completer<void>();
      when(() => mockApiClient.delete('/client/trainer'))
          .thenAnswer((_) => deleteCompleter.future);

      await _openUnlinkDialog(tester);

      await tester.tap(find.text('Unlink'));
      // First pump: process dialog close (Navigator.pop).
      await tester.pump();
      // Second pump: process the delete call's setState (isUnlinking = true).
      await tester.pump();

      expect(find.text('Unlinking...'), findsOneWidget);

      // Clean up: resolve the completer.
      deleteCompleter.complete();
      await tester.pump();
    });

    // =====================================================================
    // 7. Unlink success
    // =====================================================================

    testWidgets('shows success snackbar after successful unlink',
        (tester) async {
      when(() => mockApiClient.delete('/client/trainer'))
          .thenAnswer((_) async => {});

      await _openUnlinkDialog(tester);

      await tester.tap(find.text('Unlink'));
      await _pumpUntilSettled(tester);

      // SnackBar with success message
      expect(
        find.text('Successfully unlinked from trainer.'),
        findsOneWidget,
      );

      // Returns to no-trainer state
      expect(find.text('No trainer assigned yet.'), findsOneWidget);
      expect(find.text('Test Trainer'), findsNothing);
    });

    // =====================================================================
    // 8. Unlink error
    // =====================================================================

    testWidgets('shows error snackbar when unlink fails', (tester) async {
      when(() => mockApiClient.delete('/client/trainer'))
          .thenThrow(_apiError(500, 'Failed to unlink trainer'));

      await _openUnlinkDialog(tester);

      await tester.tap(find.text('Unlink'));
      await _pumpUntilSettled(tester);

      // Error snackbar shown
      expect(find.text('Failed to unlink trainer'), findsOneWidget);

      // Trainer details should still be displayed
      expect(find.text('Test Trainer'), findsOneWidget);
    });

    // =====================================================================
    // Pull to refresh
    // =====================================================================

    testWidgets('shows RefreshIndicator for pull to refresh', (tester) async {
      when(() => mockApiClient.get('/client/trainer'))
          .thenAnswer(
            (_) async => _trainerResponse({'name': 'Test Trainer'}),
          );

      await _pumpWithMock(tester, mockApiClient);

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
