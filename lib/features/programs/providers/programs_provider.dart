import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/template_exercise.dart';
import 'package:zirofit_fl/data/models/workout_program.dart';
import 'package:zirofit_fl/data/models/workout_template.dart';
import 'package:zirofit_fl/features/auth/providers/auth_provider.dart'
    show apiClientProvider;
import 'package:zirofit_fl/features/programs/data/program_template_remote_source.dart';
import 'package:zirofit_fl/features/programs/data/template_exercise_dao.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ProgramsState {
  final List<WorkoutProgram> userPrograms;
  final List<WorkoutProgram> systemPrograms;
  final List<WorkoutTemplate> userTemplates;
  final List<WorkoutTemplate> systemTemplates;
  final List<TemplateExercise> templateExercises;
  final String? editingTemplateId;
  final String? editingProgramId;
  final bool isLoading;
  final String? error;

  const ProgramsState({
    this.userPrograms = const [],
    this.systemPrograms = const [],
    this.userTemplates = const [],
    this.systemTemplates = const [],
    this.templateExercises = const [],
    this.editingTemplateId,
    this.editingProgramId,
    this.isLoading = false,
    this.error,
  });

  /// Backward compatible getter.
  List<WorkoutProgram> get programs => userPrograms;

  ProgramsState copyWith({
    List<WorkoutProgram>? userPrograms,
    List<WorkoutProgram>? systemPrograms,
    List<WorkoutTemplate>? userTemplates,
    List<WorkoutTemplate>? systemTemplates,
    List<TemplateExercise>? templateExercises,
    String? editingTemplateId,
    String? editingProgramId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearEditing = false,
  }) {
    return ProgramsState(
      userPrograms: userPrograms ?? this.userPrograms,
      systemPrograms: systemPrograms ?? this.systemPrograms,
      userTemplates: userTemplates ?? this.userTemplates,
      systemTemplates: systemTemplates ?? this.systemTemplates,
      templateExercises: templateExercises ?? this.templateExercises,
      editingTemplateId:
          clearEditing ? null : (editingTemplateId ?? this.editingTemplateId),
      editingProgramId:
          clearEditing ? null : (editingProgramId ?? this.editingProgramId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProgramsNotifier extends StateNotifier<ProgramsState> {
  final ApiClient _api;
  final ProgramTemplateRemoteSource _remoteSource;
  TemplateExerciseDao? _dao;

  ProgramsNotifier({
    ApiClient? apiClient,
    ProgramTemplateRemoteSource? remoteSource,
    TemplateExerciseDao? dao,
  }) : _api = apiClient ?? ApiClient.instance,
       _remoteSource = remoteSource ?? ProgramTemplateRemoteSource(Dio()),
       super(const ProgramsState()) {
    _dao = dao;
  }

  // ---------------------------------------------------------------------------
  // Fetch (backward compatible)
  // ---------------------------------------------------------------------------

  Future<void> fetchPrograms() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _api.get<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
      );

      final List<WorkoutProgram> programs;
      final rawData = response['data'];
      if (rawData is List) {
        programs = rawData
            .map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        programs = [];
      }

      state = ProgramsState(userPrograms: programs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch Programs & Templates
  // ---------------------------------------------------------------------------

  Future<void> fetchProgramsAndTemplates() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.fetchProgramsAndTemplates();
      final data = response['data'] as Map<String, dynamic>?;

      state = state.copyWith(
        userPrograms: _parseProgramList(data?['userPrograms']),
        systemPrograms: _parseProgramList(data?['systemPrograms']),
        userTemplates: _parseTemplateList(data?['userTemplates']),
        systemTemplates: _parseTemplateList(data?['systemTemplates']),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Create Program (backward compatible)
  // ---------------------------------------------------------------------------

  Future<WorkoutProgram?> createProgram(
    String name,
    String? description,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final body = <String, dynamic>{'name': name};
      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.trainerPrograms,
        body: body,
      );

      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) {
        final programData = rawData['program'] ?? rawData;
        if (programData is Map<String, dynamic>) {
          final program = WorkoutProgram.fromJson(programData);
          state = state.copyWith(
            userPrograms: [...state.userPrograms, program],
            isLoading: false,
          );
          return program;
        }
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Create Template
  // ---------------------------------------------------------------------------

  Future<WorkoutTemplate?> createTemplate({
    required String name,
    String? description,
    required String programId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response =
          await _remoteSource.createTemplate(name, description, programId);
      final data = response['data'];
      final templateData = data is Map<String, dynamic>
          ? (data['template'] as Map<String, dynamic>?)
          : null;

      if (templateData != null) {
        final template = WorkoutTemplate.fromJson(templateData);
        state = state.copyWith(
          userTemplates: [...state.userTemplates, template],
          editingTemplateId: template.id,
          editingProgramId: programId,
          isLoading: false,
        );
        return template;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Template Editing
  // ---------------------------------------------------------------------------

  Future<void> startEditingTemplate(
      String templateId, String programId) async {
    state = state.copyWith(
      editingTemplateId: templateId,
      editingProgramId: programId,
      isLoading: true,
    );

    try {
      final steps = _dao != null
          ? await _dao!.getByTemplateId(templateId)
          : <TemplateExercise>[];
      state = state.copyWith(templateExercises: steps, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        templateExercises: [],
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Add Exercise Step
  // ---------------------------------------------------------------------------

  Future<TemplateExercise?> addExerciseStep(
    Map<String, dynamic> fields,
  ) async {
    final templateId = state.editingTemplateId;
    if (templateId == null) {
      state = state.copyWith(error: 'No template is being edited');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _remoteSource.addExerciseStep(templateId, fields);
      final data = response['data'];
      final stepData = data is Map<String, dynamic>
          ? (data['templateExercise'] as Map<String, dynamic>?)
          : null;

      if (stepData != null) {
        final step = TemplateExercise.fromJson(stepData);
        if (_dao != null) {
          try { _dao!.insert(step); } catch (_) {}
        }
        state = state.copyWith(
          templateExercises: [...state.templateExercises, step],
          isLoading: false,
        );
        return step;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Add Rest Step
  // ---------------------------------------------------------------------------

  Future<TemplateExercise?> addRestStep(int durationSeconds) async {
    final templateId = state.editingTemplateId;
    if (templateId == null) {
      state = state.copyWith(error: 'No template is being edited');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response =
          await _remoteSource.addRestStep(templateId, durationSeconds);
      final data = response['data'];
      final stepData = data is Map<String, dynamic>
          ? (data['restStep'] as Map<String, dynamic>?)
          : null;

      if (stepData != null) {
        final step = TemplateExercise.fromJson(stepData);
        if (_dao != null) {
          try { _dao!.insert(step); } catch (_) {}
        }
        state = state.copyWith(
          templateExercises: [...state.templateExercises, step],
          isLoading: false,
        );
        return step;
      }

      state = state.copyWith(isLoading: false);
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Delete Exercise Step
  // ---------------------------------------------------------------------------

  Future<bool> deleteExerciseStep(String stepId) async {
    final templateId = state.editingTemplateId;
    if (templateId == null) {
      state = state.copyWith(error: 'No template is being edited');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _remoteSource.deleteExerciseStep(templateId, stepId);
      if (_dao != null) {
        try { _dao!.softDelete(stepId); } catch (_) {}
      }
      state = state.copyWith(
        templateExercises:
            state.templateExercises.where((s) => s.id != stepId).toList(),
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Copy Template
  // ---------------------------------------------------------------------------

  Future<bool> copyTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _remoteSource.copyTemplate(templateId);
      await fetchProgramsAndTemplates();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> refreshLocalSteps() async {
    final templateId = state.editingTemplateId;
    if (templateId == null || _dao == null) return;
    try {
      final steps = await _dao!.getByTemplateId(templateId);
      state = state.copyWith(templateExercises: steps);
    } catch (_) {}
  }

  List<WorkoutProgram> _parseProgramList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  List<WorkoutTemplate> _parseTemplateList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => WorkoutTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
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

final programsProvider =
    StateNotifierProvider<ProgramsNotifier, ProgramsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final remoteSource = ref.watch(programTemplateRemoteSourceProvider);
  final dao = ref.watch(templateExerciseDaoProvider);
  return ProgramsNotifier(
    apiClient: apiClient,
    remoteSource: remoteSource,
    dao: dao,
  );
});
