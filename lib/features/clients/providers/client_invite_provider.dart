import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ClientInviteState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final String? invitedEmail;
  final String? invitedPhone;
  final bool emailExists;

  const ClientInviteState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.invitedEmail,
    this.invitedPhone,
    this.emailExists = false,
  });

  ClientInviteState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSuccess,
    String? invitedEmail,
    String? invitedPhone,
    bool? emailExists,
  }) {
    return ClientInviteState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedPhone: invitedPhone ?? this.invitedPhone,
      emailExists: emailExists ?? this.emailExists,
    );
  }

  bool get hasError => error != null;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ClientInviteNotifier extends StateNotifier<ClientInviteState> {
  final ApiClient _apiClient;

  ClientInviteNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const ClientInviteState());

  /// Checks whether an email is already registered.
  /// Returns `true` if the user exists.
  Future<bool> checkEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get(
        '/clients/check-email',
        queryParams: {'email': email},
      );

      final exists = response['exists'] as bool? ?? false;
      state = state.copyWith(
        isLoading: false,
        emailExists: exists,
      );
      return exists;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Sends an invitation to a new client.
  Future<void> invite({
    String? email,
    required String name,
    String? phone,
    String? message,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final body = <String, dynamic>{
        'name': name,
      };
      if (email != null && email.trim().isNotEmpty) {
        body['email'] = email.trim();
      }
      if (phone != null && phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }
      if (message != null && message.trim().isNotEmpty) {
        body['message'] = message.trim();
      }

      await _apiClient.post('/clients/invite', body: body);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        invitedEmail: email,
        invitedPhone: phone,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 409) {
        // User already exists
        state = state.copyWith(
          isLoading: false,
          emailExists: true,
          error: 'This user is already registered on Ziro Fit.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _extractErrorMessage(e),
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Sends a link request to an existing user.
  Future<void> linkExisting(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.post(
        '/clients/link',
        body: {'email': email},
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        invitedEmail: email,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Resets the state back to initial (e.g. when navigating away).
  void reset() {
    state = const ClientInviteState();
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

final clientInviteProvider =
    StateNotifierProvider<ClientInviteNotifier, ClientInviteState>((ref) {
  final apiClient = ApiClient.instance;
  return ClientInviteNotifier(apiClient: apiClient);
});
