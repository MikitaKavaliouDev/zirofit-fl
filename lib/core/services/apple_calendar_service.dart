import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart';

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final appleCalendarServiceProvider = Provider<AppleCalendarService>((ref) {
  return AppleCalendarService();
});

// ---------------------------------------------------------------------------
// Apple Calendar Service
// ---------------------------------------------------------------------------

/// Service for syncing bookings with Apple Calendar via EKEvent.
///
/// Uses the [device_calendar] plugin to create, update, and delete calendar
/// events.  Also persists two kinds of data in [SharedPreferences]:
///
///   * **Event mapping** – each booking ID → (calendar event ID, calendar ID)
///   * **Sync toggle** – whether the user wants calendar sync enabled by
///     default.
class AppleCalendarService {
  AppleCalendarService({
    DeviceCalendarPlugin? plugin,
    SharedPreferences? prefs,
  })  : _plugin = plugin ?? DeviceCalendarPlugin(),
        _prefs = prefs;

  final DeviceCalendarPlugin _plugin;
  SharedPreferences? _prefs;

  static const _eventPrefix = 'apple_calendar_event_';
  static const _toggleKey = 'apple_calendar_sync_enabled';

  // ---------------------------------------------------------------------------
  // SharedPreferences (lazy init)
  // ---------------------------------------------------------------------------

  Future<SharedPreferences> get _sharedPrefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ---------------------------------------------------------------------------
  // Permissions
  // ---------------------------------------------------------------------------

  /// Requests calendar read/write permission.
  /// Returns `true` when granted.
  Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess;
  }

  /// Returns `true` if calendar permission has already been granted.
  Future<bool> hasPermission() async {
    final result = await _plugin.hasPermissions();
    return result.isSuccess;
  }

  // ---------------------------------------------------------------------------
  // CRUD — events
  // ---------------------------------------------------------------------------

  /// Creates a calendar event.
  ///
  /// Returns a record with the platform [eventId] and the [calendarId] it was
  /// created in, or `null` on failure.  The caller should pass both values to
  /// [storeEventMapping] so the event can be updated / deleted later.
  Future<({String eventId, String calendarId})?> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? notes,
    String? location,
  }) async {
    final calendarId = await _resolveWritableCalendarId();
    if (calendarId == null) return null;

    _ensureTimezones();
    final tzStart = TZDateTime.from(start, local);
    final tzEnd = TZDateTime.from(end, local);

    final event = Event(
      calendarId,
      title: title,
      start: tzStart,
      end: tzEnd,
      description: notes,
      location: location,
      availability: Availability.Busy,
    );

    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null || !result.isSuccess) return null;
    final eventId = result.data;
    if (eventId == null || eventId.isEmpty) return null;
    return (eventId: eventId, calendarId: calendarId);
  }

  /// Updates an existing calendar event.
  /// Requires the [eventId] and [calendarId] that were returned when the
  /// event was created.
  Future<bool> updateEvent({
    required String eventId,
    required String calendarId,
    String? title,
    DateTime? start,
    DateTime? end,
    String? notes,
    String? location,
  }) async {
    _ensureTimezones();
    final tzStart = start != null ? TZDateTime.from(start, local) : null;
    final tzEnd = end != null ? TZDateTime.from(end, local) : null;

    final event = Event(
      calendarId,
      eventId: eventId,
      title: title,
      start: tzStart,
      end: tzEnd,
      description: notes,
      location: location,
      availability: Availability.Busy,
    );

    final result = await _plugin.createOrUpdateEvent(event);
    return result?.isSuccess ?? false;
  }

  /// Deletes a calendar event.
  Future<bool> deleteEvent({
    required String eventId,
    required String calendarId,
  }) async {
    final result = await _plugin.deleteEvent(calendarId, eventId);
    return result.isSuccess;
  }

  // ---------------------------------------------------------------------------
  // Booking ↔ Event mapping
  // ---------------------------------------------------------------------------

  /// Stores the association between a [bookingId] and its calendar
  /// [eventId] / [calendarId].
  Future<void> storeEventMapping({
    required String bookingId,
    required String eventId,
    required String calendarId,
  }) async {
    final prefs = await _sharedPrefs;
    await prefs.setString('${_eventPrefix}${bookingId}_event', eventId);
    await prefs.setString('${_eventPrefix}${bookingId}_calendar', calendarId);
  }

  /// Returns the stored mapping for [bookingId], or `null`.
  Future<({String eventId, String calendarId})?> getEventMapping(
    String bookingId,
  ) async {
    final prefs = await _sharedPrefs;
    final eventId = prefs.getString('${_eventPrefix}${bookingId}_event');
    final calendarId = prefs.getString('${_eventPrefix}${bookingId}_calendar');
    if (eventId == null || calendarId == null) return null;
    return (eventId: eventId, calendarId: calendarId);
  }

  /// Removes the stored mapping for [bookingId].
  Future<void> removeEventMapping(String bookingId) async {
    final prefs = await _sharedPrefs;
    await prefs.remove('${_eventPrefix}${bookingId}_event');
    await prefs.remove('${_eventPrefix}${bookingId}_calendar');
  }

  // ---------------------------------------------------------------------------
  // Sync toggle persistence
  // ---------------------------------------------------------------------------

  /// Returns `true` if the user has previously opted into calendar sync.
  Future<bool> isSyncEnabled() async {
    final prefs = await _sharedPrefs;
    return prefs.getBool(_toggleKey) ?? false;
  }

  /// Persists the user's calendar sync preference.
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await _sharedPrefs;
    await prefs.setBool(_toggleKey, enabled);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Finds the first writable calendar on the device.
  /// Returns its ID, or `null` if none is available.
  Future<String?> _resolveWritableCalendarId() async {
    final result = await _plugin.retrieveCalendars();
    if (!result.isSuccess || result.data == null) return null;

    final writable = result.data!
        .where((c) => c.isReadOnly == false && c.id != null)
        .toList();
    if (writable.isEmpty) return null;

    return writable.first.id;
  }

  /// Ensures the timezone database is initialized (idempotent).
  static bool _timezonesInitialized = false;

  void _ensureTimezones() {
    if (!_timezonesInitialized) {
      _timezonesInitialized = true;
      tz.initializeTimeZones();
    }
  }
}
