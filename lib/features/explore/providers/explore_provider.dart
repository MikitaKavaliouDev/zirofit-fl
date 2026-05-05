import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/trainer_search_result.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ExploreState {
  // Existing fields (kept for backward compatibility)
  final List<Profile> trainers;
  final bool isLoading;
  final String? error;

  // New search / discovery fields
  final List<TrainerSearchResult> results;
  final List<String> specialties;
  final List<Event> featuredEvents;
  final String? searchQuery;
  final String? selectedSpecialty;
  final String? locationFilter;
  final double? latitude;
  final double? longitude;
  final bool hasMore;
  final int currentPage;

  const ExploreState({
    this.trainers = const [],
    this.isLoading = false,
    this.error,
    this.results = const [],
    this.specialties = const [],
    this.featuredEvents = const [],
    this.searchQuery,
    this.selectedSpecialty,
    this.locationFilter,
    this.latitude,
    this.longitude,
    this.hasMore = true,
    this.currentPage = 1,
  });

  ExploreState copyWith({
    List<Profile>? trainers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<TrainerSearchResult>? results,
    List<String>? specialties,
    List<Event>? featuredEvents,
    String? searchQuery,
    bool clearSearchQuery = false,
    String? selectedSpecialty,
    bool clearSelectedSpecialty = false,
    String? locationFilter,
    bool clearLocationFilter = false,
    double? latitude,
    double? longitude,
    bool? hasMore,
    int? currentPage,
  }) {
    return ExploreState(
      trainers: trainers ?? this.trainers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      results: results ?? this.results,
      specialties: specialties ?? this.specialties,
      featuredEvents: featuredEvents ?? this.featuredEvents,
      searchQuery:
          clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      selectedSpecialty: clearSelectedSpecialty
          ? null
          : (selectedSpecialty ?? this.selectedSpecialty),
      locationFilter: clearLocationFilter
          ? null
          : (locationFilter ?? this.locationFilter),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
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

  // =========================================================================
  // Existing methods (backward compatible)
  // =========================================================================

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

  // =========================================================================
  // New discovery / search methods
  // =========================================================================

  /// Loads featured content (trainers + events) from the explore endpoint.
  Future<void> loadFeatured() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _api.get(
        ApiConstants.exploreFeatured,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];
      final trainers = rawList
          .map((e) => Profile.fromJson(e as Map<String, dynamic>))
          .toList();

      // Parse featured events if present in the response
      final List<Event> events;
      final rawEvents = data['events'] as List?;
      if (rawEvents != null) {
        events = rawEvents
            .map((e) => Event.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        events = [];
      }

      state = state.copyWith(
        trainers: trainers,
        featuredEvents: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Searches trainers with optional filters.
  ///
  /// [query]      – free-text search query
  /// [specialty]  – filter by specialty (overrides [state.selectedSpecialty])
  /// [lat]/[lon]  – location-based proximity filter
  /// [page]       – page number (defaults to 1; pass `state.currentPage + 1`
  ///                for [loadMore])
  Future<void> search({
    String? query,
    String? specialty,
    double? lat,
    double? lon,
    int? page = 1,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      searchQuery: query ?? state.searchQuery,
      selectedSpecialty: specialty ?? state.selectedSpecialty,
      latitude: lat ?? state.latitude,
      longitude: lon ?? state.longitude,
      currentPage: page ?? 1,
    );

    // Clear results on a fresh search (page 1), append on subsequent pages.
    if (page == null || page == 1) {
      state = state.copyWith(results: []);
    }

    try {
      final queryParams = <String, dynamic>{};
      if (state.searchQuery != null && state.searchQuery!.isNotEmpty) {
        queryParams['search'] = state.searchQuery;
      }
      if (state.selectedSpecialty != null) {
        queryParams['specialty'] = state.selectedSpecialty;
      }
      if (state.locationFilter != null) {
        queryParams['location'] = state.locationFilter;
      }
      if (state.latitude != null) {
        queryParams['lat'] = state.latitude;
      }
      if (state.longitude != null) {
        queryParams['lon'] = state.longitude;
      }
      queryParams['page'] = state.currentPage;

      final Map<String, dynamic> data = await _api.get(
        ApiConstants.trainersSearch,
        queryParams: queryParams,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];
      final pageResults = rawList
          .map((e) => TrainerSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();

      // Pagination metadata: the API may return `has_more`, `total`, etc.
      final bool hasMore = (data['has_more'] as bool?) ??
          (data['total_pages'] == null || state.currentPage < (data['total_pages'] as int? ?? 1));

      state = state.copyWith(
        results: page == 1 ? pageResults : [...state.results, ...pageResults],
        isLoading: false,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Loads the list of available trainer specialties.
  Future<void> loadSpecialties() async {
    // Don't re-fetch if we already have them.
    if (state.specialties.isNotEmpty) return;

    try {
      final Map<String, dynamic> data = await _api.get(
        ApiConstants.trainersSpecialties,
      );

      final List<dynamic> rawList = (data['data'] as List?) ??
          (data['specialties'] as List?) ??
          [];
      final specialties = rawList.cast<String>().toList();

      state = state.copyWith(specialties: specialties);
    } catch (e) {
      // Silently fail – specialties are non-critical.
    }
  }

  /// Fetches the next page of search results.
  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    await search(page: state.currentPage + 1);
  }

  // =========================================================================
  // Filter / query mutators
  // =========================================================================

  /// Updates the search query in state (does NOT automatically re-fetch).
  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
  }

  /// Sets the specialty filter and immediately re-searches.
  void setSpecialty(String? specialty) {
    state = state.copyWith(
      selectedSpecialty: specialty,
      clearSelectedSpecialty: specialty == null,
    );
    // Optionally trigger a search. The caller can also call [search] manually.
    if (specialty != null || state.searchQuery != null) {
      search(specialty: specialty, page: 1);
    }
  }

  /// Sets a location filter and immediately re-searches.
  void setLocation(String location, double lat, double lon) {
    state = state.copyWith(
      locationFilter: location,
      latitude: lat,
      longitude: lon,
    );
    search(lat: lat, lon: lon, page: 1);
  }

  /// Clears all active search filters and resets results.
  void clearFilters() {
    state = state.copyWith(
      results: [],
      searchQuery: null,
      clearSearchQuery: true,
      selectedSpecialty: null,
      clearSelectedSpecialty: true,
      locationFilter: null,
      clearLocationFilter: true,
      latitude: null,
      longitude: null,
      hasMore: true,
      currentPage: 1,
    );
  }

  // =========================================================================
  // Helpers
  // =========================================================================

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
