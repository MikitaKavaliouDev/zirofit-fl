
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';
import 'package:zirofit_fl/features/workout/services/voice_log_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSpeechToText extends Mock implements stt.SpeechToText {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SpeechRecognitionResult recognitionResult({
  required String words,
  bool finalResult = true,
  double confidence = 0.9,
}) {
  return SpeechRecognitionResult(
    [SpeechRecognitionWords(words, null, confidence)],
    finalResult,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(ListenMode.dictation);
  });

  group('VoiceLogService', () {
    late VoiceLogService service;

    setUp(() {
      service = VoiceLogService();
    });

    // -----------------------------------------------------------------------
    // Test 1: Speech recognition initializes
    // -----------------------------------------------------------------------
    group('initialization', () {
      test('speech recognition initializes successfully', () async {
        final mockSpeech = MockSpeechToText();

        when(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).thenAnswer((_) async => true);

        when(() => mockSpeech.isAvailable).thenReturn(true);

        final svc = VoiceLogService(speech: mockSpeech);
        final result = await svc.initialize();

        expect(result, isTrue);
        expect(svc.isAvailable, isTrue);
        verify(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).called(1);
      });

      test('initialize returns false when speech not available', () async {
        final mockSpeech = MockSpeechToText();

        when(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).thenAnswer((_) async => false);

        final svc = VoiceLogService(speech: mockSpeech);
        final result = await svc.initialize();

        expect(result, isFalse);
      });

      test('initialize is idempotent', () async {
        final mockSpeech = MockSpeechToText();

        when(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).thenAnswer((_) async => true);

        final svc = VoiceLogService(speech: mockSpeech);
        await svc.initialize();
        await svc.initialize();

        verify(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).called(1);
      });
    });

    // -----------------------------------------------------------------------
    // Test 2: Parses "5 reps 100 pounds" correctly
    // -----------------------------------------------------------------------
    group('parsing — basic patterns', () {
      test('parses "5 reps 100 pounds" correctly', () {
        final result = service.parse('5 reps 100 pounds');

        expect(result, isNotNull);
        expect(result!.reps, 5);
        expect(result.weight, closeTo(100.0, 0.01));
        expect(result.exerciseName, isNull);
        expect(result.rawText, '5 reps 100 pounds');
      });

      test('parses "10 reps 50 lbs" correctly', () {
        final result = service.parse('10 reps 50 lbs');
        expect(result, isNotNull);
        expect(result!.reps, 10);
        expect(result.weight, closeTo(50.0, 0.01));
      });

      test('parses "8 reps 60 kg" correctly', () {
        final result = service.parse('8 reps 60 kg');
        expect(result, isNotNull);
        expect(result!.reps, 8);
        expect(result.weight, closeTo(60.0, 0.01));
      });

      test('parses reps without weight', () {
        final result = service.parse('12 reps');
        expect(result, isNotNull);
        expect(result!.reps, 12);
        expect(result.weight, isNull);
      });

      test('parses "135 for 8" correctly', () {
        final result = service.parse('135 for 8');
        expect(result, isNotNull);
        expect(result!.reps, 8);
        expect(result.weight, closeTo(135.0, 0.01));
      });

      test('parses "135 pounds for 8 reps" correctly', () {
        final result = service.parse('135 pounds for 8 reps');
        expect(result, isNotNull);
        expect(result!.reps, 8);
        expect(result.weight, closeTo(135.0, 0.01));
      });

      test('parses "for 5 reps" without weight', () {
        final result = service.parse('for 5 reps');
        expect(result, isNotNull);
        expect(result!.reps, 5);
        expect(result.weight, isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Test 3: Parses "bench press three sets of eight at 135" correctly
    // -----------------------------------------------------------------------
    group('parsing — with exercise names', () {
      test(
          'parses "bench press three sets of eight at 135" with known exercises',
          () {
        final result = service.parse(
          'bench press three sets of eight at 135',
          knownExercises: ['Bench Press'],
        );
        expect(result, isNotNull);
        expect(result!.exerciseName, 'Bench Press');
        expect(result.reps, 8);
        expect(result.weight, closeTo(135.0, 0.01));
      });

      test('parses "bench press 5 reps 135 pounds" with exercise name', () {
        final result = service.parse(
          'bench press 5 reps 135 pounds',
          knownExercises: ['Bench Press'],
        );
        expect(result, isNotNull);
        expect(result!.exerciseName, 'Bench Press');
        expect(result.reps, 5);
        expect(result.weight, closeTo(135.0, 0.01));
      });

      test('parses "squat 3 sets of 10 at 200" with known exercise', () {
        final result = service.parse(
          'squat 3 sets of 10 at 200',
          knownExercises: ['Squat'],
        );
        expect(result, isNotNull);
        expect(result!.exerciseName, 'Squat');
        expect(result.reps, 10);
        expect(result.weight, closeTo(200.0, 0.01));
      });

      test('parses "deadlift 405 for 5" correctly', () {
        final result = service.parse(
          'deadlift 405 for 5',
          knownExercises: ['Deadlift'],
        );
        expect(result, isNotNull);
        expect(result!.exerciseName, 'Deadlift');
        expect(result.reps, 5);
        expect(result.weight, closeTo(405.0, 0.01));
      });

      test('extracts exercise name from leading words when not in known list',
          () {
        final result = service.parse('overhead press 8 reps 95 pounds');
        expect(result, isNotNull);
        expect(result!.exerciseName, 'Overhead Press');
        expect(result.reps, 8);
        expect(result.weight, closeTo(95.0, 0.01));
      });
    });

    // -----------------------------------------------------------------------
    // Test 4: Error when no speech detected
    // -----------------------------------------------------------------------
    group('error handling', () {
      test('startListening returns null when no speech detected', () async {
        final mockSpeech = MockSpeechToText();

        when(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).thenAnswer((_) async => true);

        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              listenFor: any(named: 'listenFor'),
              pauseFor: any(named: 'pauseFor'),
              partialResults: any(named: 'partialResults'),
              cancelOnError: any(named: 'cancelOnError'),
              listenMode: any(named: 'listenMode'),
            )).thenAnswer((_) async {});

        final svc = VoiceLogService(speech: mockSpeech);
        final result = await svc.startListening();

        expect(result, isNull);
      });

      test('parse returns null for empty text', () {
        expect(service.parse(''), isNull);
        expect(service.parse('   '), isNull);
      });

      test('parse returns null when no reps found', () {
        expect(service.parse('just some random words'), isNull);
      });
    });

    // -----------------------------------------------------------------------
    // Test 5: Full pipeline
    // -----------------------------------------------------------------------
    group('end-to-end recognition flow', () {
      test('full speech-to-parse pipeline works end-to-end', () async {
        final mockSpeech = MockSpeechToText();

        when(() => mockSpeech.initialize(
              onError: any(named: 'onError'),
              onStatus: any(named: 'onStatus'),
            )).thenAnswer((_) async => true);

        // Set up listen with any() matchers to avoid mocktail issues
        when(() => mockSpeech.listen(
              onResult: any(named: 'onResult'),
              listenFor: any(named: 'listenFor'),
              pauseFor: any(named: 'pauseFor'),
              partialResults: any(named: 'partialResults'),
              cancelOnError: any(named: 'cancelOnError'),
              listenMode: any(named: 'listenMode'),
            )).thenAnswer((invocation) async {
          final onResult = invocation.namedArguments[#onResult]
              as void Function(SpeechRecognitionResult);
          onResult(recognitionResult(
            words: 'squat 5 reps 200 pounds',
            finalResult: true,
          ));
        });

        final svc = VoiceLogService(speech: mockSpeech);
        final text = await svc.startListening();

        expect(text, isNotNull);
        expect(text, 'squat 5 reps 200 pounds');

        final parsed = svc.parse(text!, knownExercises: ['Squat']);
        expect(parsed, isNotNull);
        expect(parsed!.exerciseName, 'Squat');
        expect(parsed.reps, 5);
        expect(parsed.weight, closeTo(200.0, 0.01));
      });

      test('recognised set values can be passed to logExercise', () {
        final parsed = service.parse('barbell row 3x10 150');
        expect(parsed, isNotNull);
        expect(parsed!.reps, 10);
        expect(parsed.weight, closeTo(150.0, 0.01));
        expect(parsed.reps, greaterThan(0));
      });
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------
    group('edge cases', () {
      test('handles mixed case input', () {
        final result = service.parse('Bench Press 5 REPS 135 POUNDS');
        expect(result, isNotNull);
        expect(result!.reps, 5);
        expect(result.weight, closeTo(135.0, 0.01));
      });

      test('parses "3x10" cross notation', () {
        final result = service.parse('pull ups 3x10');
        expect(result, isNotNull);
        expect(result!.reps, 10);
      });

      test('parses word numbers correctly', () {
        final result = service.parse('five reps one hundred pounds');
        expect(result, isNotNull);
        expect(result!.reps, 5);
      });

      test('parses "5 reps" without weight', () {
        final result = service.parse('5 reps');
        expect(result, isNotNull);
        expect(result!.reps, 5);
        expect(result.weight, isNull);
      });

      test('does not crash on gibberish', () {
        expect(service.parse('asdfghjkl'), isNull);
      });
    });
  });
}
