import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

/// Provider for ProgramTemplateRemoteSource.
final programTemplateRemoteSourceProvider =
    Provider<ProgramTemplateRemoteSource>((ref) {
  return ProgramTemplateRemoteSource(ApiClient.instance.dio);
});

/// Remote data source for all program and template API calls.
///
/// Communicates with the backend trainer/programs and exercises endpoints.
/// Each method returns the full response data map for the caller to parse.
class ProgramTemplateRemoteSource {
  final Dio _dio;

  ProgramTemplateRemoteSource(this._dio);

  /// GET /api/trainer/programs
  /// Returns nested programs and templates with full details.
  Future<Map<String, dynamic>> fetchProgramsAndTemplates() async {
    final response = await _dio.get(
      ApiConstants.trainerPrograms,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/trainer/programs?lightweight=true
  /// Returns lightweight templates for dropdowns/selectors.
  Future<Map<String, dynamic>> fetchLightweightPrograms() async {
    final response = await _dio.get(
      ApiConstants.trainerPrograms,
      queryParameters: {'lightweight': true},
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/trainer/programs
  /// Creates a new program with [name] and optional [description].
  Future<Map<String, dynamic>> createProgram(
    String name,
    String? description,
  ) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.trainerPrograms,
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/trainer/programs/templates
  /// Creates a new template inside a program.
  Future<Map<String, dynamic>> createTemplate(
    String name,
    String? description,
    String programId,
  ) async {
    final body = <String, dynamic>{
      'name': name,
      'programId': programId,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.trainerProgramTemplates,
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/trainer/programs/templates
  /// Fetches templates for calendar/template picker display.
  Future<Map<String, dynamic>> fetchTemplates() async {
    final response = await _dio.get(
      ApiConstants.trainerProgramTemplates,
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/trainer/programs/templates/{templateId}/exercises
  /// Adds an exercise step to a template with optional fields.
  Future<Map<String, dynamic>> addExerciseStep(
    String templateId,
    Map<String, dynamic> fields,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.templateExercises(templateId),
      data: fields,
    );
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/trainer/programs/templates/{templateId}/rest
  /// Adds a rest step with duration in seconds.
  Future<Map<String, dynamic>> addRestStep(
    String templateId,
    int durationSeconds,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.templateRest(templateId),
      data: {'durationSeconds': durationSeconds},
    );
    return response.data as Map<String, dynamic>;
  }

  /// DELETE /api/trainer/programs/templates/{templateId}/exercises/{stepId}
  /// Removes an exercise or rest step from a template.
  Future<void> deleteExerciseStep(
    String templateId,
    String stepId,
  ) async {
    await _dio.delete(
      ApiConstants.templateExerciseStep(templateId, stepId),
    );
  }

  /// POST /api/trainer/programs/templates/{templateId}/copy
  /// Deep-copies a system template to the user's own program.
  Future<Map<String, dynamic>> copyTemplate(String templateId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.templateCopy(templateId),
      data: null,
    );
    return response.data as Map<String, dynamic>;
  }

  /// GET /api/exercises?search=...&page=...&limit=...
  /// Searches exercises with optional text query and pagination.
  Future<Map<String, dynamic>> searchExercises({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    final response = await _dio.get(
      ApiConstants.exercises,
      queryParameters: queryParams,
    );
    return response.data as Map<String, dynamic>;
  }
}
