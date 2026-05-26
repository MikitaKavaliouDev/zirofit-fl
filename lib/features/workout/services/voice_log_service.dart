import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:zirofit_fl/core/constants/exercise_aliases.dart';

/// ---------------------------------------------------------------------------
/// ParsedVoiceInput
/// ---------------------------------------------------------------------------

/// Represents a successfully parsed voice command for logging a workout set.
class ParsedVoiceInput {
  /// The recognized exercise name (may be null if not identifiable).
  final String? exerciseName;

  /// The number of reps extracted from the voice input.
  final int reps;

  /// The weight in the default unit (kg / lb as spoken); null if bodyweight.
  final double? weight;

  /// The raw recognized text from speech-to-text.
  final String rawText;

  const ParsedVoiceInput({
    this.exerciseName,
    required this.reps,
    this.weight,
    required this.rawText,
  });

  @override
  String toString() =>
      'ParsedVoiceInput(exerciseName: $exerciseName, reps: $reps, '
      'weight: $weight, rawText: "$rawText")';
}

/// ---------------------------------------------------------------------------
/// VoiceLogService
/// ---------------------------------------------------------------------------

/// Service that provides speech-to-text recognition and natural-language
/// parsing of workout voice commands.
///
/// Example utterances:
/// - "Bench press 5 reps 135 pounds" → {exercise: "Bench Press", reps: 5, weight: 135}
/// - "5 reps 100 pounds"            → {reps: 5, weight: 100}
/// - "squat three sets of eight at 135" → {exercise: "Squat", reps: 8, weight: 135}
class VoiceLogService {
  final stt.SpeechToText _speech;
  bool _isInitialized = false;

  VoiceLogService({stt.SpeechToText? speech}) : _speech = speech ?? stt.SpeechToText();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Whether the speech engine is currently listening.
  bool get isListening => _speech.isListening;

  /// Whether the speech engine is available on this device.
  bool get isAvailable => _speech.isAvailable;

