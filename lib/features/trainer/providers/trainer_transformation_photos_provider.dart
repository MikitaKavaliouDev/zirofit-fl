import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/transformation_photo_pair.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TrainerTransformationPhotosState {
  final List<TransformationPhotoPair> photos;
  final bool isLoading;
  final bool isUploading;
  final String? error;

  const TrainerTransformationPhotosState({
    this.photos = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
  });

  TrainerTransformationPhotosState copyWith({
    List<TransformationPhotoPair>? photos,
    bool? isLoading,
    bool? isUploading,
    String? error,
    bool clearError = false,
  }) {
    return TrainerTransformationPhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TrainerTransformationPhotosNotifier
    extends StateNotifier<TrainerTransformationPhotosState> {
  final ApiClient _apiClient;

  TrainerTransformationPhotosNotifier({required ApiClient apiClient})
      : _apiClient = apiClient,
        super(const TrainerTransformationPhotosState());

  // -- Fetch all transformation photos --

  Future<void> fetchPhotos() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _apiClient.get<List<TransformationPhotoPair>>(
        ApiConstants.profileMeTransformations,
        fromJson: (json) {
          final raw = json['data'] as List<dynamic>?;
          if (raw == null) return <TransformationPhotoPair>[];
          return raw
              .map((e) => TransformationPhotoPair.fromJson(
                  e as Map<String, dynamic>))
              .toList();
        },
      );

      state = state.copyWith(
        photos: response,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // -- Upload transformation photo pair (multipart) --

  Future<String?> uploadPhotos({
    required String beforeImagePath,
    required String afterImagePath,
    String? caption,
    DateTime? date,
  }) async {
    state = state.copyWith(isUploading: true, clearError: true);

    try {
      final formData = FormData.fromMap({
        'before_image': await MultipartFile.fromFile(beforeImagePath),
        'after_image': await MultipartFile.fromFile(afterImagePath),
        'caption': ?caption,
        'date': (date ?? DateTime.now())
            .toIso8601String()
            .split('T')[0],
      });

      await _apiClient.dio.post(
        ApiConstants.profileMeTransformations,
        data: formData,
      );

      // Refresh list after upload
      await fetchPhotos();
      state = state.copyWith(isUploading: false);
      return null;
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      state = state.copyWith(
        isUploading: false,
        error: errorMsg,
      );
      return errorMsg;
    }
  }

  // -- Delete a transformation photo pair --

  Future<void> deletePhoto(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _apiClient.delete(
        '${ApiConstants.profileMeTransformations}/$id',
      );

      state = state.copyWith(
        photos: state.photos.where((p) => p.id != id).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
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

final trainerTransformationPhotosProvider = StateNotifierProvider<
    TrainerTransformationPhotosNotifier,
    TrainerTransformationPhotosState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TrainerTransformationPhotosNotifier(apiClient: apiClient);
});
