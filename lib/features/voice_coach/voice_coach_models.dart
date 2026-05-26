// ---------------------------------------------------------------------------
// VoiceMode
// ---------------------------------------------------------------------------

/// The mode the voice coach operates in.
///
/// Mirrors the iOS `VoiceInteractionMode` enum.
enum VoiceMode {
  /// Command dictation — log exercises, weight, reps via speech.
  dictation,

  /// Conversational AI coach — verbal advice and motivation.
  coach,
}

// ---------------------------------------------------------------------------
// VoiceLabels
// ---------------------------------------------------------------------------

/// Descriptive labels associated with a voice (e.g. gender, accent).
///
/// Mirrors the iOS `VoiceLabels` struct.
class VoiceLabels {
  final String? accent;
  final String? gender;

  const VoiceLabels({this.accent, this.gender});

  factory VoiceLabels.fromJson(Map<String, dynamic> json) {
    return VoiceLabels(
      accent: json['accent'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (accent != null) 'accent': accent,
        if (gender != null) 'gender': gender,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceLabels &&
          accent == other.accent &&
          gender == other.gender;

  @override
  int get hashCode => Object.hash(accent, gender);

  @override
  String toString() => 'VoiceLabels(accent: $accent, gender: $gender)';
}

// ---------------------------------------------------------------------------
// VoiceModel
// ---------------------------------------------------------------------------

/// A voice available for TTS (retrieved from ElevenLabs via the backend).
///
/// Mirrors the iOS `VoiceModel` struct.
class VoiceModel {
  final String voiceId;
  final String name;
  final String? previewUrl;
  final VoiceLabels? labels;
  final String? description;
  final String? category;

  const VoiceModel({
    required this.voiceId,
    required this.name,
    this.previewUrl,
    this.labels,
    this.description,
    this.category,
  });

  factory VoiceModel.fromJson(Map<String, dynamic> json) {
    return VoiceModel(
      voiceId: json['voice_id'] as String,
      name: json['name'] as String,
      previewUrl: json['preview_url'] as String?,
      labels: json['labels'] != null
          ? VoiceLabels.fromJson(json['labels'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'voice_id': voiceId,
        'name': name,
        if (previewUrl != null) 'preview_url': previewUrl,
        if (labels != null) 'labels': labels!.toJson(),
        if (description != null) 'description': description,
        if (category != null) 'category': category,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceModel && voiceId == other.voiceId && name == other.name;

  @override
  int get hashCode => Object.hash(voiceId, name);

  @override
  String toString() => 'VoiceModel(voiceId: $voiceId, name: $name)';
}

// ---------------------------------------------------------------------------
// VoiceSettingsValues
// ---------------------------------------------------------------------------

/// Tunable parameters for ElevenLabs voice synthesis.
///
/// Mirrors the iOS `VoiceSettingsValues` struct.
class VoiceSettingsValues {
  final double stability;
  final double similarityBoost;
  final double style;
  final bool useSpeakerBoost;
  final double speed;

  const VoiceSettingsValues({
    this.stability = 0.5,
    this.similarityBoost = 0.75,
    this.style = 0.0,
    this.useSpeakerBoost = true,
    this.speed = 1.0,
  });

  factory VoiceSettingsValues.fromJson(Map<String, dynamic> json) {
    return VoiceSettingsValues(
      stability: (json['stability'] as num?)?.toDouble() ?? 0.5,
      similarityBoost:
          (json['similarity_boost'] as num?)?.toDouble() ?? 0.75,
      style: (json['style'] as num?)?.toDouble() ?? 0.0,
      useSpeakerBoost: json['use_speaker_boost'] as bool? ?? true,
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'stability': stability,
        'similarity_boost': similarityBoost,
        'style': style,
        'use_speaker_boost': useSpeakerBoost,
        'speed': speed,
      };

  VoiceSettingsValues copyWith({
    double? stability,
    double? similarityBoost,
    double? style,
    bool? useSpeakerBoost,
    double? speed,
  }) {
    return VoiceSettingsValues(
      stability: stability ?? this.stability,
      similarityBoost: similarityBoost ?? this.similarityBoost,
      style: style ?? this.style,
      useSpeakerBoost: useSpeakerBoost ?? this.useSpeakerBoost,
      speed: speed ?? this.speed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceSettingsValues &&
          stability == other.stability &&
          similarityBoost == other.similarityBoost &&
          style == other.style &&
          useSpeakerBoost == other.useSpeakerBoost &&
          speed == other.speed;

  @override
  int get hashCode =>
      Object.hash(stability, similarityBoost, style, useSpeakerBoost, speed);

  @override
  String toString() =>
      'VoiceSettingsValues(stability: $stability, similarityBoost: $similarityBoost, '
      'style: $style, useSpeakerBoost: $useSpeakerBoost, speed: $speed)';
}

// ---------------------------------------------------------------------------
// ParsedVoiceCoachData
// ---------------------------------------------------------------------------

/// Structured data extracted from a voice command by the AI coach.
///
/// Mirrors the iOS `ParsedVoiceCoachData` struct.
class ParsedVoiceCoachData {
  /// The recognized exercise name (e.g. "Bench Press").
  final String? exerciseName;

  /// Number of reps detected.
  final double? reps;

  /// Weight in kg detected.
  final double? weight;

  const ParsedVoiceCoachData({
    this.exerciseName,
    this.reps,
    this.weight,
  });

  factory ParsedVoiceCoachData.fromJson(Map<String, dynamic> json) {
    return ParsedVoiceCoachData(
      exerciseName: json['exercise'] as String? ??
          json['exercise_name'] as String?,
      reps: (json['reps'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (exerciseName != null) 'exercise': exerciseName,
        if (reps != null) 'reps': reps,
        if (weight != null) 'weight': weight,
      };

  @override
  String toString() =>
      'ParsedVoiceCoachData(exerciseName: $exerciseName, reps: $reps, weight: $weight)';
}

// ---------------------------------------------------------------------------
// VoiceCoachResponse
// ---------------------------------------------------------------------------

/// The response from the AI coach API after processing voice input.
///
/// Mirrors the iOS `VoiceCoachResponse` struct.
class VoiceCoachResponse {
  /// Action type returned by the AI ("log_set", "response", etc.).
  final String action;

  /// Raw transcript of the user's speech.
  final String? transcript;

  /// Parsed structured data from the voice command.
  final ParsedVoiceCoachData? parsed;

  /// The coach's text response to speak back to the user.
  final String? coachResponse;

  /// An optional ElevenLabs TTS stream URL for direct playback.
  final String? streamUrl;

  const VoiceCoachResponse({
    required this.action,
    this.transcript,
    this.parsed,
    this.coachResponse,
    this.streamUrl,
  });

  factory VoiceCoachResponse.fromJson(Map<String, dynamic> json) {
    return VoiceCoachResponse(
      action: json['action'] as String? ?? 'response',
      transcript: json['transcript'] as String?,
      parsed: json['parsed'] != null
          ? ParsedVoiceCoachData.fromJson(
              json['parsed'] as Map<String, dynamic>)
          : null,
      coachResponse: json['coach_response'] as String? ??
          json['coachResponse'] as String?,
      streamUrl: json['stream_url'] as String? ??
          json['streamUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'action': action,
        if (transcript != null) 'transcript': transcript,
        if (parsed != null) 'parsed': parsed!.toJson(),
        if (coachResponse != null) 'coach_response': coachResponse,
        if (streamUrl != null) 'stream_url': streamUrl,
      };

  @override
  String toString() =>
      'VoiceCoachResponse(action: $action, transcript: $transcript, '
      'coachResponse: $coachResponse)';
}

