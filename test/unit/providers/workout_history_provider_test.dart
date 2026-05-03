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
  });
}
