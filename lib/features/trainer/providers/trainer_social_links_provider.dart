import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/social_link.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerSocialLinksState {
  final List<SocialLink> socialLinks;
  final bool isLoading;
  final String? error;

  const TrainerSocialLinksState({
    this.socialLinks = const [],
    this.isLoading = false,
    this.error,
  });

  TrainerSocialLinksState copyWith({
    List<SocialLink>? socialLinks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerSocialLinksState(
      socialLinks: socialLinks ?? this.socialLinks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerSocialLinksNotifier extends StateNotifier<TrainerSocialLinksState> {
  final ApiClient _apiClient;

  TrainerSocialLinksNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerSocialLinksState());

  // -- Fetch all social links --

  Future<void> fetchLinks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get<List<SocialLink>>(
        ApiConstants.profileMeSocialLinks,
        fromJson: (json) => (json['data'] as List<dynamic>?)
                ?.map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

      state = state.copyWith(
        socialLinks: response,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Create social link --

  Future<void> addLink({required String platform, required String url}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.post<SocialLink>(
        ApiConstants.profileMeSocialLinks,
        body: {'platform': platform, 'profile_url': url},
        fromJson: (json) => SocialLink.fromJson(json),
      );

      state = state.copyWith(
        socialLinks: [...state.socialLinks, response],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Update social link --

  Future<void> updateLink({
    required String id,
    required String platform,
    required String url,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.put<SocialLink>(
        '${ApiConstants.profileMeSocialLinks}/$id',
        body: {'platform': platform, 'profile_url': url},
        fromJson: (json) => SocialLink.fromJson(json),
      );

      final updatedLinks = state.socialLinks.map((link) {
        return link.id == id ? response : link;
      }).toList();

      state = state.copyWith(
        socialLinks: updatedLinks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Delete social link --

  Future<void> deleteLink(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete('${ApiConstants.profileMeSocialLinks}/$id');

      state = state.copyWith(
        socialLinks: state.socialLinks.where((link) => link.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Reorder (optimistic local update) --

  void reorderLinks(List<SocialLink> updatedLinks) {
    state = state.copyWith(socialLinks: updatedLinks);
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

final trainerSocialLinksProvider =
    StateNotifierProvider<TrainerSocialLinksNotifier, TrainerSocialLinksState>(
        (ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerSocialLinksNotifier(apiClient: apiClient);
});
