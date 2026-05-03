import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SupportTicketsState {
  final List<SupportTicket> tickets;
  final bool isLoading;
  final String? error;
  final bool isSending;

  const SupportTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
    this.isSending = false,
  });

  SupportTicketsState copyWith({
    List<SupportTicket>? tickets,
    bool? isLoading,
    String? error,
    bool? isSending,
    bool clearError = false,
  }) {
    return SupportTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSending: isSending ?? this.isSending,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class SupportTicketNotifier extends StateNotifier<SupportTicketsState> {
  final ApiClient _api;

  SupportTicketNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const SupportTicketsState());

  /// Fetches all support tickets.
  Future<void> fetchTickets() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final Map<String, dynamic> data = await _api.get(
        ApiConstants.supportTickets,
      );

      final List<dynamic> rawList = (data['data'] as List?) ?? [];

      final tickets = rawList
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        tickets: tickets,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a new support ticket.
  Future<bool> createTicket(String category, String message) async {
    state = state.copyWith(isSending: true, clearError: true);

    try {
      final Map<String, dynamic> response = await _api.post(
        ApiConstants.supportTickets,
        body: {
          'category': category,
          'message': message,
        },
      );

      // If the API returns the created ticket, prepend it to the list
      if (response['data'] != null) {
        final newTicket = SupportTicket.fromJson(
          response['data'] as Map<String, dynamic>,
        );
        state = state.copyWith(
          tickets: [newTicket, ...state.tickets],
          isSending: false,
        );
      } else {
        state = state.copyWith(isSending: false);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        error: _extractErrorMessage(e),
      );
      return false;
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final supportTicketsProvider =
    StateNotifierProvider<SupportTicketNotifier, SupportTicketsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportTicketNotifier(apiClient: apiClient);
});
