import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zirofit_fl/core/constants/api_constants.dart';
import 'package:zirofit_fl/features/programs/data/program_template_remote_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late ProgramTemplateRemoteSource remoteSource;

  setUp(() {
    mockDio = MockDio();
    remoteSource = ProgramTemplateRemoteSource(mockDio);
  });

  group('fetchProgramsAndTemplates', () {
    test('returns programs and templates map on success', () async {
      final responseData = {
        'data': {
          'userPrograms': [],
          'systemPrograms': [],
          'userTemplates': [],
          'systemTemplates': [],
        },
      };

      when(() => mockDio.get(
            ApiConstants.trainerPrograms,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
            data: responseData,
            statusCode: 200,
          ));

      final result = await remoteSource.fetchProgramsAndTemplates();

      expect(result, responseData);
    });

    test('throws on network error', () async {
      when(() => mockDio.get(
            ApiConstants.trainerPrograms,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
        type: DioExceptionType.connectionTimeout,
      ));

      expect(
        () => remoteSource.fetchProgramsAndTemplates(),
        throwsA(isA<DioException>()),
      );
    });
  });

  group('createProgram', () {
    test('sends POST with name and optional description and returns response',
        () async {
      final responseData = {
        'data': {
          'program': {
            'id': 'prog-1',
            'name': 'Test Program',
            'description': 'A test',
          },
        },
      };

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
            data: responseData,
            statusCode: 201,
          ));

      final result = await remoteSource.createProgram('Test Program', 'A test');

      expect(result, responseData);
    });

    test('omits description when null', () async {
      Map<String, dynamic>? capturedData;
      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerPrograms,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((invocation) async {
            capturedData =
                invocation.namedArguments[#data] as Map<String, dynamic>?;
            return Response(
              requestOptions: RequestOptions(path: ApiConstants.trainerPrograms),
              data: {'data': {'program': {'id': 'p1', 'name': 'Minimal'}}},
              statusCode: 201,
            );
          });

      await remoteSource.createProgram('Minimal', null);

      expect(capturedData, isNotNull);
      expect(capturedData!['name'], 'Minimal');
      expect(capturedData!.containsKey('description'), isFalse);
    });
  });

  group('createTemplate', () {
    test('sends POST with name, description, programId', () async {
      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.trainerProgramTemplates,
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.trainerProgramTemplates),
            data: {'data': {'template': {'id': 'tmpl-1', 'name': 'Workout A'}}},
            statusCode: 201,
          ));

      final result =
          await remoteSource.createTemplate('Workout A', 'Push day', 'prog-1');

      expect(result, {'data': {'template': {'id': 'tmpl-1', 'name': 'Workout A'}}});
    });
  });

  group('fetchTemplates', () {
    test('returns templates list', () async {
      final responseData = {
        'data': {'templates': []},
      };

      when(() => mockDio.get(
            ApiConstants.trainerProgramTemplates,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.trainerProgramTemplates),
            data: responseData,
            statusCode: 200,
          ));

      final result = await remoteSource.fetchTemplates();

      expect(result, responseData);
    });
  });

  group('addExerciseStep', () {
    test('sends POST with exercise fields', () async {
      const templateId = 'tmpl-1';
      final fields = {
        'exerciseId': 'ex-1',
        'targetReps': '8-12',
        'targetSets': 3,
        'tempo': '3010',
        'exerciseCategory': 'MAIN',
        'durationSeconds': 60,
      };

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.templateExercises(templateId),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(
                path: ApiConstants.templateExercises(templateId)),
            data: {'data': {'templateExercise': {'id': 'te-1'}}},
            statusCode: 201,
          ));

      final result = await remoteSource.addExerciseStep(templateId, fields);

      expect(result, {'data': {'templateExercise': {'id': 'te-1'}}});
    });
  });

  group('addRestStep', () {
    test('sends POST with durationSeconds', () async {
      const templateId = 'tmpl-1';

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.templateRest(templateId),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.templateRest(templateId)),
            data: {'data': {'restStep': {'id': 'te-2', 'durationSeconds': 90}}},
            statusCode: 201,
          ));

      final result = await remoteSource.addRestStep(templateId, 90);

      expect(result, {'data': {'restStep': {'id': 'te-2', 'durationSeconds': 90}}});
    });
  });

  group('deleteExerciseStep', () {
    test('sends DELETE to correct endpoint', () async {
      const templateId = 'tmpl-1';
      const stepId = 'te-1';

      when(() => mockDio.delete(
            ApiConstants.templateExerciseStep(templateId, stepId),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(
              path: ApiConstants.templateExerciseStep(templateId, stepId),
            ),
            data: {'data': {'message': 'Deleted'}},
            statusCode: 200,
          ));

      await remoteSource.deleteExerciseStep(templateId, stepId);
      // No exception = success
    });
  });

  group('copyTemplate', () {
    test('sends POST to copy endpoint', () async {
      const templateId = 'sys-tmpl-1';

      when(() => mockDio.post<Map<String, dynamic>>(
            ApiConstants.templateCopy(templateId),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onSendProgress: any(named: 'onSendProgress'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions:
                RequestOptions(path: ApiConstants.templateCopy(templateId)),
            data: {
              'data': {
                'newTemplate': {'id': 'new-tmpl-1'},
                'newProgram': null,
              },
            },
            statusCode: 201,
          ));

      final result = await remoteSource.copyTemplate(templateId);

      expect(result, isA<Map<String, dynamic>>());
    });
  });

  group('searchExercises', () {
    test('sends GET with search query', () async {
      when(() => mockDio.get(
            ApiConstants.exercises,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.exercises),
            data: {
              'data': {
                'exercises': [],
                'total': 0,
                'page': 1,
                'hasMore': false,
              },
            },
            statusCode: 200,
          ));

      final result = await remoteSource.searchExercises(search: 'bench');

      expect(result, isA<Map<String, dynamic>>());
    });

    test('sends GET without search returns all exercises', () async {
      when(() => mockDio.get(
            ApiConstants.exercises,
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
            cancelToken: any(named: 'cancelToken'),
            onReceiveProgress: any(named: 'onReceiveProgress'),
          )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.exercises),
            data: {
              'data': {
                'exercises': [],
                'total': 0,
                'page': 1,
                'hasMore': false,
              },
            },
            statusCode: 200,
          ));

      final result = await remoteSource.searchExercises();

      expect(result, isA<Map<String, dynamic>>());
    });
  });
}
