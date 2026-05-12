import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/explore_event.dart';
import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/trainer_search_result.dart';
import 'package:zirofit_fl/data/models/public_trainer_profile_data.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Discovery enums
// ---------------------------------------------------------------------------

/// Tab selection for the discovery segmented picker.
enum DiscoveryType { specialists, events, all }

/// Sort options for the filter sheet.
enum DiscoverySortBy {
  closest('Closest'),
  rating('Rating'),
  priceLow('Price: Low'),
  priceHigh('Price: High');

  final String label;
  const DiscoverySortBy(this.label);

  String get apiValue {
    switch (this) {
      case DiscoverySortBy.closest:
        return 'distance';
      case DiscoverySortBy.rating:
        return 'rating';
      case DiscoverySortBy.priceLow:
        return 'price_asc';
      case DiscoverySortBy.priceHigh:
        return 'price_desc';
    }
  }
}

// ---------------------------------------------------------------------------
// City model for city picker
// ---------------------------------------------------------------------------

class ExploreCity {
  final String id;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;

  const ExploreCity({
    required this.id,
    required this.name,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  factory ExploreCity.fromJson(Map<String, dynamic> json) {
    return ExploreCity(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

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
  final List<ExploreEvent> featuredEvents;
  final String? searchQuery;
  final String? selectedSpecialty;
  final String? locationFilter;
  final double? latitude;
  final double? longitude;
  final bool hasMore;
  final int currentPage;

  // City and event data for explore tab
  final List<ExploreCity> cities;
  final List<ExploreEvent> upcomingEvents;

  // Discovery filter fields
  final DiscoveryType discoveryType;
  final DiscoverySortBy? sortBy;
  final List<String> selectedSpecialties;
  final double? minRating;

  /// Whether any non-default filter is active.
  bool get hasActiveFilters =>
      sortBy != null ||
      selectedSpecialties.isNotEmpty ||
      minRating != null ||
      (locationFilter != null && locationFilter!.isNotEmpty);

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
    this.cities = const [],
    this.upcomingEvents = const [],
    this.discoveryType = DiscoveryType.all,
    this.sortBy,
    this.selectedSpecialties = const [],
    this.minRating,
  });

  ExploreState copyWith({
    List<Profile>? trainers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<TrainerSearchResult>? results,
    List<String>? specialties,
    List<ExploreEvent>? featuredEvents,
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
    List<ExploreCity>? cities,
    List<ExploreEvent>? upcomingEvents,
    DiscoveryType? discoveryType,
    DiscoverySortBy? sortBy,
    bool clearSortBy = false,
    List<String>? selectedSpecialties,
    double? minRating,
    bool clearMinRating = false,
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
      cities: cities ?? this.cities,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      discoveryType: discoveryType ?? this.discoveryType,
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      selectedSpecialties: selectedSpecialties ?? this.selectedSpecialties,
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
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
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.exploreFeatured,
      );

      // Backend wraps response in { data: ... } via jsonSuccess()
      final Map<String, dynamic> data = response['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> rawTrainers = data['featuredTrainers'] as List? ?? [];

      final trainers = rawTrainers.map((e) {
        final map = e as Map<String, dynamic>;
        // Map featured trainer shape to Profile fields
        // Backend: {id, name, avatarUrl, rating, tier, isVerified, specialties}
        // Profile needs: id, userId, profilePhotoPath, averageRating, isVerified, specialties, createdAt, updatedAt
        final now = DateTime.now();
        return Profile(
          id: map['id'] as String? ?? '',
          userId: map['id'] as String? ?? '',
          aboutMe: map['name'] as String?,
          profilePhotoPath: map['avatarUrl'] as String?,
          averageRating: (map['rating'] as num?)?.toDouble(),
          isVerified: map['isVerified'] as bool? ?? false,
          specialties: (map['specialties'] as List?)?.cast<String>() ?? [],
          createdAt: now,
          updatedAt: now,
        );
      }).toList();

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
  /// Passes the current location filter (city + coordinates) if available.
  Future<void> loadFeatured() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{};
      if (state.locationFilter != null) {
        queryParams['city'] = state.locationFilter;
      }
      if (state.latitude != null) {
        queryParams['lat'] = state.latitude;
      }
      if (state.longitude != null) {
        queryParams['lon'] = state.longitude;
      }

      final Map<String, dynamic> response = await _api.get(
        ApiConstants.exploreFeatured,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      // Backend wraps response in { data: ... } via jsonSuccess()
      final Map<String, dynamic> data = response['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> rawTrainers = data['featuredTrainers'] as List? ?? [];

      final trainers = rawTrainers.map((e) {
        final map = e as Map<String, dynamic>;
        // Map featured trainer shape to Profile fields
        // Backend: {id, name, avatarUrl, rating, tier, isVerified, specialties}
        // Profile needs: id, userId, profilePhotoPath, averageRating, isVerified, specialties, createdAt, updatedAt
        final now = DateTime.now();
        return Profile(
          id: map['id'] as String? ?? '',
          userId: map['id'] as String? ?? '',
          aboutMe: map['name'] as String?,
          profilePhotoPath: map['avatarUrl'] as String?,
          averageRating: (map['rating'] as num?)?.toDouble(),
          isVerified: map['isVerified'] as bool? ?? false,
          specialties: (map['specialties'] as List?)?.cast<String>() ?? [],
          createdAt: now,
          updatedAt: now,
        );
      }).toList();

      // Parse featured events from the data
      final List<ExploreEvent> events;
      final rawEvents = data['featuredEvents'] as List?;
      if (rawEvents != null) {
        events = rawEvents
            .map((e) => ExploreEvent.fromJson(e as Map<String, dynamic>))
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

  /// Fetches explore metadata (cities list for city picker).
  Future<void> loadMetadata() async {
    try {
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.exploreMetadata,
      );

      // Backend wraps response in { data: ... } via jsonSuccess()
      final Map<String, dynamic> data = response['data'] as Map<String, dynamic>? ?? {};

      final List<ExploreCity> cities;
      final rawCities = data['cities'] as List?;
      if (rawCities != null) {
        cities = rawCities
            .map((e) => ExploreCity.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        cities = [];
      }

      // Also load categories from metadata
      final List<String> categories;
      final rawCategories = data['categories'] as List?;
      if (rawCategories != null) {
        categories = rawCategories
            .map((e) => (e as Map<String, dynamic>)['name'] as String)
            .toList();
      } else {
        categories = [];
      }

      state = state.copyWith(
        cities: cities,
        specialties: categories.isNotEmpty ? categories : state.specialties,
      );
    } catch (e) {
      // Silently fail – metadata is non-critical
    }
  }

  /// Fetches upcoming events for the explore tab.
  /// Passes the current location filter (city + coordinates) if available.
  Future<void> loadUpcomingEvents({int limit = 10}) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
      };
      if (state.locationFilter != null) {
        queryParams['city'] = state.locationFilter;
      }
      if (state.latitude != null) {
        queryParams['lat'] = state.latitude;
      }
      if (state.longitude != null) {
        queryParams['lon'] = state.longitude;
      }

      final Map<String, dynamic> response = await _api.get(
        ApiConstants.exploreEvents,
        queryParams: queryParams,
      );

      // Backend wraps response in { data: ... } via jsonSuccess()
      final Map<String, dynamic> data = response['data'] as Map<String, dynamic>? ?? {};

      final List<ExploreEvent> events;
      final rawEvents = data['events'] as List?;
      if (rawEvents != null) {
        events = rawEvents
            .map((e) => ExploreEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        events = [];
      }

      state = state.copyWith(upcomingEvents: events);
    } catch (e) {
      // Silently fail – events are non-critical
    }
  }

  /// Sets the active discovery tab.
  void setDiscoveryType(DiscoveryType type) {
    state = state.copyWith(discoveryType: type);
    // Re-run search if there's an active query or filters
    if (state.searchQuery != null && state.searchQuery!.isNotEmpty ||
        state.hasActiveFilters) {
      search(page: 1);
    }
  }

  /// Sets the sort order and re-searches.
  void setSortBy(DiscoverySortBy? sort) {
    state = state.copyWith(
      sortBy: sort,
      clearSortBy: sort == null,
    );
    search(page: 1);
  }

  /// Applies all filter sheet values at once and re-searches.
  void applyFilters({
    DiscoverySortBy? sortBy,
    String? location,
    double? lat,
    double? lon,
    List<String>? specialties,
    double? minRating,
  }) {
    state = state.copyWith(
      sortBy: sortBy,
      clearSortBy: sortBy == null,
      locationFilter: location,
      latitude: lat,
      longitude: lon,
      selectedSpecialties: specialties,
      minRating: minRating,
      clearMinRating: minRating == null,
      currentPage: 1,
      results: [],
    );
    search(page: 1);
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
      if (state.sortBy != null) {
        queryParams['sort_by'] = state.sortBy!.apiValue;
      }
      if (state.minRating != null) {
        queryParams['min_rating'] = state.minRating!.toStringAsFixed(1);
      }
      queryParams['page'] = state.currentPage;

      final Map<String, dynamic> response = await _api.get(
        ApiConstants.trainersSearch,
        queryParams: queryParams,
      );

      // Backend wraps response in { data: ... } via jsonSuccess()
      final Map<String, dynamic> data = response['data'] as Map<String, dynamic>? ?? {};
      final List<dynamic> rawList = data['trainers'] as List? ?? [];
      final pageResults = rawList
          .map((e) => TrainerSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();

      // Pagination metadata: the API returns pagination object with has_more, total, etc.
      final Map<String, dynamic>? pagination = data['pagination'] as Map<String, dynamic>?;
      final bool hasMore = (pagination?['has_more'] as bool?) ?? false;

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
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.trainersSpecialties,
      );

      // Backend wraps response in { data: ... } via jsonSuccess()
      final Map<String, dynamic> data = response['data'] as Map<String, dynamic>? ?? {};
      
      // Specialties endpoint returns { specialties: [...] } in data, not a list at top level
      final List<dynamic> rawList = data['specialties'] as List? ?? [];
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

  /// Updates the location filter in state WITHOUT triggering a search.
  ///
  /// Use this during initial screen load when you want to set the location
  /// before fetching featured/events data. For manual city picker changes
  /// that should trigger a search, use [setLocation] instead.
  void updateLocation(String location, double? lat, double? lon) {
    state = state.copyWith(
      locationFilter: location,
      latitude: lat,
      longitude: lon,
    );
  }

  /// Sets a location filter and immediately re-searches.
  void setLocation(String location, double? lat, double? lon) {
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
      sortBy: null,
      clearSortBy: true,
      selectedSpecialties: [],
      minRating: null,
      clearMinRating: true,
      hasMore: true,
      currentPage: 1,
    );
  }

  // =========================================================================
  // Public trainer profile
  // =========================================================================

  /// Fetches the full public profile for a trainer by [username].
  ///
  /// GET /api/trainers/{username}
  /// Returns [PublicTrainerProfileData] with all marketplace fields.
  Future<PublicTrainerProfileData?> fetchFullPublicProfile(
      String username) async {
    try {
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.trainerPublicProfile(username),
      );

      final Map<String, dynamic> data =
          response['data'] as Map<String, dynamic>? ?? response;

      return PublicTrainerProfileData.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Sends a request from the current client to connect/link with a trainer.
  Future<bool> requestConnectTrainer(String trainerId) async {
    try {
      await _api.post(
        ApiConstants.clientConnectTrainer(trainerId),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Creates a Stripe checkout session for the given [packageId].
  ///
  /// POST /checkout/session
  /// Body: { packageId: <id> }
  /// Returns the checkout URL to open in browser, or null on failure.
  Future<String?> createCheckoutSession(String packageId) async {
    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.createCheckoutSession,
        body: {'packageId': packageId},
      );
      final data = response['data'] as Map<String, dynamic>?;
      return data?['url'] as String?;
    } catch (e) {
      return null;
    }
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
