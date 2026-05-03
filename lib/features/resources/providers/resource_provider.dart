import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/data/models/resource.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ResourcesState {
  final List<Resource> resources;
  final bool isLoading;
  final String? error;
  final bool isSaving;
  final String? successMessage;

  const ResourcesState({
    this.resources = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
    this.successMessage,
  });

  ResourcesState copyWith({
    List<Resource>? resources,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return ResourcesState(
      resources: resources ?? this.resources,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSaving: isSaving ?? this.isSaving,
      successMessage:
          clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ResourceNotifier extends StateNotifier<ResourcesState> {
  final ApiClient _api;

  ResourceNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const ResourcesState());

  /// Fetches all resources from the vault.
  Future<void> fetchResources() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerResourceVault,
      );

      final List<Resource> resources;
      final rawData = response['data'];
      if (rawData is List) {
        resources = rawData
            .map((e) => Resource.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        resources = [];
      }

      state = ResourcesState(resources: resources, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a new resource from [data] and returns it.
  Future<Resource> createResource(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerResourceVault,
        body: data,
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final resource = Resource.fromJson(rawData);
        state = ResourcesState(
          resources: [...state.resources, resource],
          isLoading: false,
          isSaving: false,
          successMessage: 'Resource created',
        );
        return resource;
      }

      state = state.copyWith(isSaving: false);
      throw const ApiException('Invalid response from server');
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Deletes a resource by [id].
  Future<void> deleteResource(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.delete(ApiConstants.trainerResource(id));

      state = ResourcesState(
        resources: state.resources.where((r) => r.id != id).toList(),
        isLoading: false,
        successMessage: 'Resource deleted',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Clears the success message.
  void clearSuccessMessage() {
    state = state.copyWith(clearSuccessMessage: true);
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

final resourcesProvider =
    StateNotifierProvider<ResourceNotifier, ResourcesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ResourceNotifier(apiClient: apiClient);
});
