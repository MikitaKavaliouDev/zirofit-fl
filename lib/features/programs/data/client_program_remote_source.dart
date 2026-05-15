import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';

/// Provider for ClientProgramRemoteSource.
final clientProgramRemoteSourceProvider =
    Provider<ClientProgramRemoteSource>((ref) {
  return ClientProgramRemoteSource(ApiClient.instance.dio);
});

/// Remote data source for all client program and template API calls.
///
/// Communicates with the `/api/client/programs` endpoints for library
/// management, template building, and active program tracking.
/// Each method returns the full response data map for the caller to parse.
class ClientProgramRemoteSource {
  final Dio _dio;

  ClientProgramRemoteSource(this._dio);

  // ---------------------------------------------------------------------------
  // 1. GET /api/client/programs
  //    Full library with optional filters
  //    Query params: category, source, type
  // ---------------------------------------------------------------------------

  /// Fetches the client's full program/template library.
  ///
  /// Returns assigned programs, personal programs, personal templates,
  /// system templates, and available categories.
  Future<Map<String, dynamic>> fetchLibrary({
    String? category,
    String? source,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (source != null) queryParams['source'] = source;
    if (type != null) queryParams['type'] = type;

    final response = await _dio.get(
      ApiConstants.clientPrograms,
      queryParameters:
          queryParams.isNotEmpty ? queryParams : null,
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 2. POST /api/client/programs
  //    Create program (manual or AI — same endpoint, different body)
  // ---------------------------------------------------------------------------

  /// Creates a new program manually with [name] and optional [description].
  Future<Map<String, dynamic>> createManualProgram({
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clientPrograms,
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Creates a new AI-generated program with [duration] and [focus].
  ///
  /// [duration] is "week" or "month". [focus] is free text describing
  /// the training focus (e.g. "strength training").
  Future<Map<String, dynamic>> createAIProgram({
    required String duration,
    required String focus,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clientPrograms,
      data: {
        'duration': duration,
        'focus': focus,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 3. POST /api/client/programs/templates
  //    Create a template under a program
  // ---------------------------------------------------------------------------

  /// Creates a new template inside [programId] with [name] and optional description.
  Future<Map<String, dynamic>> createTemplate({
    required String name,
    String? description,
    required String programId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'programId': programId,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clientProgramTemplates,
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 4. POST /api/client/programs/templates/{templateId}/exercises
  //    Add an exercise step to a template
  // ---------------------------------------------------------------------------

  /// Adds an exercise step to [templateId] with the given [fields].
  ///
  /// Fields map supports: exerciseId, targetReps, targetSets, tempo,
  /// enableRpe, notes, exerciseCategory, durationSeconds, supersetGroupId,
  /// supersetOrder.
  Future<Map<String, dynamic>> addExerciseStep(
    String templateId,
    Map<String, dynamic> fields,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clientTemplateExercises(templateId),
      data: fields,
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 5. POST /api/client/programs/templates/{templateId}/rest
  //    Add a rest step to a template
  // ---------------------------------------------------------------------------

  /// Adds a rest step of [durationSeconds] to [templateId].
  Future<Map<String, dynamic>> addRestStep(
    String templateId,
    int durationSeconds,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clientTemplateRest(templateId),
      data: {'durationSeconds': durationSeconds},
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 6. DELETE /api/client/programs/templates/{templateId}/exercises/{stepId}
  //    Remove an exercise or rest step from a template
  // ---------------------------------------------------------------------------

  /// Removes the step [stepId] from template [templateId].
  Future<void> deleteExerciseStep(
    String templateId,
    String stepId,
  ) async {
    await _dio.delete(
      ApiConstants.clientTemplateExerciseStep(templateId, stepId),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. POST /api/client/programs/templates/{templateId}/copy
  //    Copy a system template to the user's own library
  // ---------------------------------------------------------------------------

  /// Deep-copies a system template (and its parent program if needed)
  /// into the authenticated user's library.
  Future<Map<String, dynamic>> copyTemplate(String templateId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.clientTemplateCopy(templateId),
      data: null,
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 8. GET /api/client/program/active
  //    Get active program with progress
  // ---------------------------------------------------------------------------

  /// Fetches the currently active assigned program with template-by-template
  /// progress information.
  Future<Map<String, dynamic>> fetchActiveProgram() async {
    final response = await _dio.get(
      ApiConstants.clientActiveProgram,
    );
    return response.data as Map<String, dynamic>;
  }

  // ---------------------------------------------------------------------------
  // 9. PUT /api/client/program/active
  //    Switch active program
  // ---------------------------------------------------------------------------

  /// Sets [programId] as the active program for the client.
  ///
  /// The program must be one the client has an assignment for.
  Future<Map<String, dynamic>> setActiveProgram(String programId) async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiConstants.clientActiveProgram,
      data: {'programId': programId},
    );
    return response.data as Map<String, dynamic>;
  }
}
