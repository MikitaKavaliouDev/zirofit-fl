import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/trainer_assessment.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerAssessmentsState {
  final List<TrainerAssessment> assessments;
  final bool isLoading;
  final String? error;

  const TrainerAssessmentsState({
    this.assessments = const [],
    this.isLoading = false,
    this.error,
  });

  TrainerAssessmentsState copyWith({
    List<TrainerAssessment>? assessments,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerAssessmentsState(
      assessments: assessments ?? this.assessments,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerAssessmentsNotifier
    extends StateNotifier<TrainerAssessmentsState> {
  final ApiClient _apiClient;

  TrainerAssessmentsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerAssessmentsState());

  // -- Fetch all assessment templates --

  Future<void> fetchAssessments() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.trainerAssessments,
      );

      final data = response['data'] as List<dynamic>? ??
          (response['templates'] as List<dynamic>? ?? <dynamic>[]);

      final assessments = data
          .map((e) => TrainerAssessment.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        assessments: assessments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Create assessment template --

  Future<TrainerAssessment?> createAssessment(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.trainerAssessments,
        body: data,
      );

      final resultData = response['data'] as Map<String, dynamic>? ?? response;
      final assessment = TrainerAssessment.fromJson(resultData);

      state = state.copyWith(
        assessments: [...state.assessments, assessment],
        isLoading: false,
      );

      return assessment;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // -- Update assessment template --

  Future<TrainerAssessment?> updateAssessment(
      String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.trainerAssessments}/$id',
        body: data,
      );

      final resultData = response['data'] as Map<String, dynamic>? ?? response;
      final updated = TrainerAssessment.fromJson(resultData);

      state = state.copyWith(
        assessments: state.assessments.map((a) {
          return a.id == id ? updated : a;
        }).toList(),
        isLoading: false,
      );

      return updated;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // -- Delete assessment template --

  Future<void> deleteAssessment(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.trainerAssessments}/$id');

      state = state.copyWith(
        assessments: state.assessments.where((a) => a.id != id).toList(),
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

final trainerAssessmentsProvider = StateNotifierProvider<
    TrainerAssessmentsNotifier, TrainerAssessmentsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerAssessmentsNotifier(apiClient: apiClient);
});
