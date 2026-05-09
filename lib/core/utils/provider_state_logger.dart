import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/calendar/providers/calendar_provider.dart';
import '../../features/dashboard/providers/trainer_dashboard_provider.dart';
import '../../features/clients/providers/client_list_provider.dart';
import '../../features/workout/providers/workout_history_provider.dart';
import '../../features/notifications/providers/notifications_provider.dart';
import '../../features/bookings/providers/bookings_provider.dart';
import '../../features/programs/providers/programs_provider.dart';
import '../../features/explore/providers/explore_provider.dart';

/// Utility for logging provider states in a format similar to API logging:
///
/// *** PROVIDER ***
/// name: authProvider
/// state: { status: authenticated, user: ..., role: trainer }
/// ...
class ProviderStateLogger {
  ProviderStateLogger._();

  /// Logs all key provider states to the terminal.
  /// Similar format to API request/response logging.
  static void logAllProviders(ProviderContainer container) {
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER STATES ***');
    buffer.writeln('');
    
    buffer.write(logAuthState(container));
    buffer.write(logCalendarState(container));
    buffer.write(logTrainerDashboardState(container));
    buffer.write(logClientListState(container));
    buffer.write(logWorkoutHistoryState(container));
    buffer.write(logNotificationsState(container));
    buffer.write(logBookingsState(container));
    buffer.write(logProgramsState(container));
    buffer.write(logExploreState(container));
    
    buffer.writeln('*** END PROVIDER STATES ***');
    
    debugPrint(buffer.toString());
  }

  /// Logs auth provider state.
  static String logAuthState(ProviderContainer container) {
    final state = container.read(authProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: authProvider');
    buffer.writeln('state: {');
    buffer.writeln('  status: ${state.status.name}');
    buffer.writeln('  isAuthenticated: ${state.isAuthenticated}');
    buffer.writeln('  user: ${state.user != null ? '${state.user!.email} (id: ${state.user!.id})' : 'null'}');
    buffer.writeln('  role: ${state.role ?? 'null'}');
    buffer.writeln('  hasCompletedOnboarding: ${state.hasCompletedOnboarding}');
    buffer.writeln('  isFreeAccessMode: ${state.isFreeAccessMode}');
    buffer.writeln('  tier: ${state.tier ?? 'null'}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs calendar provider state.
  static String logCalendarState(ProviderContainer container) {
    final state = container.read(calendarProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: calendarProvider');
    buffer.writeln('state: {');
    buffer.writeln('  events count: ${state.events.length}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('  selectedDate: ${state.selectedDate.toIso8601String()}');
    if (state.events.isNotEmpty) {
      buffer.writeln('  events: [');
      for (var i = 0; i < state.events.length; i++) {
        final event = state.events[i];
        buffer.writeln('    { title: "${event.title}", type: "${event.type}", start: "${event.startTime.toIso8601String()}" },');
      }
      buffer.writeln('  ]');
    }
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs trainer dashboard provider state.
  static String logTrainerDashboardState(ProviderContainer container) {
    final state = container.read(trainerDashboardProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: trainerDashboardProvider');
    buffer.writeln('state: {');
    buffer.writeln('  status: ${state.status.name}');
    buffer.writeln('  hasError: ${state.hasError}');
    if (state.data != null) {
      buffer.writeln('  data: {');
      buffer.writeln('    stats: {');
      buffer.writeln('      revenue: ${state.data!.stats.revenue}');
      buffer.writeln('      activeClients: ${state.data!.stats.activeClients}');
      buffer.writeln('      todaySessions: ${state.data!.stats.todaySessions}');
      buffer.writeln('      pendingCheckIns: ${state.data!.stats.pendingCheckIns}');
      buffer.writeln('    }');
      buffer.writeln('    upcomingSessions count: ${state.data!.upcomingSessions.length}');
      buffer.writeln('    recentActivity count: ${state.data!.recentActivity.length}');
      buffer.writeln('    activeClients count: ${state.data!.activeClients.length}');
      buffer.writeln('  }');
    } else {
      buffer.writeln('  data: null');
    }
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs client list provider state.
  static String logClientListState(ProviderContainer container) {
    final state = container.read(clientListProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: clientListProvider');
    buffer.writeln('state: {');
    buffer.writeln('  clients count: ${state.clients.length}');
    buffer.writeln('  filteredClients count: ${state.filteredClients.length}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('  searchQuery: "${state.searchQuery}"');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs workout history provider state.
  static String logWorkoutHistoryState(ProviderContainer container) {
    final state = container.read(workoutHistoryProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: workoutHistoryProvider');
    buffer.writeln('state: {');
    buffer.writeln('  sessions count: ${state.sessions.length}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs notifications provider state.
  static String logNotificationsState(ProviderContainer container) {
    final state = container.read(notificationsProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: notificationsProvider');
    buffer.writeln('state: {');
    buffer.writeln('  notifications count: ${state.notifications.length}');
    buffer.writeln('  unreadCount: ${state.unreadCount}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs bookings provider state.
  static String logBookingsState(ProviderContainer container) {
    final state = container.read(bookingsProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: bookingsProvider');
    buffer.writeln('state: {');
    buffer.writeln('  bookings count: ${state.bookings.length}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs programs provider state.
  static String logProgramsState(ProviderContainer container) {
    final state = container.read(programsProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: programsProvider');
    buffer.writeln('state: {');
    buffer.writeln('  programs count: ${state.programs.length}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }

  /// Logs explore provider state.
  static String logExploreState(ProviderContainer container) {
    final state = container.read(exploreProvider);
    final buffer = StringBuffer();
    
    buffer.writeln('*** PROVIDER ***');
    buffer.writeln('name: exploreProvider');
    buffer.writeln('state: {');
    buffer.writeln('  featuredEvents count: ${state.featuredEvents.length}');
    buffer.writeln('  upcomingEvents count: ${state.upcomingEvents.length}');
    buffer.writeln('  isLoading: ${state.isLoading}');
    buffer.writeln('  error: ${state.error ?? 'null'}');
    buffer.writeln('}');
    buffer.writeln('');
    
    return buffer.toString();
  }
}

/// Extension on ProviderContainer to easily log all providers.
extension ProviderContainerLogger on ProviderContainer {
  /// Logs all provider states to the terminal.
  void logProviderStates() {
    ProviderStateLogger.logAllProviders(this);
  }
}