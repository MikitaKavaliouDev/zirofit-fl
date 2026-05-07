import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:zirofit_fl/features/workout/services/voice_feedback_service.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockFlutterTts extends Mock implements FlutterTts {}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockFlutterTts mockTts;
  late VoiceFeedbackService service;

  setUp(() {
    mockTts = MockFlutterTts();

    // Stub platform calls so they return a default value.
    when(() => mockTts.setLanguage(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setSpeechRate(any())).thenAnswer((_) async => 1);
    when(() => mockTts.setVolume(any())).thenAnswer((_) async => 1);
    when(() => mockTts.speak(any())).thenAnswer((_) async => 1);
    when(() => mockTts.stop()).thenAnswer((_) async => 1);

    service = VoiceFeedbackService(tts: mockTts);
  });

  // ---------------------------------------------------------------------------
  // Test 1: TTS initialises
  // ---------------------------------------------------------------------------

  test('Test 1: TTS initialises', () async {
    expect(service.isInitialized, false);
    await service.initialize();
    expect(service.isInitialized, true);
    verify(() => mockTts.setLanguage('en-US')).called(1);
    verify(() => mockTts.setSpeechRate(0.5)).called(1);
    verify(() => mockTts.setVolume(1.0)).called(1);
  });

  // ---------------------------------------------------------------------------
  // Test 2: Speaks coaching phrase
  // ---------------------------------------------------------------------------

  test('Test 2: Speaks coaching phrase', () async {
    service.setEnabled(true);
    await service.speak('Push harder!');
    verify(() => mockTts.speak('Push harder!')).called(1);
  });

  // ---------------------------------------------------------------------------
  // Test 3: Respects mute setting
  // ---------------------------------------------------------------------------

  test('Test 3: Respects mute setting', () async {
    // Disabled service should NOT call TTS speak
    service.setEnabled(false);
    await service.speak('You can do it!');
    verifyNever(() => mockTts.speak(any()));

    // After enabling, it should speak
    service.setEnabled(true);
    await service.speak('Go go go!');
    verify(() => mockTts.speak('Go go go!')).called(1);
  });

  // ---------------------------------------------------------------------------
  // Test 4: Announces PR when detected
  // ---------------------------------------------------------------------------

  test('Test 4: Announces PR when detected', () async {
    service.setEnabled(true);
    await service.announcePR(
      exerciseName: 'Bench Press',
      weight: 100.0,
      reps: 8,
    );
    verify(
      () => mockTts.speak(
        "Good job! That's a new personal record on Bench Press, 8 reps at 100.0 kilograms",
      ),
    ).called(1);
  });

  test('Test 4b: Announces PR without weight/reps', () async {
    service.setEnabled(true);
    await service.announcePR(exerciseName: 'Squat');
    verify(
      () => mockTts.speak(
        "Good job! That's a new personal record on Squat",
      ),
    ).called(1);
  });

  // ---------------------------------------------------------------------------
  // Test 5: Announces rest timer
  // ---------------------------------------------------------------------------

  test('Test 5: Announces rest timer', () async {
    service.setEnabled(true);
    await service.announceRestTimer(90);
    verify(
      () => mockTts.speak('Rest timer started, 1 minutes and 30 seconds.'),
    ).called(1);
  });

  test('Test 5b: Announces short rest timer', () async {
    service.setEnabled(true);
    await service.announceRestTimer(30);
    verify(
      () => mockTts.speak('Rest timer started, 30 seconds.'),
    ).called(1);
  });

  // ---------------------------------------------------------------------------
  // Additional edge cases
  // ---------------------------------------------------------------------------

  test('announceWorkoutComplete speaks the correct phrase', () async {
    service.setEnabled(true);
    await service.announceWorkoutComplete();
    verify(() => mockTts.speak('Workout complete! Great work today.')).called(1);
  });

  test('speakConfirmation formats the message correctly', () async {
    service.setEnabled(true);
    await service.speakConfirmation(
      exerciseName: 'Deadlift',
      reps: 5,
      weight: 150.0,
    );
    verify(() => mockTts.speak('Deadlift, 5 reps, 150.0 kg')).called(1);
  });

  test('speakConfirmation omits reps/weight when null', () async {
    service.setEnabled(true);
    await service.speakConfirmation(exerciseName: 'Plank');
    verify(() => mockTts.speak('Plank')).called(1);
  });

  test('speakStatus delegates to speak', () async {
    service.setEnabled(true);
    await service.speakStatus('Rest complete!');
    verify(() => mockTts.speak('Rest complete!')).called(1);
  });

  test('speakNumber delegates to speak', () async {
    service.setEnabled(true);
    await service.speakNumber(10);
    verify(() => mockTts.speak('10')).called(1);
  });

  test('stop calls TTS stop', () async {
    await service.stop();
    verify(() => mockTts.stop()).called(1);
  });

  test('multiple speak calls work sequentially', () async {
    service.setEnabled(true);
    await service.speak('First');
    await service.speak('Second');
    await service.speak('Third');
    verify(() => mockTts.speak('First')).called(1);
    verify(() => mockTts.speak('Second')).called(1);
    verify(() => mockTts.speak('Third')).called(1);
  });

  test('initialize is idempotent', () async {
    await service.initialize();
    await service.initialize();
    // setLanguage etc should only be called once
    verify(() => mockTts.setLanguage('en-US')).called(1);
  });
}
