import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/bookings/providers/working_hours_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeRequestOptions extends Fake implements RequestOptions {}

void main() {
  late MockApiClient mockApiClient;
  late WorkingHoursNotifier notifier;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = WorkingHoursNotifier(apiClient: mockApiClient);
  });

  group('WorkingHoursNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has all 7 days with defaults', () {
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.days, hasLength(7));
      expect(notifier.state.days[0].day, 'Monday');
      expect(notifier.state.days[0].isOpen, true);
      expect(notifier.state.days[0].startTime, '09:00');
      expect(notifier.state.days[0].endTime, '17:00');
      expect(notifier.state.days[6].day, 'Sunday');
      expect(notifier.state.days[6].isOpen, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.successMessage, isNull);
    });

    // ---------------------------------------------------------------------------
    // Test 1: fetch populates all 7 days
    // ---------------------------------------------------------------------------
    test('loadWorkingHours populates all 7 days on success', () async {
      final apiDays = [
        {
          'day': 'Monday',
          'isOpen': true,
          'startTime': '08:00',
          'endTime': '18:00',
        },
        {
          'day': 'Tuesday',
          'isOpen': true,
          'startTime': '08:00',
          'endTime': '18:00',
        },
        {
          'day': 'Wednesday',
          'isOpen': true,
          'startTime': '08:00',
          'endTime': '18:00',
        },
        {
          'day': 'Thursday',
          'isOpen': true,
          'startTime': '08:00',
          'endTime': '18:00',
        },
        {
          'day': 'Friday',
          'isOpen': true,
          'startTime': '08:00',
          'endTime': '16:00',
        },
        {
          'day': 'Saturday',
          'isOpen': false,
          'startTime': '10:00',
          'endTime': '14:00',
        },
        {
          'day': 'Sunday',
          'isOpen': false,
          'startTime': '10:00',
          'endTime': '14:00',
        },
      ];

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAvailability,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': apiDays,
          });

      await notifier.loadWorkingHours();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.days, hasLength(7));
      expect(notifier.state.days[0].startTime, '08:00');
      expect(notifier.state.days[0].endTime, '18:00');
      expect(notifier.state.days[4].endTime, '16:00');
      expect(notifier.state.days[5].isOpen, false);
      expect(notifier.state.error, isNull);
    });

    test('loadWorkingHours keeps defaults on empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAvailability,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => {
            'data': <dynamic>[],
          });

      await notifier.loadWorkingHours();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.days, hasLength(7));
      expect(notifier.state.days[0].startTime, '09:00');
    });

    test('loadWorkingHours keeps defaults on API error', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAvailability,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Network error'));

      await notifier.loadWorkingHours();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.days, hasLength(7));
      expect(notifier.state.days[0].startTime, '09:00');
    });

    // ---------------------------------------------------------------------------
    // Test 2: toggleDay switches between open/closed
    // ---------------------------------------------------------------------------
    test('toggleDay toggles a day between open and closed', () {
      // Monday starts open
      expect(notifier.state.days[0].isOpen, true);

      notifier.toggleDay(0);
      expect(notifier.state.days[0].isOpen, false);

      notifier.toggleDay(0);
      expect(notifier.state.days[0].isOpen, true);
    });

    test('toggleDay does not affect other days', () {
      notifier.toggleDay(0);
      expect(notifier.state.days[0].isOpen, false);
      expect(notifier.state.days[1].isOpen, true);
      expect(notifier.state.days[2].isOpen, true);
    });

    // ---------------------------------------------------------------------------
    // Test 3: save sends complete schedule
    // ---------------------------------------------------------------------------
    test('saveWorkingHours sends all 7 days', () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerAvailability,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        final body = invocation.namedArguments[const Symbol('body')] as List;
        expect(body, hasLength(7));
        expect(body[0]['day'], 'Monday');
        expect(body[0]['isOpen'], true);
        expect(body[0]['startTime'], '09:00');
        expect(body[0]['endTime'], '17:00');
        expect(body[6]['day'], 'Sunday');
        expect(body[6]['isOpen'], false);
        return <String, dynamic>{};
      });

      final result = await notifier.saveWorkingHours();

      expect(result, true);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.successMessage, isNotNull);
    });

    test('saveWorkingHours returns false and sets error on API failure',
        () async {
      when(() => mockApiClient.put<Map<String, dynamic>>(
            ApiConstants.trainerAvailability,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          data: {'message': 'Server error'},
          statusCode: 500,
          requestOptions: RequestOptions(path: ''),
        ),
      ));

      final result = await notifier.saveWorkingHours();

      expect(result, false);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.error, isNotNull);
    });

    test('saveWorkingHours validates start < end time before saving', () async {
      // Set an invalid time (start >= end)
      notifier.updateDayTime(0, startTime: '17:00', endTime: '09:00');

      // Save should fail validation before hitting API
      final result = await notifier.saveWorkingHours();

      expect(result, false);
      expect(notifier.state.isSaving, false);
      expect(notifier.state.error, contains('Start time must be before end time'));
    });

    // ---------------------------------------------------------------------------
    // Test 4: bulk set weekdays works
    // ---------------------------------------------------------------------------
    test('bulkSetWeekdays sets all weekdays to the given values', () {
      // First change some days to have different values
      notifier.updateDayTime(0, startTime: '10:00', endTime: '20:00');
      notifier.updateDayTime(1, startTime: '11:00', endTime: '21:00');

      // Act
      notifier.bulkSetWeekdays();

      // Assert Mon-Fri all at 09:00-17:00 and open
      for (var i = 0; i <= 4; i++) {
        expect(notifier.state.days[i].isOpen, true);
        expect(notifier.state.days[i].startTime, '09:00');
        expect(notifier.state.days[i].endTime, '17:00');
      }
      // Sat-Sun unchanged
      expect(notifier.state.days[5].startTime, '10:00');
      expect(notifier.state.days[6].startTime, '10:00');
    });

    test('bulkSetWeekends sets all weekend days to the given values', () {
      notifier.bulkSetWeekends();

      expect(notifier.state.days[5].isOpen, true);
      expect(notifier.state.days[5].startTime, '10:00');
      expect(notifier.state.days[5].endTime, '14:00');
      expect(notifier.state.days[6].isOpen, true);
      expect(notifier.state.days[6].startTime, '10:00');
      expect(notifier.state.days[6].endTime, '14:00');
      // Weekdays unchanged
      expect(notifier.state.days[0].startTime, '09:00');
    });

    // ---------------------------------------------------------------------------
    // copyFromPreviousDay
    // ---------------------------------------------------------------------------
    test('copyFromPreviousDay copies times from previous day', () {
      // Modify Monday
      notifier.updateDayTime(0, startTime: '07:00', endTime: '15:00');
      notifier.toggleDay(0); // close Monday

      // Copy Tuesday from Monday
      notifier.copyFromPreviousDay(1);

      expect(notifier.state.days[1].isOpen, false);
      expect(notifier.state.days[1].startTime, '07:00');
      expect(notifier.state.days[1].endTime, '15:00');
    });

    test('copyFromPreviousDay does nothing for index 0', () {
      notifier.copyFromPreviousDay(0);
      // No crash, state unchanged
      expect(notifier.state.days[0].startTime, '09:00');
    });

    // ---------------------------------------------------------------------------
    // updateDayTime
    // ---------------------------------------------------------------------------
    test('updateDayTime updates start time only', () {
      notifier.updateDayTime(0, startTime: '10:00');
      expect(notifier.state.days[0].startTime, '10:00');
      expect(notifier.state.days[0].endTime, '17:00');
    });

    test('updateDayTime updates end time only', () {
      notifier.updateDayTime(0, endTime: '18:00');
      expect(notifier.state.days[0].startTime, '09:00');
      expect(notifier.state.days[0].endTime, '18:00');
    });

    // ---------------------------------------------------------------------------
    // validateDay
    // ---------------------------------------------------------------------------
    test('validateDay returns null for valid times', () {
      expect(notifier.validateDay(0), isNull);
    });

    test('validateDay returns error when start >= end', () {
      notifier.updateDayTime(0, startTime: '17:00', endTime: '09:00');
      expect(notifier.validateDay(0), isNotNull);
    });

    test('validateDay returns null for closed days regardless of times', () {
      notifier.updateDayTime(5, startTime: '17:00', endTime: '09:00');
      // Saturday is closed by default - validation should be skipped
      expect(notifier.validateDay(5), isNull);
    });

    // ---------------------------------------------------------------------------
    // clearMessages
    // ---------------------------------------------------------------------------
    test('clearMessages clears error and successMessage', () {
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
