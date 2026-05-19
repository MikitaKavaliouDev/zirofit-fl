import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/notification_model.dart' as models;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SharingRequestsState {
  final List<models.Notification> requests;
  final bool isLoading;
  final String? error;

  const SharingRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  SharingRequestsState copyWith({
    List<models.Notification>? requests,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SharingRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SharingRequestsNotifier extends StateNotifier<SharingRequestsState> {
  final ApiClient _apiClient;

  SharingRequestsNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const SharingRequestsState());

  /// GET /api/notifications?types=client_link_request
  ///
  /// Fetches only client link request notifications.
  Future<void> fetchRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.notifications,
        queryParams: {'types': 'client_link_request'},
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final requests = rawList
          .map((e) => models.Notification.fromJson(e as Map<String, dynamic>))
          .toList();

      state = SharingRequestsState(requests: requests);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// POST /api/trainer/clients/{clientId}/accept
  ///
  /// Accepts a client link request and removes it from the list.
  Future<bool> acceptRequest(String clientId) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.trainerClientAccept(clientId),
      );
      _removeRequest(clientId);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
      return false;
    }
  }

  /// POST /api/trainer/clients/{clientId}/decline
  ///
  /// Declines a client link request and removes it from the list.
  Future<bool> declineRequest(String clientId) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.trainerClientDecline(clientId),
      );
      _removeRequest(clientId);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractErrorMessage(e));
      return false;
    }
  }

  /// Clears any error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Removes all requests for a given client from the local list.
  void _removeRequest(String clientId) {
    final updated = state.requests.where((n) {
      final meta = n.metadata;
      if (meta == null) return true;
      return meta['client_id'] != clientId;
    }).toList();

    state = state.copyWith(requests: updated);
  }

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
      return 'Something went wrong. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final sharingRequestsProvider =
    StateNotifierProvider<SharingRequestsNotifier, SharingRequestsState>((ref) {
  return SharingRequestsNotifier(apiClient: ApiClient.instance);
});
