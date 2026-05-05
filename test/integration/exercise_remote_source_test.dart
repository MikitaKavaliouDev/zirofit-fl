import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/core/network/api_client.dart';
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

Map<String, dynamic> _exerciseJson({
  String id = 'ex-1',
  String name = 'Bench Press',
  String muscleGroup = 'Chest',
  String category = 'Strength',
}) => {
  'id': id,
  'name': name,
  'muscle_group': muscleGroup,
  'category': category,
  'created_at': 1704067200000,
  'updated_at': 1704067200000,
};

/// Wraps a list of exercise fixtures in the backend response envelope.
///
/// The backend returns:
/// ```json
/// { "data": { "exercises": [...], "total": 1, "page": 1, "hasMore": false } }
/// ```
Map<String, dynamic> _searchResponse({
  List<Map<String, dynamic>> exercises = const [],
  int total = 0,
  int page = 1,
  bool hasMore = false,
}) => {
  'data': {
    'exercises': exercises,
    'total': total,
    'page': page,
    'hasMore': hasMore,
  },
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
    group('searchExercises', () {
      test(
        'sends default params (page=1, limit=50) when no optional params',
        () async {
          when(
            () => mockApiClient.get<ApiResponse<List<Exercise>>>(
              any(),
              queryParams: any(named: 'queryParams'),
              fromJson: any(named: 'fromJson'),
            ),
          ).thenAnswer((invocation) async {
            final fromJson =
                invocation.namedArguments[#fromJson]
                    as ApiResponse<List<Exercise>> Function(
                      Map<String, dynamic>,
                    );
            return fromJson(_searchResponse(exercises: [_exerciseJson()]));
          });

          await remoteSource.searchExercises();

          verify(
            () => mockApiClient.get<ApiResponse<List<Exercise>>>(
              ApiConstants.exercises,
              queryParams: {'page': 1, 'limit': 50},
              fromJson: any(named: 'fromJson'),
            ),
          ).called(1);
        },
      );

      test('includes search param when provided', () async {
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
          return fromJson(_searchResponse(exercises: [_exerciseJson()]));
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

      test('includes category param when provided', () async {
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
          return fromJson(_searchResponse(exercises: [_exerciseJson()]));
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

      test('includes muscle_group param when provided', () async {
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
          return fromJson(_searchResponse(exercises: [_exerciseJson()]));
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

      test('includes all params when all provided', () async {
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
          return fromJson(_searchResponse(exercises: [_exerciseJson()]));
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

      test('returns exercises on success', () async {
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
          return fromJson(
            _searchResponse(
              exercises: [
                _exerciseJson(id: 'ex-1', name: 'Bench Press'),
                _exerciseJson(id: 'ex-2', name: 'Squat'),
              ],
              total: 2,
              page: 1,
              hasMore: false,
            ),
          );
        });

        final result = await remoteSource.searchExercises();

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<Exercise>>());
        expect(result.data, hasLength(2));
        expect(result.data![0].id, 'ex-1');
        expect(result.data![0].name, 'Bench Press');
        expect(result.data![1].id, 'ex-2');
        expect(result.data![1].name, 'Squat');
      });

      test('handles API error', () async {
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
          // Backend error format: { error: { message, code, statusCode } }
          return fromJson({
            'error': {
              'message': 'Failed to load',
              'code': 'ERROR',
              'statusCode': 500,
            },
          });
        });

        final result = await remoteSource.searchExercises();

        expect(result.isError, isTrue);
        expect(result.data, isNull);
        expect(result.errorMessage, 'Failed to load');
        expect(result.errorCode, 'ERROR');
        expect(result.statusCode, 500);
      });

      test('handles empty exercise list', () async {
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
          return fromJson(
            _searchResponse(exercises: [], total: 0, page: 1, hasMore: false),
          );
        });

        final result = await remoteSource.searchExercises();

        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<Exercise>>());
        expect(result.data, isEmpty);
      });
    });
  });
}
