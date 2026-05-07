import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/external_link.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerExternalLinksState {
  final List<ExternalLink> links;
  final bool isLoading;
  final String? error;

  const TrainerExternalLinksState({
    this.links = const [],
    this.isLoading = false,
    this.error,
  });

  TrainerExternalLinksState copyWith({
    List<ExternalLink>? links,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerExternalLinksState(
      links: links ?? this.links,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerExternalLinksNotifier
    extends StateNotifier<TrainerExternalLinksState> {
  final ApiClient _apiClient;

  TrainerExternalLinksNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerExternalLinksState());

  // -- Fetch all external links --

  Future<void> fetchLinks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get(
        ApiConstants.profileMeExternalLinks,
        fromJson: (json) {
          final data = json['data'] as List<dynamic>?;
          if (data == null) return <ExternalLink>[];
          return data
              .map((e) => ExternalLink.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

      state = state.copyWith(
        links: response,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Create external link --

  Future<void> addLink(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post(
        ApiConstants.profileMeExternalLinks,
        body: data,
        fromJson: (json) => ExternalLink.fromJson(json),
      );

      state = state.copyWith(
        links: [...state.links, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Update external link --

  Future<void> updateLink(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.put(
        '${ApiConstants.profileMeExternalLinks}/$id',
        body: data,
        fromJson: (json) => ExternalLink.fromJson(json),
      );

      final updatedLinks = state.links.map((link) {
        return link.id == id ? response : link;
      }).toList();

      state = state.copyWith(
        links: updatedLinks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Delete external link --

  Future<void> deleteLink(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.profileMeExternalLinks}/$id');

      state = state.copyWith(
        links: state.links.where((link) => link.id != id).toList(),
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

final trainerExternalLinksProvider = StateNotifierProvider<
    TrainerExternalLinksNotifier, TrainerExternalLinksState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerExternalLinksNotifier(apiClient: apiClient);
});
