import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ExploreState {
  final List<Profile> trainers;
  final bool isLoading;
  final String? error;

  const ExploreState({
    this.trainers = const [],
    this.isLoading = false,
    this.error,
  });

  ExploreState copyWith({
    List<Profile>? trainers,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExploreState(
      trainers: trainers ?? this.trainers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final exploreProvider =
    StateNotifierProvider<ExploreNotifier, ExploreState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ExploreNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ExploreNotifier extends StateNotifier<ExploreState> {
  final ApiClient _api;

  ExploreNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const ExploreState());

  /// Fetches featured trainers from the explore endpoint.
  Future<void> fetchFeatured() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _api.get(
        ApiConstants.exploreFeatured,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];
      final trainers = rawList
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        trainers: trainers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Refreshes the featured trainers list.
  Future<void> refresh() async {
    await fetchFeatured();
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}
