import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerCheckInsState {
  final List<CheckIn> checkIns;
  final bool isLoading;
  final String? error;
  final CheckIn? selectedCheckIn;
  final bool isLoadingDetail;
  final bool isReviewing;
  final String? reviewError;

  const TrainerCheckInsState({
    this.checkIns = const [],
    this.isLoading = false,
    this.error,
    this.selectedCheckIn,
    this.isLoadingDetail = false,
    this.isReviewing = false,
    this.reviewError,
  });

  TrainerCheckInsState copyWith({
    List<CheckIn>? checkIns,
    bool? isLoading,
    String? error,
    CheckIn? selectedCheckIn,
    bool? isLoadingDetail,
    bool? isReviewing,
    String? reviewError,
    bool clearError = false,
    bool clearReviewError = false,
  }) {
    return TrainerCheckInsState(
      checkIns: checkIns ?? this.checkIns,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedCheckIn: selectedCheckIn ?? this.selectedCheckIn,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      isReviewing: isReviewing ?? this.isReviewing,
      reviewError:
          clearReviewError ? null : (reviewError ?? this.reviewError),
    );
  }

  List<CheckIn> get pendingCheckIns =>
      checkIns.where((c) => c.status == 'SUBMITTED').toList();

  List<CheckIn> get reviewedCheckIns =>
      checkIns.where((c) => c.status == 'REVIEWED').toList();
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerCheckInsNotifier extends StateNotifier<TrainerCheckInsState> {
  final ApiClient _api;

  TrainerCheckInsNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const TrainerCheckInsState());

  /// GET /api/trainer/check-ins?status=SUBMITTED
  /// Fetches all check-ins, optionally filtered by status.
  Future<void> fetchCheckIns({String? status}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerCheckIns,
        queryParams: queryParams,
      );

      final rawList = result['data'] as List<dynamic>? ?? [];
      final checkIns = rawList
          .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(
        checkIns: checkIns,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// GET /api/trainer/check-ins/[id]
  /// Fetches a single check-in with full detail.
  Future<void> fetchCheckInDetail(String id) async {
    state = state.copyWith(
      isLoadingDetail: true,
      clearError: true,
      selectedCheckIn: null,
    );

    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerCheckInDetail(id),
      );

      final raw = result['data'] as Map<String, dynamic>?;
      if (raw != null) {
        final checkIn = CheckIn.fromJson(raw);
        state = state.copyWith(
          selectedCheckIn: checkIn,
          isLoadingDetail: false,
        );
      } else {
        state = state.copyWith(
          isLoadingDetail: false,
          error: 'Failed to parse check-in detail',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingDetail: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// PATCH /api/trainer/check-ins/[id]/review
  /// Submits a trainer's review response for a check-in.
  Future<void> submitReview({
    required String checkInId,
    required String responseText,
    String status = 'REVIEWED',
  }) async {
    state = state.copyWith(
      isReviewing: true,
      clearReviewError: true,
    );

    try {
      final result = await _api.patch<Map<String, dynamic>>(
        ApiConstants.trainerCheckInReview(checkInId),
        body: {
          'trainer_response': responseText,
          'status': status,
        },
      );

      final raw = result['data'] as Map<String, dynamic>?;
      CheckIn? updated;
      if (raw != null) {
        updated = CheckIn.fromJson(raw);
      }

      // Update the check-in in the list and as selected
      final updatedCheckIns = state.checkIns.map((c) {
        if (c.id == checkInId) {
          return updated ?? c;
        }
        return c;
      }).toList();

      state = state.copyWith(
        checkIns: updatedCheckIns,
        selectedCheckIn: updated ?? state.selectedCheckIn,
        isReviewing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isReviewing: false,
        reviewError: _extractErrorMessage(e),
      );
    }
  }

  /// Clears errors.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearReviewError() {
    state = state.copyWith(clearReviewError: true);
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

final trainerCheckInsProvider = StateNotifierProvider<
    TrainerCheckInsNotifier, TrainerCheckInsState>((ref) {
  return TrainerCheckInsNotifier();
});
