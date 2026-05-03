import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/data/models/recipe.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart' show apiClientProvider;

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class RecipesState {
  final List<Recipe> recipes;
  final bool isLoading;
  final String? error;
  final bool isSaving;
  final String? successMessage;

  const RecipesState({
    this.recipes = const [],
    this.isLoading = false,
    this.error,
    this.isSaving = false,
    this.successMessage,
  });

  RecipesState copyWith({
    List<Recipe>? recipes,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSaving,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return RecipesState(
      recipes: recipes ?? this.recipes,
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

class RecipeNotifier extends StateNotifier<RecipesState> {
  final ApiClient _api;

  RecipeNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const RecipesState());

  /// Fetches all recipes for the trainer.
  Future<void> fetchRecipes() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerRecipes,
      );

      final List<Recipe> recipes;
      final rawData = response['data'];
      if (rawData is List) {
        recipes = rawData
            .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        recipes = [];
      }

      state = RecipesState(recipes: recipes, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Creates a new recipe from [data] and returns it.
  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerRecipes,
        body: data,
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final recipe = Recipe.fromJson(rawData);
        state = RecipesState(
          recipes: [...state.recipes, recipe],
          isLoading: false,
          isSaving: false,
          successMessage: 'Recipe created',
        );
        return recipe;
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

  /// Updates an existing recipe identified by [id] with [data] and returns it.
  Future<Recipe> updateRecipe(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final response = await _api.put<Map<String, dynamic>>(
        ApiConstants.trainerRecipe(id),
        body: data,
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final updated = Recipe.fromJson(rawData);
        state = RecipesState(
          recipes: state.recipes.map((r) => r.id == id ? updated : r).toList(),
          isLoading: false,
          isSaving: false,
          successMessage: 'Recipe updated',
        );
        return updated;
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

  /// Deletes a recipe by [id].
  Future<void> deleteRecipe(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _api.delete(ApiConstants.trainerRecipe(id));

      state = RecipesState(
        recipes: state.recipes.where((r) => r.id != id).toList(),
        isLoading: false,
        successMessage: 'Recipe deleted',
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

final recipesProvider =
    StateNotifierProvider<RecipeNotifier, RecipesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RecipeNotifier(apiClient: apiClient);
});
