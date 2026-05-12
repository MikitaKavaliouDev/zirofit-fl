import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// =============================================================================
// Enums
// =============================================================================

/// Fitness experience level (iOS parity: Beginner → Elite).
enum ExperienceLevel {
  beginner('Beginner', 'New to fitness or returning after a long break'),
  intermediate('Intermediate', 'Consistent training for 6+ months'),
  advanced('Advanced', '2+ years of dedicated training'),
  expert('Expert', 'Competitive athlete or professional coach');

  final String label;
  final String description;
  const ExperienceLevel(this.label, this.description);
}

/// Fitness goal options for multi-select.
enum FitnessGoal {
  weightLoss('Weight Loss', Icons.monitor_weight_rounded),
  muscleGain('Muscle Gain', Icons.fitness_center_rounded),
  endurance('Endurance', Icons.directions_run_rounded),
  flexibility('Flexibility', Icons.self_improvement_rounded),
  generalHealth('General Health', Icons.trending_up_rounded),
  sportSpecific('Sport Specific', Icons.sports_rounded),
  rehabilitation('Rehabilitation', Icons.healing_rounded),
  other('Other', Icons.more_horiz_rounded);

  final String label;
  final IconData icon;
  const FitnessGoal(this.label, this.icon);
}

/// Permission types requested during onboarding.
enum PermissionType {
  camera('Camera', Icons.camera_alt_rounded),
  microphone('Microphone', Icons.mic_rounded),
  notifications('Notifications', Icons.notifications_rounded),
  location('Location', Icons.location_on_rounded);

  final String label;
  final IconData icon;
  const PermissionType(this.label, this.icon);
}

/// Status of a permission request.
enum PermissionStatus { unknown, granted, denied }

// =============================================================================
// Helpers
// =============================================================================

/// Returns the total number of onboarding steps (always 8 for this version).
int onboardingTotalSteps(String? role) => 8;

// =============================================================================
// State
// =============================================================================

class OnboardingState {
  final int currentStep;
  final String? role;

  // Step 0 – Welcome (no fields)

  // Step 1 – Map Location
  final double? latitude;
  final double? longitude;
  final String? address;

  // Step 2 – Avatar Photo
  final String? avatarPath;

  // Step 3 – Physical Stats
  final double? height; // cm
  final double? weight; // kg
  final int? age;
  final String? gender; // male, female, other

  // Step 4 – Experience Level
  final ExperienceLevel experienceLevel;

  // Step 5 – Fitness Goals
  final List<FitnessGoal> fitnessGoals;

  // Step 6 – Trainer Finder
  final String? trainerId;

  // Step 7 – Permissions
  final Map<PermissionType, PermissionStatus> permissions;

  // Shared
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.role,
    this.latitude,
    this.longitude,
    this.address,
    this.avatarPath,
    this.height,
    this.weight,
    this.age,
    this.gender,
    this.experienceLevel = ExperienceLevel.beginner,
    this.fitnessGoals = const [],
    this.trainerId,
    this.permissions = const {
      PermissionType.camera: PermissionStatus.unknown,
      PermissionType.microphone: PermissionStatus.unknown,
      PermissionType.notifications: PermissionStatus.unknown,
      PermissionType.location: PermissionStatus.unknown,
    },
    this.isLoading = false,
    this.error,
  });

  /// Total steps (always 8).
  int get totalSteps => 8;

  /// Number of granted permissions.
  int get grantedPermissionsCount =>
      permissions.values.where((s) => s == PermissionStatus.granted).length;

  /// Whether at least one fitness goal is selected.
  bool get hasFitnessGoals => fitnessGoals.isNotEmpty;

  OnboardingState copyWith({
    int? currentStep,
    String? role,
    double? latitude,
    double? longitude,
    String? address,
    String? avatarPath,
    double? height,
    double? weight,
    int? age,
    String? gender,
    ExperienceLevel? experienceLevel,
    List<FitnessGoal>? fitnessGoals,
    String? trainerId,
    Map<PermissionType, PermissionStatus>? permissions,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      avatarPath: avatarPath ?? this.avatarPath,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      trainerId: trainerId ?? this.trainerId,
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// =============================================================================
// Notifier
// =============================================================================

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ApiClient _apiClient;
  final Future<void> Function(String? role) _onComplete;

  OnboardingNotifier({
    required ApiClient apiClient,
    required Future<void> Function(String? role) onComplete,
  })  : _apiClient = apiClient,
        _onComplete = onComplete,
        super(const OnboardingState());

  // -- Step navigation --

  void nextStep() {
    final maxStep = state.totalSteps - 1;
    if (state.currentStep < maxStep) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // -- Field setters --

  void setLocation({double? latitude, double? longitude, String? address}) {
    state = state.copyWith(
      latitude: latitude ?? state.latitude,
      longitude: longitude ?? state.longitude,
      address: address ?? state.address,
    );
  }

  void setAvatarPath(String path) {
    state = state.copyWith(avatarPath: path);
  }

  void setPhysicalStats({
    double? height,
    double? weight,
    int? age,
    String? gender,
  }) {
    state = state.copyWith(
      height: height ?? state.height,
      weight: weight ?? state.weight,
      age: age ?? state.age,
      gender: gender ?? state.gender,
    );
  }

  void setExperienceLevel(ExperienceLevel level) {
    state = state.copyWith(experienceLevel: level);
  }

  void toggleFitnessGoal(FitnessGoal goal) {
    final goals = List<FitnessGoal>.from(state.fitnessGoals);
    if (goals.contains(goal)) {
      goals.remove(goal);
    } else {
      goals.add(goal);
    }
    state = state.copyWith(fitnessGoals: goals);
  }

  void setTrainerId(String? id) {
    state = state.copyWith(trainerId: id);
  }

  void setPermission(PermissionType type, PermissionStatus status) {
    final updated = Map<PermissionType, PermissionStatus>.from(state.permissions)
      ..[type] = status;
    state = state.copyWith(permissions: updated);
  }

  // -- Submit --

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.post(
        ApiConstants.completeOnboarding,
        body: {
          'role': state.role ?? 'client',
          'avatarPath': state.avatarPath,
          'height': state.height,
          'weight': state.weight,
          'age': state.age,
          'gender': state.gender,
          'experienceLevel': state.experienceLevel.name,
          'goals': state.fitnessGoals.map((g) => g.name).toList(),
          if (state.latitude != null && state.longitude != null) ...{
            'location': {
              'lat': state.latitude,
              'lng': state.longitude,
              if (state.address != null) 'address': state.address,
            },
          },
          if (state.trainerId != null) 'trainerId': state.trainerId,
          'permissions': {
            for (final entry in state.permissions.entries)
              entry.key.name: entry.value.name,
          },
        },
      );

      // Mark onboarding complete in shared prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);

      await _onComplete(state.role);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // -- Helpers --

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
        case DioExceptionType.badResponse:
          if (error.response?.statusCode == 401) {
            return 'Session expired. Please log in again.';
          }
          if (error.response?.statusCode == 429) {
            return 'Too many attempts. Please try again later.';
          }
          break;
        default:
          break;
      }
      return 'Network error. Please try again.';
    }
    return error.toString();
  }
}

// =============================================================================
// Provider
// =============================================================================

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return OnboardingNotifier(
    apiClient: apiClient,
    onComplete: (role) => authNotifier.completeOnboarding(role: role),
  );
});
