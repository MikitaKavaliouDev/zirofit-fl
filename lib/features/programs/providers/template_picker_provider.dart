import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TemplatePickerState {
  final List<WorkoutTemplate> templates;
  final bool isLoading;
  final String? searchQuery;
  final String? error;

  const TemplatePickerState({
    this.templates = const [],
    this.isLoading = false,
    this.searchQuery,
    this.error,
  });

  TemplatePickerState copyWith({
    List<WorkoutTemplate>? templates,
    bool? isLoading,
    String? searchQuery,
    bool clearSearch = false,
    String? error,
    bool clearError = false,
  }) {
    return TemplatePickerState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TemplatePickerNotifier extends StateNotifier<TemplatePickerState> {
  final ApiClient _api;
  List<WorkoutTemplate> _allTemplates = [];

  TemplatePickerNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const TemplatePickerState());

  /// Loads all available workout templates from the server.
  Future<void> loadTemplates() async {
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
      } else if (rawData is Map<String, dynamic>) {
        final templatesList = rawData['templates'] as List<dynamic>? ?? [];
        templates = templatesList
            .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        templates = [];
      }

      _allTemplates = templates;
      state = TemplatePickerState(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Filters templates locally by [query] (matches name or description).
  void search(String query) {
    state = state.copyWith(searchQuery: query);

    if (query.isEmpty) {
      state = state.copyWith(templates: _allTemplates);
    } else {
      final filtered = _allTemplates.where((t) {
        final nameMatch =
            t.name.toLowerCase().contains(query.toLowerCase());
        final descMatch =
            t.description?.toLowerCase().contains(query.toLowerCase()) ?? false;
        return nameMatch || descMatch;
      }).toList();

      state = state.copyWith(templates: filtered);
    }
  }

  /// Copies the template with [templateId] via the copy endpoint.
  Future<void> copyTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.post<Map<String, dynamic>>(
        ApiConstants.templateCopy(templateId),
      );

      state = state.copyWith(isLoading: false);
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

final templatePickerProvider =
    StateNotifierProvider<TemplatePickerNotifier, TemplatePickerState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TemplatePickerNotifier(apiClient: apiClient);
});
