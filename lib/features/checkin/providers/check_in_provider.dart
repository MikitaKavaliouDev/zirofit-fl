import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/check_in.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class CheckInState {
  final bool isSubmitting;
  final bool isSuccess;
  final String? error;
  final CheckIn? lastCheckIn;

  const CheckInState({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.error,
    this.lastCheckIn,
  });

  CheckInState copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? error,
    CheckIn? lastCheckIn,
    bool clearError = false,
  }) {
    return CheckInState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      error: clearError ? null : (error ?? this.error),
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class CheckInNotifier extends StateNotifier<CheckInState> {
  final ApiClient _api;

  CheckInNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const CheckInState());

  /// POST /api/client/check-in
  /// Submits a weekly check-in with optional progress photo.
  Future<void> submitCheckIn({
    required DateTime date,
    required double weight,
    double? waistCm,
    double? sleepHours,
    int? energyLevel,
    int? stressLevel,
    int? hungerLevel,
    int? digestionLevel,
    String? nutritionCompliance,
    String? clientNotes,
    XFile? photo,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final body = <String, dynamic>{
        'weight': weight,
      };

      if (waistCm != null) body['waistCm'] = waistCm;
      if (sleepHours != null) body['sleepHours'] = sleepHours;
      if (energyLevel != null) body['energyLevel'] = energyLevel;
      if (stressLevel != null) body['stressLevel'] = stressLevel;
      if (hungerLevel != null) body['hungerLevel'] = hungerLevel;
      if (digestionLevel != null) body['digestionLevel'] = digestionLevel;
      if (nutritionCompliance != null) {
        final parsed = int.tryParse(nutritionCompliance);
        if (parsed != null) body['nutritionCompliance'] = parsed;
      }
      if (clientNotes != null && clientNotes.isNotEmpty) {
        body['clientNotes'] = clientNotes;
      }

      CheckIn? created;

      if (photo != null) {
        // Multipart upload when a photo is attached
        final formData = FormData.fromMap({
          ...body,
          'photo': await MultipartFile.fromFile(
            photo.path,
            filename: photo.name,
          ),
        });
        final dioResponse = await _api.dio.post(
          ApiConstants.clientCheckIn,
          data: formData,
        );
        final raw =
            dioResponse.data?['data'] as Map<String, dynamic>?;
        if (raw != null) {
          created = CheckIn.fromJson(raw);
        }
      } else {
        final result = await _api.post<Map<String, dynamic>>(
          ApiConstants.clientCheckIn,
          body: body,
        );
        final raw = result['data'] as Map<String, dynamic>?;
        if (raw != null) {
          created = CheckIn.fromJson(raw);
        }
      }

      state = CheckInState(
        isSuccess: true,
        lastCheckIn: created,
      );
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isSubmitting: false,
        error: message,
      );
    }
  }

  /// GET /api/client/check-in
  /// Fetches the most recent check-in.
  Future<void> fetchLastCheckIn() async {
    try {
      final result = await _api.get<Map<String, dynamic>>(
        ApiConstants.clientCheckIn,
      );
      final raw = result['data'] as Map<String, dynamic>?;
      if (raw != null) {
        final checkIn = CheckIn.fromJson(raw);
        state = state.copyWith(lastCheckIn: checkIn);
      }
    } catch (_) {
      // Silently ignore - the screen handles missing data gracefully
    }
  }

  /// Resets to initial state (e.g. after navigating away).
  void reset() {
    state = const CheckInState();
  }

  /// Clears the error message.
  void clearError() {
    state = state.copyWith(clearError: true);
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

final checkInProvider =
    StateNotifierProvider<CheckInNotifier, CheckInState>((ref) {
  return CheckInNotifier();
});
