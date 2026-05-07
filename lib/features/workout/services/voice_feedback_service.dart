import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech coaching feedback during workouts.
///
/// Wraps [FlutterTts] with coaching phrases and mute control.
/// Pass a [FlutterTts] instance for testing (e.g., a mocktail `Mock`).
class VoiceFeedbackService {
  final FlutterTts _tts;
  bool _isEnabled = false;
  bool _isInitialized = false;

  VoiceFeedbackService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialise the TTS engine (language, rate, volume).
  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      _isInitialized = true;
    } catch (e) {
      debugPrint('[VoiceFeedback] Failed to initialise TTS: $e');
    }
  }

  /// Enable or disable voice feedback.
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Whether voice feedback is currently enabled.
  bool get isEnabled => _isEnabled;

  /// Whether the underlying TTS engine has been initialised.
  bool get isInitialized => _isInitialized;

  // ---------------------------------------------------------------------------
  // Core speak
  // ---------------------------------------------------------------------------

  /// Speak [message] aloud.
  ///
  /// No-op when [isEnabled] is `false`.
  Future<void> speak(String message) async {
    if (!_isEnabled) return;
    if (!_isInitialized) await initialize();
    try {
      await _tts.speak(message);
    } catch (e) {
      debugPrint('[VoiceFeedback] Speak failed: $e');
    }
  }

  /// Stop any ongoing speech.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[VoiceFeedback] Stop failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Coaching phrases
  // ---------------------------------------------------------------------------

  /// Announce a personal record.
  Future<void> announcePR({
    required String exerciseName,
    double? weight,
    int? reps,
  }) async {
    final buffer = StringBuffer()
      ..write('Good job! That\'s a new personal record on ')
      ..write(exerciseName);
    if (reps != null && weight != null) {
      buffer.write(', $reps reps at ${weight.toStringAsFixed(1)} kilograms');
    }
    await speak(buffer.toString());
  }

  /// Announce the rest timer has started.
  Future<void> announceRestTimer(int seconds) async {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      await speak('Rest timer started, $minutes minutes and $secs seconds.');
    } else {
      await speak('Rest timer started, $seconds seconds.');
    }
  }

  /// Announce the workout is complete.
  Future<void> announceWorkoutComplete() async {
    await speak('Workout complete! Great work today.');
  }

  /// Speak a confirmation after logging a set.
  Future<void> speakConfirmation({
    required String exerciseName,
    int? reps,
    double? weight,
  }) async {
    final buffer = StringBuffer(exerciseName);
    if (reps != null && reps > 0) {
      buffer.write(', $reps reps');
    }
    if (weight != null && weight > 0) {
      buffer.write(', ${weight.toStringAsFixed(1)} kg');
    }
    await speak(buffer.toString());
  }

  /// Speak a status update (e.g. rest complete, workout paused).
  Future<void> speakStatus(String status) async {
    await speak(status);
  }

  /// Speak a single number (useful for countdowns).
  Future<void> speakNumber(int number) async {
    await speak(number.toString());
  }
}
