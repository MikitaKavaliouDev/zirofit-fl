import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_assessment_result.dart';
import 'package:zirofit_fl/data/models/trainer_assessment.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// =============================================================================
// AssessmentNotifier – trainer assessment templates / client results (API)
// =============================================================================

// -----------------------------------------------------------------------------
// State
// -----------------------------------------------------------------------------

/// State for assessment templates and client assessment results.
class AssessmentState {
  final List<TrainerAssessment> templates;
  final List<ClientAssessmentResult> clientResults;
  final bool isLoading;
  final String? error;

  const AssessmentState({
    this.templates = const [],
    this.clientResults = const [],
    this.isLoading = false,
    this.error,
  });

  AssessmentState copyWith({
    List<TrainerAssessment>? templates,
    List<ClientAssessmentResult>? clientResults,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AssessmentState(
      templates: templates ?? this.templates,
      clientResults: clientResults ?? this.clientResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get hasError => error != null;
}

// -----------------------------------------------------------------------------
// Notifier
// -----------------------------------------------------------------------------

/// Notifier for managing trainer assessment templates and client assessment
/// results. Templates are managed via `/trainer/assessments` and client
/// results via `/clients/:id/assessments`.
class AssessmentNotifier extends StateNotifier<AssessmentState> {
  final ApiClient _api;

  AssessmentNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const AssessmentState());

  // ---------------------------------------------------------------------------
  // Templates
  // ---------------------------------------------------------------------------

  /// Fetches all assessment templates for the trainer.
  Future<void> fetchTemplates() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerAssessments,
      );

      final data = response['data'] as List<dynamic>? ??
          (response['templates'] as List<dynamic>? ?? <dynamic>[]);

      final templates = data
          .map((e) => TrainerAssessment.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a new assessment template.
  Future<TrainerAssessment?> createTemplate({
    required String name,
    String? description,
    required String unit,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerAssessments,
        body: {
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          'unit': unit,
        },
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final template = TrainerAssessment.fromJson(data);

      state = state.copyWith(
        templates: [...state.templates, template],
        isLoading: false,
      );

      return template;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  /// Deletes an assessment template by [id].
  Future<void> deleteTemplate(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.delete('${ApiConstants.trainerAssessments}/$id');

      state = state.copyWith(
        templates: state.templates.where((t) => t.id != id).toList(),
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
  // Client Results
  // ---------------------------------------------------------------------------

  /// Fetches assessment results for a specific client.
  Future<void> fetchClientResults(String clientId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.clientAssessments(clientId),
      );

      final data = response['data'] as List<dynamic>? ??
          (response['results'] as List<dynamic>? ?? <dynamic>[]);

      final results = data
          .map((e) =>
              ClientAssessmentResult.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(clientResults: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Adds a new assessment result for a client.
  Future<bool> addClientResult({
    required String clientId,
    required String assessmentId,
    required double value,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.clientAssessments(clientId),
        body: {
          'assessment_id': assessmentId,
          'value': value,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final result = ClientAssessmentResult.fromJson(data);

      state = state.copyWith(
        clientResults: [...state.clientResults, result],
        isLoading: false,
      );

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

// -----------------------------------------------------------------------------
// Provider
// -----------------------------------------------------------------------------

/// Provider for assessment templates and client assessment results.
final assessmentProvider =
    StateNotifierProvider<AssessmentNotifier, AssessmentState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AssessmentNotifier(apiClient: apiClient);
});
