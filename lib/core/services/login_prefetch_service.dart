import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/features/calendar/providers/calendar_provider.dart';
import 'package:zirofit_fl/features/clients/providers/client_list_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/client_dashboard_provider.dart';
import 'package:zirofit_fl/features/dashboard/providers/trainer_dashboard_provider.dart';
import 'package:zirofit_fl/features/exercises/providers/exercise_provider.dart';
import 'package:zirofit_fl/features/programs/providers/client_programs_provider.dart';
import 'package:zirofit_fl/features/programs/providers/programs_provider.dart';
import 'package:zirofit_fl/features/progress/providers/analytics_provider.dart';
import 'package:zirofit_fl/features/workout/providers/workout_history_provider.dart';

/// Background data prefetch service triggered on successful login.
///
/// Mirrors the iOS prefetch strategy: after authentication completes, fire
/// background requests for the datasets the user is most likely to visit
/// first (dashboard, clients, programs, etc.) so that screens render
/// instantly without spinners.
///
/// All prefetches are:
///   - Fire-and-forget (no await on the top-level call)
///   - Run in parallel via [Future.wait]
///   - Individually wrapped in try/catch so a single failure never blocks
///     other prefetches or the login flow.
class LoginPrefetchService {
  /// Entry point — fire and forget.
  ///
  /// Call this after authentication state changes to authenticated:
  /// ```dart
  /// LoginPrefetchService.prefetch(container, role);
  /// ```
  static void prefetch(ProviderContainer container, String role) {
    unawaited(_prefetchInternal(container, role));
  }

  /// Internal async implementation that runs all prefetches in parallel.
  static Future<void> _prefetchInternal(
    ProviderContainer container,
    String role,
  ) async {
    debugPrint('LOGIN_PREFETCH: starting for role=$role');

    if (role == 'trainer') {
      await Future.wait([
        _safeCall(
          'trainerDashboard',
          () => container.read(trainerDashboardProvider.notifier).fetchDashboard(),
        ),
        _safeCall(
          'clientList',
          () => container.read(clientListProvider.notifier).fetchClients(),
        ),
        _safeCall(
          'programsAndTemplates',
          () => container.read(programsProvider.notifier).fetchProgramsAndTemplates(),
        ),
        _safeCall(
          'calendar',
          () => _prefetchCalendar(container),
        ),
      ]);
    } else if (role == 'client') {
      await Future.wait([
        _safeCall(
          'clientDashboard',
          () => container.read(clientDashboardProvider.notifier).refresh(),
        ),
        _safeCall(
          'clientPrograms',
          () => container.read(clientProgramsProvider.notifier).fetchPrograms(),
        ),
        _safeCall(
          'analytics',
          () => container.read(analyticsProvider.notifier).loadAnalytics(days: 30),
        ),
        _safeCall(
          'workoutHistory',
          () => container.read(workoutHistoryProvider.notifier).fetchHistory(),
        ),
        _safeCall(
          'exercises',
          () => container.read(exerciseListProvider.notifier).fetchExercises(),
        ),
      ]);
    }

    debugPrint('LOGIN_PREFETCH: complete for role=$role');
  }

  /// Fetches calendar events for the next 5 months.
  static Future<void> _prefetchCalendar(ProviderContainer container) async {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 5, now.day);
    await container.read(calendarProvider.notifier).fetchEvents(now, end);
  }

  /// Runs [call] and catches any exception so that a single failed prefetch
  /// never blocks other prefetches or the login flow.
  static Future<void> _safeCall(
    String label,
    Future<void> Function() call,
  ) async {
    try {
      await call();
    } catch (e, st) {
      debugPrint('LOGIN_PREFETCH_ERROR [$label]: $e\n$st');
    }
  }
}
