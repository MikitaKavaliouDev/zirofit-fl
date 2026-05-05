import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';
import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import '../helpers/provider_utils.dart';
import '../helpers/response_fixture.dart';

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

  group('Calendar Flow', () {
    test('fetch events → create session → update session → send reminder → delete session',
        () async {
      // -----------------------------------------------------------------------
      // 1. Fetch initial events (empty)
      // -----------------------------------------------------------------------
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 200,
            data: {
              'data': {
                'bookings': [],
                'sessions': [],
              },
            },
          ));

      await container.read(calendarProvider.notifier).fetchEvents(start, end);

      var state = container.read(calendarProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, false);

      // -----------------------------------------------------------------------
      // 2. Create a new session
      // -----------------------------------------------------------------------
      final newSessionData = {
        'name': 'Morning Workout',
        'client_id': 'client-1',
        'start_time': 1704067200000, // 2024-01-01 00:00:00
        'end_time': 1704070800000, // 2024-01-01 01:00:00
      };

      when(() => mockApiClient.post(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 201,
            data: {
              'data': {
                'id': 'session-1',
                'client_id': 'client-1',
                'name': 'Morning Workout',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200000,
              },
            },
          ));

      final createSuccess =
          await container.read(calendarProvider.notifier).createSession(newSessionData);

      expect(createSuccess, isTrue);

      state = container.read(calendarProvider);
      expect(state.events, hasLength(1));
      expect(state.events[0].title, 'Morning Workout');
      expect(state.events[0].status, 'PLANNED');

      // -----------------------------------------------------------------------
      // 3. Update the session
      // -----------------------------------------------------------------------
      final updateData = {
        'name': 'Updated Morning Workout',
        'notes': 'Bring water bottle',
      };

      when(() => mockApiClient.put(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.calendarSession('session-1')),
            statusCode: 200,
            data: {
              'data': {
                'id': 'session-1',
                'client_id': 'client-1',
                'name': 'Updated Morning Workout',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'notes': 'Bring water bottle',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200001,
              },
            },
          ));

      final updateSuccess = await container
          .read(calendarProvider.notifier)
          .updateSession('session-1', updateData);

      expect(updateSuccess, isTrue);

      state = container.read(calendarProvider);
      expect(state.events[0].title, 'Updated Morning Workout');
      expect(state.events[0].notes, 'Bring water bottle');

      // -----------------------------------------------------------------------
      // 4. Send a reminder
      // -----------------------------------------------------------------------
      when(() => mockApiClient.post(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.sessionRemind('session-1')),
            statusCode: 200,
            data: {'data': {'message': 'Reminder sent successfully'}},
          ));

      final reminderSuccess = await container
          .read(calendarProvider.notifier)
          .sendReminder('session-1');

      expect(reminderSuccess, isTrue);

      // -----------------------------------------------------------------------
      // 5. Delete the session
      // -----------------------------------------------------------------------
      when(() => mockApiClient.delete(
            any(),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.calendarSession('session-1')),
            statusCode: 204,
          ));

      final deleteSuccess = await container
          .read(calendarProvider.notifier)
          .deleteSession('session-1');

      expect(deleteSuccess, isTrue);

      state = container.read(calendarProvider);
      expect(state.events, isEmpty);
    });

    test('fetch events with bookings and sessions', () async {
      final start = DateTime(2024, 1, 1);
      final end = DateTime(2024, 1, 31);

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 200,
            data: {
              'data': {
                'bookings': [
                  {
                    'id': 'booking-1',
                    'start_time': 1704067200000,
                    'end_time': 1704070800000,
                    'status': 'CONFIRMED',
                    'trainer_id': 'trainer-1',
                    'client_id': 'client-1',
                    'client_name': 'John Doe',
                    'created_at': 1704067200000,
                    'updated_at': 1704067200000,
                  },
                  {
                    'id': 'booking-2',
                    'start_time': 1704153600000, // 2024-01-02
                    'end_time': 1704157200000,
                    'status': 'PENDING',
                    'trainer_id': 'trainer-1',
                    'client_id': 'client-2',
                    'client_name': 'Jane Smith',
                    'created_at': 1704153600000,
                    'updated_at': 1704153600000,
                  },
                ],
                'sessions': [
                  {
                    'id': 'session-1',
                    'client_id': 'client-3',
                    'name': 'HIIT Training',
                    'start_time': 1704070800000,
                    'end_time': 1704074400000,
                    'status': 'PLANNED',
                    'is_trainer_led': true,
                    'created_at': 1704067200000,
                    'updated_at': 1704067200000,
                  },
                ],
              },
            },
          ));

      await container.read(calendarProvider.notifier).fetchEvents(start, end);

      final state = container.read(calendarProvider);
      expect(state.events, hasLength(3));

      // Verify events are sorted by start time
      expect(state.events[0].id, 'booking-1');
      expect(state.events[1].id, 'session-1');
      expect(state.events[2].id, 'booking-2');

      // Verify event types
      expect(state.events[0].type, 'booking');
      expect(state.events[1].type, 'session');
      expect(state.events[2].type, 'booking');

      // Verify client names
      expect(state.events[0].clientName, 'John Doe');
      expect(state.events[2].clientName, 'Jane Smith');
    });

    test('handles date selection and filtering', () {
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

      // Set initial state with events
      container.read(calendarProvider.notifier).state = CalendarState(
        events: events,
        selectedDate: DateTime(2024, 1, 15),
      );

      var state = container.read(calendarProvider);
      expect(state.selectedDateEvents, hasLength(2));

      // Change selected date
      container.read(calendarProvider.notifier).setSelectedDate(DateTime(2024, 1, 16));

      state = container.read(calendarProvider);
      expect(state.selectedDateEvents, hasLength(1));
      expect(state.selectedDateEvents[0].id, '2');
    });

    test('error handling in create session', () async {
      final sessionData = {
        'name': 'New Session',
        'client_id': 'client-1',
      };

      when(() => mockApiClient.post(
            any(),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
          statusCode: 400,
          data: {'error': {'message': 'Invalid client ID'}},
        ),
      ));

      final result =
          await container.read(calendarProvider.notifier).createSession(sessionData);

      expect(result, isFalse);

      final state = container.read(calendarProvider);
      expect(state.error, isNotNull);
      expect(state.events, isEmpty);
    });

    test('error handling in delete session', () async {
      // First add a session
      when(() => mockApiClient.post(
            any(),
            body: any(named: 'body'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 201,
            data: {
              'data': {
                'id': 'session-1',
                'client_id': 'client-1',
                'name': 'Session',
                'start_time': 1704067200000,
                'end_time': 1704070800000,
                'status': 'PLANNED',
                'is_trainer_led': true,
                'created_at': 1704067200000,
                'updated_at': 1704067200000,
              },
            },
          ));

      await container.read(calendarProvider.notifier).createSession({'name': 'Session'});

      // Try to delete with error
      when(() => mockApiClient.delete(
            any(),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.calendarSession('session-1')),
        response: Response(
          requestOptions: RequestOptions(path: ApiConstants.calendarSession('session-1')),
          statusCode: 404,
          data: {'error': {'message': 'Session not found'}},
        ),
      ));

      final result = await container
          .read(calendarProvider.notifier)
          .deleteSession('session-1');

      expect(result, isFalse);

      final state = container.read(calendarProvider);
      expect(state.error, isNotNull);
      // Session should still be in the list since delete failed
      expect(state.events, hasLength(1));
    });

    // -------------------------------------------------------------------------
    // Response shape verification
    // -------------------------------------------------------------------------

    test('fetchEvents handles empty bookings and sessions', () async {
      // Backend shape: GET /trainer/calendar → {"data": {"bookings": [], "sessions": []}}
      final start = DateTime(2024, 2, 1);
      final end = DateTime(2024, 2, 28);

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 200,
            data: dataResponse({
              'bookings': <dynamic>[],
              'sessions': <dynamic>[],
            }),
          ));

      await container.read(calendarProvider.notifier).fetchEvents(start, end);

      final state = container.read(calendarProvider);
      expect(state.events, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('fetchEvents parses bookings and sessions into CalendarEvents', () async {
      // Backend shape: {"data": {"bookings": [...], "sessions": [...]}}
      final start = DateTime(2024, 3, 1);
      final end = DateTime(2024, 3, 31);

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 200,
            data: dataResponse({
              'bookings': [
                {
                  'id': 'b-cal',
                  'start_time': 1709251200000,
                  'end_time': 1709254800000,
                  'status': 'CONFIRMED',
                  'trainer_id': 'trainer-1',
                  'client_id': 'client-1',
                  'client_name': 'Alice',
                  'created_at': 1709251200000,
                  'updated_at': 1709251200000,
                },
              ],
              'sessions': [
                {
                  'id': 's-cal',
                  'client_id': 'client-2',
                  'name': 'Yoga',
                  'start_time': 1709337600000,
                  'end_time': 1709341200000,
                  'status': 'PLANNED',
                  'is_trainer_led': true,
                  'created_at': 1709251200000,
                  'updated_at': 1709251200000,
                },
              ],
            }),
          ));

      await container.read(calendarProvider.notifier).fetchEvents(start, end);

      final state = container.read(calendarProvider);
      expect(state.events, hasLength(2));

      // Verify booking-derived event
      expect(state.events[0].type, 'booking');
      expect(state.events[0].id, 'b-cal');
      expect(state.events[0].clientName, 'Alice');
      expect(state.events[0].status, 'CONFIRMED');

      // Verify session-derived event
      expect(state.events[1].type, 'session');
      expect(state.events[1].id, 's-cal');
      expect(state.events[1].title, 'Yoga');
      expect(state.events[1].status, 'PLANNED');
    });

    test('fetchEvents handles null notes and optional fields', () async {
      final start = DateTime(2024, 4, 1);
      final end = DateTime(2024, 4, 30);

      when(() => mockApiClient.get(
            any(),
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerCalendar),
            statusCode: 200,
            data: dataResponse({
              'bookings': [
                {
                  'id': 'b-null',
                  'start_time': 1711929600000,
                  'end_time': 1711933200000,
                  'status': 'PENDING',
                  'trainer_id': 'trainer-1',
                  'client_id': null,
                  'client_name': null,
                  'created_at': 1711929600000,
                  'updated_at': 1711929600000,
                },
              ],
              'sessions': <dynamic>[],
            }),
          ));

      await container.read(calendarProvider.notifier).fetchEvents(start, end);

      final state = container.read(calendarProvider);
      expect(state.events, hasLength(1));
      expect(state.events[0].clientName, isNull);
      expect(state.events[0].clientId, isNull);
    });
  });
}
