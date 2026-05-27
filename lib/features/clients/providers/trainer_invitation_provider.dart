import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/trainer_invitation_data.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

/// All possible states for the trainer invitation flow.
enum TrainerInvitationStatus {
  /// Initial state before any action.
  initial,

  /// Fetching trainer profile from the invitation token.
  loading,

  /// Trainer profile loaded and ready for user action.
  loaded,

  /// Sending accept request to the server.
  accepting,

  /// Sending decline request to the server.
  declining,

  /// Invitation was accepted successfully.
  accepted,

  /// Invitation was declined successfully.
  declined,

  /// An error occurred.
  error,
}

/// State container for [TrainerInvitationNotifier].
class TrainerInvitationState {
  final TrainerInvitationStatus status;
  final TrainerInvitationData? trainer;
  final String? error;

  const TrainerInvitationState({
    this.status = TrainerInvitationStatus.initial,
    this.trainer,
    this.error,
  });

  TrainerInvitationState copyWith({
    TrainerInvitationStatus? status,
    TrainerInvitationData? trainer,
    bool clearTrainer = false,
    String? error,
    bool clearError = false,
  }) {
    return TrainerInvitationState(
      status: status ?? this.status,
      trainer: clearTrainer ? null : (trainer ?? this.trainer),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerInvitationNotifier
    extends StateNotifier<TrainerInvitationState> {
  final ApiClient _apiClient;

  TrainerInvitationNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerInvitationState());

  /// Fetches the trainer profile for the given [token].
  Future<void> fetchTrainerProfile(String token) async {
    state = state.copyWith(
      status: TrainerInvitationStatus.loading,
      clearError: true,
      clearTrainer: true,
    );

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.invitationDetail(token),
      );

      final trainer = TrainerInvitationData.fromJson(response);
      state = state.copyWith(
        status: TrainerInvitationStatus.loaded,
        trainer: trainer,
      );
    } catch (e) {
      state = state.copyWith(
        status: TrainerInvitationStatus.error,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Accepts the invitation identified by [token].
  Future<bool> acceptInvitation(String token) async {
    state = state.copyWith(status: TrainerInvitationStatus.accepting);

    try {
      await _apiClient.post(
        ApiConstants.acceptInvitation,
        body: {'token': token},
      );

      state = state.copyWith(status: TrainerInvitationStatus.accepted);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: TrainerInvitationStatus.loaded,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Declines the invitation identified by [token].
  Future<bool> declineInvitation(String token) async {
    state = state.copyWith(status: TrainerInvitationStatus.declining);

    try {
      await _apiClient.post(
        ApiConstants.declineInvitation,
        body: {'token': token},
      );

      state = state.copyWith(status: TrainerInvitationStatus.declined);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: TrainerInvitationStatus.loaded,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  /// Resets state to initial (e.g. when navigating away).
  void reset() {
    state = const TrainerInvitationState();
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

final trainerInvitationProvider = StateNotifierProvider<
    TrainerInvitationNotifier, TrainerInvitationState>((ref) {
  final apiClient = ApiClient.instance;
  return TrainerInvitationNotifier(apiClient: apiClient);
});
