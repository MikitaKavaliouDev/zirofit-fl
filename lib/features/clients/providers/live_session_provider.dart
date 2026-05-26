import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_exercise_log.dart';
import 'package:zirofit_fl/data/models/workout_session.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class LiveSessionState {
  final WorkoutSession? session;
  final List<ClientExerciseLog> exerciseLogs;
  final bool isLoading;
  final bool isPolling;
  final String? error;
  final DateTime? lastUpdated;

  const LiveSessionState({
    this.session,
    this.exerciseLogs = const [],
    this.isLoading = false,
    this.isPolling = false,
    this.error,
    this.lastUpdated,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveSessionState &&
          session == other.session &&
          listEquals(exerciseLogs, other.exerciseLogs) &&
          isLoading == other.isLoading &&
          isPolling == other.isPolling &&
          error == other.error &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(
        session,
        Object.hashAll(exerciseLogs),
        isLoading,
        isPolling,
        error,
        lastUpdated,
      );

  LiveSessionState copyWith({
    WorkoutSession? session,
    List<ClientExerciseLog>? exerciseLogs,
    bool? isLoading,
    bool? isPolling,
    String? error,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return LiveSessionState(
      session: session ?? this.session,
      exerciseLogs: exerciseLogs ?? this.exerciseLogs,
      isLoading: isLoading ?? this.isLoading,
      isPolling: isPolling ?? this.isPolling,
      error: clearError ? null : (error ?? this.error),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Polls [ApiConstants.clientActiveSession] every 15 seconds to monitor a
/// client's active workout in real time.
class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  final ApiClient _apiClient;
  Timer? _pollTimer;
  String? _currentClientId;

  LiveSessionNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const LiveSessionState());

  /// Starts polling for the given [clientId]'s active session.
  /// Does nothing if already polling for the same client.
  void startPolling(String clientId) {
    if (_currentClientId == clientId && state.isPolling) return;

    stopPolling();
    _currentClientId = clientId;
    _fetchSession();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchSession(),
    );
    state = state.copyWith(isPolling: true);
  }

  /// Stops the polling timer and resets polling state.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _currentClientId = null;
    if (state.isPolling) {
      state = state.copyWith(isPolling: false);
    }
  }

  /// Manual one-time refresh.
  Future<void> refresh() async {
    if (_currentClientId == null) return;
    await _fetchSession();
  }

  Future<void> _fetchSession() async {
    if (_currentClientId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.clientActiveSession(_currentClientId!),
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final sessionMap = data['session'] as Map<String, dynamic>?;

      if (sessionMap == null) {
        // No active session – stop polling and clear data
        state = state.copyWith(
          session: null,
          exerciseLogs: [],
          isLoading: false,
          isPolling: false,
          lastUpdated: DateTime.now(),
        );
        _pollTimer?.cancel();
        _pollTimer = null;
        return;
      }

      final session = WorkoutSession.fromJson(sessionMap);

      final sessionClientId =
          (sessionMap['client'] as Map<String, dynamic>?)?['id'] as String?;

      final logsList = (data['exerciseLogs'] as List<dynamic>?)
              ?.map((e) {
                final logJson = e as Map<String, dynamic>;
                final exerciseMap =
                    logJson['exercise'] as Map<String, dynamic>?;
                final exerciseName = exerciseMap?['name'] as String?;
                final exerciseId = exerciseMap?['id'] as String?;
                return ClientExerciseLog.fromJson(
                  {
                    ...logJson,
                    'exerciseId': ?exerciseId,
                    'exerciseName': ?exerciseName,
                  },
                  sessionClientId: sessionClientId,
                  workoutSessionId: session.id,
                );
              }).toList() ??
          [];

      state = state.copyWith(
        session: session,
        exerciseLogs: logsList,
        isLoading: false,
        error: null,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final errorData = error.response!.data as Map;
        if (errorData['error'] is Map) {
          return (errorData['error'] as Map)['message'] as String? ??
              'An error occurred';
        }
        if (errorData['message'] is String) {
          return errorData['message'] as String;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please try again.';
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network.';
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final liveSessionProvider =
    StateNotifierProvider<LiveSessionNotifier, LiveSessionState>((ref) {
  final apiClient = ApiClient.instance;
  return LiveSessionNotifier(apiClient: apiClient);
});
