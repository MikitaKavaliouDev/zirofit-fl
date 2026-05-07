import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
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

  TrainerCustomExercisesNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerCustomExercisesState());

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

  // -- Create custom exercise --

  Future<void> createExercise(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.trainerCustomExercises,
        body: data,
        fromJson: (json) => Exercise.fromJson(json),
      );

      state = state.copyWith(
        exercises: [...state.exercises, response],
        isLoading: false,
      );
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
  return TrainerCustomExercisesNotifier(apiClient: apiClient);
});
