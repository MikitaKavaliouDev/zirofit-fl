import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';
import 'package:zirofit_fl/features/workout/data/workout_remote_source.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';

class MockWorkoutRemoteSource extends Mock implements WorkoutRemoteSource {}

void main() {
  late MockWorkoutRemoteSource mockRemoteSource;
  late WorkoutHistoryNotifier notifier;

  setUp(() {
    mockRemoteSource = MockWorkoutRemoteSource();
    notifier = WorkoutHistoryNotifier(remoteSource: mockRemoteSource);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  WorkoutSession createSession({String id = 'session-1'}) {
    return WorkoutSession(
      id: id,
      clientId: 'client-1',
      startTime: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  group('WorkoutHistoryNotifier', () {
    test('initial state: searchQuery empty, dateRange null', () {
      final state = notifier.state;
      expect(state.searchQuery, '');
      expect(state.dateRange, isNull);
      expect(state.filteredSessions, isEmpty);
    });

    test('initial state: sessions empty, isLoading=false, hasMore=true', () {
      final state = notifier.state;
      expect(state.sessions, isEmpty);
      expect(state.isLoading, false);
      expect(state.isLoadingMore, false);
      expect(state.hasMore, true);
      expect(state.error, isNull);
      expect(state.cursor, isNull);
    });

    group('fetchHistory', () {
      test('populates sessions on success', () async {
        final sessions = [
          createSession(),
          createSession(id: 'session-2'),
        ];
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: sessions,
              hasMore: true,
            ));

        final future = notifier.fetchHistory();
        // Intermediate loading state
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.sessions.length, 2);
        expect(state.sessions[0].id, 'session-1');
        expect(state.sessions[1].id, 'session-2');
        expect(state.hasMore, true);
        expect(state.error, isNull);
        // Cursor should be last session's id
        expect(state.cursor, 'session-2');
      });

      test('sets error on failure', () async {
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('Failed to load history'));

        await notifier.fetchHistory();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.sessions, isEmpty);
        expect(state.error, contains('Failed to load history'));
      });

      test('sets cursor to null when sessions are empty', () async {
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: <WorkoutSession>[],
              hasMore: false,
            ));

        await notifier.fetchHistory();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.sessions, isEmpty);
        expect(state.hasMore, false);
        expect(state.cursor, isNull);
      });
    });

    group('fetchMore', () {
      test('appends sessions when hasMore is true', () async {
        // Set up first page
        final page1 = [createSession()];
        when(() => mockRemoteSource.getHistory(
              cursor: null,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: page1,
              hasMore: true,
            ));

        await notifier.fetchHistory();
        expect(notifier.state.sessions.length, 1);

        // Set up second page
        final page2 = [createSession(id: 'session-2')];
        when(() => mockRemoteSource.getHistory(
              cursor: 'session-1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: page2,
              hasMore: false,
            ));

        final future = notifier.fetchMore();
        // Intermediate loading more state
        expect(notifier.state.isLoadingMore, true);

        await future;

        final state = notifier.state;
        expect(state.isLoadingMore, false);
        expect(state.sessions.length, 2);
        expect(state.sessions[0].id, 'session-1');
        expect(state.sessions[1].id, 'session-2');
        expect(state.hasMore, false);
      });

      test('does nothing when isLoadingMore', () async {
        // Load initial page with hasMore=true
        when(() => mockRemoteSource.getHistory(
              cursor: null,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: [createSession()],
              hasMore: true,
            ));

        await notifier.fetchHistory();
        expect(notifier.state.hasMore, true);
        expect(notifier.state.cursor, 'session-1');

        // Make the next getHistory call (for fetchMore) hang
        final completer = Completer<
            ({List<WorkoutSession> sessions, bool hasMore})>();
        when(() => mockRemoteSource.getHistory(
              cursor: 'session-1',
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => completer.future);

        // Start first fetchMore — isLoadingMore becomes true synchronously
        final firstCall = notifier.fetchMore();
        expect(notifier.state.isLoadingMore, true);

        // Second call should be a no-op (isLoadingMore is true)
        await notifier.fetchMore();

        // Complete the first call
        completer.complete((
          sessions: [createSession(id: 'session-2')],
          hasMore: false,
        ));
        await firstCall;

        // Only 2 sessions — second fetchMore was a no-op
        expect(notifier.state.sessions.length, 2);
        verify(() => mockRemoteSource.getHistory(
              cursor: 'session-1',
              limit: any(named: 'limit'),
            )).called(1);
      });

      test('does nothing when hasMore is false', () async {
        // Load with hasMore=false
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: [createSession()],
              hasMore: false,
            ));

        await notifier.fetchHistory();
        expect(notifier.state.hasMore, false);

        // fetchMore should be a no-op since hasMore is false
        await notifier.fetchMore();

        // Verify getHistory was only called once (during fetchHistory)
        verify(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).called(1);
      });
    });

    group('refresh', () {
      test('resets and re-fetches', () async {
        // First load: 2 sessions
        final initialSessions = [
          createSession(id: 'old-1'),
          createSession(id: 'old-2'),
        ];
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: initialSessions,
              hasMore: false,
            ));

        await notifier.fetchHistory();
        expect(notifier.state.sessions.length, 2);

        // Re-mock for refresh
        final refreshedSessions = [
          createSession(id: 'new-1'),
          createSession(id: 'new-2'),
          createSession(id: 'new-3'),
        ];
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: refreshedSessions,
              hasMore: true,
            ));

        final future = notifier.refresh();
        // Verify state is reset to loading
        expect(notifier.state.isLoading, true);

        await future;

        final state = notifier.state;
        expect(state.isLoading, false);
        // Should be replaced, not appended
        expect(state.sessions.length, 3);
        expect(state.sessions[0].id, 'new-1');
        expect(state.sessions[1].id, 'new-2');
        expect(state.sessions[2].id, 'new-3');
        expect(state.hasMore, true);
        expect(state.cursor, 'new-3');
      });

      test('sets error on failure', () async {
        // Put some existing data in
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => (
              sessions: [createSession()],
              hasMore: false,
            ));
        await notifier.fetchHistory();

        // Make refresh fail
        when(() => mockRemoteSource.getHistory(
              cursor: any(named: 'cursor'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('Refresh failed'));

        await notifier.refresh();

        final state = notifier.state;
        expect(state.isLoading, false);
        expect(state.sessions, isEmpty);
        expect(state.error, contains('Refresh failed'));
      });
    });

    // -------------------------------------------------------------------------
    // Search & Filter
    // -------------------------------------------------------------------------

    group('search & filter', () {
      // Sessions used across search/filter tests
      final now = DateTime.now();
      final sessions = [
        WorkoutSession(
          id: 's1',
          clientId: 'c1',
          name: 'Upper Body',
          notes: 'Felt strong today',
          startTime: now.subtract(const Duration(days: 1)),
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: 's2',
          clientId: 'c1',
          name: 'Leg Day',
          notes: 'Squats and deadlifts',
          startTime: now.subtract(const Duration(days: 5)),
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: 's3',
          clientId: 'c1',
          name: 'Push Day',
          notes: 'Bench press focus',
          startTime: now.subtract(const Duration(days: 15)),
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: 's4',
          clientId: 'c1',
          name: 'Pull Day',
          notes: 'Rows and pull-ups',
          startTime: now.subtract(const Duration(days: 45)),
          createdAt: now,
          updatedAt: now,
        ),
        WorkoutSession(
          id: 's5',
          clientId: 'c1',
          name: 'Cardio',
          notes: 'Treadmill intervals',
          startTime: now.subtract(const Duration(days: 100)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      setUp(() {
        // Manually set state with the test sessions and no filters
        notifier = WorkoutHistoryNotifier(remoteSource: mockRemoteSource)
          ..state = WorkoutHistoryState(
            sessions: sessions,
            hasMore: false,
          );
      });

      test('setSearchQuery filters by session name', () {
        notifier.setSearchQuery('Upper');
        expect(notifier.state.filteredSessions.length, 1);
        expect(notifier.state.filteredSessions.first.name, 'Upper Body');
      });

      test('setSearchQuery filters by notes', () {
        notifier.setSearchQuery('squats');
        expect(notifier.state.filteredSessions.length, 1);
        expect(notifier.state.filteredSessions.first.name, 'Leg Day');
      });

      test('setSearchQuery is case-insensitive', () {
        notifier.setSearchQuery('upper');
        expect(notifier.state.filteredSessions.length, 1);
        expect(notifier.state.filteredSessions.first.name, 'Upper Body');
      });

      test('setSearchQuery matches multiple sessions in name and notes', () {
        notifier.setSearchQuery('day');
        // Matches: "Leg Day", "Push Day", "Pull Day" (name),
        // and "Felt strong today" (notes of Upper Body)
        expect(notifier.state.filteredSessions.length, 4);
      });

      test('clear search restores full list', () {
        notifier.setSearchQuery('Upper');
        expect(notifier.state.filteredSessions.length, 1);

        notifier.setSearchQuery('');
        expect(notifier.state.filteredSessions.length, sessions.length);
      });

      test('setDateRange filters by last 7 days', () {
        notifier.setDateRange(DateRange.last7Days());
        expect(notifier.state.filteredSessions.length, 2);
      });

      test('setDateRange filters by last 30 days', () {
        notifier.setDateRange(DateRange.last30Days());
        expect(notifier.state.filteredSessions.length, 3);
      });

      test('setDateRange filters by last 3 months', () {
        notifier.setDateRange(DateRange.last3Months());
        expect(notifier.state.filteredSessions.length, 4);
      });

      test('clearing dateRange restores full list', () {
        notifier.setDateRange(DateRange.last7Days());
        expect(notifier.state.filteredSessions.length, 2);

        notifier.setDateRange(null);
        expect(notifier.state.filteredSessions.length, sessions.length);
      });

      test('combined search + date filter', () {
        notifier.setSearchQuery('day');
        notifier.setDateRange(DateRange.last30Days());
        // Within last 30 days: "Leg Day" (day 5), "Push Day" (day 15),
        // and "Upper Body" notes "Felt strong today" (day 1)
        expect(notifier.state.filteredSessions.length, 3);
      });

      test('combined filter returns empty when no match', () {
        notifier.setSearchQuery('Upper');
        notifier.setDateRange(DateRange.last3Months());
        // "Upper Body" is within 3 months, so 1 result
        expect(notifier.state.filteredSessions.length, 1);

        // Now narrow further
        notifier.setDateRange(DateRange.last7Days());
        // "Upper Body" is 1 day old, still within 7 days
        notifier.setSearchQuery('nonexistent');
        expect(notifier.state.filteredSessions, isEmpty);
      });

      test('filteredSessions is empty when no sessions match date range', () {
        notifier.setDateRange(DateRange(
          start: now.subtract(const Duration(days: 200)),
          end: now.subtract(const Duration(days: 150)),
          preset: DateRangePreset.custom,
        ));
        // Session 5 is at day 100, which is before day 150-200 range
        // Actually session 5 is at day 100, which is after day 150-200
        // Let me recalculate: day 100 = 100 days ago. Range: 200-150 days ago
        // Session 5: 100 days ago - NOT in range (100 > 150 = later)
        // Session 4: 45 days ago - NOT in range
        // All sessions are too recent for this range
        expect(notifier.state.filteredSessions, isEmpty);
      });

      test('setSearchQuery persists in state', () {
        notifier.setSearchQuery('Leg Day');
        expect(notifier.state.searchQuery, 'Leg Day');
      });

      test('setDateRange persists in state', () {
        final range = DateRange.last30Days();
        notifier.setDateRange(range);
        expect(notifier.state.dateRange, range);
      });
    });
  });
}
