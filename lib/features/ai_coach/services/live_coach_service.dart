import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/workout/services/voice_feedback_service.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';

// ---------------------------------------------------------------------------
// CoachResult
// ---------------------------------------------------------------------------

/// The result of processing a voice/text input through the AI coach.
class CoachResult {
  /// The coaching response text.
  final String message;

  /// Whether a set was auto-detected and logged.
  final bool setLogged;

  /// The parsed exercise name if a set was logged.
  final String? exerciseName;

  /// The number of reps if a set was logged.
  final int? reps;

  /// The weight in kg if a set was logged.
  final double? weight;

  const CoachResult({
    required this.message,
    this.setLogged = false,
    this.exerciseName,
    this.reps,
    this.weight,
  });
}

// ---------------------------------------------------------------------------
// LiveCoachService
// ---------------------------------------------------------------------------

/// Orchestrates the live coaching flow:
///
/// 1. User speaks   → voice_input records audio
/// 2. STT transcribes to text
/// 3. Text sent to POST /api/ai-trainer/voice
/// 4. API returns coaching response
/// 5. TTS reads response aloud
/// 6. Auto-logs sets if detected in transcript
class LiveCoachService {
  final ApiClient _api;
  final VoiceLogService _voiceLogService;
  final VoiceFeedbackService _voiceFeedbackService;

  LiveCoachService({
    ApiClient? apiClient,
    VoiceLogService? voiceLogService,
    VoiceFeedbackService? voiceFeedbackService,
  })  : _api = apiClient ?? ApiClient.instance,
        _voiceLogService = voiceLogService ?? VoiceLogService(),
        _voiceFeedbackService =
            voiceFeedbackService ?? VoiceFeedbackService();

  /// Initialises the underlying STT and TTS services.
  Future<void> initialize() async {
    await _voiceLogService.initialize();
    await _voiceFeedbackService.initialize();
    _voiceFeedbackService.setEnabled(true);
  }

  /// Processes an audio recording (base64-encoded) through the coaching
  /// pipeline: STT → AI → TTS.
  ///
  /// Returns a [CoachResult] with the AI's coaching message and any
  /// auto-detected exercise data.
  Future<CoachResult> processVoiceInput(String audioBase64) async {
    // 1. Send audio to API for transcription + coaching in one call
    final body = <String, dynamic>{
      'audio': audioBase64,
    };

    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.aiVoice,
      body: body,
    );

    return _buildResult(response);
  }

  /// Processes a raw text input through the coaching pipeline: AI → TTS.
  ///
  /// Useful as a keyboard fallback when voice input is unavailable.
  Future<CoachResult> processTextInput(String text) async {
    final body = <String, dynamic>{
      'text': text,
    };

    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.aiVoice,
      body: body,
    );

    return _buildResult(response);
  }

  /// Speaks a coaching message aloud via TTS.
  Future<void> speakFeedback(String message) async {
    await _voiceFeedbackService.speak(message);
  }

  /// Stops any ongoing TTS speech.
  Future<void> stopSpeaking() async {
    await _voiceFeedbackService.stop();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Builds a [CoachResult] from the API response.
  CoachResult _buildResult(Map<String, dynamic> response) {
    final data = response['data'] as Map<String, dynamic>? ?? response;
    final message = (data['message'] ?? data['response'] ?? '') as String;

    // Check for auto-logged set data
    final setLogged = data['set_logged'] == true || data['auto_logged'] == true;
    final exerciseName = data['exercise_name'] as String?;
    final reps = data['reps'] as int?;
    final weight = (data['weight'] as num?)?.toDouble();

    return CoachResult(
      message: message,
      setLogged: setLogged,
      exerciseName: exerciseName,
      reps: reps,
      weight: weight,
    );
  }

  /// Parses auto-logged set information from a transcript.
  /// Falls back to local NLP when the API does not return structured data.
  CoachResult parseAndCreateResult(String transcript) {
    final parsed = _voiceLogService.parse(transcript);
    if (parsed != null) {
      return CoachResult(
        message: 'Logged ${parsed.exerciseName ?? "set"}: '
            '${parsed.reps} reps'
            '${parsed.weight != null ? " at ${parsed.weight!.toStringAsFixed(1)} kg" : ""}',
        setLogged: true,
        exerciseName: parsed.exerciseName,
        reps: parsed.reps,
        weight: parsed.weight,
      );
    }
    return CoachResult(
      message: transcript,
      setLogged: false,
    );
  }
}
