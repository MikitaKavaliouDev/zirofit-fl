import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/features/ai_coach/providers/ai_coach_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AICoachNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = AICoachNotifier(apiClient: mockApiClient);
  });

  group('AICoachNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('initial state has default values', () {
      expect(notifier.state.generatedProgram, isNull);
      expect(notifier.state.goal, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.conversation, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // generateProgram – success
    // ---------------------------------------------------------------------------
    test('generateProgram sets isLoading then sets generatedProgram on success',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'program': 'Here is your custom workout program...',
          });

      final future = notifier.generateProgram('Build muscle');

      // During loading
      expect(notifier.state.isLoading, true);
      expect(notifier.state.goal, 'Build muscle');

      await future;

      expect(notifier.state.isLoading, false);
      expect(notifier.state.generatedProgram, 'Here is your custom workout program...');
      expect(notifier.state.error, isNull);
      expect(notifier.state.conversation.length, 1);
    });

    // ---------------------------------------------------------------------------
    // generateProgram – extracts program from nested data
    // ---------------------------------------------------------------------------
    test('generateProgram handles nested data.program response', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {
            'data': {'program': 'Nested program content'},
          });

      await notifier.generateProgram('Lose weight');

      expect(notifier.state.generatedProgram, 'Nested program content');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // generateProgram – failure
    // ---------------------------------------------------------------------------
    test('generateProgram sets error on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(Exception('Network error'));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.generatedProgram, isNull);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // generateProgram – DioException
    // ---------------------------------------------------------------------------
    test('generateProgram handles DioException', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Connection timeout'));
    });

    // ---------------------------------------------------------------------------
    // generateProgram – sends correct body
    // ---------------------------------------------------------------------------
    test('generateProgram sends goal in request body', () async {
      Map<String, dynamic>? capturedBody;

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>?;
        return {'program': 'Program'};
      });

      await notifier.generateProgram('Get ripped');

      expect(capturedBody, isNotNull);
      expect(capturedBody!['goal'], 'Get ripped');
      expect(notifier.state.isLoading, false);
    });

    // ---------------------------------------------------------------------------
    // refineProgram – success
    // ---------------------------------------------------------------------------
    test('refineProgram sends goal, userInput, currentProgram and conversation',
        () async {
      // First generate a program
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'program': 'Initial program'});

      await notifier.generateProgram('Build muscle');

      Map<String, dynamic>? capturedBody;

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachRefine,
            body: any(named: 'body'),
          )).thenAnswer((invocation) async {
        capturedBody = invocation.namedArguments[#body] as Map<String, dynamic>?;
        return {'program': 'Refined program'};
      });

      await notifier.refineProgram('Add more cardio');

      expect(capturedBody, isNotNull);
      expect(capturedBody!['goal'], 'Build muscle');
      expect(capturedBody!['user_input'], 'Add more cardio');
      expect(capturedBody!['current_program'], 'Initial program');
      expect(capturedBody!['conversation'], isA<List>());
    });

    // ---------------------------------------------------------------------------
    // refineProgram – appends to conversation
    // ---------------------------------------------------------------------------
    test('refineProgram appends user input and refined program to conversation',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'program': 'Initial program'});

      await notifier.generateProgram('Build muscle');
      expect(notifier.state.conversation.length, 1);

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachRefine,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'program': 'Refined program'});

      await notifier.refineProgram('Add more cardio');

      expect(notifier.state.conversation.length, 3);
      expect(notifier.state.conversation[0], 'Initial program');
      expect(notifier.state.conversation[1], 'Add more cardio');
      expect(notifier.state.conversation[2], 'Refined program');
    });

    // ---------------------------------------------------------------------------
    // refineProgram – failure
    // ---------------------------------------------------------------------------
    test('refineProgram sets error on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'program': 'Initial program'});

      await notifier.generateProgram('Build muscle');

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachRefine,
            body: any(named: 'body'),
          )).thenThrow(Exception('Refine error'));

      await notifier.refineProgram('Add more cardio');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
    });

    // ---------------------------------------------------------------------------
    // clearError
    // ---------------------------------------------------------------------------
    test('clearError clears the error', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(Exception('Some error'));

      await notifier.generateProgram('Build muscle');
      expect(notifier.state.error, isNotNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // clearError – safe when no error
    // ---------------------------------------------------------------------------
    test('clearError is safe when no error exists', () {
      expect(notifier.state.error, isNull);

      notifier.clearError();

      expect(notifier.state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // reset
    // ---------------------------------------------------------------------------
    test('reset restores initial state', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'program': 'Some program'});

      await notifier.generateProgram('Build muscle');
      expect(notifier.state.generatedProgram, isNotNull);

      notifier.reset();

      expect(notifier.state.generatedProgram, isNull);
      expect(notifier.state.goal, isNull);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.conversation, isEmpty);
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – DioException sendTimeout
    // ---------------------------------------------------------------------------
    test('generateProgram handles DioException sendTimeout', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.sendTimeout,
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Connection timeout'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – DioException receiveTimeout
    // ---------------------------------------------------------------------------
    test('generateProgram handles DioException receiveTimeout', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.receiveTimeout,
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Connection timeout'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – DioException connectionError
    // ---------------------------------------------------------------------------
    test('generateProgram handles DioException connectionError', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.connectionError,
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('No internet connection'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – badResponse with nested error.message
    // ---------------------------------------------------------------------------
    test('generateProgram handles badResponse with structured error map',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {'error': {'message': 'Structured error message'}},
        ),
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Structured error message'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – badResponse with flat message field
    // ---------------------------------------------------------------------------
    test('generateProgram handles badResponse with flat message field',
        () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 400,
          data: {'message': 'Flat error message'},
        ),
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Flat error message'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – DioException unknown
    // ---------------------------------------------------------------------------
    test('generateProgram handles DioException unknown', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        error: Exception('Inner error'),
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Something went wrong'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – DioException cancel
    // ---------------------------------------------------------------------------
    test('generateProgram handles DioException cancel', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.cancel,
      ));

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('Something went wrong'));
    });

    // ---------------------------------------------------------------------------
    // _extractErrorMessage – non-Dio Object (int)
    // ---------------------------------------------------------------------------
    test('generateProgram handles non-Dio Object (int) thrown', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.aiCoachGenerate,
            body: any(named: 'body'),
          )).thenThrow(42);

      await notifier.generateProgram('Build muscle');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, contains('42'));
    });
  });
}
