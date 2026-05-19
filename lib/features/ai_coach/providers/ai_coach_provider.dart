import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/ai_coach/services/live_coach_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class AICoachState {
  final String? generatedProgram;
  final String? goal;
  final bool isLoading;
  final String? error;
  final List<String> conversation;

  // Live coach fields
  final bool isListening;
  final bool isProcessing;
  final String? lastCoachMessage;
  final List<CoachResult> coachResponses;
  final String? activeWorkoutSessionId;

  const AICoachState({
    this.generatedProgram,
    this.goal,
    this.isLoading = false,
    this.error,
    this.conversation = const [],
    this.isListening = false,
    this.isProcessing = false,
    this.lastCoachMessage,
    this.coachResponses = const [],
    this.activeWorkoutSessionId,
  });

  AICoachState copyWith({
    String? generatedProgram,
    String? goal,
    bool? isLoading,
    String? error,
    List<String>? conversation,
    bool? isListening,
    bool? isProcessing,
    String? lastCoachMessage,
    List<CoachResult>? coachResponses,
    String? activeWorkoutSessionId,
    bool clearError = false,
    bool clearGeneratedProgram = false,
  }) {
    return AICoachState(
      generatedProgram:
          clearGeneratedProgram ? null : (generatedProgram ?? this.generatedProgram),
      goal: goal ?? this.goal,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      conversation: conversation ?? this.conversation,
      isListening: isListening ?? this.isListening,
      isProcessing: isProcessing ?? this.isProcessing,
      lastCoachMessage: lastCoachMessage ?? this.lastCoachMessage,
      coachResponses: coachResponses ?? this.coachResponses,
      activeWorkoutSessionId:
          activeWorkoutSessionId ?? this.activeWorkoutSessionId,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class AICoachNotifier extends StateNotifier<AICoachState> {
  final ApiClient _api;

  AICoachNotifier({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const AICoachState());

  /// POST /api/mobile/ai-coach/generate
  /// Generates a workout program based on the user's [goal].
  Future<void> generateProgram(String goal) async {
    state = state.copyWith(
      isLoading: true,
      goal: goal,
      clearError: true,
      clearGeneratedProgram: true,
    );

    try {
      final body = <String, dynamic>{
        'goal': goal,
      };

      final result = await _api.post<Map<String, dynamic>>(
        ApiConstants.aiCoachGenerate,
        body: body,
      );

      final program = result['program'] as String? ??
          result['data']?['program'] as String? ??
          result.toString();

      state = state.copyWith(
        isLoading: false,
        generatedProgram: program,
        conversation: [program],
      );
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
      );
    }
  }

  /// POST /api/mobile/ai-coach/refine
  /// Refines the generated program based on [userInput].
  Future<void> refineProgram(String userInput) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final body = <String, dynamic>{
        'goal': state.goal,
        'user_input': userInput,
        'current_program': state.generatedProgram,
        'conversation': state.conversation,
      };

      final result = await _api.post<Map<String, dynamic>>(
        ApiConstants.aiCoachRefine,
        body: body,
      );

      final refined = result['program'] as String? ??
          result['data']?['program'] as String? ??
          result.toString();

      final updatedConversation = [
        ...state.conversation,
        userInput,
        refined,
      ];

      state = state.copyWith(
        isLoading: false,
        generatedProgram: refined,
        conversation: updatedConversation,
      );
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        isLoading: false,
        error: message,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Live Coaching
  // ---------------------------------------------------------------------------

  /// Starts a live coaching session for the given [workoutSessionId].
  ///
  /// Resets coaching state and marks the session as active.
  void startCoaching(String workoutSessionId) {
    state = state.copyWith(
      activeWorkoutSessionId: workoutSessionId,
      coachResponses: [],
      lastCoachMessage: null,
      isListening: false,
      isProcessing: false,
      clearError: true,
    );
  }

  /// Processes a base64-encoded audio input through the AI coach.
  ///
  /// Sets [isProcessing] to `true` during the request, updates
  /// [coachResponses] and [lastCoachMessage] on completion.
  Future<void> processVoiceInput(String audioBase64) async {
    state = state.copyWith(
      isProcessing: true,
      isListening: false,
      clearError: true,
    );

    try {
      final service = LiveCoachService();
      final result = await service.processVoiceInput(audioBase64);

      await service.speakFeedback(result.message);

      state = state.copyWith(
        isProcessing: false,
        lastCoachMessage: result.message,
        coachResponses: [...state.coachResponses, result],
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Processes a text input through the AI coach (keyboard fallback).
  Future<void> processTextInput(String text) async {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      isProcessing: true,
      clearError: true,
    );

    try {
      final service = LiveCoachService();
      final result = await service.processTextInput(text);

      await service.speakFeedback(result.message);

      state = state.copyWith(
        isProcessing: false,
        lastCoachMessage: result.message,
        coachResponses: [...state.coachResponses, result],
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  /// Toggles the listening state for voice input.
  void setListening(bool value) {
    state = state.copyWith(isListening: value);
  }

  /// Stops the live coaching session and clears coaching-specific state.
  void stopCoaching() {
    state = state.copyWith(
      isListening: false,
      isProcessing: false,
      lastCoachMessage: null,
      coachResponses: [],
      activeWorkoutSessionId: null,
    );
  }

  /// Clears the error message.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Resets state to initial values.
  void reset() {
    state = const AICoachState();
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
      return 'Something went wrong. Please try again.';
    }
    return error.toString();
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final aiCoachProvider =
    StateNotifierProvider<AICoachNotifier, AICoachState>((ref) {
  return AICoachNotifier();
});
