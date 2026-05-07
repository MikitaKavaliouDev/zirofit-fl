import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import '../../helpers/provider_utils.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      apiClientProvider.overrideWithValue(mockApiClient),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('CalendarNotifier', () {
    test('initial state has empty events and current date', () {
      final state = container.read(calendarProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    group('fetchEvents', () {
      test('fetches and combines bookings and sessions', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        when(() => mockApiClient.get<Map<String, dynamic>>(
              any<String>(),
              queryParams: any<Map<String, dynamic>?>(named: 'queryParams'),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{
                'bookings': <dynamic>[
                  <String, dynamic>{
                    'id': 'booking-1',
                    'start_time': 1704067200000, // 2024-01-01 00:00:00
                    'end_time': 1704070800000, // 2024-01-01 01:00:00
                    'status': 'CONFIRMED',
                    'trainer_id': 'trainer-1',
                    'client_id': 'client-1',
                    'client_name': 'John Doe',
                    'created_at': 1704067200000,
                    'updated_at': 1704067200000,
                  },
                ],
                'sessions': <dynamic>[
                  <String, dynamic>{
                    'id': 'session-1',
                    'client_id': 'client-2',
                    'name': 'Morning Workout',
                    'start_time': 1704070800000, // 2024-01-01 01:00:00
                    'end_time': 1704074400000, // 2024-01-01 02:00:00
                    'status': 'PLANNED',
                    'is_trainer_led': true,
                    'created_at': 1704067200000,
                    'updated_at': 1704067200000,
                  },
                ],
              },
            });

        await container.read(calendarProvider.notifier).fetchEvents(start, end);

        final state = container.read(calendarProvider);
        expect(state.events, hasLength(2));
        expect(state.isLoading, false);
        expect(state.error, isNull);

        // Verify events are sorted by start time
        expect(state.events[0].id, 'booking-1');
        expect(state.events[1].id, 'session-1');
      });

      test('handles empty response', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        when(() => mockApiClient.get<Map<String, dynamic>>(
              any<String>(),
              queryParams: any<Map<String, dynamic>?>(named: 'queryParams'),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{
                'bookings': <dynamic>[],
                'sessions': <dynamic>[],
              },
            });

        await container.read(calendarProvider.notifier).fetchEvents(start, end);

        final state = container.read(calendarProvider);
        expect(state.events, isEmpty);
        expect(state.isLoading, false);
      });

      test('handles error response', () async {
        final start = DateTime(2024, 1, 1);
        final end = DateTime(2024, 1, 31);

        when(() => mockApiClient.get<Map<String, dynamic>>(
              any<String>(),
              queryParams: any<Map<String, dynamic>?>(named: 'queryParams'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 500,
            data: {'error': {'message': 'Internal server error'}},
          ),
        ));

        await container.read(calendarProvider.notifier).fetchEvents(start, end);

        final state = container.read(calendarProvider);
        expect(state.events, isEmpty);
        expect(state.isLoading, false);
        expect(state.error, isNotNull);
      });
    });

    group('createSession', () {
      test('creates session and adds to events list', () async {
        final sessionData = {
          'name': 'New Session',
          'client_id': 'client-1',
          'start_time': 1704067200000,
          'end_time': 1704070800000,
        };

        when(() => mockApiClient.post<Map<String, dynamic>>(
              any<String>(),
              body: any<Map<String, dynamic>?>(named: 'body'),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{
                'id': 'session-new',
                'client_id': 'client-1',
                'name': 'New Session',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200000,
              },
            });

        final result =
            await container.read(calendarProvider.notifier).createSession(sessionData);

        expect(result, true);

        final state = container.read(calendarProvider);
        expect(state.events, hasLength(1));
        expect(state.events[0].id, 'session-new');
        expect(state.events[0].title, 'New Session');
        expect(state.isLoading, false);
      });

      test('returns false on error', () async {
        final sessionData = {
          'name': 'New Session',
          'client_id': 'client-1',
        };

        when(() => mockApiClient.post<Map<String, dynamic>>(
              any<String>(),
              body: any<Map<String, dynamic>?>(named: 'body'),
            )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
          response: Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 400,
            data: {'error': {'message': 'Invalid data'}},
          ),
        ));

        final result =
            await container.read(calendarProvider.notifier).createSession(sessionData);

        expect(result, false);

        final state = container.read(calendarProvider);
        expect(state.events, isEmpty);
        expect(state.error, isNotNull);
      });
    });

    group('updateSession', () {
      test('updates session in events list', () async {
        // First add a session
        when(() => mockApiClient.post<Map<String, dynamic>>(
              any<String>(),
              body: any<Map<String, dynamic>?>(named: 'body'),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{
                'id': 'session-1',
                'client_id': 'client-1',
                'name': 'Original Name',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200000,
              },
            });

        await container
            .read(calendarProvider.notifier)
            .createSession({'name': 'Original Name'});

        // Now update it
        when(() => mockApiClient.put<Map<String, dynamic>>(
              any<String>(),
              body: any<Map<String, dynamic>?>(named: 'body'),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{
                'id': 'session-1',
                'client_id': 'client-1',
                'name': 'Updated Name',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200001,
              },
            });

        final result = await container
            .read(calendarProvider.notifier)
            .updateSession('session-1', {'name': 'Updated Name'});

        expect(result, true);

        final state = container.read(calendarProvider);
        expect(state.events[0].title, 'Updated Name');
      });
    });

    group('deleteSession', () {
      test('removes session from events list', () async {
        // First add a session
        when(() => mockApiClient.post<Map<String, dynamic>>(
              any<String>(),
              body: any<Map<String, dynamic>?>(named: 'body'),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{
                'id': 'session-1',
                'client_id': 'client-1',
                'name': 'Session to Delete',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200000,
              },
            });

        await container
            .read(calendarProvider.notifier)
            .createSession({'name': 'Session to Delete'});

        expect(container.read(calendarProvider).events, hasLength(1));

        // Now delete it
        when(() => mockApiClient.delete(
              any(),
            )).thenAnswer((_) async {});

        final result = await container
            .read(calendarProvider.notifier)
            .deleteSession('session-1');

        expect(result, true);

        final state = container.read(calendarProvider);
        expect(state.events, isEmpty);
      });
    });

    group('sendReminder', () {
      test('sends reminder successfully', () async {
        when(() => mockApiClient.post(
              any<String>(),
            )).thenAnswer((_) async => <String, dynamic>{
              'data': <String, dynamic>{'message': 'Reminder sent'},
            });

        final result = await container
            .read(calendarProvider.notifier)
            .sendReminder('session-1');

        expect(result, true);
      });

      test('returns false on error', () async {
        when(() => mockApiClient.post(
              any<String>(),
            )).thenThrow(DioException(
          requestOptions:
              RequestOptions(path: ApiConstants.sessionRemind('session-1')),
          response: Response(
            requestOptions:
                RequestOptions(path: ApiConstants.sessionRemind('session-1')),
            statusCode: 404,
            data: {'error': {'message': 'Session not found'}},
          ),
        ));

        final result = await container
            .read(calendarProvider.notifier)
            .sendReminder('session-1');

        expect(result, false);
      });
    });

    group('setSelectedDate', () {
      test('updates selected date', () {
        final newDate = DateTime(2024, 6, 15);
        container.read(calendarProvider.notifier).setSelectedDate(newDate);

        final state = container.read(calendarProvider);
        expect(state.selectedDate, newDate);
      });
    });

    group('CalendarState', () {
      test('getEventsForDate returns events for specific date', () {
        final events = [
          CalendarEvent(
            id: '1',
            title: 'Event 1',
            startTime: DateTime(2024, 1, 15, 9, 0),
            endTime: DateTime(2024, 1, 15, 10, 0),
            type: 'session',
            status: 'PLANNED',
          ),
          CalendarEvent(
            id: '2',
            title: 'Event 2',
            startTime: DateTime(2024, 1, 16, 9, 0),
            endTime: DateTime(2024, 1, 16, 10, 0),
            type: 'booking',
            status: 'CONFIRMED',
          ),
          CalendarEvent(
            id: '3',
            title: 'Event 3',
            startTime: DateTime(2024, 1, 15, 14, 0),
            endTime: DateTime(2024, 1, 15, 15, 0),
            type: 'session',
            status: 'PLANNED',
          ),
        ];

        final state = CalendarState(events: events);

        final jan15Events = state.getEventsForDate(DateTime(2024, 1, 15));
        expect(jan15Events, hasLength(2));
        expect(jan15Events.map((e) => e.id), containsAll(['1', '3']));

        final jan16Events = state.getEventsForDate(DateTime(2024, 1, 16));
        expect(jan16Events, hasLength(1));
        expect(jan16Events[0].id, '2');

        final jan17Events = state.getEventsForDate(DateTime(2024, 1, 17));
        expect(jan17Events, isEmpty);
      });

      test('selectedDateEvents returns events for selected date', () {
        final selectedDate = DateTime(2024, 1, 15);
        final events = [
          CalendarEvent(
            id: '1',
            title: 'Event 1',
            startTime: DateTime(2024, 1, 15, 9, 0),
            endTime: DateTime(2024, 1, 15, 10, 0),
            type: 'session',
            status: 'PLANNED',
          ),
          CalendarEvent(
            id: '2',
            title: 'Event 2',
            startTime: DateTime(2024, 1, 16, 9, 0),
            endTime: DateTime(2024, 1, 16, 10, 0),
            type: 'booking',
            status: 'CONFIRMED',
          ),
        ];

        final state = CalendarState(
          events: events,
          selectedDate: selectedDate,
        );

        expect(state.selectedDateEvents, hasLength(1));
        expect(state.selectedDateEvents[0].id, '1');
      });
    });
  });
}
