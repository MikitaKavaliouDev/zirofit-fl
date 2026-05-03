import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProgramsState {
  final List<WorkoutProgram> programs;
  final bool isLoading;
  final String? error;

  const ProgramsState({
    this.programs = const [],
    this.isLoading = false,
    this.error,
  });

  ProgramsState copyWith({
    List<WorkoutProgram>? programs,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProgramsState(
      programs: programs ?? this.programs,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProgramsNotifier extends StateNotifier<ProgramsState> {
  final ApiClient _api;

  ProgramsNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const ProgramsState());

  /// Fetches all programs for the trainer.
  Future<void> fetchPrograms() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
      );

      final List<WorkoutProgram> programs;
      final rawData = response['data'];
      if (rawData is List) {
        programs = rawData
            .map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        programs = [];
      }

      state = ProgramsState(programs: programs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a new program with [name] and optional [description].
  Future<WorkoutProgram?> createProgram(
    String name,
    String? description,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final body = <String, dynamic>{'name': name};
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
        body: body,
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final program = WorkoutProgram.fromJson(rawData);
        state = ProgramsState(
          programs: [...state.programs, program],
          isLoading: false,
        );
        return program;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final programsProvider =
    StateNotifierProvider<ProgramsNotifier, ProgramsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgramsNotifier(apiClient: apiClient);
});
