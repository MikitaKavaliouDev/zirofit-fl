import 'dart:collection';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:zirofit_fl/core/services/apple_calendar_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockDeviceCalendarPlugin extends Mock implements DeviceCalendarPlugin {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [Result<T>] with [data] and no errors.
Result<T> successResult<T>(T data) {
  final r = Result<T>();
  r.data = data;
  return r;
}

/// Creates a [Result<T>] with an error.
Result<T> failureResult<T>() {
  final r = Result<T>();
  r.errors.add(const ResultError(1, 'Simulated failure'));
  return r;
}

/// Shorthand for an [UnmodifiableListView] of [Calendar].
UnmodifiableListView<Calendar> calendarList(List<Calendar> calendars) =>
    UnmodifiableListView(calendars);

void main() {
  late MockDeviceCalendarPlugin mockPlugin;
  late SharedPreferences prefs;
  late AppleCalendarService service;

  setUp(() async {
    mockPlugin = MockDeviceCalendarPlugin();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tz.initializeTimeZones();

    service = AppleCalendarService(
      plugin: mockPlugin,
      prefs: prefs,
    );
  });

  group('AppleCalendarService', () {
    // =========================================================================
    // Test 1: Requests calendar permission
    // =========================================================================
    group('requestPermission', () {
      test('returns true when permission is granted', () async {
        when(() => mockPlugin.requestPermissions())
            .thenAnswer((_) async => successResult(true));

        final granted = await service.requestPermission();

        expect(granted, isTrue);
        verify(() => mockPlugin.requestPermissions()).called(1);
      });

      test('returns false when permission is denied', () async {
        when(() => mockPlugin.requestPermissions())
            .thenAnswer((_) async => failureResult<bool>());

        final granted = await service.requestPermission();

        expect(granted, isFalse);
      });

      test('hasPermission delegates to plugin', () async {
        when(() => mockPlugin.hasPermissions())
            .thenAnswer((_) async => successResult(true));

        final ok = await service.hasPermission();

        expect(ok, isTrue);
        verify(() => mockPlugin.hasPermissions()).called(1);
      });
    });

    // =========================================================================
    // Test 2: Creates event with correct data
    // =========================================================================
    group('createEvent', () {
      late DateTime start;
      late DateTime end;

      setUp(() {
        start = DateTime(2026, 5, 15, 10, 0);
        end = DateTime(2026, 5, 15, 11, 0);
      });

      test('creates event and returns event ID', () async {
        when(() => mockPlugin.retrieveCalendars()).thenAnswer(
          (_) async => successResult(
            calendarList([
              Calendar(id: 'cal-1', isReadOnly: false, name: 'Work'),
            ]),
          ),
        );
        when(() => mockPlugin.createOrUpdateEvent(any())).thenAnswer(
          (_) async => successResult('event-abc-123'),
        );

        final eventId = await service.createEvent(
          title: 'Session with Trainer',
          start: start,
          end: end,
          notes: 'Bring water',
          location: 'Gym',
        );

        expect(eventId, isNotNull);
        expect(eventId!.eventId, 'event-abc-123');
        expect(eventId.calendarId, 'cal-1');

        // Verify the event was created with correct data
        final captured = verify(() => mockPlugin.createOrUpdateEvent(
              captureAny(),
            )).captured.single as Event;

        expect(captured.title, 'Session with Trainer');
        expect(captured.start?.millisecondsSinceEpoch,
            start.millisecondsSinceEpoch);
        expect(captured.end?.millisecondsSinceEpoch,
            end.millisecondsSinceEpoch);
        expect(captured.description, 'Bring water');
        expect(captured.location, 'Gym');
        expect(captured.calendarId, 'cal-1');
        expect(captured.availability, Availability.Busy);
      });

      test('returns null when no writable calendars', () async {
        when(() => mockPlugin.retrieveCalendars()).thenAnswer(
          (_) async => successResult(
            calendarList([
              Calendar(id: 'cal-ro', isReadOnly: true), // read-only
            ]),
          ),
        );

        final eventId = await service.createEvent(
          title: 'Test',
          start: start,
          end: end,
        );

        expect(eventId, isNull);
        verifyNever(() => mockPlugin.createOrUpdateEvent(any()));
      });

      test('returns null when plugin returns null', () async {
        when(() => mockPlugin.retrieveCalendars()).thenAnswer(
          (_) async => successResult(
            calendarList([
              Calendar(id: 'cal-1', isReadOnly: false),
            ]),
          ),
        );
        when(() => mockPlugin.createOrUpdateEvent(any()))
            .thenAnswer((_) async => null);

        final eventId = await service.createEvent(
          title: 'Test',
          start: start,
          end: end,
        );

        expect(eventId, isNull);
      });

      test('returns null when plugin result has errors', () async {
        when(() => mockPlugin.retrieveCalendars()).thenAnswer(
          (_) async => successResult(
            calendarList([
              Calendar(id: 'cal-1', isReadOnly: false),
            ]),
          ),
        );
        when(() => mockPlugin.createOrUpdateEvent(any()))
            .thenAnswer((_) async => failureResult<String>());

        final eventId = await service.createEvent(
          title: 'Test',
          start: start,
          end: end,
        );

        expect(eventId, isNull);
      });
    });

    // =========================================================================
    // Test 3: Updates existing event
    // =========================================================================
    group('updateEvent', () {
      test('updates event and returns true', () async {
        when(() => mockPlugin.createOrUpdateEvent(any())).thenAnswer(
          (_) async => successResult('updated-event-id'),
        );

        final ok = await service.updateEvent(
          eventId: 'event-abc',
          calendarId: 'cal-1',
          title: 'Updated Title',
          location: 'New Location',
        );

        expect(ok, isTrue);

        final captured = verify(() => mockPlugin.createOrUpdateEvent(
              captureAny(),
            )).captured.single as Event;

        expect(captured.eventId, 'event-abc');
        expect(captured.calendarId, 'cal-1');
        expect(captured.title, 'Updated Title');
        expect(captured.location, 'New Location');
      });

      test('updates event with new time', () async {
        when(() => mockPlugin.createOrUpdateEvent(any())).thenAnswer(
          (_) async => successResult('event-id'),
        );

        final newStart = DateTime(2026, 6, 1, 14, 0);
        final newEnd = DateTime(2026, 6, 1, 15, 0);

        final ok = await service.updateEvent(
          eventId: 'event-abc',
          calendarId: 'cal-1',
          title: 'Rescheduled',
          start: newStart,
          end: newEnd,
        );

        expect(ok, isTrue);

        final captured = verify(() => mockPlugin.createOrUpdateEvent(
              captureAny(),
            )).captured.single as Event;

        expect(captured.eventId, 'event-abc');
        expect(captured.start?.millisecondsSinceEpoch,
            newStart.millisecondsSinceEpoch);
        expect(captured.end?.millisecondsSinceEpoch,
            newEnd.millisecondsSinceEpoch);
      });

      test('returns false when result has errors', () async {
        when(() => mockPlugin.createOrUpdateEvent(any()))
            .thenAnswer((_) async => failureResult<String>());

        final ok = await service.updateEvent(
          eventId: 'event-abc',
          calendarId: 'cal-1',
        );

        expect(ok, isFalse);
      });

      test('returns false when plugin returns null', () async {
        when(() => mockPlugin.createOrUpdateEvent(any()))
            .thenAnswer((_) async => null);

        final ok = await service.updateEvent(
          eventId: 'event-abc',
          calendarId: 'cal-1',
        );

        expect(ok, isFalse);
      });
    });

    // =========================================================================
    // Test 4: Deletes event on cancellation
    // =========================================================================
    group('deleteEvent', () {
      test('deletes event and returns true', () async {
        when(() => mockPlugin.deleteEvent(any(), any())).thenAnswer(
          (_) async => successResult(true),
        );

        final ok = await service.deleteEvent(
          eventId: 'event-abc',
          calendarId: 'cal-1',
        );

        expect(ok, isTrue);
        verify(() => mockPlugin.deleteEvent('cal-1', 'event-abc')).called(1);
      });

      test('returns false when deletion fails', () async {
        when(() => mockPlugin.deleteEvent(any(), any())).thenAnswer(
          (_) async => failureResult<bool>(),
        );

        final ok = await service.deleteEvent(
          eventId: 'event-abc',
          calendarId: 'cal-1',
        );

        expect(ok, isFalse);
      });
    });

    // =========================================================================
    // Test 5: Toggle state persists
    // =========================================================================
    group('sync toggle persistence', () {
      test('isSyncEnabled returns false by default', () async {
        final enabled = await service.isSyncEnabled();
        expect(enabled, isFalse);
      });

      test('isSyncEnabled returns true after enabling', () async {
        await service.setSyncEnabled(true);
        final enabled = await service.isSyncEnabled();
        expect(enabled, isTrue);
      });

      test('isSyncEnabled returns false after disabling', () async {
        await service.setSyncEnabled(true);
        await service.setSyncEnabled(false);
        final enabled = await service.isSyncEnabled();
        expect(enabled, isFalse);
      });

      test('toggle persists across service instances', () async {
        // Write with one instance
        await service.setSyncEnabled(true);

        // Read from a different instance (shares SharedPreferences mock)
        final service2 = AppleCalendarService(
          plugin: MockDeviceCalendarPlugin(),
          prefs: await SharedPreferences.getInstance(),
        );

        final enabled = await service2.isSyncEnabled();
        expect(enabled, isTrue);
      });
    });

    // =========================================================================
    // Event mapping storage
    // =========================================================================
    group('event mapping', () {
      test('stores and retrieves event mapping', () async {
        await service.storeEventMapping(
          bookingId: 'bkg_001',
          eventId: 'evt_abc',
          calendarId: 'cal_work',
        );

        final mapping = await service.getEventMapping('bkg_001');

        expect(mapping, isNotNull);
        expect(mapping!.eventId, 'evt_abc');
        expect(mapping.calendarId, 'cal_work');
      });

      test('returns null for unknown booking', () async {
        final mapping = await service.getEventMapping('bkg_unknown');
        expect(mapping, isNull);
      });

      test('removes event mapping', () async {
        await service.storeEventMapping(
          bookingId: 'bkg_001',
          eventId: 'evt_abc',
          calendarId: 'cal_work',
        );
        await service.removeEventMapping('bkg_001');

        final mapping = await service.getEventMapping('bkg_001');
        expect(mapping, isNull);
      });

      test('stores multiple mappings independently', () async {
        await service.storeEventMapping(
          bookingId: 'bkg_a',
          eventId: 'evt_a',
          calendarId: 'cal_1',
        );
        await service.storeEventMapping(
          bookingId: 'bkg_b',
          eventId: 'evt_b',
          calendarId: 'cal_2',
        );

        final mappingA = await service.getEventMapping('bkg_a');
        final mappingB = await service.getEventMapping('bkg_b');

        expect(mappingA!.eventId, 'evt_a');
        expect(mappingB!.eventId, 'evt_b');
      });
    });

    // =========================================================================
    // Integration: booking lifecycle with calendar
    // =========================================================================
    group('booking lifecycle integration', () {
      test('full flow: create, update, delete', () async {
        // --- Setup ---
        when(() => mockPlugin.retrieveCalendars()).thenAnswer(
          (_) async => successResult(
            calendarList([Calendar(id: 'cal-main', isReadOnly: false)]),
          ),
        );
        when(() => mockPlugin.createOrUpdateEvent(any())).thenAnswer(
          (_) async => successResult('evt-final'),
        );
        when(() => mockPlugin.deleteEvent(any(), any())).thenAnswer(
          (_) async => successResult(true),
        );

        // --- Create booking + event ---
        final created = await service.createEvent(
          title: 'Personal Training',
          start: DateTime(2026, 5, 20, 9, 0),
          end: DateTime(2026, 5, 20, 10, 0),
        );
        expect(created, isNotNull);
        expect(created!.eventId, 'evt-final');
        expect(created.calendarId, 'cal-main');

        await service.storeEventMapping(
          bookingId: 'bkg_42',
          eventId: created.eventId,
          calendarId: created.calendarId,
        );

        // --- Update event ---
        final updated = await service.updateEvent(
          eventId: created.eventId,
          calendarId: created.calendarId,
          title: 'PT Session (Rescheduled)',
        );
        expect(updated, isTrue);

        // --- Delete on cancellation ---
        final mapping = await service.getEventMapping('bkg_42');
        expect(mapping, isNotNull);

        final deleted = await service.deleteEvent(
          eventId: mapping!.eventId,
          calendarId: mapping.calendarId,
        );
        expect(deleted, isTrue);

        await service.removeEventMapping('bkg_42');

        final afterDelete = await service.getEventMapping('bkg_42');
        expect(afterDelete, isNull);
      });
    });
  });
}
