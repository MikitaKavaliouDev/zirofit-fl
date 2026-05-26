import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/data/sync/sync_engine.dart';
import 'package:zirofit_fl/data/sync/sync_models.dart';
import 'package:zirofit_fl/data/sync/sync_provider.dart' show syncEngineProvider;
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerCustomExercisesState {
  final List<Exercise> exercises;
  final bool isLoading;
  final String? error;

  const TrainerCustomExercisesState({
    this.exercises = const [],
    this.isLoading = false,
    this.error,
  });

  TrainerCustomExercisesState copyWith({
    List<Exercise>? exercises,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerCustomExercisesState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerCustomExercisesNotifier
    extends StateNotifier<TrainerCustomExercisesState> {
  final ApiClient _apiClient;
  final SyncEngine _syncEngine;
  final Set<String> _pendingTempIds = {};
  StreamSubscription<SyncUiStatus>? _syncSubscription;

  TrainerCustomExercisesNotifier({
    required ApiClient apiClient,
    required SyncEngine syncEngine,
  })  : _apiClient = apiClient,
        _syncEngine = syncEngine,
        super(const TrainerCustomExercisesState()) {
    _syncSubscription = _syncEngine.statusStream.listen(_onSyncStatusChanged);
  }

  // -- Fetch all custom exercises --

  Future<void> fetchExercises() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get(
        ApiConstants.trainerCustomExercises,
        fromJson: (json) {
          final data = json['data'] as List<dynamic>?;
          if (data == null) return <Exercise>[];
          return data
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

      state = state.copyWith(
        exercises: response,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Create custom exercise (offline-capable) --

  Future<void> createExercise(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Generate a temp ID for offline-first / optimistic UI
    final tempId = const Uuid().v4();
    final now = DateTime.now();

    try {
      final response = await _apiClient.post(
        ApiConstants.trainerCustomExercises,
        body: data,
        fromJson: (json) => Exercise.fromJson(json),
      );

      // Online success – use the server-returned exercise
      state = state.copyWith(
        exercises: [...state.exercises, response],
        isLoading: false,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        // Offline – create locally with temp ID and queue for later sync
        final exercise = Exercise(
          id: tempId,
          name: data['name'] as String? ?? '',
          muscleGroup: data['muscleGroup'] as String?,
          equipment: data['equipment'] as String?,
          category: data['category'] as String?,
          description: data['description'] as String?,
          videoUrl: data['videoUrl'] as String?,
          imageUrl: data['imageUrl'] as String?,
          createdById: data['createdById'] as String?,
          recommendedRestSeconds: data['recommendedRestSeconds'] as int?,
          isUnilateral: data['isUnilateral'] as bool? ?? false,
          createdAt: now,
          updatedAt: now,
        );

        _pendingTempIds.add(tempId);

        // Build the data payload with snake_case keys + temp ID for the server
        final queueData = exercise.toJson();
        queueData.removeWhere((_, v) => v == null);

        await _syncEngine.queueMutation(
          tableName: 'exercises',
          recordId: tempId,
          operation: SyncOperation.create,
          data: queueData,
        );

        state = state.copyWith(
          exercises: [...state.exercises, exercise],
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _extractErrorMessage(e),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Update custom exercise --

  Future<void> updateExercise(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.put(
        '${ApiConstants.trainerCustomExercises}/$id',
        body: data,
        fromJson: (json) => Exercise.fromJson(json),
      );

      final updatedExercises = state.exercises.map((e) {
        return e.id == id ? response : e;
      }).toList();

      state = state.copyWith(
        exercises: updatedExercises,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Delete custom exercise --

  Future<void> deleteExercise(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.trainerCustomExercises}/$id');

      state = state.copyWith(
        exercises: state.exercises.where((e) => e.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Sync reconciliation --

  /// Called when the sync engine emits a new status.
  /// When a full sync completes, silently refresh exercises to pick up
  /// real server-generated IDs for any exercises that were created offline.
  void _onSyncStatusChanged(SyncUiStatus status) {
    if (status == SyncUiStatus.synced && _pendingTempIds.isNotEmpty) {
      _silentRefreshExercises();
    }
  }

  /// Fetches exercises from the API without showing a loading indicator.
  /// Used after sync to replace temp-ID exercises with their server versions.
  Future<void> _silentRefreshExercises() async {
    try {
      final response = await _apiClient.get(
        ApiConstants.trainerCustomExercises,
        fromJson: (json) {
          final data = json['data'] as List<dynamic>?;
          if (data == null) return <Exercise>[];
          return data
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

      state = state.copyWith(exercises: response);
      _pendingTempIds.clear();
    } catch (_) {
      // Silently fail – next sync cycle will trigger another refresh
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }

  // -- Helpers --

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
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return 'Unauthorized. Please log in again.';
          }
          if (error.response?.statusCode == 429) {
            return 'Too many attempts. Please try again later.';
          }
          break;
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final trainerCustomExercisesProvider = StateNotifierProvider<
    TrainerCustomExercisesNotifier, TrainerCustomExercisesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return TrainerCustomExercisesNotifier(
    apiClient: apiClient,
    syncEngine: syncEngine,
  );
});
