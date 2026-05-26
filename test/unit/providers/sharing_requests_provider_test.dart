import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/dashboard/providers/sharing_requests_provider.dart';
import '../../helpers/mock_api_client.dart';
import '../../helpers/test_setup.dart';

void main() {
  late MockApiClient mockApiClient;
  late SharingRequestsNotifier notifier;

  setUpAll(() => configureTestApiClient());

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = SharingRequestsNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Fixtures
  // ---------------------------------------------------------------------------

  Map<String, dynamic> linkRequestJson({
    String id = 'lr-1',
    String clientId = 'client-123',
    String clientName = 'John Doe',
    String message = 'John Doe wants to connect with you',
  }) {
    return {
      'id': id,
      'user_id': 'user-1',
      'message': message,
      'type': 'client_link_request',
      'read_status': false,
      'metadata': {'client_id': clientId, 'client_name': clientName},
      'created_at': 1700000000000,
      'updated_at': 1700000000000,
      'deleted_at': null,
    };
  }

  Map<String, dynamic> responseWithData(List<Map<String, dynamic>> items) {
    return <String, dynamic>{'data': items};
  }

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('initial state', () {
    test('requests empty, isLoading=false', () {
      final state = notifier.state;
      expect(state.requests, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchRequests
  // ---------------------------------------------------------------------------

  group('fetchRequests', () {
    test('populates requests on success', () async {
      final json1 = linkRequestJson();
      final json2 = linkRequestJson(
        id: 'lr-2',
        clientId: 'client-456',
        clientName: 'Jane Smith',
        message: 'Jane Smith wants to connect with you',
      );

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([json1, json2]));

      final future = notifier.fetchRequests();
      // Intermediate loading state
      expect(notifier.state.isLoading, true);

      await future;

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.requests.length, 2);
      expect(state.requests[0].id, 'lr-1');
      expect(state.requests[0].type, 'client_link_request');
      expect(state.requests[0].metadata!['client_id'], 'client-123');
      expect(state.requests[1].id, 'lr-2');
      expect(state.error, isNull);
    });

    test('handles empty list', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([]));

      await notifier.fetchRequests();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.requests, isEmpty);
      expect(state.error, isNull);
    });

    test('sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.notifications),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.notifications),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Server error'},
        ),
      ));

      await notifier.fetchRequests();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.requests, isEmpty);
      expect(state.error, isNotNull);
    });

    test('filters query params to types=client_link_request', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([]));

      await notifier.fetchRequests();

      verify(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: {'types': 'client_link_request'},
          )).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // acceptRequest
  // ---------------------------------------------------------------------------

  group('acceptRequest', () {
    test('calls POST /trainer/clients/{id}/accept and removes request',
        () async {
      // Arrange: seed a request
      final json = linkRequestJson();
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([json]));
      await notifier.fetchRequests();
      expect(notifier.state.requests.length, 1);

      // Act
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerClientAccept('client-123'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final result = await notifier.acceptRequest('client-123');

      // Assert
      expect(result, true);
      verify(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerClientAccept('client-123'),
            body: any(named: 'body'),
          )).called(1);
      expect(notifier.state.requests, isEmpty);
    });

    test('returns false on failure', () async {
      // Arrange: seed a request
      final json = linkRequestJson();
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([json]));
      await notifier.fetchRequests();
      expect(notifier.state.requests.length, 1);

      // Act: API error
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerClientAccept('client-123'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
          path: ApiConstants.trainerClientAccept('client-123'),
        ),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(
            path: ApiConstants.trainerClientAccept('client-123'),
          ),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Accept failed'},
        ),
      ));

      final result = await notifier.acceptRequest('client-123');

      expect(result, false);
      expect(notifier.state.error, isNotNull);
      // request still present
      expect(notifier.state.requests.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // declineRequest
  // ---------------------------------------------------------------------------

  group('declineRequest', () {
    test('calls POST /trainer/clients/{id}/decline and removes request',
        () async {
      // Arrange: seed a request
      final json = linkRequestJson();
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([json]));
      await notifier.fetchRequests();
      expect(notifier.state.requests.length, 1);

      // Act
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerClientDecline('client-123'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{});

      final result = await notifier.declineRequest('client-123');

      // Assert
      expect(result, true);
      verify(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerClientDecline('client-123'),
            body: any(named: 'body'),
          )).called(1);
      expect(notifier.state.requests, isEmpty);
    });

    test('returns false on failure', () async {
      // Arrange: seed a request
      final json = linkRequestJson();
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.notifications,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => responseWithData([json]));
      await notifier.fetchRequests();
      expect(notifier.state.requests.length, 1);

      // Act: API error
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerClientDecline('client-123'),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
          path: ApiConstants.trainerClientDecline('client-123'),
        ),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(
            path: ApiConstants.trainerClientDecline('client-123'),
          ),
          statusCode: 500,
          data: <String, dynamic>{'message': 'Decline failed'},
        ),
      ));

      final result = await notifier.declineRequest('client-123');

      expect(result, false);
      expect(notifier.state.error, isNotNull);
      // request still present
      expect(notifier.state.requests.length, 1);
    });
  });
}
