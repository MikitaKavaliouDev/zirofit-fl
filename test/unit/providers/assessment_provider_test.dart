import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/client_assessment_result.dart';
import 'package:zirofit_fl/data/models/trainer_assessment.dart';
import 'package:zirofit_fl/features/clients/providers/assessment_provider.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

const testClientId = 'test-client-id';
const testAssessmentId = 'test-assessment-id';

final _now = DateTime(2025, 1, 15, 10, 0, 0);

Map<String, dynamic> createSampleTemplateJson({String? id}) => {
      'id': id ?? 'tpl_1',
      'name': 'Push-ups',
      'description': 'Maximum push-ups in 60 seconds',
      'unit': 'count',
      'trainer_id': 'trainer-1',
      'created_at': _now.millisecondsSinceEpoch,
      'updated_at': _now.millisecondsSinceEpoch,
    };

Map<String, dynamic> createSampleResultJson({String? id}) => {
      'id': id ?? 'res_1',
      'client_id': testClientId,
      'assessment_id': testAssessmentId,
      'assessment_name': 'Push-ups',
      'value': 25,
      'unit': 'count',
      'notes': 'Felt strong today',
      'assessed_at': _now.millisecondsSinceEpoch,
      'created_at': _now.millisecondsSinceEpoch,
      'updated_at': _now.millisecondsSinceEpoch,
    };

// =============================================================================
// AssessmentNotifier
// =============================================================================

void main() {
  group('AssessmentNotifier', () {
    late MockApiClient mockApiClient;
    late AssessmentNotifier notifier;

    setUp(() {
      mockApiClient = MockApiClient();
      notifier = AssessmentNotifier(apiClient: mockApiClient);
    });

    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------

    test('initial state has empty templates, empty results, isLoading=false, '
        'error=null', () {
      final state = notifier.state;
      expect(state.templates, isEmpty);
      expect(state.clientResults, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    // ---------------------------------------------------------------------------
    // fetchTemplates
    // ---------------------------------------------------------------------------

    test('fetchTemplates sets isLoading true before completion', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      final future = notifier.fetchTemplates();
      expect(notifier.state.isLoading, isTrue);
      await future;
      expect(notifier.state.isLoading, isFalse);
    });

    test('fetchTemplates populates templates on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[
              createSampleTemplateJson(),
              createSampleTemplateJson(id: 'tpl_2'),
            ],
          });

      await notifier.fetchTemplates();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.templates.length, 2);
      expect(state.templates[0].name, 'Push-ups');
      expect(state.templates[0].unit, 'count');
    });

    test('fetchTemplates handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await notifier.fetchTemplates();

      expect(notifier.state.templates, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('fetchTemplates sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerAssessments),
        type: DioExceptionType.connectionTimeout,
      ));

      await notifier.fetchTemplates();

      expect(notifier.state.isLoading, false);
      expect(
          notifier.state.error, 'Connection timeout. Please try again.');
    });

    // ---------------------------------------------------------------------------
    // createTemplate
    // ---------------------------------------------------------------------------

    test('createTemplate posts and appends template to state', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': createSampleTemplateJson(id: 'tpl_new'),
          });

      final result = await notifier.createTemplate(
        name: 'Squat max',
        description: 'Maximum squat weight',
        unit: 'kg',
      );

      expect(result, isNotNull);
      expect(result!.name, 'Push-ups');
      expect(notifier.state.templates.length, 1);
      expect(notifier.state.templates.first.name, 'Push-ups');
    });

    test('createTemplate returns null on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions:
            RequestOptions(path: ApiConstants.trainerAssessments),
        response: Response(
          requestOptions:
              RequestOptions(path: ApiConstants.trainerAssessments),
          statusCode: 400,
          data: <String, dynamic>{
            'error': {'message': 'Invalid assessment data'},
          },
        ),
      ));

      final result = await notifier.createTemplate(
        name: '',
        description: null,
        unit: 'kg',
      );

      expect(result, isNull);
      expect(notifier.state.error, 'Invalid assessment data');
    });

    // ---------------------------------------------------------------------------
    // deleteTemplate
    // ---------------------------------------------------------------------------

    test('deleteTemplate removes template from state', () async {
      // Seed the state with a template
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[
              createSampleTemplateJson(),
            ],
          });
      await notifier.fetchTemplates();
      expect(notifier.state.templates.length, 1);

      // Mock the delete
      when(() => mockApiClient.delete(
            '${ApiConstants.trainerAssessments}/tpl_1',
          )).thenAnswer((_) async {});

      await notifier.deleteTemplate('tpl_1');

      expect(notifier.state.templates, isEmpty);
      expect(notifier.state.isLoading, false);
    });

    test('deleteTemplate sets error on failure', () async {
      when(() => mockApiClient.delete(
            '${ApiConstants.trainerAssessments}/nonexistent',
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: '${ApiConstants.trainerAssessments}/nonexistent'),
        type: DioExceptionType.badResponse,
      ));

      await notifier.deleteTemplate('nonexistent');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, 'Network error. Please try again.');
    });

    // ---------------------------------------------------------------------------
    // fetchClientResults
    // ---------------------------------------------------------------------------

    test('fetchClientResults populates results on success', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientAssessments(testClientId),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[
              createSampleResultJson(),
              createSampleResultJson(id: 'res_2'),
            ],
          });

      await notifier.fetchClientResults(testClientId);

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.clientResults.length, 2);
      expect(state.clientResults[0].value, 25);
      expect(state.clientResults[0].unit, 'count');
    });

    test('fetchClientResults handles empty response', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientAssessments(testClientId),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': <dynamic>[],
          });

      await notifier.fetchClientResults(testClientId);

      expect(notifier.state.clientResults, isEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
    });

    test('fetchClientResults sets error on failure', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.clientAssessments(testClientId),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: ApiConstants.clientAssessments(testClientId)),
        type: DioExceptionType.connectionError,
      ));

      await notifier.fetchClientResults(testClientId);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error,
          'No internet connection. Please check your network.');
    });

    // ---------------------------------------------------------------------------
    // addClientResult
    // ---------------------------------------------------------------------------

    test('addClientResult posts and appends result to state', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientAssessments(testClientId),
            body: any(named: 'body'),
          )).thenAnswer((_) async => <String, dynamic>{
            'data': createSampleResultJson(id: 'res_new'),
          });

      final success = await notifier.addClientResult(
        clientId: testClientId,
        assessmentId: testAssessmentId,
        value: 30,
        notes: 'Great improvement',
      );

      expect(success, isTrue);
      expect(notifier.state.clientResults.length, 1);
      expect(notifier.state.clientResults.first.value, 25);
      expect(
          notifier.state.clientResults.first.notes, 'Felt strong today');
    });

    test('addClientResult returns false on failure', () async {
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.clientAssessments(testClientId),
            body: any(named: 'body'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(
            path: ApiConstants.clientAssessments(testClientId)),
        response: Response(
          requestOptions: RequestOptions(
              path: ApiConstants.clientAssessments(testClientId)),
          statusCode: 500,
          data: <String, dynamic>{
            'error': {'message': 'Server error'},
          },
        ),
      ));

      final success = await notifier.addClientResult(
        clientId: testClientId,
        assessmentId: testAssessmentId,
        value: -1,
      );

      expect(success, isFalse);
      expect(notifier.state.error, 'Server error');
    });
  });
}
