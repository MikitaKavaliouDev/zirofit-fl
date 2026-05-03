import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_model.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientListState {
  final List<Client> clients;
  final List<Client> filteredClients;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  const ClientListState({
    this.clients = const [],
    this.filteredClients = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  ClientListState copyWith({
    List<Client>? clients,
    List<Client>? filteredClients,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool clearError = false,
  }) {
    return ClientListState(
      clients: clients ?? this.clients,
      filteredClients: filteredClients ?? this.filteredClients,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasError => error != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientListNotifier extends StateNotifier<ClientListState> {
  final ApiClient _apiClient;

  ClientListNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const ClientListState());

  /// Fetches clients from the API, optionally filtered by [search].
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

      final List<Client> clients;
      final rawData = response['data'];
      if (rawData is List) {
        clients = rawData
            .map((e) => Client.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        clients = [];
      }

      state = ClientListState(
        clients: clients,
        filteredClients: clients,
        isLoading: false,
        searchQuery: search ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

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

  /// Invites a new client via POST /clients/invite.
  Future<String?> inviteClient({
    required String name,
    required String email,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.clients}/invite',
        body: {'name': name, 'email': email},
      );
      // Refresh the list after a successful invite
      await fetchClients();
      return null; // no error
    } catch (e) {
      return _extractErrorMessage(e);
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

final clientListProvider =
    StateNotifierProvider<ClientListNotifier, ClientListState>((ref) {
  final apiClient = ApiClient.instance;
  return ClientListNotifier(apiClient: apiClient);
});
