import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// DaySchedule model
// ---------------------------------------------------------------------------

class DaySchedule {
  final String day;
  bool isOpen;
  String startTime;
  String endTime;

  DaySchedule({
    required this.day,
    this.isOpen = true,
    this.startTime = '09:00',
    this.endTime = '17:00',
  });

  Map<String, dynamic> toJson() => {
        'day': day,
        'isOpen': isOpen,
        'startTime': startTime,
        'endTime': endTime,
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        day: json['day'] as String? ?? '',
        isOpen: json['isOpen'] as bool? ?? false,
        startTime: json['startTime'] as String? ?? '09:00',
        endTime: json['endTime'] as String? ?? '17:00',
      );

  DaySchedule copyWith({
    String? day,
    bool? isOpen,
    String? startTime,
    String? endTime,
  }) {
    return DaySchedule(
      day: day ?? this.day,
      isOpen: isOpen ?? this.isOpen,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class WorkingHoursState {
  final List<DaySchedule> days;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  const WorkingHoursState({
    this.days = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  WorkingHoursState copyWith({
    List<DaySchedule>? days,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return WorkingHoursState(
      days: days ?? this.days,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WorkingHoursNotifier extends StateNotifier<WorkingHoursState> {
  final ApiClient _api;

  WorkingHoursNotifier({required ApiClient apiClient})
      : _api = apiClient,
        super(WorkingHoursState(days: _defaultDays()));

  static List<DaySchedule> _defaultDays() => [
        DaySchedule(day: 'Monday', isOpen: true, startTime: '09:00', endTime: '17:00'),
        DaySchedule(day: 'Tuesday', isOpen: true, startTime: '09:00', endTime: '17:00'),
        DaySchedule(day: 'Wednesday', isOpen: true, startTime: '09:00', endTime: '17:00'),
        DaySchedule(day: 'Thursday', isOpen: true, startTime: '09:00', endTime: '17:00'),
        DaySchedule(day: 'Friday', isOpen: true, startTime: '09:00', endTime: '17:00'),
        DaySchedule(day: 'Saturday', isOpen: false, startTime: '10:00', endTime: '14:00'),
        DaySchedule(day: 'Sunday', isOpen: false, startTime: '10:00', endTime: '14:00'),
      ];

  // -- Load working hours --

  Future<void> loadWorkingHours() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerSettings,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;
      final workingHoursRaw = data['workingHours'] as List<dynamic>?;

      if (workingHoursRaw != null && workingHoursRaw.isNotEmpty) {
        final days = workingHoursRaw
            .map((e) => DaySchedule.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(days: days, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      // On error, keep defaults — don't block the UI
      state = state.copyWith(isLoading: false);
    }
  }

  // -- Save working hours --

  Future<bool> saveWorkingHours() async {
    state = state.copyWith(isSaving: true, clearError: true, clearSuccess: true);

    try {
      await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerSettings,
        body: {
          'workingHours': state.days.map((d) => d.toJson()).toList(),
        },
      );

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Working hours saved successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // -- Update a day --

  void updateDay(int index, DaySchedule updated) {
    final days = [...state.days];
    days[index] = updated;
    state = state.copyWith(days: days, clearError: true, clearSuccess: true);
  }

  void toggleDay(int index) {
    final days = [...state.days];
    days[index].isOpen = !days[index].isOpen;
    state = state.copyWith(days: days, clearError: true, clearSuccess: true);
  }

  void updateDayTime(int index, {String? startTime, String? endTime}) {
    final days = [...state.days];
    if (startTime != null) days[index].startTime = startTime;
    if (endTime != null) days[index].endTime = endTime;
    state = state.copyWith(days: days, clearError: true, clearSuccess: true);
  }

  // -- Helpers --

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
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
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final workingHoursProvider =
    StateNotifierProvider<WorkingHoursNotifier, WorkingHoursState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkingHoursNotifier(apiClient: apiClient);
});
