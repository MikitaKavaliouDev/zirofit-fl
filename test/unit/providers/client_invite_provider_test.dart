import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/clients/providers/client_invite_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ClientInviteNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = ClientInviteNotifier(apiClient: mockApiClient);
  });

  group('ClientInviteNotifier', () {
    test('initial state has correct defaults', () {
      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.isSuccess, false);
      expect(state.invitedEmail, isNull);
      expect(state.emailExists, false);
      expect(state.hasError, isFalse);
    });

    // -----------------------------------------------------------------------
    // invite
    // -----------------------------------------------------------------------

    test('invite sends correct payload', () async {
      when(() => mockApiClient.post(
            '/clients/invite',
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.invite(
        email: 'alice@test.com',
        name: 'Alice Johnson',
      );

      verify(() => mockApiClient.post(
            '/clients/invite',
            body: {
              'email': 'alice@test.com',
              'name': 'Alice Johnson',
            },
          )).called(1);

      expect(notifier.state.isSuccess, true);
      expect(notifier.state.invitedEmail, 'alice@test.com');
      expect(notifier.state.isLoading, false);
    });

    test('invite includes optional message when provided', () async {
      when(() => mockApiClient.post(
            '/clients/invite',
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.invite(
        email: 'bob@test.com',
        name: 'Bob Smith',
        message: 'Welcome to Ziro Fit!',
      );

      verify(() => mockApiClient.post(
            '/clients/invite',
            body: {
              'email': 'bob@test.com',
              'name': 'Bob Smith',
              'message': 'Welcome to Ziro Fit!',
            },
          )).called(1);
    });

    test('invite sets emailExists when server returns 409', () async {
      when(() => mockApiClient.post(
            '/clients/invite',
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/clients/invite'),
        response: Response(
          requestOptions: RequestOptions(path: '/clients/invite'),
          statusCode: 409,
          data: <String, dynamic>{
            'error': {'message': 'User already exists'},
          },
        ),
      ));

      await notifier.invite(
        email: 'existing@test.com',
        name: 'Existing User',
      );

      final state = notifier.state;
      expect(state.emailExists, true);
      expect(state.isLoading, false);
      expect(state.error, 'This user is already registered on Ziro Fit.');
    });

    test('invite handles network error gracefully', () async {
      when(() => mockApiClient.post(
            '/clients/invite',
            body: any(named: 'body'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionTimeout,
        requestOptions: RequestOptions(path: '/clients/invite'),
      ));

      await notifier.invite(
        email: 'network@test.com',
        name: 'Network Test',
      );

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.hasError, true);
      expect(state.error, 'Connection timeout. Please try again.');
    });

    // -----------------------------------------------------------------------
    // checkEmail
    // -----------------------------------------------------------------------

    test('checkEmail returns true when user exists', () async {
      when(() => mockApiClient.get(
            '/clients/check-email',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'exists': true});

      final exists = await notifier.checkEmail('existing@test.com');

      verify(() => mockApiClient.get(
            '/clients/check-email',
            queryParams: {'email': 'existing@test.com'},
          )).called(1);

      expect(exists, true);
      expect(notifier.state.emailExists, true);
    });

    test('checkEmail returns false when user does not exist', () async {
      when(() => mockApiClient.get(
            '/clients/check-email',
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => <String, dynamic>{'exists': false});

      final exists = await notifier.checkEmail('new@test.com');

      expect(exists, false);
      expect(notifier.state.emailExists, false);
    });

    test('checkEmail returns false on error', () async {
      when(() => mockApiClient.get(
            '/clients/check-email',
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        type: DioExceptionType.connectionError,
        requestOptions: RequestOptions(path: '/clients/check-email'),
      ));

      final exists = await notifier.checkEmail('error@test.com');

      expect(exists, false);
      expect(notifier.state.hasError, true);
    });

    // -----------------------------------------------------------------------
    // linkExisting
    // -----------------------------------------------------------------------

    test('linkExisting sends link request', () async {
      when(() => mockApiClient.post(
            '/clients/link',
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      await notifier.linkExisting('existing@test.com');

      verify(() => mockApiClient.post(
            '/clients/link',
            body: {'email': 'existing@test.com'},
          )).called(1);

      expect(notifier.state.isSuccess, true);
      expect(notifier.state.invitedEmail, 'existing@test.com');
      expect(notifier.state.isLoading, false);
    });

    test('linkExisting handles error', () async {
      when(() => mockApiClient.post(
            '/clients/link',
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: '/clients/link'),
        response: Response(
          requestOptions: RequestOptions(path: '/clients/link'),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Server error'},
          },
        ),
      ));

      await notifier.linkExisting('existing@test.com');

      final state = notifier.state;
      expect(state.isSuccess, false);
      expect(state.hasError, true);
      expect(state.error, 'Server error');
    });

    // -----------------------------------------------------------------------
    // reset
    // -----------------------------------------------------------------------

    test('reset clears state', () async {
      // First set some state
      when(() => mockApiClient.post(
            '/clients/invite',
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});
      await notifier.invite(email: 'a@b.com', name: 'Test');
      expect(notifier.state.isSuccess, true);

      // Then reset
      notifier.reset();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.isSuccess, false);
      expect(state.invitedEmail, isNull);
      expect(state.emailExists, false);
      expect(state.error, isNull);
    });
  });
}
