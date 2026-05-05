import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
import 'package:zirofit_fl/data/models/api_response.dart';
import 'package:zirofit_fl/data/models/exercise.dart';
import 'package:zirofit_fl/features/exercises/data/exercise_remote_source.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ExerciseRemoteSource remoteSource;

  setUp(() {
    mockApiClient = MockApiClient();
    remoteSource = ExerciseRemoteSource(apiClient: mockApiClient);
  });

  group('ExerciseRemoteSource', () {
    group('searchExercises', () {
      final testExercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          muscleGroup: 'Chest',
          category: 'Strength',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
        Exercise(
          id: '2',
          name: 'Squat',
          muscleGroup: 'Legs',
          category: 'Strength',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      ];

      setUp(() {
        when(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: any(named: 'queryParams'),
              fromJson: any(named: 'fromJson'),
            )).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(
                    Map<String, dynamic>,
                  );
          // Backend returns {data: {exercises: [...], total, page, hasMore}}
          return fromJson({
            'data': {
              'exercises': [
                {
                  'id': '1',
                  'name': 'Bench Press',
                  'muscle_group': 'Chest',
                  'category': 'Strength',
                  'created_at': 1704067200000,
                  'updated_at': 1704067200000,
                },
                {
                  'id': '2',
                  'name': 'Squat',
                  'muscle_group': 'Legs',
                  'category': 'Strength',
                  'created_at': 1704067200000,
                  'updated_at': 1704067200000,
                },
              ],
              'total': 2,
              'page': 1,
              'hasMore': false,
            },
          });
        });
      });

      // ---------------------------------------------------------------------------
      // Default params
      // ---------------------------------------------------------------------------
      test('sends default params (page=1, limit=50) when no optional params', () async {
        await remoteSource.searchExercises();

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      // ---------------------------------------------------------------------------
      // Empty optional params are excluded
      // ---------------------------------------------------------------------------
      test('excludes empty search string from queryParams', () async {
        await remoteSource.searchExercises(search: '');

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      test('excludes empty category string from queryParams', () async {
        await remoteSource.searchExercises(category: '');

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      test('excludes empty muscleGroup string from queryParams', () async {
        await remoteSource.searchExercises(muscleGroup: '');

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      // ---------------------------------------------------------------------------
      // Populated optional params are included
      // ---------------------------------------------------------------------------
      test('includes search param when provided', () async {
        await remoteSource.searchExercises(search: 'chest');

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
                'search': 'chest',
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      test('includes category param when provided', () async {
        await remoteSource.searchExercises(category: 'Strength');

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
                'category': 'Strength',
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      test('includes muscle_group param when provided', () async {
        await remoteSource.searchExercises(muscleGroup: 'Chest');

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
                'muscle_group': 'Chest',
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      test('includes all params when all provided', () async {
        await remoteSource.searchExercises(
          search: 'press',
          category: 'Strength',
          muscleGroup: 'Chest',
        );

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 1,
                'limit': 50,
                'search': 'press',
                'category': 'Strength',
                'muscle_group': 'Chest',
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      // ---------------------------------------------------------------------------
      // Custom pagination
      // ---------------------------------------------------------------------------
      test('custom pagination (page=3, limit=10)', () async {
        await remoteSource.searchExercises(page: 3, limit: 10);

        verify(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {
                'page': 3,
                'limit': 10,
              },
              fromJson: any(named: 'fromJson'),
            )).called(1);
      });

      // ---------------------------------------------------------------------------
      // Return values
      // ---------------------------------------------------------------------------
      test('returns ApiResponse with data on success', () async {
        final result = await remoteSource.searchExercises();

        expect(result, isA<ApiResponse<List<Exercise>>>());
        expect(result.data, hasLength(2));
        expect(result.data![0].name, 'Bench Press');
        expect(result.data![1].name, 'Squat');
        expect(result.errorMessage, isNull);
      });

      test('handles API error properly (ApiResponse with errorMessage)', () async {
        when(() => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: any(named: 'queryParams'),
              fromJson: any(named: 'fromJson'),
            )).thenAnswer((invocation) async {
          final fromJson =
              invocation.namedArguments[#fromJson]
                  as ApiResponse<List<Exercise>> Function(
                    Map<String, dynamic>,
                  );
          return fromJson({
            'error': {
              'message': 'Failed to load exercises',
              'code': 'FETCH_ERROR',
              'statusCode': 500,
            },
          });
        });

        final result = await remoteSource.searchExercises();

        expect(result, isA<ApiResponse<List<Exercise>>>());
        expect(result.errorMessage, 'Failed to load exercises');
        expect(result.data, isNull);
      });

      // ---------------------------------------------------------------------------
      // fromJson parser verification
      // ---------------------------------------------------------------------------
      test('passes fromJson parser to ApiClient.get', () async {
        await remoteSource.searchExercises();

        final captured = verify(() =>
                mockApiClient.get<ApiResponse<List<Exercise>>>(
                  ApiConstants.exercises,
                  queryParams: any(named: 'queryParams'),
                  fromJson: captureAny(named: 'fromJson'),
                )).captured;

        expect(captured, hasLength(1));
        expect(captured.first, isNotNull);
      });
    });
  });
}
