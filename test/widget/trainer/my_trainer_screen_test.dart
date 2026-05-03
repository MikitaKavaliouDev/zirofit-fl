import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/screens/my_trainer_screen.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_setup.dart';

/// A custom Dio interceptor that returns mock responses for testing.
class _MockInterceptor extends Interceptor {
  final Map<String, dynamic> trainerData;
  final bool shouldFailGet;
  final bool shouldFailDelete;

  _MockInterceptor({
    required this.trainerData,
    this.shouldFailGet = false,
    this.shouldFailDelete = false,
  });

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Intercept requests to /client/trainer
    if (options.path == '/client/trainer') {
      if (options.method == 'GET') {
        if (shouldFailGet) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 500,
                data: {'message': 'Failed to fetch trainer'},
              ),
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': trainerData},
          ),
        );
        return;
      } else if (options.method == 'DELETE') {
        if (shouldFailDelete) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 500,
                data: {'message': 'Failed to unlink trainer'},
              ),
            ),
          );
          return;
        }
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {},
          ),
        );
        return;
      }
    }

    // Let other requests pass through (they will fail, but we don't care)
    handler.next(options);
  }
}

void main() {
  group('MyTrainerScreen', () {
    setUp(() {
      ApiClient.reset();
      configureTestApiClient();
    });

    tearDown(() {
      ApiClient.reset();
    });

    testWidgets('shows loading indicator initially', (tester) async {
      // Add interceptor that delays the response
      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: {},
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Initially should show loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state when API fails', (tester) async {
      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: {},
          shouldFailGet: true,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Failed to fetch trainer'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows no trainer state when trainer is null', (tester) async {
      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: {}, // Empty data means no trainer
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Should show no trainer message
      expect(find.text('No trainer assigned yet.'), findsOneWidget);
      expect(find.byIcon(Icons.person_off), findsOneWidget);
    });

    testWidgets('shows trainer details when trainer exists', (tester) async {
      final trainerData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '+1234567890',
        'average_rating': 4.5,
        'about_me': 'Experienced fitness trainer',
        'specialties': ['Strength Training', 'Cardio'],
        'location': 'New York',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Should show trainer details
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

    testWidgets('shows initials when no avatar path', (tester) async {
      final trainerData = {
        'name': 'Jane Smith',
        'email': 'jane@example.com',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Should show initials
      expect(find.text('JS'), findsOneWidget);
    });

    testWidgets('shows avatar when avatar path exists', (tester) async {
      final trainerData = {
        'name': 'Bob Wilson',
        'avatar_path': 'https://example.com/avatar.jpg',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Should show CircleAvatar with NetworkImage
      expect(find.byType(CircleAvatar), findsOneWidget);
      // Initials should not be shown when avatar exists
      expect(find.text('BW'), findsNothing);
    });

    testWidgets('shows unlink confirmation dialog', (tester) async {
      final trainerData = {
        'name': 'Test Trainer',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Tap the unlink button
      await tester.tap(find.text('Unlink from Trainer'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Unlink Trainer'), findsOneWidget);
      expect(find.text('Are you sure you want to unlink from your trainer?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Unlink'), findsOneWidget);
    });

    testWidgets('closes dialog when cancel is tapped', (tester) async {
      final trainerData = {
        'name': 'Test Trainer',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Tap the unlink button
      await tester.tap(find.text('Unlink from Trainer'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Unlink Trainer'), findsNothing);
      // Trainer should still be shown
      expect(find.text('Test Trainer'), findsOneWidget);
    });

    testWidgets('shows unlinking state when unlinking', (tester) async {
      final trainerData = {
        'name': 'Test Trainer',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Tap the unlink button
      await tester.tap(find.text('Unlink from Trainer'));
      await tester.pumpAndSettle();

      // Tap unlink in dialog
      await tester.tap(find.text('Unlink'));
      // Don't pumpAndSettle yet - we want to see the loading state
      await tester.pump();

      // Should show unlinking state
      expect(find.text('Unlinking...'), findsOneWidget);
    });

    testWidgets('shows no trainer state after successful unlink', (tester) async {
      final trainerData = {
        'name': 'Test Trainer',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Tap the unlink button
      await tester.tap(find.text('Unlink from Trainer'));
      await tester.pumpAndSettle();

      // Tap unlink in dialog
      await tester.tap(find.text('Unlink'));
      await tester.pumpAndSettle();

      // Should show no trainer state
      expect(find.text('No trainer assigned yet.'), findsOneWidget);
      expect(find.text('Test Trainer'), findsNothing);
    });

    testWidgets('shows error snackbar when unlink fails', (tester) async {
      final trainerData = {
        'name': 'Test Trainer',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
          shouldFailDelete: true,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Tap the unlink button
      await tester.tap(find.text('Unlink from Trainer'));
      await tester.pumpAndSettle();

      // Tap unlink in dialog
      await tester.tap(find.text('Unlink'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.text('Failed to unlink trainer'), findsOneWidget);
      // Trainer should still be shown
      expect(find.text('Test Trainer'), findsOneWidget);
    });

    testWidgets('shows refresh indicator for pull to refresh', (tester) async {
      final trainerData = {
        'name': 'Test Trainer',
      };

      ApiClient.instance.dio.interceptors.add(
        _MockInterceptor(
          trainerData: trainerData,
        ),
      );

      await tester.pumpApp(
        const MyTrainerScreen(),
      );

      // Wait for the API call to complete
      await tester.pumpAndSettle();

      // Should show RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
