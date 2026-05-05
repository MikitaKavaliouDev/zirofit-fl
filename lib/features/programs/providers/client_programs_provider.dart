import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientProgramsState {
  final List<WorkoutProgram> programs;
  final List<WorkoutTemplate> templates;
  final WorkoutProgram? activeProgram;
  final bool isLoading;
  final String? error;

  const ClientProgramsState({
    this.programs = const [],
    this.templates = const [],
    this.activeProgram,
    this.isLoading = false,
    this.error,
  });

  ClientProgramsState copyWith({
    List<WorkoutProgram>? programs,
    List<WorkoutTemplate>? templates,
    WorkoutProgram? activeProgram,
    bool clearActive = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClientProgramsState(
      programs: programs ?? this.programs,
      templates: templates ?? this.templates,
      activeProgram: clearActive ? null : (activeProgram ?? this.activeProgram),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientProgramsNotifier extends StateNotifier<ClientProgramsState> {
  final ApiClient _api;

  ClientProgramsNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const ClientProgramsState());

  /// Fetches assigned programs/routines for the client.
  Future<void> fetchPrograms() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.clientPrograms,
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

      state = state.copyWith(programs: programs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Fetches available workout templates.
  Future<void> fetchTemplates() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerWorkoutTemplates,
      );

      final List<WorkoutTemplate> templates;
      final rawData = response['data'];
      if (rawData is List) {
        templates = rawData
            .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        templates = [];
      }

      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Sets the active program for the client.
  Future<void> setActiveProgram(String programId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.put<Map<String, dynamic>>(
        ApiConstants.clientActiveProgram,
        body: {'programId': programId},
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final program = WorkoutProgram.fromJson(rawData);
        state = state.copyWith(activeProgram: program, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Clears the active program for the client.
  Future<void> clearActiveProgram() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.clientActiveProgram,
        body: {},
      );

      state = state.copyWith(clearActive: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
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

final clientProgramsProvider =
    StateNotifierProvider<ClientProgramsNotifier, ClientProgramsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ClientProgramsNotifier(apiClient: apiClient);
});
