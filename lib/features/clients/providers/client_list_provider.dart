import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/services/app_event_bus.dart';
import 'package:zirofit_fl/core/services/cache_manager.dart';
import 'package:zirofit_fl/data/models/client_model.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Cache key used for the client list JSON file.
const String _clientListCacheKey = 'client_list';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientListState {
  final List<Client> clients;
  final List<Client> filteredClients;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  /// Whether the current list data was loaded from the local cache.
  /// When `true`, the UI can show a subtle indicator while the network
  /// fetch completes in the background.
  final bool isFromCache;

  const ClientListState({
    this.clients = const [],
    this.filteredClients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.isFromCache = false,
  });

  ClientListState copyWith({
    List<Client>? clients,
    List<Client>? filteredClients,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? isFromCache,
    bool clearError = false,
  }) {
    return ClientListState(
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  bool get hasError => error != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientListNotifier extends StateNotifier<ClientListState> {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;

  ClientListNotifier({required ApiClient apiClient, CacheManager? cacheManager})
      : _apiClient = apiClient,
        _cacheManager = cacheManager ?? CacheManager(),
        super(const ClientListState());

  // ---------------------------------------------------------------------------
  // Cache-first loading
  // ---------------------------------------------------------------------------

  /// Loads the client list using a cache-first strategy:
  /// 1. Instantly show cached data (if available)
  /// 2. Fetch fresh data from the API in the background
  /// 3. Update cache with fresh data
  ///
  /// Mirrors iOS `ClientsViewModel` cacheKey + `CacheManager.shared.load(key:)`.
  Future<void> loadClients() async {
    // Phase 1: Load from cache for instant display
    final cached = await _cacheManager.loadList<Client>(
      _clientListCacheKey,
      Client.fromJson,
    );

    if (cached != null && cached.isNotEmpty) {
      state = ClientListState(
        clients: cached,
        filteredClients: cached,
        searchQuery: state.searchQuery,
        isFromCache: true,
      );
    }

    // Phase 2: Fetch from network and update cache
    await fetchClients();
  }

  /// Fetches clients from the API, optionally filtered by [search].
  /// After a successful fetch, updates the local cache.
  Future<void> fetchClients({String? search}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      queryParams['sortBy'] = 'name';

      final response = await _apiClient.get(
        ApiConstants.clients,
        queryParams: queryParams,
      );

      // API returns {"data": {"clients": [...]}}, extract correctly
      final List<Client> clients;
      final dataMap = response['data'] as Map<String, dynamic>?;
      final rawList = dataMap?['clients'] as List<dynamic>?;

      if (rawList != null) {
        clients = rawList
            .map((e) => Client.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        clients = [];
      }

      // Save to cache for next app launch
      await _cacheManager.save(
        _clientListCacheKey,
        clients.map((c) => c.toJson()).toList(),
      );

      state = ClientListState(
        clients: clients,
        filteredClients: clients,
        isLoading: false,
        searchQuery: search ?? '',
        isFromCache: false,
      );

      // Notify listeners that client list changed
      AppEventBus().notifyClientListDidChange();
    } catch (e) {
      // If we already have cached data, keep showing it and just clear loading
      if (state.clients.isNotEmpty) {
        state = state.copyWith(isLoading: false);
        debugPrint('CLIENT_FETCH_ERROR (keeping cache): $e');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _extractErrorMessage(e),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Optimistic add
  // ---------------------------------------------------------------------------

  /// Optimistically adds a temporary client to the list and attempts to
  /// invite them via the API.
  ///
  /// Flow:
  /// 1. Create temp client with `pending` status and optimistically add to list
  /// 2. Insert at index 0 (top of list)
  /// 3. Save to cache immediately
  /// 4. On API success: replace temp with server-returned client
  /// 5. On API failure: remove temp, return error message
  ///
  /// Returns `null` on success, or an error message on failure.
  Future<String?> inviteClient({
    required String name,
    required String email,
  }) async {
    // 1. Create temp client with pending status
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final tempClient = Client(
      id: tempId,
      name: name,
      email: email,
      status: 'pending',
    );

    // 2. Insert at index 0
    final updatedClients = [tempClient, ...state.clients];
    state = ClientListState(
      clients: updatedClients,
      filteredClients: updatedClients,
      searchQuery: state.searchQuery,
    );

    // 3. Save to cache immediately
    await _cacheManager.save(
      _clientListCacheKey,
      updatedClients.map((c) => c.toJson()).toList(),
    );

    try {
      // 4. Call API
      final response = await _apiClient.post(
        '${ApiConstants.clients}/invite',
        body: {'name': name, 'email': email},
      );

      // Try to extract the real client from the response
      final data = response['data'] as Map<String, dynamic>?;
      final clientData = data?['client'] as Map<String, dynamic>?;

      if (clientData != null) {
        // 4a. Replace temp with server client
        final realClient = Client.fromJson(clientData);
        final finalClients = state.clients.map((c) {
          return c.id == tempId ? realClient : c;
        }).toList();

        state = ClientListState(
          clients: finalClients,
          filteredClients: finalClients,
          searchQuery: state.searchQuery,
        );

        await _cacheManager.save(
          _clientListCacheKey,
          finalClients.map((c) => c.toJson()).toList(),
        );

        AppEventBus().notifyClientListDidChange();
        return null; // no error
      }

      // If no client data in response, refresh the list instead
      await fetchClients();
      return null;
    } catch (e) {
      // 5. On failure: remove temp, return error
      final rolledBack = state.clients
          .where((c) => c.id != tempId)
          .toList();

      state = ClientListState(
        clients: rolledBack,
        filteredClients: rolledBack,
        searchQuery: state.searchQuery,
        error: _extractErrorMessage(e),
      );

      // Re-save rolled-back cache
      await _cacheManager.save(
        _clientListCacheKey,
        rolledBack.map((c) => c.toJson()).toList(),
      );

      return _extractErrorMessage(e);
    }
  }

  /// Adds a client directly to the list and cache (used when invite returns
  /// a real client but optimistic add wasn't used).
  Future<void> addClientDirect(Client client) async {
    final updatedClients = [client, ...state.clients];
    state = ClientListState(
      clients: updatedClients,
      filteredClients: updatedClients,
      searchQuery: state.searchQuery,
    );
    await _cacheManager.save(
      _clientListCacheKey,
      updatedClients.map((c) => c.toJson()).toList(),
    );
    AppEventBus().notifyClientListDidChange();
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Sets the search query and filters the local client list.
  void setSearch(String query) {
    final trimmed = query.trim().toLowerCase();
    final filtered = state.clients.where((client) {
      final nameMatch = client.name.toLowerCase().contains(trimmed);
      final emailMatch =
          client.email?.toLowerCase().contains(trimmed) ?? false;
      return nameMatch || emailMatch;
    }).toList();

    state = state.copyWith(
      searchQuery: query,
      filteredClients: filtered,
    );
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
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

final clientListProvider =
    StateNotifierProvider<ClientListNotifier, ClientListState>((ref) {
  final apiClient = ApiClient.instance;
  return ClientListNotifier(apiClient: apiClient);
});
