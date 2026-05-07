import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/text_content.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerTextContentState {
  final TextContent? textContent;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const TrainerTextContentState({
    this.textContent,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  TrainerTextContentState copyWith({
    TextContent? textContent,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return TrainerTextContentState(
      textContent: textContent ?? this.textContent,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerTextContentNotifier extends StateNotifier<TrainerTextContentState> {
  final ApiClient _apiClient;

  /// Tracks which fields have been modified since the last fetch or save.
  final Set<String> _dirtyFields = {};

  /// The last-saved field values, used to determine dirty fields.
  Map<String, String?> _savedValues = {};

  TrainerTextContentNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerTextContentState());

  // -----------------------------------------------------------------------
  // Fetch
  // -----------------------------------------------------------------------

  Future<void> fetchTextContent() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get<TextContent>(
        ApiConstants.profileMeTextContent,
        fromJson: (json) => TextContent.fromJson(json),
      );

      _savedValues = {
        'aboutMe': response.aboutMe,
        'philosophy': response.philosophy,
        'methodology': response.methodology,
        'certifications': response.certifications,
        'qualifications': response.qualifications,
      };
      _dirtyFields.clear();

      state = state.copyWith(
        textContent: response,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Field update (local only)
  // -----------------------------------------------------------------------

  void updateField(String field, String value) {
    final current = state.textContent;
    if (current == null) return;

    final updated = current.copyWith(
      aboutMe: field == 'aboutMe' ? value : null,
      philosophy: field == 'philosophy' ? value : null,
      methodology: field == 'methodology' ? value : null,
      certifications: field == 'certifications' ? value : null,
      qualifications: field == 'qualifications' ? value : null,
    );

    // Track dirty fields
    final savedValue = _savedValues[field];
    if (savedValue == value || (savedValue == null && value.isEmpty)) {
      _dirtyFields.remove(field);
    } else {
      _dirtyFields.add(field);
    }

    state = state.copyWith(
      textContent: updated,
      clearError: true,
      clearSuccess: true,
    );
  }

  // -----------------------------------------------------------------------
  // Save all fields
  // -----------------------------------------------------------------------

  Future<void> saveTextContent() async {
    final current = state.textContent;
    if (current == null) return;

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      final body = {
        'about_me': current.aboutMe,
        'philosophy': current.philosophy,
        'methodology': current.methodology,
        'certifications': current.certifications,
        'qualifications': current.qualifications,
      };

      await _apiClient.put(
        ApiConstants.profileMeTextContent,
        body: body,
      );

      _savedValues = {
        'aboutMe': current.aboutMe,
        'philosophy': current.philosophy,
        'methodology': current.methodology,
        'certifications': current.certifications,
        'qualifications': current.qualifications,
      };
      _dirtyFields.clear();

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Text content saved successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Save only changed fields
  // -----------------------------------------------------------------------

  Future<void> savePartial() async {
    if (_dirtyFields.isEmpty) {
      state = state.copyWith(successMessage: 'No changes to save');
      return;
    }

    final current = state.textContent;
    if (current == null) return;

    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      final body = <String, dynamic>{};
      if (_dirtyFields.contains('aboutMe')) {
        body['about_me'] = current.aboutMe;
      }
      if (_dirtyFields.contains('philosophy')) {
        body['philosophy'] = current.philosophy;
      }
      if (_dirtyFields.contains('methodology')) {
        body['methodology'] = current.methodology;
      }
      if (_dirtyFields.contains('certifications')) {
        body['certifications'] = current.certifications;
      }
      if (_dirtyFields.contains('qualifications')) {
        body['qualifications'] = current.qualifications;
      }

      await _apiClient.put(
        ApiConstants.profileMeTextContent,
        body: body,
      );

      // Update saved values only for dirty fields
      if (body.containsKey('about_me')) {
        _savedValues['aboutMe'] = current.aboutMe;
        _dirtyFields.remove('aboutMe');
      }
      if (body.containsKey('philosophy')) {
        _savedValues['philosophy'] = current.philosophy;
        _dirtyFields.remove('philosophy');
      }
      if (body.containsKey('methodology')) {
        _savedValues['methodology'] = current.methodology;
        _dirtyFields.remove('methodology');
      }
      if (body.containsKey('certifications')) {
        _savedValues['certifications'] = current.certifications;
        _dirtyFields.remove('certifications');
      }
      if (body.containsKey('qualifications')) {
        _savedValues['qualifications'] = current.qualifications;
        _dirtyFields.remove('qualifications');
      }

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Text content saved successfully',
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Returns the set of dirty (modified) field names.
  Set<String> get dirtyFields => Set.unmodifiable(_dirtyFields);

  /// Whether any field has been modified since last fetch/save.
  bool get hasDirtyFields => _dirtyFields.isNotEmpty;

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

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

final trainerTextContentProvider =
    StateNotifierProvider<TrainerTextContentNotifier, TrainerTextContentState>(
        (ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerTextContentNotifier(apiClient: apiClient);
});