  /// Initialises the speech recognition engine.
  ///
  /// Returns `true` when initialised, `false` if not available or permission
  /// was denied.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) => debugPrint('[VoiceLog] Error: $error'),
      onStatus: (status) => debugPrint('[VoiceLog] Status: $status'),
    );
    return _isInitialized;
  }

  /// Starts listening for speech and returns the recognised text.
  ///
  /// Listening automatically stops after [timeout] (default 10 seconds) or
  /// when the speaker pauses for [pauseFor] (default 2 seconds).
  ///
  /// Returns `null` if initialisation failed or no speech was detected.
  Future<String?> startListening({
    Duration? timeout,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return null;
    }

    final completer = Completer<String?>();
    String? lastWords;

    await _speech.listen(
      onResult: (val) {
        lastWords = val.recognizedWords;
        if (val.finalResult && !completer.isCompleted) {
          completer.complete(val.recognizedWords);
        }
      },
      listenFor: timeout ?? const Duration(seconds: 10),
      pauseFor: pauseFor ?? const Duration(seconds: 2),
      partialResults: false,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );

    // If listen() returned without a final result, use the last partial words.
    if (!completer.isCompleted) {
      completer.complete(lastWords);
    }

    return completer.future;
  }

  /// Stops listening early.
  void stopListening() {
    _speech.stop();
  }

  // ---------------------------------------------------------------------------
  // NLP Parsing
  // ---------------------------------------------------------------------------

  /// Attempts to parse a natural-language voice command into structured data.
  ///
  /// Provide a list of [knownExercises] to improve exercise-name matching.
  /// Returns `null` when the utterance cannot be parsed (minimal requirement:
  /// at least a reps value).
  ParsedVoiceInput? parse(
    String text, {
    List<String> knownExercises = const [],
    List<String> libraryExercises = const [],
  }) {
    if (text.trim().isEmpty) return null;

    // 1 – Normalise
    String normalized = text.toLowerCase().trim();

    // Remove punctuation except 'x' which we use as a delimiter
    normalized = normalized.replaceAll(RegExp(r'[^\w\sx]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 2 – Replace word numbers with digits
    normalized = _replaceWordNumbers(normalized);

    // Work on a copy so we can safely remove matched parts
    String remaining = normalized;

    // 3 – Extract weight
    // "X pounds / lbs / lb / kg / kilos / kgs"
    double? weight;
    final weightUnitRegex = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:pounds|lbs?|kgs?|kilos)\b',
    );
    final weightUnitMatch = weightUnitRegex.firstMatch(remaining);
    if (weightUnitMatch != null) {
      weight = double.parse(weightUnitMatch.group(1)!);
      remaining = remaining.replaceFirst(weightUnitMatch.group(0)!, '').trim();
    } else {
      // "at X"
      final atRegex = RegExp(r'\bat\s+(\d+(?:\.\d+)?)\b');
      final atMatch = atRegex.firstMatch(remaining);
      if (atMatch != null) {
        weight = double.parse(atMatch.group(1)!);
        remaining = remaining.replaceFirst(atMatch.group(0)!, '').trim();
      }
    }

    // 4 – Extract reps
    int? reps;

    // "X reps" (or "rep")
    final repsRegex = RegExp(r'(\d+)\s*reps?\b');
    final repsMatch = repsRegex.firstMatch(remaining);
    if (repsMatch != null) {
      reps = int.parse(repsMatch.group(1)!);
      remaining = remaining.replaceFirst(repsMatch.group(0)!, '').trim();
    }

    // "X sets of Y"  →  Y is the reps per set
    if (reps == null) {
      final setsOfRegex = RegExp(r'(\d+)\s*set?s?\s*of\s*(\d+)');
      final setsOfMatch = setsOfRegex.firstMatch(remaining);
      if (setsOfMatch != null) {
        reps = int.parse(setsOfMatch.group(2)!);
        remaining = remaining.replaceFirst(setsOfMatch.group(0)!, '').trim();
      }
    }

    // "X × Y" or "X x Y"  →  second number is reps
    if (reps == null) {
      final crossRegex = RegExp(r'(\d+)\s*x\s*(\d+)');
      final crossMatch = crossRegex.firstMatch(remaining);
      if (crossMatch != null) {
        reps = int.parse(crossMatch.group(2)!);
        remaining = remaining.replaceFirst(crossMatch.group(0)!, '').trim();
      }
    }

    // "for X" — always treat the number after "for" as reps
    if (reps == null) {
      final forRegex = RegExp(r'\bfor\s+(\d+)\b');
      final forMatch = forRegex.firstMatch(remaining);
      if (forMatch != null) {
        reps = int.parse(forMatch.group(1)!);
        remaining = remaining.replaceFirst(forMatch.group(0)!, '').trim();
      }
    }

    // 5 – Fill missing values from remaining bare numbers
    final allNumbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(remaining)
        .map((m) => m.group(0)!)
        .toList();

    if (reps == null && allNumbers.isNotEmpty) {
      reps = int.tryParse(allNumbers.first);
      if (reps != null) {
        remaining = remaining.replaceFirst(allNumbers.first, '').trim();
        allNumbers.removeAt(0);
      }
    }

    if (weight == null && allNumbers.isNotEmpty) {
      weight = double.tryParse(allNumbers.first);
      if (weight != null) {
        remaining = remaining.replaceFirst(allNumbers.first, '').trim();
      }
    }

    // If we still have no reps, parsing failed.
    if (reps == null || reps <= 0) return null;

    // 6 – Extract exercise name (6-tier cascade matching iOS VoiceLogManager)
    String? exerciseName;
    final nameSource = remaining;

    // Clean up the query text by stripping digits and filler words
    final query = nameSource
        .replaceAll(RegExp(r'\d+(?:\.\d+)?'), '')
        .replaceAll(
          RegExp(
            r'\b(?:reps?|pounds|lbs?|kgs?|kilos|set?s?|of|at|for|and|do|the|a|an|please|um|uh|like|gonna|wanna)\b',
          ),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (query.isNotEmpty) {
      exerciseName = _resolveExerciseName(
        query,
        knownExercises,
        libraryExercises,
      );
    }

    return ParsedVoiceInput(
      exerciseName: exerciseName,
      reps: reps,
      weight: weight,
      rawText: text,
    );
  }

  /// ---------------------------------------------------------------------------
  /// 6-tier exercise name resolution (mirrors iOS VoiceLogManager).
  ///
  /// [rawText] is the cleaned query text (stop words removed, lowercased).
  /// [knownExercises] are the exercises in the current session.
  /// [libraryExercises] are ALL exercises from the full exercise library.
  /// ---------------------------------------------------------------------------
  static String? _resolveExerciseName(
    String rawText,
    List<String> knownExercises,
    List<String> libraryExercises,
  ) {
    final clean = rawText.trim().toLowerCase();

    // Tier 1: Exact name match (case-insensitive) against session exercises
    for (final name in knownExercises) {
      if (name.toLowerCase() == clean) return name;
    }

    // Tier 2: Bidirectional substring against session exercises
    for (final name in knownExercises) {
      final nameLower = name.toLowerCase();
      if (nameLower.contains(clean) || clean.contains(nameLower)) {
        return name;
      }
    }

    // Tier 3: Library-wide exact match (full exercise library)
    for (final name in libraryExercises) {
      if (name.toLowerCase() == clean) return name;
    }

    // Tier 4: Popular/default exercises — bidirectional substring
    for (final name in popularExercises) {
      final nameLower = name.toLowerCase();
      if (nameLower.contains(clean) || clean.contains(nameLower)) {
        return name;
      }
    }

    // Tier 5: Library-wide bidirectional substring with confidence scoring
    //         (longest match wins — more specific = better)
    String? bestMatch;
    int bestScore = 0;
    for (final name in libraryExercises) {
      final nameLower = name.toLowerCase();
      if (nameLower.contains(clean) || clean.contains(nameLower)) {
        final score = name.length;
        if (score > bestScore) {
          bestScore = score;
          bestMatch = name;
        }
      }
    }
    if (bestMatch != null) return bestMatch;

    // Tier 6: Keyword alias map
    for (final entry in exerciseAliases.entries) {
      if (clean.contains(entry.key)) return entry.value;
    }

    return null;
  }

  /// Relaxed matching of a resolved exercise name against session exercises.
  ///
  /// Tiers 1-2 (exact match then bidirectional substring) against
  /// [sessionExercises].  Use this in the post-parse step to match the
  /// resolved name to an actual exercise in the current session.
  static String? matchSessionExercise(
    String resolvedName,
    List<String> sessionExercises,
  ) {
    final clean = resolvedName.trim().toLowerCase();

    // Tier 1: Exact match
    for (final name in sessionExercises) {
      if (name.toLowerCase() == clean) return name;
    }

    // Tier 2: Bidirectional substring
    for (final name in sessionExercises) {
      final nameLower = name.toLowerCase();
      if (nameLower.contains(clean) || clean.contains(nameLower)) {
        return name;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static final Map<String, String> _wordNumberMap = {
    'zero': '0',
    'one': '1',
    'two': '2',
    'three': '3',
    'four': '4',
    'five': '5',
    'six': '6',
    'seven': '7',
    'eight': '8',
    'nine': '9',
    'ten': '10',
    'eleven': '11',
    'twelve': '12',
    'thirteen': '13',
    'fourteen': '14',
    'fifteen': '15',
    'sixteen': '16',
    'seventeen': '17',
    'eighteen': '18',
    'nineteen': '19',
    'twenty': '20',
    'thirty': '30',
    'forty': '40',
    'fifty': '50',
  };

  /// Replaces English word numbers with their digit equivalents in [text].
  static String _replaceWordNumbers(String text) {
    String result = text;

    // Sort by length descending so "three" is not partially replaced by "one"
    final entries = _wordNumberMap.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in entries) {
      // Use word-boundary regex so "three" doesn't match "threes"
      result = result.replaceAllMapped(
        RegExp(r'\b' + entry.key + r'\b'),
        (_) => entry.value,
      );
    }

    return result;
  }
}
