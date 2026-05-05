import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';

import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/core/network/api_exception.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';

// ---------------------------------------------------------------------------
// Mock
// ---------------------------------------------------------------------------

class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// Fixture helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> exerciseJson({
  String id = 'ex-1',
  String name = 'Bench Press',
  String? muscleGroup = 'Chest',
  String? equipment = 'Barbell',
  String? category = 'Strength',
  String? description = 'Lie on a bench and press the bar upward',
  String? videoUrl,
  String? createdById,
  int? recommendedRestSeconds = 90,
  bool isUnilateral = false,
}) => {
  'id': id,
  'name': name,
  if (muscleGroup != null) 'muscle_group': muscleGroup,
  if (equipment != null) 'equipment': equipment,
  if (category != null) 'category': category,
  if (description != null) 'description': description,
  if (videoUrl != null) 'video_url': videoUrl,
  if (createdById != null) 'created_by_id': createdById,
  if (recommendedRestSeconds != null)
    'recommended_rest_seconds': recommendedRestSeconds,
  'is_unilateral': isUnilateral,
  'created_at': 1700000000000,
  'updated_at': 1700000000000,
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockApiClient mockApiClient;
  late ExerciseRemoteSource remoteSource;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteSource = ExerciseRemoteSource(apiClient: mockApiClient);
  });

  group('ExerciseRemoteSource', () {
    // =========================================================================
    // searchExercises
    // =========================================================================

    group('searchExercises', () {
      test('with default params calls correct endpoint', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({
            'data': [exerciseJson()],
          });
        });

        await remoteSource.searchExercises();

        verify(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            ApiConstants.exercises,
            queryParams: {'page': 1, 'limit': 50},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('with search term passes search query param', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({
            'data': [exerciseJson()],
          });
        });

        await remoteSource.searchExercises(search: 'bench');

        verify(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            ApiConstants.exercises,
            queryParams: {'page': 1, 'limit': 50, 'search': 'bench'},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('with category filter passes category query param', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({
            'data': [exerciseJson()],
          });
        });

        await remoteSource.searchExercises(category: 'Strength');

        verify(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            ApiConstants.exercises,
            queryParams: {'page': 1, 'limit': 50, 'category': 'Strength'},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('with muscleGroup filter passes muscle_group query param', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({
            'data': [exerciseJson()],
          });
        });

        await remoteSource.searchExercises(muscleGroup: 'Chest');

        verify(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            ApiConstants.exercises,
            queryParams: {'page': 1, 'limit': 50, 'muscle_group': 'Chest'},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('with all filters combined passes all query params', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({
            'data': [exerciseJson()],
          });
        });

        await remoteSource.searchExercises(
          search: 'bench',
          category: 'Strength',
          muscleGroup: 'Chest',
          page: 2,
          limit: 20,
        );

        verify(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            ApiConstants.exercises,
            queryParams: {
              'page': 2,
              'limit': 20,
              'search': 'bench',
              'category': 'Strength',
              'muscle_group': 'Chest',
            },
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('with custom pagination passes page and limit params', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({
            'data': [exerciseJson()],
          });
        });

        await remoteSource.searchExercises(page: 2, limit: 20);

        verify(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            ApiConstants.exercises,
            queryParams: {'page': 2, 'limit': 20},
            fromJson: any(named: 'fromJson'),
          ),
        ).called(1);
      });

      test('empty response returns empty list', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          return fromJson({'data': <Map<String, dynamic>>[]});
        });

        final result = await remoteSource.searchExercises();

        expect(result.data, isA<List<Exercise>>());
        expect(result.data, isEmpty);
        expect(result.isSuccess, isTrue);
      });

      test('error response propagates DioException', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            message: 'Connection refused',
          ),
        );

        expect(remoteSource.searchExercises(), throwsA(isA<DioException>()));
      });

      test('response.data is null returns ApiResponse with error', () async {
        when(
          () => mockApiClient.get<ApiResponse<List<Exercise>>>(
            any(),
            queryParams: any(named: 'queryParams'),
            fromJson: any(named: 'fromJson'),
          ),
        ).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(Map<String, dynamic>);
          // JSON without a 'data' key triggers the error path in
          // apiResponseListFromJson.
          return fromJson({});
        });

        final result = await remoteSource.searchExercises();

        expect(result.data, isNull);
        expect(result.isError, isTrue);
        expect(result.errorMessage, 'Unknown response format');
      });
    });
  });
}
