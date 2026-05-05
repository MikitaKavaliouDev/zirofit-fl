import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_model.dart';
import 'package:zirofit_fl/data/models/event.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// Search result types
// ---------------------------------------------------------------------------

enum SearchResultType { exercise, client, trainer, event, program }

// ---------------------------------------------------------------------------
// SearchResult model
// ---------------------------------------------------------------------------

class SearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? routePath;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.routePath,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          subtitle == other.subtitle &&
          imageUrl == other.imageUrl &&
          routePath == other.routePath;

  @override
  int get hashCode => Object.hash(id, type, title, subtitle, imageUrl, routePath);

  @override
  String toString() =>
      'SearchResult(id: $id, type: $type, title: $title, subtitle: $subtitle)';
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class GlobalSearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;
  final bool isSearching;

  const GlobalSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.isSearching = false,
  });

  GlobalSearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSearching,
  }) {
    return GlobalSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSearching: isSearching ?? this.isSearching,
    );
  }

  bool get hasError => error != null;
  bool get hasResults => results.isNotEmpty;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final globalSearchProvider =
    StateNotifierProvider<GlobalSearchNotifier, GlobalSearchState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GlobalSearchNotifier(apiClient: apiClient);
});

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class GlobalSearchNotifier extends StateNotifier<GlobalSearchState> {
  final ApiClient _api;
  Timer? _debounce;

  static const String _recentSearchesKey = 'global_search_recent';
  static const int _maxRecentSearches = 10;

  GlobalSearchNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(const GlobalSearchState());

  // =========================================================================
  // Debounced search
  // =========================================================================

  /// Sets the search query with a 300ms debounce to avoid excessive API calls.
  void search(String query) {
    state = state.copyWith(query: query, clearError: true);

    _debounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query.trim());
    });
  }

  /// Performs the actual API search calls.
  Future<void> _executeSearch(String query) async {
    state = state.copyWith(isLoading: true, isSearching: false);

    try {
      final results = <SearchResult>[];

      // Run searches concurrently
      final futures = <Future<void>>[
        _searchExercises(query, results),
        _searchClients(query, results),
        _searchEvents(query, results),
      ];
      await Future.wait(futures);

      state = state.copyWith(
        results: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Searches exercises via GET /exercises?search=query
  Future<void> _searchExercises(String query, List<SearchResult> results) async {
    try {
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.exercises,
        queryParams: {'search': query, 'limit': 5},
      );

      final List<dynamic> rawList = (response['data'] as List?) ?? [];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final exercise = Exercise.fromJson(item);
          results.add(SearchResult(
            id: exercise.id,
            type: SearchResultType.exercise,
            title: exercise.name,
            subtitle: exercise.muscleGroup ?? exercise.category,
            imageUrl: exercise.imageUrl,
            routePath: '/exercises',
          ));
        }
      }
    } catch (_) {
      // Silently continue – one failing source shouldn't break the whole search
    }
  }

  /// Searches clients via GET /clients?search=query
  Future<void> _searchClients(String query, List<SearchResult> results) async {
    try {
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.clients,
        queryParams: {'search': query, 'sortBy': 'name'},
      );

      final List<dynamic> rawList = (response['data'] as List?) ?? [];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final client = Client.fromJson(item);
          results.add(SearchResult(
            id: client.id,
            type: SearchResultType.client,
            title: client.name,
            subtitle: client.email,
            imageUrl: client.avatarPath,
            routePath: '/trainer/clients/${client.id}',
          ));
        }
      }
    } catch (_) {
      // Silently continue
    }
  }

  /// Searches events via GET /events?search=query
  Future<void> _searchEvents(String query, List<SearchResult> results) async {
    try {
      final Map<String, dynamic> response = await _api.get(
        ApiConstants.events,
        queryParams: {'search': query, 'page': 1},
      );

      final List<dynamic> rawList = (response['data'] as List?) ?? [];
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          final event = Event.fromJson(item);
          results.add(SearchResult(
            id: event.id,
            type: SearchResultType.event,
            title: event.title,
            subtitle: event.category ?? event.locationName,
            imageUrl: event.imageUrl,
            routePath: '/events/${event.id}',
          ));
        }
      }
    } catch (_) {
      // Silently continue
    }
  }

  // =========================================================================
  // Clear
  // =========================================================================

  /// Clears the current search query and results.
  void clearSearch() {
    _debounce?.cancel();
    state = const GlobalSearchState();
  }

  // =========================================================================
  // Recent searches (SharedPreferences)
  // =========================================================================

  /// Loads recent search terms from SharedPreferences.
  Future<List<String>> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  /// Saves a search term to recent searches.
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final recent = prefs.getStringList(_recentSearchesKey) ?? [];

    // Remove duplicate if exists, then prepend
    recent.remove(query);
    recent.insert(0, query);

    // Keep only the latest N
    if (recent.length > _maxRecentSearches) {
      recent.removeRange(_maxRecentSearches, recent.length);
    }

    await prefs.setStringList(_recentSearchesKey, recent);
  }

  /// Clears all recent search terms.
  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
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

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
