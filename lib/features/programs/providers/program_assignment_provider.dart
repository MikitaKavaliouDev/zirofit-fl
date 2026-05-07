import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProgramAssignmentState {
  final List<WorkoutProgram> programs;
  final bool isLoading;
  final bool isAssigning;
  final bool assignSuccess;
  final String? error;

  const ProgramAssignmentState({
    this.programs = const [],
    this.isLoading = false,
    this.isAssigning = false,
    this.assignSuccess = false,
    this.error,
  });

  ProgramAssignmentState copyWith({
    List<WorkoutProgram>? programs,
    bool? isLoading,
    bool? isAssigning,
    bool? assignSuccess,
    String? error,
    bool clearError = false,
  }) {
    return ProgramAssignmentState(
      programs: programs ?? this.programs,
      isLoading: isLoading ?? this.isLoading,
      isAssigning: isAssigning ?? this.isAssigning,
      assignSuccess: assignSuccess ?? this.assignSuccess,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProgramAssignmentNotifier
    extends StateNotifier<ProgramAssignmentState> {
  final ApiClient _api;

  ProgramAssignmentNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const ProgramAssignmentState());

  /// Fetches the trainer's programs available for assignment.
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

      state = state.copyWith(
        programs: programs,
        isLoading: false,
        assignSuccess: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Assigns a program to a client.
  ///
  /// Sends `POST /trainer/programs/{programId}/assign` with `{clientId}`.
  /// Returns `null` on success or an error message on failure.
  Future<String?> assignProgram({
    required String programId,
    required String clientId,
  }) async {
    state = state.copyWith(isAssigning: true, clearError: true);

    try {
      await _api.post<Map<String, dynamic>>(
        ApiConstants.programAssign(programId),
        body: {'clientId': clientId},
      );

      state = state.copyWith(
        isAssigning: false,
        assignSuccess: true,
      );
      return null;
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isAssigning: false,
        error: message,
      );
      return message;
    }
  }

  /// Resets the assignSuccess flag so the UI can dismiss success state.
  void resetSuccess() {
    state = state.copyWith(assignSuccess: false);
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

final programAssignmentProvider = StateNotifierProvider<
    ProgramAssignmentNotifier, ProgramAssignmentState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgramAssignmentNotifier(apiClient: apiClient);
});
