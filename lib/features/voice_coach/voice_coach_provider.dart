import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/voice_coach/voice_coach_models.dart';

export 'voice_coach_models.dart';

// ---------------------------------------------------------------------------
// SharedPreferences keys
// ---------------------------------------------------------------------------

const _kVoiceMode = 'voice_coach_mode';
const _kSelectedVoiceId = 'voice_coach_selected_voice_id';

// ---------------------------------------------------------------------------
// DialogueEntry
// ---------------------------------------------------------------------------

/// A single entry in the coach dialogue history.
class DialogueEntry {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const DialogueEntry({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// ---------------------------------------------------------------------------
// VoiceCoachState
// ---------------------------------------------------------------------------

/// Observable state of the voice coach manager.
class VoiceCoachState {
  final VoiceMode voiceMode;
  final String? selectedVoiceId;
  final VoiceSettingsValues voiceSettings;
  final List<VoiceModel> voices;
  final bool isLoading;
  final bool isRecording;
  final bool isProcessing;
  final bool isSpeaking;
  final double audioLevel;
  final String transcription;
  final String coachTextResponse;
  final List<DialogueEntry> dialogueHistory;
  final String? error;

  const VoiceCoachState({
    this.voiceMode = VoiceMode.dictation,
    this.selectedVoiceId,
    this.voiceSettings = const VoiceSettingsValues(),
    this.voices = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.isProcessing = false,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
    this.transcription = '',
    this.coachTextResponse = '',
    this.dialogueHistory = const [],
    this.error,
  });

  VoiceModel? get selectedVoice =>
      voices.where((v) => v.voiceId == selectedVoiceId).firstOrNull;

  VoiceCoachState copyWith({
    VoiceMode? voiceMode,
    String? selectedVoiceId,
    VoiceSettingsValues? voiceSettings,
    List<VoiceModel>? voices,
    bool? isLoading,
    bool? isRecording,
    bool? isProcessing,
    bool? isSpeaking,
    double? audioLevel,
    String? transcription,
    String? coachTextResponse,
    List<DialogueEntry>? dialogueHistory,
    String? error,
    bool clearError = false,
    bool clearSelectedVoiceId = false,
  }) {
    return VoiceCoachState(
      voiceMode: voiceMode ?? this.voiceMode,
      selectedVoiceId: clearSelectedVoiceId
          ? null
          : (selectedVoiceId ?? this.selectedVoiceId),
      voiceSettings: voiceSettings ?? this.voiceSettings,
      voices: voices ?? this.voices,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      isProcessing: isProcessing ?? this.isProcessing,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
      transcription: transcription ?? this.transcription,
      coachTextResponse: coachTextResponse ?? this.coachTextResponse,
      dialogueHistory: dialogueHistory ?? this.dialogueHistory,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// VoiceCoachManager
// ---------------------------------------------------------------------------

/// Central state manager for the AI Voice Coach feature.
class VoiceCoachManager extends StateNotifier<VoiceCoachState> {
  final ApiClient _api;

  VoiceCoachManager({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance,
        super(const VoiceCoachState()) {
    _loadPersistedPreferences();
  }

  // ===========================================================================
  // Persistence
  // ===========================================================================

  Future<void> _loadPersistedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_kVoiceMode);
      final savedVoiceId = prefs.getString(_kSelectedVoiceId);
      state = state.copyWith(
        voiceMode: modeString != null
            ? VoiceMode.values.firstWhere(
                (m) => m.name == modeString,
                orElse: () => VoiceMode.dictation,
              )
            : VoiceMode.dictation,
        selectedVoiceId: savedVoiceId,
      );
    } catch (e) {
      debugPrint('[VoiceCoach] Failed to load preferences: ');
    }
  }

  Future<void> _persistVoiceMode(VoiceMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kVoiceMode, mode.name);
    } catch (e) {
      debugPrint('[VoiceCoach] Failed to persist voice mode: ');
    }
  }

  Future<void> _persistSelectedVoiceId(String? voiceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (voiceId != null) {
        await prefs.setString(_kSelectedVoiceId, voiceId);
      } else {
        await prefs.remove(_kSelectedVoiceId);
      }
    } catch (e) {
      debugPrint('[VoiceCoach] Failed to persist voice ID: ');
    }
  }

  // ===========================================================================
  // Loading
  // ===========================================================================

  Future<void> loadSettingsAndVoices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      try {
        final response = await _api.get<Map<String, dynamic>>(
          ApiConstants.userVoiceSettings,
        );
        final data = response['data'] as Map<String, dynamic>? ?? response;
        final voiceId =
            data['voice_id'] as String? ?? data['voiceId'] as String?;
        final settingsMap = data['settings'] as Map<String, dynamic>? ?? data;
        if (voiceId != null) {
          state = state.copyWith(selectedVoiceId: voiceId);
          await _persistSelectedVoiceId(voiceId);
        }
        state = state.copyWith(
          voiceSettings: VoiceSettingsValues.fromJson(settingsMap),
        );
      } catch (e) {
        debugPrint('[VoiceCoach] Failed to fetch voice settings: ');
      }

      try {
        final voicesResponse = await _api.get<Map<String, dynamic>>(
          ApiConstants.aiTrainerVoices,
        );
        final data =
            voicesResponse['data'] as Map<String, dynamic>? ?? voicesResponse;
        final voicesList = data['voices'] as List<dynamic>?;
        if (voicesList != null) {
          final voices = voicesList
              .map((v) => VoiceModel.fromJson(v as Map<String, dynamic>))
              .toList();
          state = state.copyWith(voices: voices);
          if (state.selectedVoiceId == null && voices.isNotEmpty) {
            state = state.copyWith(selectedVoiceId: voices.first.voiceId);
          }
        }
      } catch (e) {
        debugPrint('[VoiceCoach] Failed to fetch voices: ');
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  // ===========================================================================
  // Voice Mode
  // ===========================================================================

  Future<void> setVoiceMode(VoiceMode mode) async {
    state = state.copyWith(voiceMode: mode, clearError: true);
    await _persistVoiceMode(mode);
  }

  // ===========================================================================
  // Voices
  // ===========================================================================

  void setVoices(List<VoiceModel> voices) {
    state = state.copyWith(voices: voices, isLoading: false);
    if (state.selectedVoiceId == null && voices.isNotEmpty) {
      state = state.copyWith(selectedVoiceId: voices.first.voiceId);
    }
  }

  void setLoadingVoices() {
    state = state.copyWith(isLoading: true, clearError: true);
  }

  void setVoicesError(String error) {
    state = state.copyWith(isLoading: false, error: error);
  }

  // ===========================================================================
  // Voice Selection
  // ===========================================================================

  Future<void> selectVoice(String voiceId) async {
    state = state.copyWith(selectedVoiceId: voiceId, clearError: true);
    await _persistSelectedVoiceId(voiceId);
    try {
      await _api.put(
        ApiConstants.userVoiceSettings,
        body: {
          'voice_id': voiceId,
          'settings': state.voiceSettings.toJson(),
        },
      );
    } catch (e) {
      debugPrint('[VoiceCoach] Failed to save voice selection: ');
      state = state.copyWith(error: _extractErrorMessage(e));
    }
  }

  // ===========================================================================
  // Voice Settings
  // ===========================================================================

  Future<void> updateVoiceSettings(VoiceSettingsValues settings) async {
    state = state.copyWith(voiceSettings: settings, clearError: true);
    try {
      await _api.put(
        ApiConstants.userVoiceSettings,
        body: {
          'voice_id': state.selectedVoiceId,
          'settings': settings.toJson(),
        },
      );
    } catch (e) {
      debugPrint('[VoiceCoach] Failed to update voice settings: ');
      state = state.copyWith(error: _extractErrorMessage(e));
    }
  }

  void setStability(double value) {
    state = state.copyWith(
      voiceSettings: state.voiceSettings.copyWith(stability: value),
    );
  }

  void setSimilarityBoost(double value) {
    state = state.copyWith(
      voiceSettings: state.voiceSettings.copyWith(similarityBoost: value),
    );
  }

  void setStyle(double value) {
    state = state.copyWith(
      voiceSettings: state.voiceSettings.copyWith(style: value),
    );
  }

  void setUseSpeakerBoost(bool value) {
    state = state.copyWith(
      voiceSettings: state.voiceSettings.copyWith(useSpeakerBoost: value),
    );
  }

  void setSpeed(double value) {
    state = state.copyWith(
      voiceSettings: state.voiceSettings.copyWith(speed: value),
    );
  }

  // ===========================================================================
  // Recording
  // ===========================================================================

  void setRecording(bool value) {
    state = state.copyWith(
      isRecording: value,
      audioLevel: value ? state.audioLevel : 0.0,
    );
    if (value) {
      state = state.copyWith(
        transcription: '',
        coachTextResponse: '',
        clearError: true,
      );
    }
  }

  void setAudioLevel(double level) {
    state = state.copyWith(audioLevel: level.clamp(0.0, 1.0));
  }

  Future<VoiceCoachResponse?> stopAndProcessRecording({
    required String audioBase64,
    String? sessionId,
  }) async {
    if (!state.isRecording) return null;
    state = state.copyWith(
      isRecording: false,
      isProcessing: true,
      clearError: true,
    );
    try {
      final body = <String, dynamic>{
        'audio': audioBase64,
        'session_id': ?sessionId,
      };
      final response = await _api.post<Map<String, dynamic>>(
        ApiConstants.aiVoice,
        body: body,
      );
      final data = response['data'] as Map<String, dynamic>? ?? response;
      final coachResponse = VoiceCoachResponse.fromJson(data);
      final newHistory = <DialogueEntry>[
        ...state.dialogueHistory,
        if (coachResponse.transcript != null &&
            coachResponse.transcript!.isNotEmpty)
          DialogueEntry(
            text: coachResponse.transcript!,
            isUser: true,
            timestamp: DateTime.now(),
          ),
        if (coachResponse.coachResponse != null &&
            coachResponse.coachResponse!.isNotEmpty)
          DialogueEntry(
            text: coachResponse.coachResponse!,
            isUser: false,
            timestamp: DateTime.now(),
          ),
      ];
      state = state.copyWith(
        isProcessing: false,
        transcription: coachResponse.transcript ?? '',
        coachTextResponse: coachResponse.coachResponse ?? '',
        dialogueHistory: newHistory,
      );
      if (coachResponse.coachResponse != null &&
          coachResponse.coachResponse!.isNotEmpty) {
        await playCoachTts(
          coachResponse.coachResponse!,
          streamUrl: coachResponse.streamUrl,
        );
      }
      return coachResponse;
    } catch (e) {
      final errorMsg = _extractErrorMessage(e);
      const fallbackText =
          'Sorry, I had trouble processing that. Can you repeat it?';
      state = state.copyWith(
        isProcessing: false,
        error: errorMsg,
        coachTextResponse: fallbackText,
        dialogueHistory: [
          ...state.dialogueHistory,
          DialogueEntry(
            text: fallbackText,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );
      await playCoachTts(state.coachTextResponse);
      return null;
    }
  }

  // ===========================================================================
  // Transcription / Response
  // ===========================================================================

  void setTranscription(String text) {
    state = state.copyWith(transcription: text);
  }

  void setCoachResponse(String text) {
    state = state.copyWith(coachTextResponse: text);
  }

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  void setSpeaking(bool value) {
    state = state.copyWith(isSpeaking: value);
  }

  // ===========================================================================
  // Dialogue History
  // ===========================================================================

  void addUserDialogue(String text) {
    final entry = DialogueEntry(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      transcription: '',
      dialogueHistory: [...state.dialogueHistory, entry],
    );
  }

  void addCoachDialogue(String text) {
    final entry = DialogueEntry(
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
    state = state.copyWith(
      coachTextResponse: '',
      dialogueHistory: [...state.dialogueHistory, entry],
    );
  }

  void clearDialogue() {
    state = state.copyWith(
      dialogueHistory: [],
      transcription: '',
      coachTextResponse: '',
    );
  }

  // ===========================================================================
  // TTS Playback
  // ===========================================================================

  Future<void> playCoachTts(
    String text, {
    String? streamUrl,
  }) async {
    state = state.copyWith(isSpeaking: true, clearError: true);
    try {
      if (streamUrl != null && streamUrl.isNotEmpty) {
        await _playAudioStream(streamUrl);
      } else {
        final body = <String, dynamic>{
          'text': text,
          if (state.selectedVoiceId != null)
            'voice_id': state.selectedVoiceId,
        };
        final response = await _api.dio.post<List<int>>(
          '',
          data: body,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          await _playAudioBytes(response.data!);
        }
      }
    } catch (e) {
      debugPrint('[VoiceCoach] TTS playback error: ');
      state = state.copyWith(
        isSpeaking: false,
        error: _extractErrorMessage(e),
      );
    }
  }

  void stopPlayback() {
    _stopAudio();
    state = state.copyWith(isSpeaking: false);
  }

  void reset() {
    state = const VoiceCoachState();
  }

  // ===========================================================================
  // Error
  // ===========================================================================

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // ===========================================================================
  // Audio Playback (private)
  // ===========================================================================

  Future<void> _playAudioStream(String url) async {
    debugPrint('[VoiceCoach] Playing audio stream: ');
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> _playAudioBytes(List<int> bytes) async {
    debugPrint('[VoiceCoach] Playing audio bytes (${bytes.length} bytes)');
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isSpeaking: false);
  }

  void _stopAudio() {
    debugPrint('[VoiceCoach] Audio playback stopped');
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

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

/// Provides the [VoiceCoachManager] singleton for the voice coach feature.
final voiceCoachProvider =
    StateNotifierProvider<VoiceCoachManager, VoiceCoachState>((ref) {
  return VoiceCoachManager();
});
