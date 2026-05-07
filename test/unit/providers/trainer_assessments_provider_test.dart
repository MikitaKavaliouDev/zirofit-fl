import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/trainer_assessment.dart';
import 'package:zirofit_fl/features/trainer/providers/trainer_assessments_provider.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TrainerAssessmentsNotifier notifier;

  setUp(() {
    mockApiClient = MockApiClient();
    notifier = TrainerAssessmentsNotifier(apiClient: mockApiClient);
  });

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  TrainerAssessment createAssessment({
    String id = 'assess-1',
    String name = 'Body Fat %',
    String? description,
    String unit = 'kg',
  }) =>
      TrainerAssessment(
        id: id,
        name: name,
        description: description,
        unit: unit,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

  List<TrainerAssessment> createAssessments() => [
        createAssessment(
          id: 'assess-1',
          name: 'Body Fat %',
          unit: '%',
          description: 'Body fat percentage measurement',
        ),
        createAssessment(
          id: 'assess-2',
          name: 'Weight',
          unit: 'kg',
        ),
      ];

  Map<String, dynamic> mockResponse(List<dynamic> data) => {'data': data};

  group('TrainerAssessmentsNotifier', () {
    // ---------------------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------------------
    test('Test 1: fetchAssessments populates list', () async {
      final assessments = createAssessments();

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockResponse(
              assessments.map((a) => a.toJson()).toList()));

      await notifier.fetchAssessments();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.assessments.length, 2);
      expect(notifier.state.assessments[0].name, 'Body Fat %');
      expect(notifier.state.assessments[1].name, 'Weight');
    });

    // ---------------------------------------------------------------------------
    // Create assessment
    // ---------------------------------------------------------------------------
    test('Test 2: createAssessment adds assessment', () async {
      final newAssessment = createAssessment(
        id: 'assess-3',
        name: 'Height',
        unit: 'cm',
      );

      final data = {
        'name': 'Height',
        'unit': 'cm',
      };

      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            body: data,
          )).thenAnswer((_) async => {'data': newAssessment.toJson()});

      await notifier.createAssessment(data);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.assessments.length, 1);
      expect(notifier.state.assessments[0].name, 'Height');
    });

    // ---------------------------------------------------------------------------
    // Update assessment
    // ---------------------------------------------------------------------------
    test('Test 3: updateAssessment modifies existing', () async {
      // Start with one assessment in state
      final initial = createAssessment();
      when(() => mockApiClient.post<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            body: any(named: 'body'),
          )).thenAnswer((_) async => {'data': initial.toJson()});

      await notifier.createAssessment({'name': 'Old Name', 'unit': 'kg'});

      // Now update it
      final updatedAssessment = createAssessment(
        name: 'Updated Name',
        unit: 'lb',
      );

      final updateData = {
        'name': 'Updated Name',
        'unit': 'lb',
      };

      when(() => mockApiClient.put<Map<String, dynamic>>(
            '${ApiConstants.trainerAssessments}/assess-1',
            body: updateData,
          )).thenAnswer((_) async => {'data': updatedAssessment.toJson()});

      await notifier.updateAssessment('assess-1', updateData);

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.assessments.length, 1);
      expect(notifier.state.assessments[0].name, 'Updated Name');
      expect(notifier.state.assessments[0].unit, 'lb');
    });

    // ---------------------------------------------------------------------------
    // Delete assessment
    // ---------------------------------------------------------------------------
    test('Test 4: deleteAssessment removes assessment', () async {
      // Start with two assessments
      final assessments = createAssessments();

      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            queryParams: any(named: 'queryParams'),
          )).thenAnswer((_) async => mockResponse(
              assessments.map((a) => a.toJson()).toList()));

      await notifier.fetchAssessments();
      expect(notifier.state.assessments.length, 2);

      // Delete one
      when(() => mockApiClient.delete(
            '${ApiConstants.trainerAssessments}/assess-1',
          )).thenAnswer((_) async => {});

      await notifier.deleteAssessment('assess-1');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNull);
      expect(notifier.state.assessments.length, 1);
      expect(notifier.state.assessments[0].id, 'assess-2');
    });

    // ---------------------------------------------------------------------------
    // Error states
    // ---------------------------------------------------------------------------
    test('Test 5: error states are handled', () async {
      when(() => mockApiClient.get<Map<String, dynamic>>(
            ApiConstants.trainerAssessments,
            queryParams: any(named: 'queryParams'),
          )).thenThrow(Exception('Network failure'));

      await notifier.fetchAssessments();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.error, isNotNull);
      expect(notifier.state.assessments, isEmpty);
    });
  });
}
