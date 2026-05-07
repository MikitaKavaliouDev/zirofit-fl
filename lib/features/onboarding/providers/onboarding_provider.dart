import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class OnboardingState {
  final int currentStep;
  final String? role;
  final String? name;
  final String? bio;
  final String? avatarPath;
  final double? height;
  final double? weight;
  final String? experienceLevel;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.role,
    this.name,
    this.bio,
    this.avatarPath,
    this.height,
    this.weight,
    this.experienceLevel,
    this.isLoading = false,
    this.error,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? role,
    String? name,
    String? bio,
    String? avatarPath,
    double? height,
    double? weight,
    String? experienceLevel,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      role: role ?? this.role,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ApiClient _apiClient;
  final Future<void> Function() _onComplete;

  OnboardingNotifier({
    required ApiClient apiClient,
    required Future<void> Function() onComplete,
  })  : _apiClient = apiClient,
        _onComplete = onComplete,
        super(const OnboardingState());

  // -- Step navigation --

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  // -- Field setters --

  void setRole(String role) {
    state = state.copyWith(role: role);
  }

  void setProfile(String name, String? bio, String? avatarPath) {
    state = state.copyWith(name: name, bio: bio, avatarPath: avatarPath);
  }

  void setStats(double height, double weight, String experienceLevel) {
    state = state.copyWith(
      height: height,
      weight: weight,
      experienceLevel: experienceLevel,
    );
  }

  // -- Submit --

  Future<void> submit() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.post(
        ApiConstants.completeOnboarding,
        body: {
          'role': state.role,
          'name': state.name,
          'bio': state.bio,
          'avatarPath': state.avatarPath,
          'height': state.height,
          'weight': state.weight,
          'experienceLevel': state.experienceLevel,
        },
      );

      await _onComplete();

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

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authNotifier = ref.read(authProvider.notifier);
  return OnboardingNotifier(
    apiClient: apiClient,
    onComplete: () => authNotifier.completeOnboarding(),
  );
});
