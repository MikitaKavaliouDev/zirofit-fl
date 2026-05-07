import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerBrandingState {
  final String? bannerUrl;
  final String? avatarUrl;
  final bool isLoading;
  final bool isUploading;
  final double uploadProgress;
  final String? error;

  const TrainerBrandingState({
    this.bannerUrl,
    this.avatarUrl,
    this.isLoading = false,
    this.isUploading = false,
    this.uploadProgress = 0.0,
    this.error,
  });

  TrainerBrandingState copyWith({
    String? bannerUrl,
    String? avatarUrl,
    bool? isLoading,
    bool? isUploading,
    double? uploadProgress,
    String? error,
    bool clearError = false,
  }) {
    return TrainerBrandingState(
      bannerUrl: bannerUrl ?? this.bannerUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerBrandingNotifier extends StateNotifier<TrainerBrandingState> {
  final ApiClient _apiClient;

  TrainerBrandingNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerBrandingState());

  /// GET /api/trainer/profile/branding
  /// Fetches current banner and avatar URLs.
  Future<void> fetchBranding() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.trainerProfileBranding,
      );

      final data = response['data'] as Map<String, dynamic>? ?? response;

      state = state.copyWith(
        bannerUrl: data['banner_url'] as String?,
        avatarUrl: data['avatar_url'] as String?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// POST /api/trainer/profile/avatar
  /// Uploads a new avatar image via multipart.
  Future<void> uploadAvatar(String imagePath) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, clearError: true);

    try {
      final file = File(imagePath);
      final fileName = file.uri.pathSegments.last;

      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.trainerProfileAvatar,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      final responseData = response.data;
      final data = responseData?['data'] as Map<String, dynamic>? ?? responseData ?? {};

      state = state.copyWith(
        avatarUrl: data['url'] as String? ?? data['avatar_url'] as String?,
        isUploading: false,
        uploadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// POST /api/trainer/profile/banner
  /// Uploads a new banner image via multipart.
  Future<void> uploadBanner(String imagePath) async {
    state = state.copyWith(isUploading: true, uploadProgress: 0.0, clearError: true);

    try {
      final file = File(imagePath);
      final fileName = file.uri.pathSegments.last;

      final formData = FormData.fromMap({
        'banner': await MultipartFile.fromFile(
          imagePath,
          filename: fileName,
        ),
      });

      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        ApiConstants.trainerProfileBanner,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );

      final responseData = response.data;
      final data = responseData?['data'] as Map<String, dynamic>? ?? responseData ?? {};

      state = state.copyWith(
        bannerUrl: data['url'] as String? ?? data['banner_url'] as String?,
        isUploading: false,
        uploadProgress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadProgress: 0.0,
        error: _extractErrorMessage(e),
      );
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
            return 'Unauthorized. Please log in again.';
          }
          if (error.response?.statusCode == 413) {
            return 'File too large. Please choose a smaller image.';
          }
          if (error.response?.statusCode == 415) {
            return 'Unsupported file type. Please use JPEG or PNG.';
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

final trainerBrandingProvider =
    StateNotifierProvider<TrainerBrandingNotifier, TrainerBrandingState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerBrandingNotifier(apiClient: apiClient);
});
