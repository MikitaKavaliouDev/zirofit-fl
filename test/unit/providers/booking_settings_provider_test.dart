import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/bookings/providers/booking_settings_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockApiClient mockApiClient;
  late BookingSettingsNotifier notifier;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = BookingSettingsNotifier(apiClient: mockApiClient);
  });

  group('BookingSettingsNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has sensible defaults', () {
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.advanceNotice, 24);
      expect(notifier.state.bookingHorizon, 30);
      expect(notifier.state.bufferMinutes, 0);
      expect(notifier.state.error, isNull);
      expect(notifier.state.successMessage, isNull);
    });

    // ---------------------------------------------------------------------------
    // loadSettings
    // ---------------------------------------------------------------------------
    test('loadSettings populates values on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': {
              'advanceNotice': 4,
              'bookingHorizon': 60,
              'bufferMinutes': 15,
            },
          });

      await notifier.loadSettings();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.advanceNotice, 4);
      expect(notifier.state.bookingHorizon, 60);
      expect(notifier.state.bufferMinutes, 15);
      expect(notifier.state.error, isNull);
    });

    test('loadSettings handles flat response without data wrapper', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'advanceNotice': 12,
            'bookingHorizon': 45,
            'bufferMinutes': 30,
          });

      await notifier.loadSettings();

      expect(notifier.state.advanceNotice, 12);
      expect(notifier.state.bookingHorizon, 45);
      expect(notifier.state.bufferMinutes, 30);
    });

    test('loadSettings keeps defaults on missing fields', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': <String, dynamic>{},
          });

      await notifier.loadSettings();

      expect(notifier.state.advanceNotice, 24);
      expect(notifier.state.bookingHorizon, 30);
      expect(notifier.state.bufferMinutes, 0);
    });

    test('loadSettings keeps defaults on API error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Network error'));

      await notifier.loadSettings();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.advanceNotice, 24);
      expect(notifier.state.bookingHorizon, 30);
      expect(notifier.state.bufferMinutes, 0);
      // Error is silently handled (same pattern as working hours)
    });

    // ---------------------------------------------------------------------------
    // saveSettings
    // ---------------------------------------------------------------------------
    test('saveSettings sends correct values', () async {
      // Set up some values first
      notifier.updateAdvanceNotice(6);
      notifier.updateBookingHorizon(30);
      notifier.updateBufferMinutes(20);

      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[const Symbol('body')] as Map;
        expect(body['advanceNotice'], 6);
        expect(body['bookingHorizon'], 30);
        expect(body['bufferMinutes'], 20);
        return <String, dynamic>{};
      });

      final result = await notifier.saveSettings();

      expect(result, true);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.error, isNull);
    });

    test('saveSettings returns false on API error and sets error', () async {
      notifier.updateAdvanceNotice(12);

      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          data: {'message': 'Validation failed'},
          statusCode: 422,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      final result = await notifier.saveSettings();

      expect(result, false);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // Mutators
    // ---------------------------------------------------------------------------
    test('updateAdvanceNotice clamps between 2 and 72', () {
      notifier.updateAdvanceNotice(1);
      expect(notifier.state.advanceNotice, 2);

      notifier.updateAdvanceNotice(100);
      expect(notifier.state.advanceNotice, 72);

      notifier.updateAdvanceNotice(24);
      expect(notifier.state.advanceNotice, 24);
    });

    test('updateBookingHorizon clamps between 7 and 90', () {
      notifier.updateBookingHorizon(3);
      expect(notifier.state.bookingHorizon, 7);

      notifier.updateBookingHorizon(120);
      expect(notifier.state.bookingHorizon, 90);

      notifier.updateBookingHorizon(30);
      expect(notifier.state.bookingHorizon, 30);
    });

    test('updateBufferMinutes clamps between 0 and 120', () {
      notifier.updateBufferMinutes(-1);
      expect(notifier.state.bufferMinutes, 0);

      notifier.updateBufferMinutes(200);
      expect(notifier.state.bufferMinutes, 120);

      notifier.updateBufferMinutes(30);
      expect(notifier.state.bufferMinutes, 30);
    });

    // ---------------------------------------------------------------------------
    // Error handling
    // ---------------------------------------------------------------------------
    test('error message extracted from DioException with message field', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          data: {'message': 'Invalid advance notice value'},
          statusCode: 422,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      await notifier.saveSettings();

      expect(notifier.state.error, 'Invalid advance notice value');
    });

    test('connection error shows appropriate message', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      await notifier.saveSettings();

      expect(
        notifier.state.error,
        'No internet connection. Please check your network.',
      );
    });

    test('timeout error shows appropriate message', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerBookingSettings,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.saveSettings();

      expect(
        notifier.state.error,
        'Connection timeout. Please try again.',
      );
    });

    // ---------------------------------------------------------------------------
    // clearMessages
    // ---------------------------------------------------------------------------
    test('clearMessages clears error and successMessage', () {
      notifier = BookingSettingsNotifier(apiClient: mockApiClient);

      // Set error and success message directly via copyWith
      notifier.state = notifier.state.copyWith(
        error: 'some error',
        successMessage: 'some success',
      );

      notifier.clearMessages();

      expect(notifier.state.error, isNull);
      expect(notifier.state.successMessage, isNull);
    });
  });
}
