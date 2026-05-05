import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/ai_coach/providers/ai_coach_provider.dart';
import '../helpers/provider_utils.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Map<String, dynamic> _generateResponse({String program = 'Generated program text'}) => {
      'data': <String, dynamic>{
        'program': program,
      },
    };

Map<String, dynamic> _generateResponseFlat({String program = 'Flat program text'}) => {
      'program': program,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ProviderContainer container;

  setUp(() {
    mockApiClient = MockApiClient();
    container = createTestContainer(overrides: [
      aiCoachProvider.overrideWith(
        (ref) => AICoachNotifier(apiClient: mockApiClient),
      ),
    ]);
  });

  tearDown(() {
    container.dispose();
  });

  group('AICoachNotifier', () {
    test('initial state has null program, not loading, no error', () {
      final state = container.read(aiCoachProvider);
      expect(state.generatedProgram, isNull);
      expect(state.goal, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.conversation, isEmpty);
    });

    test("generateProgram extracts program from result['data']['program']", () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _generateResponse(program: 'Workout for strength'));

      await container.read(aiCoachProvider.notifier).generateProgram('Build strength');

      final state = container.read(aiCoachProvider);
      expect(state.generatedProgram, 'Workout for strength');
      expect(state.goal, 'Build strength');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.conversation, hasLength(1));
    });

    test("generateProgram falls back to result['program'] when data is absent", () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _generateResponseFlat(program: 'Flat program'));

      await container.read(aiCoachProvider.notifier).generateProgram('Lose weight');

      final state = container.read(aiCoachProvider);
      expect(state.generatedProgram, 'Flat program');
      expect(state.goal, 'Lose weight');
      expect(state.isLoading, isFalse);
    });

    test('generateProgram sets error on API failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(Exception('Generate failed'));

      await container.read(aiCoachProvider.notifier).generateProgram('Test');

      final state = container.read(aiCoachProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
      expect(state.generatedProgram, isNull);
    });

    test('generateProgram handles null program in nested response', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <String, dynamic>{'program': null},
          });

      await container.read(aiCoachProvider.notifier).generateProgram('Test');

      final state = container.read(aiCoachProvider);
      // Falls through to result.toString() since null coalescing chain ends with result.toString()
      expect(state.generatedProgram, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('refineProgram refines the generated program', () async {
      // First generate
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _generateResponse(program: 'Initial program'));

      await container.read(aiCoachProvider.notifier).generateProgram('Build muscle');

      // Then refine
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachRefine,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _generateResponse(program: 'Refined program'));

      await container
          .read(aiCoachProvider.notifier)
          .refineProgram('Make it harder');

      final state = container.read(aiCoachProvider);
      expect(state.generatedProgram, 'Refined program');
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      // Conversation should contain: initial program, user input, refined program
      expect(state.conversation, hasLength(3));
    });

    test('refineProgram sets error on API failure', () async {
      // First set initial state with a goal and program
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _generateResponse(program: 'Initial'));

      await container.read(aiCoachProvider.notifier).generateProgram('Test');
      expect(container.read(aiCoachProvider).generatedProgram, isNotNull);

      // Refine fails
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachRefine,
            body: any(named: 'body'),
          )).thenThrow(Exception('Refine failed'));

      await container
          .read(aiCoachProvider.notifier)
          .refineProgram('Make it harder');

      final state = container.read(aiCoachProvider);
      expect(state.isLoading, isFalse);
      expect(state.error, isNotNull);
    });

    test('clearError clears the error', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(Exception('Error'));

      await container.read(aiCoachProvider.notifier).generateProgram('Test');
      expect(container.read(aiCoachProvider).error, isNotNull);

      container.read(aiCoachProvider.notifier).clearError();

      expect(container.read(aiCoachProvider).error, isNull);
    });

    test('reset restores initial state', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => _generateResponse(program: 'Some program'));

      await container.read(aiCoachProvider.notifier).generateProgram('Test');
      expect(container.read(aiCoachProvider).generatedProgram, isNotNull);

      container.read(aiCoachProvider.notifier).reset();

      final state = container.read(aiCoachProvider);
      expect(state.generatedProgram, isNull);
      expect(state.goal, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.conversation, isEmpty);
    });
  });
}
