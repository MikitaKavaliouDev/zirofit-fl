import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/active_program_response.dart';
import 'package:zirofit_fl/data/models/client_program_library_response.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;
import 'package:zirofit_fl/features/programs/data/client_program_remote_source.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// State for the client programs & templates feature.
///
/// Holds the full program library and active program progress.
class ClientProgramsState {
  /// The full program/template library response from GET /client/programs.
  final ClientProgramLibraryResponse? library;

  /// The currently active assigned program with progress.
  final ActiveProgramResponse? activeProgramResponse;

  final bool isLoading;
  final String? error;

  /// Backward-compatible convenience getter.
  ///
  /// Returns assigned programs unwrapped from their assignment objects.
  /// Used by legacy screens like [MyRoutinesScreen].
  List<WorkoutProgram> get programs =>
      library?.assignedPrograms.map((a) => a.program).toList() ?? [];

  const ClientProgramsState({
    this.library,
    this.activeProgramResponse,
    this.isLoading = false,
    this.error,
  });

  ClientProgramsState copyWith({
    ClientProgramLibraryResponse? library,
    bool clearLibrary = false,
    ActiveProgramResponse? activeProgramResponse,
    bool clearActiveProgram = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClientProgramsState(
      library: clearLibrary ? null : (library ?? this.library),
      activeProgramResponse: clearActiveProgram
          ? null
          : (activeProgramResponse ?? this.activeProgramResponse),
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
  final ClientProgramRemoteSource _remoteSource;

  ClientProgramsNotifier({
    ApiClient? apiClient,
    ClientProgramRemoteSource? remoteSource,
  })  : _api = apiClient ?? ApiClient.instance,
        _remoteSource = remoteSource ??
            ClientProgramRemoteSource(ApiClient.instance.dio),
        super(const ClientProgramsState());

  // ---------------------------------------------------------------------------
  // Library
  // ---------------------------------------------------------------------------

  /// Fetches the full program/template library.
  ///
  /// Supports optional filters: [category] (e.g. "strength"), [source]
  /// ("self"/"assigned"/"system"), [type] ("program"/"template").
  Future<void> fetchLibrary({
    String? category,
    String? source,
    String? type,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.fetchLibrary(
        category: category,
        source: source,
        type: type,
      );

      final rawData = response['data'] as Map<String, dynamic>? ?? response;
      final library = ClientProgramLibraryResponse.fromJson(rawData);

      state = state.copyWith(library: library, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Backward-compatible alias that fetches the full library.
  ///
  /// Previously fetched only assigned programs. Now fetches everything.
  Future<void> fetchPrograms() => fetchLibrary();

  // ---------------------------------------------------------------------------
  // Create Program (Manual)
  // ---------------------------------------------------------------------------

  /// Creates a new program manually with [name] and optional [description].
  ///
  /// On success, re-fetches the library to get fresh data.
  Future<Map<String, dynamic>?> createManualProgram({
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.createManualProgram(
        name: name,
        description: description,
      );

      // Re-fetch library after creation
      await fetchLibrary();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Create Program (AI Generated)
  // ---------------------------------------------------------------------------

  /// Creates a program using AI generation with [duration] and [focus].
  ///
  /// [duration] is "week" or "month". [focus] is free text (e.g. "strength").
  Future<Map<String, dynamic>?> createAIProgram({
    required String duration,
    required String focus,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.createAIProgram(
        duration: duration,
        focus: focus,
      );

      await fetchLibrary();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Create Template
  // ---------------------------------------------------------------------------

  /// Creates a new template under [programId] with [name] and optional description.
  Future<Map<String, dynamic>?> createTemplate({
    required String name,
    String? description,
    required String programId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.createTemplate(
        name: name,
        description: description,
        programId: programId,
      );

      await fetchLibrary();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Add Exercise Step
  // ---------------------------------------------------------------------------

  /// Adds an exercise step to [templateId] with the given [fields].
  Future<Map<String, dynamic>?> addExerciseStep(
    String templateId,
    Map<String, dynamic> fields,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.addExerciseStep(
        templateId,
        fields,
      );

      await fetchLibrary();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Add Rest Step
  // ---------------------------------------------------------------------------

  /// Adds a rest step of [durationSeconds] to [templateId].
  Future<Map<String, dynamic>?> addRestStep(
    String templateId,
    int durationSeconds,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.addRestStep(
        templateId,
        durationSeconds,
      );

      await fetchLibrary();
      return response;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Exercise Step
  // ---------------------------------------------------------------------------

  /// Removes the step [stepId] from template [templateId].
  Future<bool> deleteExerciseStep(
    String templateId,
    String stepId,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _remoteSource.deleteExerciseStep(templateId, stepId);

      await fetchLibrary();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Copy Template
  // ---------------------------------------------------------------------------

  /// Deep-copies a system template to the user's own library.
  Future<bool> copyTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _remoteSource.copyTemplate(templateId);

      await fetchLibrary();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Active Program
  // ---------------------------------------------------------------------------

  /// Fetches the currently active assigned program with progress.
  Future<void> fetchActiveProgram() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.fetchActiveProgram();

      final rawData = response['data'] as Map<String, dynamic>? ?? response;
      final activeProgramResponse =
          ActiveProgramResponse.fromJson(rawData);

      state = state.copyWith(
        activeProgramResponse: activeProgramResponse,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Sets [programId] as the active program.
  Future<bool> setActiveProgram(String programId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _remoteSource.setActiveProgram(programId);

      // Re-fetch both the active program and library
      await fetchActiveProgram();
      await fetchLibrary();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Clear Active Program
  // ---------------------------------------------------------------------------

  /// Clears the active program by sending an empty programId.
  Future<void> clearActiveProgram() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.clientActiveProgram,
        body: <String, dynamic>{},
      );

      state = state.copyWith(
        clearActiveProgram: true,
        isLoading: false,
      );
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

  /// Extracts a user-friendly error message from various exception types.
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
  final remoteSource = ref.watch(clientProgramRemoteSourceProvider);
  return ClientProgramsNotifier(
    apiClient: apiClient,
    remoteSource: remoteSource,
  );
});
