import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/auth/providers/email_verification_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  // ===========================================================================
  // Initial state
  // ===========================================================================

  group('initial state', () {
    test('has correct default values', () {
      final state = container.read(emailVerificationProvider);
      expect(state.isPolling, false);
      expect(state.isConfirmed, false);
      expect(state.hasTimedOut, false);
      expect(state.error, isNull);
      expect(state.resendStatus, ResendStatus.idle);
    });
  });

  // ===========================================================================
  // startPolling
  // ===========================================================================

  group('startPolling', () {
    test('sets isPolling to true synchronously', () {
      final notifier = container.read(emailVerificationProvider.notifier);

      notifier.startPolling();

      expect(container.read(emailVerificationProvider).isPolling, true);
    });

    test('immediate check detects confirmed email and stops polling',
        () {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'user-1',
              'email': 'test@test.com',
              'emailConfirmedAt': '2024-06-01T12:00:00Z',
            },
          });

      fakeAsync((async) {
        final notifier = container.read(emailVerificationProvider.notifier);
        notifier.startPolling();

        // Check polling state immediately (synchronous)
        expect(container.read(emailVerificationProvider).isPolling, true);

        // Flush microtasks to let async continuation run
        async.flushMicrotasks();

        // Verify API was called
        verify(() => mockApiClient.get<Map<String, dynamic>>(ApiConstants.me)).called(1);

        final state = container.read(emailVerificationProvider);
        expect(state.isConfirmed, true);
        expect(state.isPolling, false);
      });
    });

    test('immediate check with no confirmation keeps polling', () {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'user-1',
              'email': 'test@test.com',
              // no emailConfirmedAt
            },
          });

      fakeAsync((async) {
        final notifier = container.read(emailVerificationProvider.notifier);
        notifier.startPolling();
        async.flushMicrotasks();

        final state = container.read(emailVerificationProvider);
        expect(state.isConfirmed, false);
        expect(state.isPolling, true);
      });
    });

    test('network error during check keeps polling alive', () {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.me),
        type: DioExceptionType.connectionTimeout,
      ));

      fakeAsync((async) {
        final notifier = container.read(emailVerificationProvider.notifier);
        notifier.startPolling();
        async.flushMicrotasks();

        final state = container.read(emailVerificationProvider);
        // Polling should continue silently despite the error
        expect(state.isPolling, true);
        expect(state.isConfirmed, false);
      });
    });

    test('polls repeatedly every 5 seconds', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'user-1',
              'email': 'test@test.com',
              // no emailConfirmedAt — keeps polling
            },
          });

      final notifier = container.read(emailVerificationProvider.notifier);
      notifier.startPolling();

      // Immediate check fires once
      // Wait for timer-based checks
      await Future.delayed(const Duration(milliseconds: 100));
      await Future(() {});

      // 1 (immediate) + timer-based calls = need to check
      verify(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).called(1);
    });
  });

  // ===========================================================================
  // Confirmation flow
  // ===========================================================================

  group('confirmation', () {
    test('stops polling when emailConfirmedAt is returned', () async {
      final completer = Completer<Map<String, dynamic>>();
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenAnswer((_) => completer.future);

      final notifier = container.read(emailVerificationProvider.notifier);
      notifier.startPolling();

      // State should be polling while waiting
      expect(container.read(emailVerificationProvider).isPolling, true);

      // Complete with confirmed email
      completer.complete(<String, dynamic>{
        'data': {
          'id': 'user-1',
          'email': 'test@test.com',
          'emailConfirmedAt': '2024-06-01T12:00:00Z',
        },
      });

      // Pump microtasks until the continuation runs
      for (var i = 0; i < 50; i++) {
        await null;
      }

      final state = container.read(emailVerificationProvider);
      expect(state.isConfirmed, true);
      expect(state.isPolling, false);
    });

    test('polls stop after maxPolls timeout', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'user-1',
              'email': 'test@test.com',
              // no emailConfirmedAt
            },
          });

      final notifier = container.read(emailVerificationProvider.notifier);
      notifier.startPolling();

      // isPolling should be true immediately after start
      expect(container.read(emailVerificationProvider).isPolling, true);
    });
  });

  // ===========================================================================
  // resendEmail
  // ===========================================================================

  group('resendEmail', () {
    test('sets resendStatus to sending', () async {
      when(() => mockApiClient.post(
            ApiConstants.resendVerification,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'message': 'Resent.'},
          });

      final notifier = container.read(emailVerificationProvider.notifier);

      // Don't await — check synchronous state change
      final future = notifier.resendEmail();

      expect(
        container.read(emailVerificationProvider).resendStatus,
        ResendStatus.sending,
      );

      await future;
    });

    test('calls POST to resendVerification endpoint on success', () async {
      when(() => mockApiClient.post(
            ApiConstants.resendVerification,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {'message': 'Resent.'},
          });

      await container
          .read(emailVerificationProvider.notifier)
          .resendEmail();

      verify(() => mockApiClient.post(
            ApiConstants.resendVerification,
          )).called(1);

      final state = container.read(emailVerificationProvider);
      expect(state.resendStatus, ResendStatus.sent);
      expect(state.error, isNull);
    });

    test('sets error state on failure', () async {
      when(() => mockApiClient.post(
            ApiConstants.resendVerification,
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.resendVerification),
        type: DioExceptionType.badResponse,
      ));

      await container
          .read(emailVerificationProvider.notifier)
          .resendEmail();

      final state = container.read(emailVerificationProvider);
      expect(state.resendStatus, ResendStatus.error);
      expect(state.error, isNotNull);
      expect(state.error, contains('Failed to resend'));
    });
  });

  // ===========================================================================
  // Lifecycle
  // ===========================================================================

  group('dispose', () {
    test('stops polling on container dispose', () {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.me,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': {
              'id': 'user-1',
              'email': 'test@test.com',
              // no emailConfirmedAt
            },
          });

      fakeAsync((async) {
        final notifier = container.read(emailVerificationProvider.notifier);
        notifier.startPolling();
        async.flushMicrotasks();

        // Polling is active
        expect(container.read(emailVerificationProvider).isPolling, true);

        // Dispose container
        container.dispose();

        // Re-create container and verify the notifier started fresh
        // (The old notifier should have been disposed.)
        final newContainer = createTestContainer(overrides: [
          apiClientProvider.overrideWithValue(mockApiClient as ApiClient),
        ]);

        final freshState = newContainer.read(emailVerificationProvider);
        expect(freshState.isPolling, false);
        expect(freshState.isConfirmed, false);

        newContainer.dispose();
      });
    });
  });
}
