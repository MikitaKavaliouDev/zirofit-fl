import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/exercise.dart';

/// Data source for exercise-related API calls.
class ExerciseRemoteSource {
  final ApiClient _apiClient;

  ExerciseRemoteSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// Searches exercises with optional filters and pagination.
  ///
  /// [search] - text search query
  /// [category] - filter by exercise category (e.g. "Strength", "Cardio")
  /// [muscleGroup] - filter by muscle group (e.g. "Chest", "Legs")
  /// [page] - page number (1-indexed)
  /// [limit] - results per page (default 50)
  Future<ApiResponse<List<Exercise>>> searchExercises({
    String? search,
    String? category,
    String? muscleGroup,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (muscleGroup != null && muscleGroup.isNotEmpty) {
      queryParams['muscle_group'] = muscleGroup;
    }

    return _apiClient.get<ApiResponse<List<Exercise>>>(
      ApiConstants.exercises,
      queryParams: queryParams,
      fromJson: (json) => apiResponseListFromJson<Exercise>(
        json,
        Exercise.fromJson,
      ),
    );
  }
}
